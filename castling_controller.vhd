library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chess_logic_types.all;

entity castling_controller is
    Port (
        CLK              : in  STD_LOGIC;
        RESET            : in  STD_LOGIC;
        move_piece       : in  STD_LOGIC_VECTOR(3 downto 0);
        move_from       : in  STD_LOGIC_VECTOR(5 downto 0);
        move_to         : in  STD_LOGIC_VECTOR(5 downto 0);
        player_color    : in  STD_LOGIC;
        make_move      : in  STD_LOGIC;
        board_input    : in  STD_LOGIC_VECTOR(255 downto 0);
        castling_allowed : out STD_LOGIC;
        rook_move_from  : out STD_LOGIC_VECTOR(5 downto 0);
        rook_move_to    : out STD_LOGIC_VECTOR(5 downto 0)
    );
end entity;

architecture Behavioral of castling_controller is
    -- Track if kings or rooks have moved
    signal white_king_moved, black_king_moved : boolean := false;
    signal white_rook_a_moved, white_rook_h_moved : boolean := false;
    signal black_rook_a_moved, black_rook_h_moved : boolean := false;

    -- Function to check if squares between positions are empty
    function is_path_clear(
        board : std_logic_vector(255 downto 0);
        start_pos : std_logic_vector(5 downto 0);
        end_pos : std_logic_vector(5 downto 0)
    ) return boolean is
        variable start_col : integer;
        variable end_col : integer;
        variable row : integer;
        variable pos : integer;
    begin
        start_col := to_integer(unsigned(start_pos(2 downto 0)));
        end_col := to_integer(unsigned(end_pos(2 downto 0)));
        row := to_integer(unsigned(start_pos(5 downto 3)));

        -- Check each square between start and end (exclusive)
        for col in (start_col + 1) to (end_col - 1) loop
            pos := (row * 8 + col) * 4;  -- Calculate board vector position
            -- Check if square is empty (piece type is PIECE_NONE)
            if board(pos+2 downto pos) /= PIECE_NONE then
                return false;
            end if;
        end loop;

        return true;
    end function;

begin
    -- Process to track piece movements
    process(CLK, RESET)
    begin
        if RESET = '1' then
            -- Reset all movement flags
            white_king_moved <= false;
            black_king_moved <= false;
            white_rook_a_moved <= false;
            white_rook_h_moved <= false;
            black_rook_a_moved <= false;
            black_rook_h_moved <= false;
        elsif rising_edge(CLK) then
            if make_move = '1' then
                -- Track king moves
                if move_piece = WHITE_KING then
                    white_king_moved <= true;
                elsif move_piece = BLACK_KING then
                    black_king_moved <= true;
                -- Track rook moves
                elsif move_piece = WHITE_ROOK then
                    if move_from = "111000" then -- a1
                        white_rook_a_moved <= true;
                    elsif move_from = "111111" then -- h1
                        white_rook_h_moved <= true;
                    end if;
                elsif move_piece = BLACK_ROOK then
                    if move_from = "000000" then -- a8
                        black_rook_a_moved <= true;
                    elsif move_from = "000111" then -- h8
                        black_rook_h_moved <= true;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Castling validation logic
    process(player_color, move_from, move_to, white_king_moved, black_king_moved,
            white_rook_a_moved, white_rook_h_moved, black_rook_a_moved, black_rook_h_moved,
            board_input)
        variable path_clear : boolean;
    begin
        -- Default outputs
        castling_allowed <= '0';
        rook_move_from <= (others => '0');
        rook_move_to <= (others => '0');

        -- White castling
        if player_color = COLOR_WHITE and (not white_king_moved) then
            -- Check kingside castling
            if move_from = "111100" and  -- e1
               move_to = "111110" and    -- g1
               (not white_rook_h_moved) then
                -- Check if path is clear between king and rook
                path_clear := is_path_clear(board_input, "111100", "111111"); -- e1 to h1
                if path_clear then
                    castling_allowed <= '1';
                    rook_move_from <= "111111"; -- h1
                    rook_move_to <= "111101";   -- f1
                end if;
            -- Check queenside castling
            elsif move_from = "111100" and  -- e1
                  move_to = "111010" and    -- c1
                  (not white_rook_a_moved) then
                -- Check if path is clear between king and rook
                path_clear := is_path_clear(board_input, "111000", "111100"); -- a1 to e1
                if path_clear then
                    castling_allowed <= '1';
                    rook_move_from <= "111000"; -- a1
                    rook_move_to <= "111011";   -- d1
                end if;
            end if;
        -- Black castling
        elsif player_color = COLOR_BLACK and (not black_king_moved) then
            -- Check kingside castling
            if move_from = "000100" and  -- e8
               move_to = "000110" and    -- g8
               (not black_rook_h_moved) then
                -- Check if path is clear between king and rook
                path_clear := is_path_clear(board_input, "000100", "000111"); -- e8 to h8
                if path_clear then
                    castling_allowed <= '1';
                    rook_move_from <= "000111"; -- h8
                    rook_move_to <= "000101";   -- f8
                end if;
            -- Check queenside castling
            elsif move_from = "000100" and  -- e8
                  move_to = "000010" and    -- c8
                  (not black_rook_a_moved) then
                -- Check if path is clear between king and rook
                path_clear := is_path_clear(board_input, "000000", "000100"); -- a8 to e8
                if path_clear then
                    castling_allowed <= '1';
                    rook_move_from <= "000000"; -- a8
                    rook_move_to <= "000011";   -- d8
                end if;
            end if;
        end if;
    end process;

end architecture;