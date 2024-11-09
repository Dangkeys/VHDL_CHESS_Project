library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cursor_controller is
    Port (
        CLK          : in  STD_LOGIC;
        RESET        : in  STD_LOGIC;
        BtnL         : in  STD_LOGIC;
        BtnU         : in  STD_LOGIC;
        BtnR         : in  STD_LOGIC;
        BtnD         : in  STD_LOGIC;
        cursor_addr  : out STD_LOGIC_VECTOR(5 downto 0)
    );
end entity;

architecture Behavioral of cursor_controller is
    signal cursor_pos : unsigned(5 downto 0);
begin
    process(CLK, RESET)
    begin
        if RESET = '1' then
            cursor_pos <= "110100"; -- Initial position
        elsif rising_edge(CLK) then
            if BtnL = '1' and cursor_pos(2 downto 0) /= "000" then
                cursor_pos <= cursor_pos - 1;
            elsif BtnR = '1' and cursor_pos(2 downto 0) /= "111" then
                cursor_pos <= cursor_pos + 1;
            elsif BtnU = '1' and cursor_pos(5 downto 3) /= "000" then
                cursor_pos <= cursor_pos - 8;
            elsif BtnD = '1' and cursor_pos(5 downto 3) /= "111" then
                cursor_pos <= cursor_pos + 8;
            end if;
        end if;
    end process;

    cursor_addr <= std_logic_vector(cursor_pos);
end architecture;