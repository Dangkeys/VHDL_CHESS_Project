library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity piece_artwork is
    Port ( 
        CLK : in STD_LOGIC;
        piece_type : in STD_LOGIC_VECTOR(2 downto 0);
        art_x : in STD_LOGIC_VECTOR(4 downto 0);
        art_y : in STD_LOGIC_VECTOR(4 downto 0);
        pixel_active : out STD_LOGIC
    );
end piece_artwork;

architecture Behavioral of piece_artwork is
    -- Constants for piece types
    constant PIECE_NONE   : std_logic_vector(2 downto 0) := "000";
    constant PIECE_PAWN   : std_logic_vector(2 downto 0) := "001";
    constant PIECE_KNIGHT : std_logic_vector(2 downto 0) := "010";
    constant PIECE_BISHOP : std_logic_vector(2 downto 0) := "011";
    constant PIECE_ROOK   : std_logic_vector(2 downto 0) := "100";
    constant PIECE_QUEEN  : std_logic_vector(2 downto 0) := "101";
    constant PIECE_KING   : std_logic_vector(2 downto 0) := "110";

    -- Define artwork arrays using 2D arrays
    type artwork_array is array (0 to 7, 0 to 7) of std_logic;

    -- Fixed artwork patterns with reversed bit order
    constant PAWN_ART : artwork_array := (
        ("00000000"),  -- Changed from left-to-right to right-to-left reading
        ("00011000"),  -- Now bits are read 0 to 7 instead of 7 to 0
        ("00111100"),
        ("00111100"),
        ("00011000"),
        ("00111100"),
        ("01111110"),
        ("11111111")
    );

    constant BISHOP_ART : artwork_array := (
        ("00011000"),
        ("00111100"),
        ("00011000"),
        ("00111100"),
        ("00111100"),
        ("00111100"),
        ("01111110"),
        ("11111111")
    );

    constant KNIGHT_ART : artwork_array := (
        ("00011000"),
        ("01111100"),
        ("11111110"),
        ("11101111"),
        ("00000111"),
        ("00011111"),
        ("00111111"),
        ("01111110")
    );

    constant QUEEN_ART : artwork_array := (
        ("00000000"),
        ("10101010"),
        ("10101010"),
        ("10101010"),
        ("10101010"),
        ("11111110"),
        ("11111110"),
        ("11111110")
    );

    constant KING_ART : artwork_array := (
        ("00011000"),
        ("01111110"),
        ("00011000"),
        ("00011000"),
        ("00111100"),
        ("01111110"),
        ("01111110"),
        ("00111100")
    );

    constant ROOK_ART : artwork_array := (
        ("00000000"),
        ("01011010"),
        ("01111110"),
        ("00111100"),
        ("00011000"),
        ("00011000"),
        ("00111100"),
        ("01111110")
    );

    signal bit_index : unsigned(2 downto 0);

begin
    -- Calculate bit index correctly (reading from 0 to 7 instead of 7 to 0)
    bit_index <= unsigned(art_x(2 downto 0));  -- No need to flip the index anymore

    process(CLK)
    begin
        if rising_edge(CLK) then
            case piece_type is
                when PIECE_PAWN =>
                    pixel_active <= PAWN_ART(to_integer(unsigned(art_y(2 downto 0))), 
                                           to_integer(bit_index));
                when PIECE_KNIGHT =>
                    pixel_active <= KNIGHT_ART(to_integer(unsigned(art_y(2 downto 0))), 
                                             to_integer(bit_index));
                when PIECE_BISHOP =>
                    pixel_active <= BISHOP_ART(to_integer(unsigned(art_y(2 downto 0))), 
                                             to_integer(bit_index));
                when PIECE_ROOK =>
                    pixel_active <= ROOK_ART(to_integer(unsigned(art_y(2 downto 0))), 
                                           to_integer(bit_index));
                when PIECE_QUEEN =>
                    pixel_active <= QUEEN_ART(to_integer(unsigned(art_y(2 downto 0))), 
                                            to_integer(bit_index));
                when PIECE_KING =>
                    pixel_active <= KING_ART(to_integer(unsigned(art_y(2 downto 0))), 
                                           to_integer(bit_index));
                when others =>
                    pixel_active <= '0';
            end case;
        end if;
    end process;

end Behavioral;