library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGAsync_controller is
    Port ( 
        clk            : in  STD_LOGIC;
        reset          : in  STD_LOGIC;
        vga_h_sync     : out STD_LOGIC;
        vga_v_sync     : out STD_LOGIC;
        inDisplayArea  : out STD_LOGIC;
        CounterX       : out STD_LOGIC_VECTOR(9 downto 0);
        CounterY       : out STD_LOGIC_VECTOR(9 downto 0)
    );
end VGAsync_controller;

architecture Behavioral of VGAsync_controller is
    -- Internal counter signals
    signal CounterX_int : unsigned(9 downto 0);
    signal CounterY_int : unsigned(9 downto 0);
    signal vga_HS      : STD_LOGIC;
    signal vga_VS      : STD_LOGIC;
    signal inDisplayArea_int : STD_LOGIC;

    -- Constants for timing
    constant H_TOTAL     : unsigned(9 downto 0) := to_unsigned(800, 10);  -- 0x320
    constant V_TOTAL     : unsigned(9 downto 0) := to_unsigned(521, 10);  -- 0x209
    constant H_SYNC_START : integer := 655;
    constant H_SYNC_END   : integer := 752;
    constant V_SYNC_START : integer := 490;
    constant V_SYNC_END   : integer := 491;
    constant H_DISPLAY    : integer := 640;
    constant V_DISPLAY    : integer := 480;

begin
    -- Convert internal counters to output
    CounterX <= std_logic_vector(CounterX_int);
    CounterY <= std_logic_vector(CounterY_int);

    -- Increment column counter process
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                CounterX_int <= (others => '0');
            else
                if CounterX_int = H_TOTAL then
                    CounterX_int <= (others => '0');
                else
                    CounterX_int <= CounterX_int + 1;
                end if;
            end if;
        end if;
    end process;

    -- Increment row counter process
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                CounterY_int <= (others => '0');
            else
                if CounterY_int = V_TOTAL then
                    CounterY_int <= (others => '0');
                elsif CounterX_int = H_TOTAL then
                    CounterY_int <= CounterY_int + 1;
                end if;
            end if;
        end if;
    end process;

    -- Generate synchronization signals process
    process(clk)
    begin
        if rising_edge(clk) then
            -- Horizontal sync
            if (CounterX_int > H_SYNC_START and CounterX_int < H_SYNC_END) then
                vga_HS <= '1';
            else
                vga_HS <= '0';
            end if;

            -- Vertical sync
            if (CounterY_int = V_SYNC_START or CounterY_int = V_SYNC_END) then
                vga_VS <= '1';
            else
                vga_VS <= '0';
            end if;
        end if;
    end process;

    -- Generate display area signal process
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                inDisplayArea_int <= '0';
            else
                if (CounterX_int < H_DISPLAY and CounterY_int < V_DISPLAY) then
                    inDisplayArea_int <= '1';
                else
                    inDisplayArea_int <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Output assignments
    vga_h_sync <= not vga_HS;
    vga_v_sync <= not vga_VS;
    inDisplayArea <= inDisplayArea_int;

end Behavioral;