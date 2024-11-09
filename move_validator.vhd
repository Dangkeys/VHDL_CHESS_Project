library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.chess_logic_types.all;

entity move_validator is
    Port (
        selected_piece    : in  STD_LOGIC_VECTOR(3 downto 0);
        target_piece      : in  STD_LOGIC_VECTOR(3 downto 0);
        h_delta          : in  STD_LOGIC_VECTOR(3 downto 0);
        v_delta          : in  STD_LOGIC_VECTOR(3 downto 0);
        player_color     : in  STD_LOGIC;
        horizontal_clear : in  STD_LOGIC;
        vertical_clear   : in  STD_LOGIC;
        diagonal_clear   : in  STD_LOGIC;
        selected_pos     : in  STD_LOGIC_VECTOR(5 downto 0);
        target_pos       : in  STD_LOGIC_VECTOR(5 downto 0);
        castling_allowed : in  STD_LOGIC;
        move_is_legal    : out STD_LOGIC
    );
end move_validator;

architecture Behavioral of move_validator is
begin
    process(selected_piece, target_piece, h_delta, v_delta, player_color, 
            horizontal_clear, vertical_clear, diagonal_clear, 
            selected_pos, target_pos, castling_allowed)
        variable move_legal : std_logic;
    begin
        move_legal := '0';

        case selected_piece(2 downto 0) is
            when PIECE_PAWN =>
                if player_color = COLOR_WHITE then
                    -- White pawn moves
                    if unsigned(v_delta) = 2 and unsigned(h_delta) = 0 and 
                       selected_pos(5 downto 3) = "110" and 
                       target_piece = EMPTY_SQUARE and
                       vertical_clear = '1' and
                       unsigned(target_pos(5 downto 3)) < unsigned(selected_pos(5 downto 3)) then
                        move_legal := '1';  -- Initial two-square move
                    elsif unsigned(v_delta) = 1 and unsigned(h_delta) = 0 and
                          target_piece = EMPTY_SQUARE and
                          unsigned(target_pos(5 downto 3)) < unsigned(selected_pos(5 downto 3)) then
                        move_legal := '1';  -- Single square forward
                    elsif unsigned(v_delta) = 1 and unsigned(h_delta) = 1 and
                          target_piece(3) = COLOR_BLACK and
                          target_piece /= EMPTY_SQUARE and
                          unsigned(target_pos(5 downto 3)) < unsigned(selected_pos(5 downto 3)) then
                        move_legal := '1';  -- Diagonal capture
                    end if;
                else
                    -- Black pawn moves
                    if unsigned(v_delta) = 2 and unsigned(h_delta) = 0 and 
                       selected_pos(5 downto 3) = "001" and 
                       target_piece = EMPTY_SQUARE and
                       vertical_clear = '1' and
                       unsigned(target_pos(5 downto 3)) > unsigned(selected_pos(5 downto 3)) then
                        move_legal := '1';  -- Initial two-square move
                    elsif unsigned(v_delta) = 1 and unsigned(h_delta) = 0 and
                          target_piece = EMPTY_SQUARE and
                          unsigned(target_pos(5 downto 3)) > unsigned(selected_pos(5 downto 3)) then
                        move_legal := '1';  -- Single square forward
                    elsif unsigned(v_delta) = 1 and unsigned(h_delta) = 1 and
                          target_piece(3) = COLOR_WHITE and
                          target_piece /= EMPTY_SQUARE and
                          unsigned(target_pos(5 downto 3)) > unsigned(selected_pos(5 downto 3)) then
                        move_legal := '1';  -- Diagonal capture
                    end if;
                end if;

            when PIECE_ROOK =>
                if (unsigned(h_delta) = 0 and vertical_clear = '1') or 
                   (unsigned(v_delta) = 0 and horizontal_clear = '1') then
                    if target_piece = EMPTY_SQUARE or target_piece(3) /= player_color then
                        move_legal := '1';
                    end if;
                end if;

            when PIECE_BISHOP =>
                if unsigned(h_delta) = unsigned(v_delta) and diagonal_clear = '1' then
                    if target_piece = EMPTY_SQUARE or target_piece(3) /= player_color then
                        move_legal := '1';
                    end if;
                end if;

            when PIECE_KNIGHT =>
                if (unsigned(h_delta) = 2 and unsigned(v_delta) = 1) or 
                   (unsigned(v_delta) = 2 and unsigned(h_delta) = 1) then
                    if target_piece = EMPTY_SQUARE or target_piece(3) /= player_color then
                        move_legal := '1';
                    end if;
                end if;

            when PIECE_QUEEN =>
                if (unsigned(h_delta) = 0 and vertical_clear = '1') or
                   (unsigned(v_delta) = 0 and horizontal_clear = '1') or
                   (unsigned(h_delta) = unsigned(v_delta) and diagonal_clear = '1') then
                    if target_piece = EMPTY_SQUARE or target_piece(3) /= player_color then
                        move_legal := '1';
                    end if;
                end if;

            when PIECE_KING =>
                -- Normal king moves
                if unsigned(h_delta) <= 1 and unsigned(v_delta) <= 1 then
                    if target_piece = EMPTY_SQUARE or target_piece(3) /= player_color then
                        move_legal := '1';
                    end if;
                -- Castling moves
                elsif castling_allowed = '1' and unsigned(v_delta) = 0 and unsigned(h_delta) = 2 then
                    move_legal := '1';
                end if;

            when others =>
                move_legal := '0';
        end case;

        move_is_legal <= move_legal;
    end process;

end Behavioral;