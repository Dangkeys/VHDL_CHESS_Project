library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library work;
use work.chess_logic_types.all;

entity chess_state_machine is
    Port (
        CLK           : in  STD_LOGIC;
        RESET         : in  STD_LOGIC;
        BtnC          : in  STD_LOGIC;
        move_is_legal : in  STD_LOGIC;
        player_color  : in  STD_LOGIC;
        current_piece : in  STD_LOGIC_VECTOR(3 downto 0);
        state         : out STD_LOGIC_VECTOR(2 downto 0)
    );
end entity;

architecture Behavioral of chess_state_machine is
    signal current_state : STD_LOGIC_VECTOR(2 downto 0);
begin
    process(CLK, RESET)
    begin
        if RESET = '1' then
            current_state <= INITIAL;
        elsif rising_edge(CLK) then
            case current_state is
                when INITIAL =>
                    current_state <= PIECE_SEL;

                when PIECE_SEL =>
                    if BtnC = '1' and current_piece(3) = player_color and 
                       current_piece(2 downto 0) /= PIECE_NONE then
                        current_state <= PIECE_MOVE;
                    end if;

                when PIECE_MOVE =>
                    if BtnC = '1' then
                        if current_piece(3) = player_color and 
                           current_piece(2 downto 0) /= PIECE_NONE then
                            -- Reselect a different piece
                            current_state <= PIECE_MOVE;
                        elsif move_is_legal = '1' then
                            current_state <= WRITE_NEW_PIECE;
                        else
                            current_state <= PIECE_SEL;
                        end if;
                    end if;

                when WRITE_NEW_PIECE =>
                    if current_piece(2 downto 0) = PIECE_KING and move_is_legal = '1' then
                        current_state <= MOVE_ROOK;
                    else
                        current_state <= ERASE_OLD_PIECE;
                    end if;

                when MOVE_ROOK =>
                    current_state <= CLEAR_KING;

                when CLEAR_KING =>
                    current_state <= CLEAR_ROOK;

                when CLEAR_ROOK =>
                    current_state <= PIECE_SEL;

                when ERASE_OLD_PIECE =>
                    current_state <= PIECE_SEL;

                when others =>
                    current_state <= INITIAL;
            end case;
        end if;
    end process;

    state <= current_state;
end architecture;