library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity path_check is
    Port ( 
        board           : in  STD_LOGIC_VECTOR(255 downto 0);
        cursor_addr     : in  STD_LOGIC_VECTOR(5 downto 0);
        selected_addr   : in  STD_LOGIC_VECTOR(5 downto 0);
        h_delta         : in  STD_LOGIC_VECTOR(3 downto 0);
        v_delta         : in  STD_LOGIC_VECTOR(3 downto 0);
        horizontal_clear: out STD_LOGIC;
        vertical_clear  : out STD_LOGIC;
        diagonal_clear  : out STD_LOGIC
    );
end path_check;

architecture Behavioral of path_check is
    constant PIECE_NONE : STD_LOGIC_VECTOR(2 downto 0) := "000";
    type board_array is array (0 to 63) of STD_LOGIC_VECTOR(3 downto 0);
    signal board_state : board_array;
    
begin
    -- Convert input board vector to array
    board_conversion: for i in 0 to 63 generate
        board_state(i) <= board((i*4+3) downto (i*4));
    end generate;

    -- Path checking process
    path_check_proc: process(cursor_addr, selected_addr, board_state, h_delta, v_delta)
        variable h_clear : STD_LOGIC;
        variable v_clear : STD_LOGIC;
        variable d_clear : STD_LOGIC;
        variable curr_pos : integer;
    begin
        -- Initialize variables
        h_clear := '1';
        v_clear := '1';
        d_clear := '1';
        
        -- Horizontal path check
        if unsigned(v_delta) = 0 and unsigned(h_delta) > 1 then
            if unsigned(cursor_addr(2 downto 0)) > unsigned(selected_addr(2 downto 0)) then
                -- Moving right
                for i in 1 to 15 loop
                    exit when i >= unsigned(h_delta);
                    curr_pos := to_integer(unsigned(selected_addr)) + i;
                    if board_state(curr_pos)(2 downto 0) /= PIECE_NONE then
                        h_clear := '0';
                        exit;
                    end if;
                end loop;
            else
                -- Moving left
                for i in 1 to 15 loop
                    exit when i >= unsigned(h_delta);
                    curr_pos := to_integer(unsigned(selected_addr)) - i;
                    if board_state(curr_pos)(2 downto 0) /= PIECE_NONE then
                        h_clear := '0';
                        exit;
                    end if;
                end loop;
            end if;
        end if;

        -- Vertical path check
        if unsigned(h_delta) = 0 and unsigned(v_delta) > 1 then
            if unsigned(cursor_addr(5 downto 3)) > unsigned(selected_addr(5 downto 3)) then
                -- Moving down
                for i in 1 to 15 loop
                    exit when i >= unsigned(v_delta);
                    curr_pos := to_integer(unsigned(selected_addr)) + (i * 8);
                    if board_state(curr_pos)(2 downto 0) /= PIECE_NONE then
                        v_clear := '0';
                        exit;
                    end if;
                end loop;
            else
                -- Moving up
                for i in 1 to 15 loop
                    exit when i >= unsigned(v_delta);
                    curr_pos := to_integer(unsigned(selected_addr)) - (i * 8);
                    if board_state(curr_pos)(2 downto 0) /= PIECE_NONE then
                        v_clear := '0';
                        exit;
                    end if;
                end loop;
            end if;
        end if;

        -- Diagonal path check
        if unsigned(h_delta) = unsigned(v_delta) and unsigned(h_delta) > 1 then
            if unsigned(cursor_addr(2 downto 0)) > unsigned(selected_addr(2 downto 0)) then
                if unsigned(cursor_addr(5 downto 3)) > unsigned(selected_addr(5 downto 3)) then
                    -- Moving down-right
                    for i in 1 to 15 loop
                        exit when i >= unsigned(h_delta);
                        curr_pos := to_integer(unsigned(selected_addr)) + i + (i * 8);
                        if board_state(curr_pos)(2 downto 0) /= PIECE_NONE then
                            d_clear := '0';
                            exit;
                        end if;
                    end loop;
                else
                    -- Moving up-right
                    for i in 1 to 15 loop
                        exit when i >= unsigned(h_delta);
                        curr_pos := to_integer(unsigned(selected_addr)) + i - (i * 8);
                        if board_state(curr_pos)(2 downto 0) /= PIECE_NONE then
                            d_clear := '0';
                            exit;
                        end if;
                    end loop;
                end if;
            else
                if unsigned(cursor_addr(5 downto 3)) > unsigned(selected_addr(5 downto 3)) then
                    -- Moving down-left
                    for i in 1 to 15 loop
                        exit when i >= unsigned(h_delta);
                        curr_pos := to_integer(unsigned(selected_addr)) - i + (i * 8);
                        if board_state(curr_pos)(2 downto 0) /= PIECE_NONE then
                            d_clear := '0';
                            exit;
                        end if;
                    end loop;
                else
                    -- Moving up-left
                    for i in 1 to 15 loop
                        exit when i >= unsigned(h_delta);
                        curr_pos := to_integer(unsigned(selected_addr)) - i - (i * 8);
                        if board_state(curr_pos)(2 downto 0) /= PIECE_NONE then
                            d_clear := '0';
                            exit;
                        end if;
                    end loop;
                end if;
            end if;
        end if;

        -- Assign outputs
        horizontal_clear <= h_clear;
        vertical_clear <= v_clear;
        diagonal_clear <= d_clear;
    end process;

end Behavioral;