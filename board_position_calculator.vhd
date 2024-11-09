library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity board_position_calculator is
    Port ( 
        CounterX : in STD_LOGIC_VECTOR(9 downto 0);
        CounterY : in STD_LOGIC_VECTOR(9 downto 0);
        counter_row : out STD_LOGIC_VECTOR(2 downto 0);
        counter_col : out STD_LOGIC_VECTOR(2 downto 0);
        square_x : out STD_LOGIC_VECTOR(6 downto 0);
        square_y : out STD_LOGIC_VECTOR(6 downto 0);
        art_x : out STD_LOGIC_VECTOR(4 downto 0);
        art_y : out STD_LOGIC_VECTOR(4 downto 0);
        in_board : out STD_LOGIC;
        in_square_border : out STD_LOGIC;
        dark_square : out STD_LOGIC
    );
end board_position_calculator;

architecture Behavioral of board_position_calculator is
    signal counter_row_int : unsigned(2 downto 0);
    signal counter_col_int : unsigned(2 downto 0);
    signal square_x_int : unsigned(6 downto 0);
    signal square_y_int : unsigned(6 downto 0);
    signal art_x_int : unsigned(4 downto 0);
    signal art_y_int : unsigned(4 downto 0);

begin
    -- Column position calculation
    process(CounterX)
        variable counterX_unsigned : unsigned(9 downto 0);
    begin
        counterX_unsigned := unsigned(CounterX);
        if counterX_unsigned <= 170 then
            counter_col_int <= "000";
            square_x_int <= resize(counterX_unsigned - 120, 7);
        elsif counterX_unsigned <= 220 then
            counter_col_int <= "001";
            square_x_int <= resize(counterX_unsigned - 170, 7);
        elsif counterX_unsigned <= 270 then
            counter_col_int <= "010";
            square_x_int <= resize(counterX_unsigned - 220, 7);
        elsif counterX_unsigned <= 320 then
            counter_col_int <= "011";
            square_x_int <= resize(counterX_unsigned - 270, 7);
        elsif counterX_unsigned <= 370 then
            counter_col_int <= "100";
            square_x_int <= resize(counterX_unsigned - 320, 7);
        elsif counterX_unsigned <= 420 then
            counter_col_int <= "101";
            square_x_int <= resize(counterX_unsigned - 370, 7);
        elsif counterX_unsigned <= 470 then
            counter_col_int <= "110";
            square_x_int <= resize(counterX_unsigned - 420, 7);
        else
            counter_col_int <= "111";
            square_x_int <= resize(counterX_unsigned - 470, 7);
        end if;
    end process;

    -- Row position calculation
    process(CounterY)
        variable counterY_unsigned : unsigned(9 downto 0);
    begin
        counterY_unsigned := unsigned(CounterY);
        if counterY_unsigned <= 90 then
            counter_row_int <= "000";
            square_y_int <= resize(counterY_unsigned - 40, 7);
        elsif counterY_unsigned <= 140 then
            counter_row_int <= "001";
            square_y_int <= resize(counterY_unsigned - 90, 7);
        elsif counterY_unsigned <= 190 then
            counter_row_int <= "010";
            square_y_int <= resize(counterY_unsigned - 140, 7);
        elsif counterY_unsigned <= 240 then
            counter_row_int <= "011";
            square_y_int <= resize(counterY_unsigned - 190, 7);
        elsif counterY_unsigned <= 290 then
            counter_row_int <= "100";
            square_y_int <= resize(counterY_unsigned - 240, 7);
        elsif counterY_unsigned <= 340 then
            counter_row_int <= "101";
            square_y_int <= resize(counterY_unsigned - 290, 7);
        elsif counterY_unsigned <= 390 then
            counter_row_int <= "110";
            square_y_int <= resize(counterY_unsigned - 340, 7);
        else
            counter_row_int <= "111";
            square_y_int <= resize(counterY_unsigned - 390, 7);
        end if;
    end process;

    -- Art position X calculation
    process(square_x_int)
    begin
        if square_x_int <= 10 then
            art_x_int <= "00000";
        elsif square_x_int <= 15 then
            art_x_int <= "00001";
        elsif square_x_int <= 20 then
            art_x_int <= "00010";
        elsif square_x_int <= 25 then
            art_x_int <= "00011";
        elsif square_x_int <= 30 then
            art_x_int <= "00100";
        elsif square_x_int <= 35 then
            art_x_int <= "00101";
        elsif square_x_int <= 40 then
            art_x_int <= "00110";
        else
            art_x_int <= "00111";
        end if;
    end process;

    -- Art position Y calculation
    process(square_y_int)
    begin
        if square_y_int <= 10 then
            art_y_int <= "00000";
        elsif square_y_int <= 15 then
            art_y_int <= "00001";
        elsif square_y_int <= 20 then
            art_y_int <= "00010";
        elsif square_y_int <= 25 then
            art_y_int <= "00011";
        elsif square_y_int <= 30 then
            art_y_int <= "00100";
        elsif square_y_int <= 35 then
            art_y_int <= "00101";
        elsif square_y_int <= 40 then
            art_y_int <= "00110";
        else
            art_y_int <= "00111";
        end if;
    end process;

    -- Output assignments
    counter_row <= std_logic_vector(counter_row_int);
    counter_col <= std_logic_vector(counter_col_int);
    square_x <= std_logic_vector(square_x_int);
    square_y <= std_logic_vector(square_y_int);
    art_x <= std_logic_vector(art_x_int);
    art_y <= std_logic_vector(art_y_int);

    -- Border and board calculations
    in_square_border <= '1' when (square_x_int <= 5 or
                                 square_x_int >= 45 or
                                 square_y_int <= 5 or
                                 square_y_int >= 45) else '0';

    in_board <= '1' when (unsigned(CounterX) >= 120 and unsigned(CounterX) < 520 and
                         unsigned(CounterY) >= 40 and unsigned(CounterY) < 440) else '0';

    dark_square <= counter_row_int(0) xor counter_col_int(0);

end Behavioral;