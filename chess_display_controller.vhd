library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity chess_display_controller is
    Port ( 
        CLK            : in  STD_LOGIC;
        RESET          : in  STD_LOGIC;
        HSYNC          : out STD_LOGIC;
        VSYNC          : out STD_LOGIC;
        R              : out STD_LOGIC_VECTOR(2 downto 0);
        G              : out STD_LOGIC_VECTOR(2 downto 0);
        B              : out STD_LOGIC_VECTOR(1 downto 0);
        BOARD          : in  STD_LOGIC_VECTOR(255 downto 0);
        CURSOR_ADDR    : in  STD_LOGIC_VECTOR(5 downto 0);
        SELECT_ADDR    : in  STD_LOGIC_VECTOR(5 downto 0);
        SELECT_EN      : in  STD_LOGIC
    );
end chess_display_controller;

architecture Behavioral of chess_display_controller is
    -- Types and constants for pieces
    constant PIECE_NONE   : std_logic_vector(2 downto 0) := "000";
    constant PIECE_PAWN   : std_logic_vector(2 downto 0) := "001";
    constant PIECE_KNIGHT : std_logic_vector(2 downto 0) := "010";
    constant PIECE_BISHOP : std_logic_vector(2 downto 0) := "011";
    constant PIECE_ROOK   : std_logic_vector(2 downto 0) := "100";
    constant PIECE_QUEEN  : std_logic_vector(2 downto 0) := "101";
    constant PIECE_KING   : std_logic_vector(2 downto 0) := "110";

    constant COLOR_WHITE  : std_logic := '0';
    constant COLOR_BLACK  : std_logic := '1';

    -- Color constants
    constant RGB_OUTSIDE    : std_logic_vector(7 downto 0) := "00000000";
    constant RGB_DARK_SQ    : std_logic_vector(7 downto 0) := "10100000";
    constant RGB_LIGHT_SQ   : std_logic_vector(7 downto 0) := "11111010";
    constant RGB_BLACK_PIECE: std_logic_vector(7 downto 0) := "00100101";
    constant RGB_WHITE_PIECE: std_logic_vector(7 downto 0) := "11111111";
    constant RGB_CURSOR     : std_logic_vector(7 downto 0) := "00000011";
    constant RGB_SELECTED   : std_logic_vector(7 downto 0) := "11100000";

    -- VGAsync_controller component
    component VGAsync_controller
        port (
            clk            : in  STD_LOGIC;
            reset          : in  STD_LOGIC;
            vga_h_sync     : out STD_LOGIC;
            vga_v_sync     : out STD_LOGIC;
            inDisplayArea  : out STD_LOGIC;
            CounterX       : out STD_LOGIC_VECTOR(9 downto 0);
            CounterY       : out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component;

    -- Internal signals for sync generator
    signal inDisplayArea : STD_LOGIC;
    signal CounterX : STD_LOGIC_VECTOR(9 downto 0);
    signal CounterY : STD_LOGIC_VECTOR(9 downto 0);
    signal output_color : STD_LOGIC_VECTOR(7 downto 0);

    -- Board position signals
    signal counter_row : unsigned(2 downto 0);
    signal counter_col : unsigned(2 downto 0);
    signal square_x : unsigned(6 downto 0);
    signal square_y : unsigned(6 downto 0);
    signal art_x : unsigned(2 downto 0);
    signal art_y : unsigned(2 downto 0);
    signal in_square_border : std_logic;
    signal in_board : std_logic;
    signal dark_square : std_logic;

    -- Board array type
    type board_array is array (0 to 63) of std_logic_vector(3 downto 0);
    signal board_state : board_array;  

    -- Piece artwork arrays
    type artwork_array is array (0 to 7, 0 to 7) of std_logic;

    -- Define piece artwork with proper array initialization
    -- '1' represents piece pixel, '0' represents background
    constant pawnArt : artwork_array := (
        ('0','0','0','0','0','0','0','0'),
        ('0','0','0','1','1','0','0','0'),
        ('0','0','1','1','1','1','0','0'),
        ('0','0','1','1','1','1','0','0'),
        ('0','0','0','1','1','0','0','0'),
        ('0','0','1','1','1','1','0','0'),
        ('0','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1')
    );

    constant bishopArt : artwork_array := (
        ('0','0','0','1','1','0','0','0'),
        ('0','0','1','1','1','1','0','0'),
        ('0','0','0','1','1','0','0','0'),
        ('0','0','1','1','1','1','0','0'),
        ('0','0','1','1','1','1','0','0'),
        ('0','0','1','1','1','1','0','0'),
        ('0','1','1','1','1','1','1','0'),
        ('1','1','1','1','1','1','1','1')
    );

    constant knightArt : artwork_array := (
        ('0','0','0','1','1','0','0','0'),
        ('0','1','1','1','1','1','0','0'),
        ('1','1','1','1','1','1','1','0'),
        ('1','1','1','0','1','1','1','1'),
        ('0','0','0','0','0','1','1','1'),
        ('0','0','0','1','1','1','1','1'),
        ('0','0','1','1','1','1','1','1'),
        ('0','1','1','1','1','1','1','0')
    );

    constant queenArt : artwork_array := (
        ('0','0','0','0','0','0','0','0'),
        ('0','1','0','1','0','1','0','1'),
        ('0','1','0','1','0','1','0','1'),
        ('0','1','0','1','0','1','0','1'),
        ('0','1','0','1','0','1','0','1'),
        ('0','1','1','1','1','1','1','1'),
        ('0','1','1','1','1','1','1','1'),
        ('0','1','1','1','1','1','1','1')
    );

    constant kingArt : artwork_array := (
        ('0','0','0','1','1','0','0','0'),
        ('0','1','1','1','1','1','1','0'),
        ('0','0','0','1','1','0','0','0'),
        ('0','0','0','1','1','0','0','0'),
        ('0','0','1','1','1','1','0','0'),
        ('0','1','1','1','1','1','1','0'),
        ('0','1','1','1','1','1','1','0'),
        ('0','0','1','1','1','1','0','0')
    );

    constant rookArt : artwork_array := (
        ('0','0','0','0','0','0','0','0'),
        ('0','1','0','1','1','0','1','0'),
        ('0','1','1','1','1','1','1','0'),
        ('0','0','1','1','1','1','0','0'),
        ('0','0','0','1','1','0','0','0'),
        ('0','0','0','1','1','0','0','0'),
        ('0','0','1','1','1','1','0','0'),
        ('0','1','1','1','1','1','1','0')
    );

begin
    -- Board array assignment from input vector
    process(BOARD)
    begin
        for i in 0 to 63 loop
            board_state(i) <= BOARD((i*4+3) downto (i*4));
        end loop;
    end process;

    -- Instantiate the VGAsync_controller
    syncgen: VGAsync_controller
        port map (
            clk => CLK,
            reset => RESET,
            vga_h_sync => HSYNC,
            vga_v_sync => VSYNC,
            inDisplayArea => inDisplayArea,
            CounterX => CounterX,
            CounterY => CounterY
        );

    -- Output color assignments
    R <= output_color(7 downto 5) when inDisplayArea = '1' else "000";
    G <= output_color(4 downto 2) when inDisplayArea = '1' else "000";
    B <= output_color(1 downto 0) when inDisplayArea = '1' else "00";

    -- Calculate column position
    process(CounterX)
        variable counter_x_unsigned : unsigned(9 downto 0);
    begin
        counter_x_unsigned := unsigned(CounterX);
        if counter_x_unsigned <= 170 then
            counter_col <= "000";
            square_x <= resize(counter_x_unsigned - 120, 7);
        elsif counter_x_unsigned <= 220 then
            counter_col <= "001";
            square_x <= resize(counter_x_unsigned - 170, 7);
        elsif counter_x_unsigned <= 270 then
            counter_col <= "010";
            square_x <= resize(counter_x_unsigned - 220, 7);
        elsif counter_x_unsigned <= 320 then
            counter_col <= "011";
            square_x <= resize(counter_x_unsigned - 270, 7);
        elsif counter_x_unsigned <= 370 then
            counter_col <= "100";
            square_x <= resize(counter_x_unsigned - 320, 7);
        elsif counter_x_unsigned <= 420 then
            counter_col <= "101";
            square_x <= resize(counter_x_unsigned - 370, 7);
        elsif counter_x_unsigned <= 470 then
            counter_col <= "110";
            square_x <= resize(counter_x_unsigned - 420, 7);
        else
            counter_col <= "111";
            square_x <= resize(counter_x_unsigned - 470, 7);
        end if;
    end process;

    -- Calculate row position
    process(CounterY)
        variable counter_y_unsigned : unsigned(9 downto 0);
    begin
        counter_y_unsigned := unsigned(CounterY);
        if counter_y_unsigned <= 90 then
            counter_row <= "000";
            square_y <= resize(counter_y_unsigned - 40, 7);
        elsif counter_y_unsigned <= 140 then
            counter_row <= "001";
            square_y <= resize(counter_y_unsigned - 90, 7);
        elsif counter_y_unsigned <= 190 then
            counter_row <= "010";
            square_y <= resize(counter_y_unsigned - 140, 7);
        elsif counter_y_unsigned <= 240 then
            counter_row <= "011";
            square_y <= resize(counter_y_unsigned - 190, 7);
        elsif counter_y_unsigned <= 290 then
            counter_row <= "100";
            square_y <= resize(counter_y_unsigned - 240, 7);
        elsif counter_y_unsigned <= 340 then
            counter_row <= "101";
            square_y <= resize(counter_y_unsigned - 290, 7);
        elsif counter_y_unsigned <= 390 then
            counter_row <= "110";
            square_y <= resize(counter_y_unsigned - 340, 7);
        else
            counter_row <= "111";
            square_y <= resize(counter_y_unsigned - 390, 7);
        end if;
    end process;

    -- Calculate art position X
    process(square_x)
    begin
        if square_x <= 10 then
            art_x <= "000";  -- Changed from "00000"
        elsif square_x <= 15 then
            art_x <= "001";  -- Changed from "00001"
        elsif square_x <= 20 then
            art_x <= "010";  -- Changed from "00010"
        elsif square_x <= 25 then
            art_x <= "011";  -- Changed from "00011"
        elsif square_x <= 30 then
            art_x <= "100";  -- Changed from "00100"
        elsif square_x <= 35 then
            art_x <= "101";  -- Changed from "00101"
        elsif square_x <= 40 then
            art_x <= "110";  -- Changed from "00110"
        else
            art_x <= "111";  -- Changed from "00111"
        end if;
    end process;

    -- Calculate art position Y
    process(square_y)
    begin
        if square_y <= 10 then
            art_y <= "000";  -- Changed from "00000"
        elsif square_y <= 15 then
            art_y <= "001";  -- Changed from "00001"
        elsif square_y <= 20 then
            art_y <= "010";  -- Changed from "00010"
        elsif square_y <= 25 then
            art_y <= "011";  -- Changed from "00011"
        elsif square_y <= 30 then
            art_y <= "100";  -- Changed from "00100"
        elsif square_y <= 35 then
            art_y <= "101";  -- Changed from "00101"
        elsif square_y <= 40 then
            art_y <= "110";  -- Changed from "00110"
        else
            art_y <= "111";  -- Changed from "00111"
        end if;
    end process;

    -- Board position calculations
    in_square_border <= '1' when (square_x <= 5 or square_x >= 45 or
                                square_y <= 5 or square_y >= 45) else '0';

    in_board <= '1' when (unsigned(CounterX) >= 120 and unsigned(CounterX) < 520 and
                         unsigned(CounterY) >= 40 and unsigned(CounterY) < 440) else '0';

    dark_square <= counter_row(0) xor counter_col(0);

    -- Main display process
    process(CLK)
        variable piece_art : std_logic;
    begin
        if rising_edge(CLK) then
            if in_board = '0' then
                output_color <= RGB_OUTSIDE;
            else

                if in_square_border = '1' then
                    if std_logic_vector(counter_row & counter_col) = CURSOR_ADDR then
                        output_color <= RGB_CURSOR;
                    elsif std_logic_vector(counter_row & counter_col) = SELECT_ADDR and SELECT_EN = '1' then
                        output_color <= RGB_SELECTED;
                    elsif dark_square = '1' then
                        output_color <= RGB_DARK_SQ;
                    else
                        output_color <= RGB_LIGHT_SQ;
                    end if;
                else

                -- if in_square_border then
                --     if std_logic_vector(counter_row & counter_col) = CURSOR_ADDR then
                --         output_color <= RGB_CURSOR;
                --     elsif std_logic_vector(counter_row & counter_col) = SELECT_ADDR and SELECT_EN = '1' then
                --         output_color <= RGB_SELECTED;
                --     elsif dark_square = '1' then
                --         output_color <= RGB_DARK_SQ;
                --     else
                --         output_color <= RGB_LIGHT_SQ;
                --     end if;
                -- else

                    -- Piece drawing logic

                    case board_state(to_integer(unsigned(counter_row & counter_col)))(2 downto 0) is
                        when PIECE_NONE =>
                            if dark_square = '1' then
                                output_color <= RGB_DARK_SQ;
                            else
                                output_color <= RGB_LIGHT_SQ;
                            end if;

                    -- case board(to_integer(unsigned(counter_row & counter_col)))(2 downto 0) is
                    --     when PIECE_NONE =>
                    --         if dark_square = '1' then
                    --             output_color <= RGB_DARK_SQ;
                    --         else
                    --             output_color <= RGB_LIGHT_SQ;
                    --             end if;
    
                            -- when PIECE_PAWN =>
                            --     piece_art := pawnArt(to_integer(art_y), to_integer(art_x));
                            --     if piece_art = '1' then
                            --         if board(to_integer(unsigned(counter_row & counter_col)))(3) = COLOR_BLACK then
                            --             output_color <= RGB_BLACK_PIECE;
                            --         else
                            --             output_color <= RGB_WHITE_PIECE;
                            --         end if;
                            --     else
                            --         if dark_square = '1' then
                            --             output_color <= RGB_DARK_SQ;
                            --         else
                            --             output_color <= RGB_LIGHT_SQ;
                            --         end if;
                            --     end if;

                            when PIECE_PAWN =>
                                piece_art := pawnArt(to_integer(art_y), to_integer(art_x));
                                if piece_art = '1' then
                                    if board_state(to_integer(unsigned(counter_row & counter_col)))(3) = COLOR_BLACK then
                                        output_color <= RGB_BLACK_PIECE;
                                    else
                                        output_color <= RGB_WHITE_PIECE;
                                    end if;
                                else
                                    if dark_square = '1' then
                                        output_color <= RGB_DARK_SQ;
                                    else
                                        output_color <= RGB_LIGHT_SQ;
                                    end if;
                                end if;
    
                            when PIECE_KNIGHT =>
                                piece_art := knightArt(to_integer(art_y), to_integer(art_x));
                                if piece_art = '1' then
                                    if board_state(to_integer(unsigned(counter_row & counter_col)))(3) = COLOR_BLACK then
                                        output_color <= RGB_BLACK_PIECE;
                                    else
                                        output_color <= RGB_WHITE_PIECE;
                                    end if;
                                else
                                    if dark_square = '1' then
                                        output_color <= RGB_DARK_SQ;
                                    else
                                        output_color <= RGB_LIGHT_SQ;
                                    end if;
                                end if;
    
                            when PIECE_BISHOP =>
                                piece_art := bishopArt(to_integer(art_y), to_integer(art_x));
                                if piece_art = '1' then
                                    if board_state(to_integer(unsigned(counter_row & counter_col)))(3) = COLOR_BLACK then
                                        output_color <= RGB_BLACK_PIECE;
                                    else
                                        output_color <= RGB_WHITE_PIECE;
                                    end if;
                                else
                                    if dark_square = '1' then
                                        output_color <= RGB_DARK_SQ;
                                    else
                                        output_color <= RGB_LIGHT_SQ;
                                    end if;
                                end if;
    
                            when PIECE_ROOK =>
                                piece_art := rookArt(to_integer(art_y), to_integer(art_x));
                                if piece_art = '1' then
                                    if board_state(to_integer(unsigned(counter_row & counter_col)))(3) = COLOR_BLACK then
                                        output_color <= RGB_BLACK_PIECE;
                                    else
                                        output_color <= RGB_WHITE_PIECE;
                                    end if;
                                else
                                    if dark_square = '1' then
                                        output_color <= RGB_DARK_SQ;
                                    else
                                        output_color <= RGB_LIGHT_SQ;
                                    end if;
                                end if;
    
                            when PIECE_QUEEN =>
                                piece_art := queenArt(to_integer(art_y), to_integer(art_x));
                                if piece_art = '1' then
                                    if board_state(to_integer(unsigned(counter_row & counter_col)))(3) = COLOR_BLACK then
                                        output_color <= RGB_BLACK_PIECE;
                                    else
                                        output_color <= RGB_WHITE_PIECE;
                                    end if;
                                else
                                    if dark_square = '1' then
                                        output_color <= RGB_DARK_SQ;
                                    else
                                        output_color <= RGB_LIGHT_SQ;
                                    end if;
                                end if;
    
                            when PIECE_KING =>
                                piece_art := kingArt(to_integer(art_y), to_integer(art_x));
                                if piece_art = '1' then
                                    if board_state(to_integer(unsigned(counter_row & counter_col)))(3) = COLOR_BLACK then
                                        output_color <= RGB_BLACK_PIECE;
                                    else
                                        output_color <= RGB_WHITE_PIECE;
                                    end if;
                                else
                                    if dark_square = '1' then
                                        output_color <= RGB_DARK_SQ;
                                    else
                                        output_color <= RGB_LIGHT_SQ;
                                    end if;
                                end if;
    
                            when others =>
                                output_color <= RGB_OUTSIDE;
                        end case;
                    end if;
                end if;
            end if;
        end process;
    
    end Behavioral;