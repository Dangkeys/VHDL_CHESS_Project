library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chess_logic_types.all;

entity board_manager is
    Port (
        CLK              : in  STD_LOGIC;
        RESET            : in  STD_LOGIC;
        state            : in  STD_LOGIC_VECTOR(2 downto 0);
        player_color     : in  STD_LOGIC;
        selected_pos     : in  STD_LOGIC_VECTOR(5 downto 0);
        target_pos       : in  STD_LOGIC_VECTOR(5 downto 0);
        rook_from_pos    : in  STD_LOGIC_VECTOR(5 downto 0);
        rook_to_pos      : in  STD_LOGIC_VECTOR(5 downto 0);
        promotion_piece  : in  STD_LOGIC_VECTOR(1 downto 0);
        board_input     : in  STD_LOGIC_VECTOR(255 downto 0);  -- Added board_input
        board_out_addr   : buffer STD_LOGIC_VECTOR(5 downto 0);
        board_out_piece  : buffer STD_LOGIC_VECTOR(3 downto 0);
        board_change_en  : out STD_LOGIC;
        is_initial_state : out STD_LOGIC
    );
end entity;

architecture Behavioral of board_manager is
    -- Signal declarations
    signal selected_piece : STD_LOGIC_VECTOR(3 downto 0);
begin
    process(CLK, RESET)
    begin
        if RESET = '1' then
            board_out_addr <= (others => '0');
            board_out_piece <= EMPTY_SQUARE;
            board_change_en <= '0';
            is_initial_state <= '1';
        elsif rising_edge(CLK) then
            board_change_en <= '0';
            is_initial_state <= '0';

            -- Get the piece at selected position
            selected_piece <= board_input((to_integer(unsigned(selected_pos)) * 4) + 3 
                                      downto (to_integer(unsigned(selected_pos)) * 4));

            case state is
                when INITIAL =>
                    board_change_en <= '1';
                    is_initial_state <= '1';
                    
                    -- Set up initial board position
                    case board_out_addr is
                        -- Black back rank
                        when "000000" => board_out_piece <= BLACK_ROOK;
                        when "000001" => board_out_piece <= BLACK_KNIGHT;
                        when "000010" => board_out_piece <= BLACK_BISHOP;
                        when "000011" => board_out_piece <= BLACK_QUEEN;
                        when "000100" => board_out_piece <= BLACK_KING;
                        when "000101" => board_out_piece <= BLACK_BISHOP;
                        when "000110" => board_out_piece <= BLACK_KNIGHT;
                        when "000111" => board_out_piece <= BLACK_ROOK;
                        
                        -- Black pawns
                        when "001000"|"001001"|"001010"|"001011"|
                             "001100"|"001101"|"001110"|"001111" => 
                            board_out_piece <= BLACK_PAWN;
                        
                        -- White back rank
                        when "111000" => board_out_piece <= WHITE_ROOK;
                        when "111001" => board_out_piece <= WHITE_KNIGHT;
                        when "111010" => board_out_piece <= WHITE_BISHOP;
                        when "111011" => board_out_piece <= WHITE_QUEEN;
                        when "111100" => board_out_piece <= WHITE_KING;
                        when "111101" => board_out_piece <= WHITE_BISHOP;
                        when "111110" => board_out_piece <= WHITE_KNIGHT;
                        when "111111" => board_out_piece <= WHITE_ROOK;
                        
                        -- White pawns
                        when "110000"|"110001"|"110010"|"110011"|
                             "110100"|"110101"|"110110"|"110111" => 
                            board_out_piece <= WHITE_PAWN;
                            
                        -- Empty squares
                        when others => board_out_piece <= EMPTY_SQUARE;
                    end case;

                    -- Increment address counter during initialization
                    if board_out_addr = "111111" then
                        board_change_en <= '0';
                    else
                        board_out_addr <= std_logic_vector(unsigned(board_out_addr) + 1);
                    end if;

                when WRITE_NEW_PIECE =>
                    board_change_en <= '1';
                    board_out_addr <= target_pos;
                    
                    -- Handle pawn promotion
                    if selected_piece(2 downto 0) = PIECE_PAWN and
                       ((player_color = COLOR_WHITE and target_pos(5 downto 3) = "000") or
                        (player_color = COLOR_BLACK and target_pos(5 downto 3) = "111")) then
                        -- Promotion logic
                        case promotion_piece is
                            when "00" => board_out_piece <= player_color & PIECE_QUEEN;
                            when "01" => board_out_piece <= player_color & PIECE_ROOK;
                            when "10" => board_out_piece <= player_color & PIECE_BISHOP;
                            when "11" => board_out_piece <= player_color & PIECE_KNIGHT;
                            when others => board_out_piece <= player_color & PIECE_QUEEN;
                        end case;
                    else
                        -- Normal move - keep the original piece
                        board_out_piece <= selected_piece;
                    end if;

                when MOVE_ROOK =>
                    board_change_en <= '1';
                    board_out_addr <= rook_to_pos;
                    board_out_piece <= player_color & PIECE_ROOK;

                when CLEAR_KING =>
                    board_change_en <= '1';
                    board_out_addr <= selected_pos;
                    board_out_piece <= EMPTY_SQUARE;

                when CLEAR_ROOK =>
                    board_change_en <= '1';
                    board_out_addr <= rook_from_pos;
                    board_out_piece <= EMPTY_SQUARE;

                when ERASE_OLD_PIECE =>
                    board_change_en <= '1';
                    board_out_addr <= selected_pos;
                    board_out_piece <= EMPTY_SQUARE;

                when others =>
                    board_change_en <= '0';
            end case;
        end if;
    end process;

end Behavioral;