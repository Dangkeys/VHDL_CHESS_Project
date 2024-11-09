library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity chess_display_controller is
    Port ( 
        CLK           : in  STD_LOGIC;
        RESET         : in  STD_LOGIC;
        HSYNC         : out STD_LOGIC;
        VSYNC         : out STD_LOGIC;
        R             : out STD_LOGIC_VECTOR(2 downto 0);
        G             : out STD_LOGIC_VECTOR(2 downto 0);
        B             : out STD_LOGIC_VECTOR(1 downto 0);
        BOARD         : in  STD_LOGIC_VECTOR(255 downto 0);
        CURSOR_ADDR   : in  STD_LOGIC_VECTOR(5 downto 0);
        SELECT_ADDR   : in  STD_LOGIC_VECTOR(5 downto 0);
        SELECT_EN     : in  STD_LOGIC
    );
end chess_display_controller;

architecture Behavioral of chess_display_controller is
    -- Component declarations
    component piece_artwork is
        Port ( 
            CLK          : in  STD_LOGIC;
            piece_type   : in  STD_LOGIC_VECTOR(2 downto 0);
            art_x        : in  STD_LOGIC_VECTOR(4 downto 0);
            art_y        : in  STD_LOGIC_VECTOR(4 downto 0);
            pixel_active : out STD_LOGIC
        );
    end component;

    component board_position_calculator is
        Port ( 
            CounterX         : in  STD_LOGIC_VECTOR(9 downto 0);
            CounterY         : in  STD_LOGIC_VECTOR(9 downto 0);
            counter_row      : out STD_LOGIC_VECTOR(2 downto 0);
            counter_col      : out STD_LOGIC_VECTOR(2 downto 0);
            square_x         : out STD_LOGIC_VECTOR(6 downto 0);
            square_y         : out STD_LOGIC_VECTOR(6 downto 0);
            art_x            : out STD_LOGIC_VECTOR(4 downto 0);
            art_y            : out STD_LOGIC_VECTOR(4 downto 0);
            in_board         : out STD_LOGIC;
            in_square_border : out STD_LOGIC;
            dark_square      : out STD_LOGIC
        );
    end component;

    component VGAsync_controller is
        Port ( 
            clk           : in  STD_LOGIC;
            reset         : in  STD_LOGIC;
            vga_h_sync    : out STD_LOGIC;
            vga_v_sync    : out STD_LOGIC;
            inDisplayArea : out STD_LOGIC;
            CounterX      : out STD_LOGIC_VECTOR(9 downto 0);
            CounterY      : out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component;

    -- Color constants
    constant RGB_OUTSIDE     : std_logic_vector(7 downto 0) := "00000000";
    constant RGB_DARK_SQ     : std_logic_vector(7 downto 0) := "10100000";
    constant RGB_LIGHT_SQ    : std_logic_vector(7 downto 0) := "11111010";
    constant RGB_BLACK_PIECE : std_logic_vector(7 downto 0) := "00100101";
    constant RGB_WHITE_PIECE : std_logic_vector(7 downto 0) := "11111111";
    constant RGB_CURSOR     : std_logic_vector(7 downto 0) := "00000011";
    constant RGB_SELECTED   : std_logic_vector(7 downto 0) := "11100000";

    -- Internal signals
    signal inDisplayArea : STD_LOGIC;
    signal CounterX : STD_LOGIC_VECTOR(9 downto 0);
    signal CounterY : STD_LOGIC_VECTOR(9 downto 0);
    signal counter_row : STD_LOGIC_VECTOR(2 downto 0);
    signal counter_col : STD_LOGIC_VECTOR(2 downto 0);
    signal square_x : STD_LOGIC_VECTOR(6 downto 0);
    signal square_y : STD_LOGIC_VECTOR(6 downto 0);
    signal art_x : STD_LOGIC_VECTOR(4 downto 0);
    signal art_y : STD_LOGIC_VECTOR(4 downto 0);
    signal in_board : STD_LOGIC;
    signal in_square_border : STD_LOGIC;
    signal dark_square : STD_LOGIC;
    signal pixel_active : STD_LOGIC;
    signal output_color : STD_LOGIC_VECTOR(7 downto 0);
    
    -- Board piece access
    signal current_piece : STD_LOGIC_VECTOR(3 downto 0);
    signal board_index : integer;

begin
    -- Component instantiations
    position_calc: board_position_calculator
        port map (
            CounterX => CounterX,
            CounterY => CounterY,
            counter_row => counter_row,
            counter_col => counter_col,
            square_x => square_x,
            square_y => square_y,
            art_x => art_x,
            art_y => art_y,
            in_board => in_board,
            in_square_border => in_square_border,
            dark_square => dark_square
        );

    artwork: piece_artwork
        port map (
            CLK => CLK,
            piece_type => current_piece(2 downto 0),
            art_x => art_x,
            art_y => art_y,
            pixel_active => pixel_active
        );

    sync_gen: VGAsync_controller
        port map (
            clk => CLK,
            reset => RESET,
            vga_h_sync => HSYNC,
            vga_v_sync => VSYNC,
            inDisplayArea => inDisplayArea,
            CounterX => CounterX,
            CounterY => CounterY
        );

    -- Calculate board index and current piece
    board_index <= to_integer(unsigned(counter_row & counter_col)) * 4;
    current_piece <= BOARD(board_index + 3 downto board_index);

    -- Main color selection process
    process(CLK)
    begin
        if rising_edge(CLK) then
            if in_board = '0' then
                output_color <= RGB_OUTSIDE;
            else
                if in_square_border = '1' then
                    if (counter_row & counter_col) = CURSOR_ADDR then
                        output_color <= RGB_CURSOR;
                    elsif (counter_row & counter_col) = SELECT_ADDR and SELECT_EN = '1' then
                        output_color <= RGB_SELECTED;
                    else
                        if dark_square = '1' then
                            output_color <= RGB_DARK_SQ;
                        else
                            output_color <= RGB_LIGHT_SQ;
                        end if;
                    end if;
                else
                    if pixel_active = '1' and current_piece(2 downto 0) /= "000" then
                        if current_piece(3) = '1' then
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
                end if;
            end if;
        end if;
    end process;

    -- Output color assignments
    R <= output_color(7 downto 5) when inDisplayArea = '1' else "000";
    G <= output_color(4 downto 2) when inDisplayArea = '1' else "000";
    B <= output_color(1 downto 0) when inDisplayArea = '1' else "00";

end Behavioral;