library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity chess_logic_module is
    Port ( 
        CLK                 : in  STD_LOGIC;
        RESET              : in  STD_LOGIC;
        board_input        : in  STD_LOGIC_VECTOR(255 downto 0);
        board_out_addr     : buffer STD_LOGIC_VECTOR(5 downto 0);  -- Changed to buffer
        board_out_piece    : buffer STD_LOGIC_VECTOR(3 downto 0);  -- Changed to buffer
        board_change_en_wire : out STD_LOGIC;
        BtnL               : in  STD_LOGIC;
        BtnU               : in  STD_LOGIC;
        BtnR               : in  STD_LOGIC;
        BtnD               : in  STD_LOGIC;
        BtnC               : in  STD_LOGIC;
        cursor_addr        : buffer STD_LOGIC_VECTOR(5 downto 0);  -- Changed to buffer
        selected_addr      : buffer STD_LOGIC_VECTOR(5 downto 0);  -- Changed to buffer
        hilite_selected_square : out STD_LOGIC;
        state              : out STD_LOGIC_VECTOR(2 downto 0);
        move_is_legal      : buffer STD_LOGIC;  -- Changed to buffer
        is_in_initial_state : out STD_LOGIC;
        Sw0                : in  STD_LOGIC;
        Sw1                : in  STD_LOGIC;
        promotion_piece    : buffer STD_LOGIC_VECTOR(1 downto 0)  -- Changed to buffer
    );
end chess_logic_module;

architecture Behavioral of chess_logic_module is
    -- Piece type constants (3 bits for piece type)
    constant PIECE_NONE   : STD_LOGIC_VECTOR(2 downto 0) := "000";
    constant PIECE_PAWN   : STD_LOGIC_VECTOR(2 downto 0) := "001";
    constant PIECE_KNIGHT : STD_LOGIC_VECTOR(2 downto 0) := "010";
    constant PIECE_BISHOP : STD_LOGIC_VECTOR(2 downto 0) := "011";
    constant PIECE_ROOK   : STD_LOGIC_VECTOR(2 downto 0) := "100";
    constant PIECE_QUEEN  : STD_LOGIC_VECTOR(2 downto 0) := "101";
    constant PIECE_KING   : STD_LOGIC_VECTOR(2 downto 0) := "110";

    -- Color constants
    constant COLOR_WHITE  : STD_LOGIC := '0';
    constant COLOR_BLACK  : STD_LOGIC := '1';

    -- Complete piece constants (4 bits - 1 bit color + 3 bits piece type)
    constant EMPTY_SQUARE  : STD_LOGIC_VECTOR(3 downto 0) := '0' & PIECE_NONE;
    constant WHITE_PAWN    : STD_LOGIC_VECTOR(3 downto 0) := COLOR_WHITE & PIECE_PAWN;
    constant WHITE_KNIGHT  : STD_LOGIC_VECTOR(3 downto 0) := COLOR_WHITE & PIECE_KNIGHT;
    constant WHITE_BISHOP  : STD_LOGIC_VECTOR(3 downto 0) := COLOR_WHITE & PIECE_BISHOP;
    constant WHITE_ROOK    : STD_LOGIC_VECTOR(3 downto 0) := COLOR_WHITE & PIECE_ROOK;
    constant WHITE_QUEEN   : STD_LOGIC_VECTOR(3 downto 0) := COLOR_WHITE & PIECE_QUEEN;
    constant WHITE_KING    : STD_LOGIC_VECTOR(3 downto 0) := COLOR_WHITE & PIECE_KING;
    constant BLACK_PAWN    : STD_LOGIC_VECTOR(3 downto 0) := COLOR_BLACK & PIECE_PAWN;
    constant BLACK_KNIGHT  : STD_LOGIC_VECTOR(3 downto 0) := COLOR_BLACK & PIECE_KNIGHT;
    constant BLACK_BISHOP  : STD_LOGIC_VECTOR(3 downto 0) := COLOR_BLACK & PIECE_BISHOP;
    constant BLACK_ROOK    : STD_LOGIC_VECTOR(3 downto 0) := COLOR_BLACK & PIECE_ROOK;
    constant BLACK_QUEEN   : STD_LOGIC_VECTOR(3 downto 0) := COLOR_BLACK & PIECE_QUEEN;
    constant BLACK_KING    : STD_LOGIC_VECTOR(3 downto 0) := COLOR_BLACK & PIECE_KING;

    -- State machine constants
    constant INITIAL       : STD_LOGIC_VECTOR(2 downto 0) := "000";
    constant PIECE_SEL     : STD_LOGIC_VECTOR(2 downto 0) := "001";
    constant PIECE_MOVE    : STD_LOGIC_VECTOR(2 downto 0) := "010";
    constant WRITE_NEW_PIECE : STD_LOGIC_VECTOR(2 downto 0) := "011";
    constant ERASE_OLD_PIECE : STD_LOGIC_VECTOR(2 downto 0) := "100";
    constant MOVE_ROOK     : STD_LOGIC_VECTOR(2 downto 0) := "101";
    constant CLEAR_KING    : STD_LOGIC_VECTOR(2 downto 0) := "110";
    constant CLEAR_ROOK    : STD_LOGIC_VECTOR(2 downto 0) := "111";

    -- Internal signals
    signal current_state : STD_LOGIC_VECTOR(2 downto 0);
    signal board_change_enable : STD_LOGIC;
    signal player_to_move : STD_LOGIC;
    signal h_delta : unsigned(3 downto 0);
    signal v_delta : unsigned(3 downto 0);
    signal king_captured : STD_LOGIC;
    
    -- Add path clearance signals
    signal path_horizontal_clear : std_logic;
    signal path_vertical_clear : std_logic;
    signal path_diagonal_clear : std_logic;
    
    -- Change rook movement flags to boolean type
    signal white_king_moved : boolean := false;
    signal black_king_moved : boolean := false;
    signal white_rook_a_moved : boolean := false;
    signal white_rook_h_moved : boolean := false;
    signal black_rook_a_moved : boolean := false;
    signal black_rook_h_moved : boolean := false;

    -- Board array type and signals
    type board_array is array (0 to 63) of STD_LOGIC_VECTOR(3 downto 0);
    signal board : board_array;
    signal cursor_contents : STD_LOGIC_VECTOR(3 downto 0);
    signal selected_contents : STD_LOGIC_VECTOR(3 downto 0);

    -- Internal signals for addresses
    signal cursor_addr_internal : STD_LOGIC_VECTOR(5 downto 0);
    signal selected_addr_internal : STD_LOGIC_VECTOR(5 downto 0);
    -- Add this in the architecture declaration section
    component path_check is
        port (
            board           : in  STD_LOGIC_VECTOR(255 downto 0);
            cursor_addr     : in  STD_LOGIC_VECTOR(5 downto 0);
            selected_addr   : in  STD_LOGIC_VECTOR(5 downto 0);
            h_delta         : in  STD_LOGIC_VECTOR(3 downto 0);
            v_delta         : in  STD_LOGIC_VECTOR(3 downto 0);
            horizontal_clear: out STD_LOGIC;
            vertical_clear  : out STD_LOGIC;
            diagonal_clear  : out STD_LOGIC
        );
end component;
begin
    -- Connect internal signals to outputs
    state <= current_state;
    board_change_en_wire <= board_change_enable;
    cursor_addr <= cursor_addr_internal;
    selected_addr <= selected_addr_internal;
    is_in_initial_state <= '1' when current_state = INITIAL else '0';
    hilite_selected_square <= '1' when current_state = PIECE_MOVE else '0';

-- Add this process in the chess_logic_module architecture before end Behavioral
    delta_calc: process(cursor_addr_internal, selected_addr_internal)
    begin
        -- Calculate horizontal delta using concatenation with '0'
        if unsigned(cursor_addr_internal(2 downto 0)) >= unsigned(selected_addr_internal(2 downto 0)) then
            h_delta <= '0' & (unsigned(cursor_addr_internal(2 downto 0)) - unsigned(selected_addr_internal(2 downto 0)));
        else
            h_delta <= '0' & (unsigned(selected_addr_internal(2 downto 0)) - unsigned(cursor_addr_internal(2 downto 0)));
        end if;

        -- Calculate vertical delta using concatenation with '0'
        if unsigned(cursor_addr_internal(5 downto 3)) >= unsigned(selected_addr_internal(5 downto 3)) then
            v_delta <= '0' & (unsigned(cursor_addr_internal(5 downto 3)) - unsigned(selected_addr_internal(5 downto 3)));
        else
            v_delta <= '0' & (unsigned(selected_addr_internal(5 downto 3)) - unsigned(cursor_addr_internal(5 downto 3)));
        end if;
    end process;

    -- Board array assignment from input vector
    process(board_input)
    begin
        for i in 0 to 63 loop
            board(i) <= board_input((i*4+3) downto (i*4));
        end loop;
    end process;

    -- Get contents of cursor and selected positions
    cursor_contents <= board(to_integer(unsigned(cursor_addr_internal)));
    selected_contents <= board(to_integer(unsigned(selected_addr_internal)));

    -- Main state machine process
    process(CLK, RESET)
    begin
        if RESET = '1' then
            current_state <= INITIAL;
            player_to_move <= COLOR_WHITE;
            cursor_addr_internal <= "110100";
            selected_addr_internal <= (others => 'X');
            board_out_addr <= (others => '0');
            board_out_piece <= (others => '0');
            board_change_enable <= '0';
            promotion_piece <= "00";
            white_king_moved <= false;
            black_king_moved <= false;
            white_rook_a_moved <= false;
            white_rook_h_moved <= false;
            black_rook_a_moved <= false;
            black_rook_h_moved <= false;
            
        elsif rising_edge(CLK) then
            promotion_piece <= Sw1 & Sw0;
            board_change_enable <= '0';

            if current_state = PIECE_MOVE and BtnC = '1' and 
                cursor_contents(2 downto 0) = PIECE_KING and
                cursor_contents(3) /= player_to_move and
                move_is_legal = '1' then
                king_captured <= '1';
                current_state <= INITIAL;
            else
                case current_state is
                    when INITIAL =>
                        board_change_enable <= '1';

                        case std_logic_vector(unsigned(board_out_addr)) is

                            when "000000" => board_out_piece <= BLACK_ROOK;
                            when "000001" => board_out_piece <= BLACK_KNIGHT;
                            when "000010" => board_out_piece <= BLACK_BISHOP;
                            when "000011" => board_out_piece <= BLACK_QUEEN;
                            when "000100" => board_out_piece <= BLACK_KING;
                            when "000101" => board_out_piece <= BLACK_BISHOP;
                            when "000110" => board_out_piece <= BLACK_KNIGHT;
                            when "000111" => board_out_piece <= BLACK_ROOK;
                            
                            when "001000"|"001001"|"001010"|"001011"|
                                "001100"|"001101"|"001110"|"001111" => board_out_piece <= BLACK_PAWN;

                            when "111000" => board_out_piece <= WHITE_ROOK;
                            when "111001" => board_out_piece <= WHITE_KNIGHT;
                            when "111010" => board_out_piece <= WHITE_BISHOP;
                            when "111011" => board_out_piece <= WHITE_QUEEN;
                            when "111100" => board_out_piece <= WHITE_KING;
                            when "111101" => board_out_piece <= WHITE_BISHOP;
                            when "111110" => board_out_piece <= WHITE_KNIGHT;
                            when "111111" => board_out_piece <= WHITE_ROOK;
                            
                            when "110000"|"110001"|"110010"|"110011"|
                                "110100"|"110101"|"110110"|"110111" => board_out_piece <= WHITE_PAWN;
                            
                            when others => board_out_piece <= EMPTY_SQUARE;
                        end case;

                        if board_out_addr = "111111" then
                            board_change_enable <= '0';
                            current_state <= PIECE_SEL;
                            player_to_move <= COLOR_WHITE;
                            cursor_addr_internal <= "110100";
                        else
                            board_out_addr <= std_logic_vector(unsigned(board_out_addr) + 1);
                        end if;

                    when PIECE_SEL =>
                        board_change_enable <= '0';  -- Make sure no accidental writes
                        if BtnC = '1' and cursor_contents(3) = player_to_move and 
                            cursor_contents(2 downto 0) /= PIECE_NONE then
                            current_state <= PIECE_MOVE;
                            selected_addr_internal <= cursor_addr_internal;
                            -- Debug: Add LED or signal to show piece selection succeeded
                    end if;

                    when PIECE_MOVE =>
                        board_change_enable <= '0';  -- Make sure no accidental writes
                        if BtnC = '1' then
                            if cursor_contents(3) = player_to_move and 
                            cursor_contents(2 downto 0) /= PIECE_NONE then
                                -- If selecting a new piece of same color
                                selected_addr_internal <= cursor_addr_internal;
                            elsif move_is_legal = '1' and 
                                (cursor_contents(2 downto 0) = PIECE_NONE or 
                                cursor_contents(3) /= player_to_move) then
                                -- If move is legal and destination is either empty or has enemy piece
                                current_state <= WRITE_NEW_PIECE;
                                board_out_addr <= cursor_addr_internal;
                                board_out_piece <= selected_contents;
                                board_change_enable <= '1';
                                -- Debug: Add LED or signal to show move execution started
                            else
                                current_state <= PIECE_SEL;
                            end if;
                        end if;

                    when WRITE_NEW_PIECE =>
                        board_change_enable <= '1';
                        if board_out_piece = (player_to_move & PIECE_KING) and h_delta = 2 then
                            -- Castling move
                            board_out_addr <= cursor_addr_internal;
                            board_out_piece <= selected_contents;
                            current_state <= MOVE_ROOK;
                        else
                            -- Normal move
                            board_out_addr <= cursor_addr_internal;
                            
                            -- Handle pawn promotion
                            if selected_contents = PIECE_PAWN then
                                if (player_to_move = COLOR_WHITE and cursor_addr_internal(5 downto 3) = "000") or
                                (player_to_move = COLOR_BLACK and cursor_addr_internal(5 downto 3) = "111") then
                                    case promotion_piece is
                                        when "00" => board_out_piece <= player_to_move & PIECE_QUEEN;
                                        when "01" => board_out_piece <= player_to_move & PIECE_ROOK;
                                        when "10" => board_out_piece <= player_to_move & PIECE_BISHOP;
                                        when "11" => board_out_piece <= player_to_move & PIECE_KNIGHT;
                                        when others => board_out_piece <= player_to_move & PIECE_QUEEN;
                                    end case;
                                else
                                    board_out_piece <= selected_contents;
                                end if;
                            else
                                board_out_piece <= selected_contents;
                            end if;
                            current_state <= ERASE_OLD_PIECE;
                        end if;

                    when MOVE_ROOK =>
                        board_change_enable <= '1';
                        if player_to_move = COLOR_WHITE then
                            if cursor_addr_internal(2 downto 0) > selected_addr_internal(2 downto 0) then
                                -- Kingside
                                board_out_addr <= "111101"; -- f1
                                board_out_piece <= COLOR_WHITE & PIECE_ROOK;
                            else
                                -- Queenside
                                board_out_addr <= "111011"; -- d1
                                board_out_piece <= COLOR_WHITE & PIECE_ROOK;
                            end if;
                        else
                            if cursor_addr_internal(2 downto 0) > selected_addr_internal(2 downto 0) then
                                -- Kingside
                                board_out_addr <= "000101"; -- f8
                                board_out_piece <= COLOR_BLACK & PIECE_ROOK;
                            else
                                -- Queenside
                                board_out_addr <= "000011"; -- d8
                                board_out_piece <= COLOR_BLACK & PIECE_ROOK;
                            end if;
                        end if;
                        current_state <= CLEAR_KING;

                    when CLEAR_KING =>
                        board_change_enable <= '1';
                        board_out_addr <= selected_addr_internal;
                        board_out_piece <= "0000"; -- Empty square
                        current_state <= CLEAR_ROOK;

                    when CLEAR_ROOK =>
                        board_change_enable <= '1';
                        -- Clear rook's original position
                        if player_to_move = COLOR_WHITE then
                            if cursor_addr_internal(2 downto 0) > selected_addr_internal(2 downto 0) then
                                board_out_addr <= "111111"; -- h1
                            else
                                board_out_addr <= "111000"; -- a1
                            end if;
                        else
                            if cursor_addr_internal(2 downto 0) > selected_addr_internal(2 downto 0) then
                                board_out_addr <= "000111"; -- h8
                            else
                                board_out_addr <= "000000"; -- a8
                            end if;

                        end if;
                        board_out_piece <= "0000"; -- Empty square
                        current_state <= PIECE_SEL;
                        player_to_move <= not player_to_move;
                        promotion_piece <= "00";

                        when ERASE_OLD_PIECE =>
                            board_change_enable <= '1';
                            board_out_addr <= selected_addr_internal;
                            board_out_piece <= EMPTY_SQUARE;
                            current_state <= PIECE_SEL;
                            player_to_move <= not player_to_move;

                    when others =>
                        current_state <= INITIAL;
                end case;
    
                -- Cursor Movement Controls
                if BtnL = '1' and cursor_addr_internal(2 downto 0) /= "000" then
                    cursor_addr_internal <= std_logic_vector(unsigned(cursor_addr_internal) - 1);
                elsif BtnR = '1' and cursor_addr_internal(2 downto 0) /= "111" then
                    cursor_addr_internal <= std_logic_vector(unsigned(cursor_addr_internal) + 1);
                elsif BtnU = '1' and cursor_addr_internal(5 downto 3) /= "000" then
                    cursor_addr_internal <= std_logic_vector(unsigned(cursor_addr_internal) - 8);
                elsif BtnD = '1' and cursor_addr_internal(5 downto 3) /= "111" then
                    cursor_addr_internal <= std_logic_vector(unsigned(cursor_addr_internal) + 8);
                end if;
            end if;
        end if;
    end process;

    path_checker: path_check
    port map (
        board => board_input,
        cursor_addr => cursor_addr_internal,
        selected_addr => selected_addr_internal,
        h_delta => std_logic_vector(h_delta),
        v_delta => std_logic_vector(v_delta),
        horizontal_clear => path_horizontal_clear,
        vertical_clear => path_vertical_clear,
        diagonal_clear => path_diagonal_clear
    );

        -- Move legality check process
    process(selected_contents, cursor_contents, h_delta, v_delta, 
        path_horizontal_clear, path_vertical_clear, path_diagonal_clear,
        player_to_move, cursor_addr_internal, selected_addr_internal,
        white_king_moved, black_king_moved, white_rook_a_moved, 
        white_rook_h_moved, black_rook_a_moved, black_rook_h_moved,
        board) 
        variable move_legal : std_logic;
    begin
        move_legal := '0';

        case selected_contents(2 downto 0) is
            when PIECE_PAWN(2 downto 0) =>
                if player_to_move = COLOR_WHITE then
                    -- White pawn moves (moves upward, so decreasing row number)
                    if v_delta = 2 and h_delta = 0 and 
                    selected_addr_internal(5 downto 3) = "110" and -- Starting from rank 7 (second row)
                    cursor_contents = EMPTY_SQUARE and
                    board(to_integer(unsigned(selected_addr_internal) - 8))(2 downto 0) = PIECE_NONE and
                    unsigned(cursor_addr_internal) = unsigned(selected_addr_internal) - 16 then -- Moving two squares up
                        move_legal := '1';  -- Initial two-square move
                    elsif v_delta = 1 and h_delta = 0 and
                        cursor_contents = EMPTY_SQUARE and
                        unsigned(cursor_addr_internal) = unsigned(selected_addr_internal) - 8 then -- Moving one square up
                        move_legal := '1';  -- Single square move
                    elsif v_delta = 1 and h_delta = 1 and
                        cursor_contents(3) = COLOR_BLACK and
                        cursor_contents /= EMPTY_SQUARE and
                        unsigned(cursor_addr_internal(5 downto 3)) = unsigned(selected_addr_internal(5 downto 3)) - 1 then
                        move_legal := '1';  -- Diagonal capture
                    end if;
                else
                    -- Black pawn moves (moves downward, so increasing row number)
                    if v_delta = 2 and h_delta = 0 and 
                    selected_addr_internal(5 downto 3) = "001" and -- Starting from rank 2
                    cursor_contents = EMPTY_SQUARE and
                    board(to_integer(unsigned(selected_addr_internal) + 8))(2 downto 0) = PIECE_NONE and
                    unsigned(cursor_addr_internal) = unsigned(selected_addr_internal) + 16 then -- Moving two squares down
                        move_legal := '1';  -- Initial two-square move
                    elsif v_delta = 1 and h_delta = 0 and
                        cursor_contents = EMPTY_SQUARE and
                        unsigned(cursor_addr_internal) = unsigned(selected_addr_internal) + 8 then -- Moving one square down
                        move_legal := '1';  -- Single square move
                    elsif v_delta = 1 and h_delta = 1 and
                        cursor_contents(3) = COLOR_WHITE and
                        cursor_contents /= EMPTY_SQUARE and
                        unsigned(cursor_addr_internal(5 downto 3)) = unsigned(selected_addr_internal(5 downto 3)) + 1 then
                        move_legal := '1';  -- Diagonal capture
                    end if;
                end if;

            when PIECE_ROOK =>
                -- Rook moves horizontally or vertically
                if (h_delta = 0 and path_vertical_clear = '1') or 
                    (v_delta = 0 and path_horizontal_clear = '1' ) then
                    move_legal := '1';
                end if;
            
            when PIECE_BISHOP =>
                -- Bishop moves diagonally
                if h_delta = v_delta and path_diagonal_clear = '1' then
                    move_legal := '1';
                end if;

            when PIECE_KNIGHT =>
                -- Knight moves in L-shape
                if (h_delta = 2 and v_delta = 1) or 
                    (v_delta = 2 and h_delta = 1) then
                    move_legal := '1';
                end if;

            when PIECE_QUEEN =>
                -- Queen moves like rook or bishop
                if h_delta = 0 then
                    if path_vertical_clear = '1' then
                        move_legal := '1';
                    end if;
                elsif v_delta = 0 then
                    if path_horizontal_clear = '1' then
                        move_legal := '1';
                    end if;
                elsif h_delta = v_delta then
                    if path_diagonal_clear = '1' then
                        move_legal := '1';
                    end if;
                end if;

            when PIECE_KING =>
                -- Normal king moves (one square in any direction)
                if h_delta <= 1 and v_delta <= 1 then
                    move_legal := '1';
                -- Castling moves
                elsif v_delta = 0 and h_delta = 2 then
                    if player_to_move = COLOR_WHITE and not white_king_moved and 
                    selected_addr_internal = "111100" then  -- e1
                        
                        -- Kingside castling
                        if cursor_addr_internal = "111110" and not white_rook_h_moved and  -- g1
                        board(to_integer(unsigned'("111101")))(2 downto 0) = PIECE_NONE(2 downto 0) and  -- f1 empty
                        board(to_integer(unsigned'("111110")))(2 downto 0) = PIECE_NONE(2 downto 0) and  -- g1 empty
                        board(to_integer(unsigned'("111111")))(2 downto 0) = PIECE_ROOK(2 downto 0) then -- h1 has rook
                            move_legal := '1';
                        
                        -- Queenside castling
                        elsif cursor_addr_internal = "111010" and not white_rook_a_moved and  -- c1
                            board(to_integer(unsigned'("111011")))(2 downto 0) = PIECE_NONE(2 downto 0) and  -- d1 empty
                            board(to_integer(unsigned'("111010")))(2 downto 0) = PIECE_NONE(2 downto 0) and  -- c1 empty
                            board(to_integer(unsigned'("111001")))(2 downto 0) = PIECE_NONE(2 downto 0) and  -- b1 empty
                            board(to_integer(unsigned'("111000")))(2 downto 0) = PIECE_ROOK(2 downto 0) then -- a1 has rook
                            move_legal := '1';
                        end if;
                    elsif player_to_move = COLOR_BLACK and not black_king_moved and 
                        selected_addr_internal = "000100" then  -- e8
                        
                        -- Kingside castling
                        if cursor_addr_internal = "000110" and not black_rook_h_moved and  -- g8
                        board(to_integer(unsigned'("000101")))(2 downto 0) = PIECE_NONE(2 downto 0) and  -- f8 empty
                        board(to_integer(unsigned'("000110")))(2 downto 0) = PIECE_NONE(2 downto 0) and  -- g8 empty
                        board(to_integer(unsigned'("000111")))(2 downto 0) = PIECE_ROOK(2 downto 0) then -- h8 has rook
                            move_legal := '1';
                        
                        -- Queenside castling
                        elsif cursor_addr_internal = "000010" and not black_rook_a_moved and  -- c8
                            board(to_integer(unsigned'("000011")))(2 downto 0) = PIECE_NONE(2 downto 0) and  -- d8 empty
                            board(to_integer(unsigned'("000010")))(2 downto 0) = PIECE_NONE(2 downto 0) and  -- c8 empty
                            board(to_integer(unsigned'("000001")))(2 downto 0) = PIECE_NONE(2 downto 0) and  -- b8 empty
                            board(to_integer(unsigned'("000000")))(2 downto 0) = PIECE_ROOK(2 downto 0) then -- a8 has rook
                            move_legal := '1';
                        end if;
                    end if;
                end if;

            when others =>
                move_legal := '0';
        end case;

        move_is_legal <= move_legal;
    end process;

end Behavioral;