library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity button_debounce is
    Port ( 
        CLK       : in  STD_LOGIC;  -- Should be at about 24.4 kHz
        RESET     : in  STD_LOGIC;
        Btn       : in  STD_LOGIC;
        Btn_pulse : out STD_LOGIC
    );
end button_debounce;

architecture Behavioral of button_debounce is
    -- State type declaration
    type state_type is (INIT, WQ, SCEN_St, CCR, WFCR);
    signal state : state_type;
    
    -- Constants
    constant max_i : integer := 1000;  -- Should yield a wait time of approx 0.25s
    
    -- Signals
    signal I : unsigned(13 downto 0);

begin
    process(CLK, RESET)
    begin
        if RESET = '1' then
            Btn_pulse <= '0';
            state <= INIT;
            I <= (others => '0');
        elsif rising_edge(CLK) then
            case state is
                when INIT =>
                    if Btn = '1' then
                        state <= WQ;
                    end if;
                    I <= (others => '0');
                    Btn_pulse <= '0';

                when WQ =>
                    if Btn = '0' then
                        state <= INIT;
                    elsif I = max_i then
                        state <= SCEN_St;
                        Btn_pulse <= '1';
                    else
                        I <= I + 1;
                    end if;

                when SCEN_St =>
                    state <= CCR;
                    Btn_pulse <= '0';
                    I <= (others => '0');

                when CCR =>
                    if Btn = '0' then
                        state <= WFCR;
                    end if;
                    I <= (others => '0');

                when WFCR =>
                    if Btn = '1' then
                        state <= CCR;
                    elsif I = max_i then
                        state <= INIT;
                    else
                        I <= I + 1;
                    end if;

            end case;
        end if;
    end process;

end Behavioral;