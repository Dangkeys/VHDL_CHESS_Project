library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package chess_logic_types is
    -- Piece type constants
    constant PIECE_NONE   : std_logic_vector(2 downto 0) := "000";
    constant PIECE_PAWN   : std_logic_vector(2 downto 0) := "001";
    constant PIECE_KNIGHT : std_logic_vector(2 downto 0) := "010";
    constant PIECE_BISHOP : std_logic_vector(2 downto 0) := "011";
    constant PIECE_ROOK   : std_logic_vector(2 downto 0) := "100";
    constant PIECE_QUEEN  : std_logic_vector(2 downto 0) := "101";
    constant PIECE_KING   : std_logic_vector(2 downto 0) := "110";

    -- Color constants
    constant COLOR_WHITE : std_logic := '0';
    constant COLOR_BLACK : std_logic := '1';

    -- Complete piece constants
    constant EMPTY_SQUARE : std_logic_vector(3 downto 0) := '0' & PIECE_NONE;
    constant WHITE_PAWN   : std_logic_vector(3 downto 0) := COLOR_WHITE & PIECE_PAWN;
    constant WHITE_KNIGHT : std_logic_vector(3 downto 0) := COLOR_WHITE & PIECE_KNIGHT;
    constant WHITE_BISHOP : std_logic_vector(3 downto 0) := COLOR_WHITE & PIECE_BISHOP;
    constant WHITE_ROOK   : std_logic_vector(3 downto 0) := COLOR_WHITE & PIECE_ROOK;
    constant WHITE_QUEEN  : std_logic_vector(3 downto 0) := COLOR_WHITE & PIECE_QUEEN;
    constant WHITE_KING   : std_logic_vector(3 downto 0) := COLOR_WHITE & PIECE_KING;
    constant BLACK_PAWN   : std_logic_vector(3 downto 0) := COLOR_BLACK & PIECE_PAWN;
    constant BLACK_KNIGHT : std_logic_vector(3 downto 0) := COLOR_BLACK & PIECE_KNIGHT;
    constant BLACK_BISHOP : std_logic_vector(3 downto 0) := COLOR_BLACK & PIECE_BISHOP;
    constant BLACK_ROOK   : std_logic_vector(3 downto 0) := COLOR_BLACK & PIECE_ROOK;
    constant BLACK_QUEEN  : std_logic_vector(3 downto 0) := COLOR_BLACK & PIECE_QUEEN;
    constant BLACK_KING   : std_logic_vector(3 downto 0) := COLOR_BLACK & PIECE_KING;

    -- State machine constants
    constant INITIAL          : std_logic_vector(2 downto 0) := "000";
    constant PIECE_SEL        : std_logic_vector(2 downto 0) := "001";
    constant PIECE_MOVE       : std_logic_vector(2 downto 0) := "010";
    constant WRITE_NEW_PIECE  : std_logic_vector(2 downto 0) := "011";
    constant ERASE_OLD_PIECE  : std_logic_vector(2 downto 0) := "100";
    constant MOVE_ROOK        : std_logic_vector(2 downto 0) := "101";
    constant CLEAR_KING       : std_logic_vector(2 downto 0) := "110";
    constant CLEAR_ROOK       : std_logic_vector(2 downto 0) := "111";
end package;