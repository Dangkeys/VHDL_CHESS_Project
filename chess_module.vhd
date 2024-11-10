library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity chess_module is
    Port (
        -- Clock and control inputs
        ClkPort     : in  STD_LOGIC;
        BtnL        : in  STD_LOGIC;
        BtnU        : in  STD_LOGIC;
        BtnD        : in  STD_LOGIC;
        BtnR        : in  STD_LOGIC;
        BtnC        : in  STD_LOGIC;
        DIP8        : in  STD_LOGIC;
        Sw0         : in  STD_LOGIC;
        Sw1         : in  STD_LOGIC;
        
        -- VGA outputs
        vga_hsync   : out STD_LOGIC;
        vga_vsync   : out STD_LOGIC;
        vga_r0      : out STD_LOGIC;
        vga_r1      : out STD_LOGIC;
        vga_r2      : out STD_LOGIC;
        vga_g0      : out STD_LOGIC;
        vga_g1      : out STD_LOGIC;
        vga_g2      : out STD_LOGIC;
        vga_b0      : out STD_LOGIC;
        vga_b1      : out STD_LOGIC;
        
        -- LED outputs
        Ld0         : out STD_LOGIC;
        Ld1         : out STD_LOGIC;
        Ld2         : out STD_LOGIC;
        Ld3         : out STD_LOGIC;
        Ld4         : out STD_LOGIC;
        Ld5         : out STD_LOGIC;
        Ld6         : out STD_LOGIC
    );
end chess_module;

architecture Behavioral of chess_module is
    
    constant PIECE_NONE   : std_logic_vector(2 downto 0) := "000";
    constant PIECE_PAWN   : std_logic_vector(2 downto 0) := "001";
    constant PIECE_KNIGHT : std_logic_vector(2 downto 0) := "010";
    constant PIECE_BISHOP : std_logic_vector(2 downto 0) := "011";
    constant PIECE_ROOK   : std_logic_vector(2 downto 0) := "100";
    constant PIECE_QUEEN  : std_logic_vector(2 downto 0) := "101";
    constant PIECE_KING   : std_logic_vector(2 downto 0) := "110";

    constant COLOR_WHITE  : std_logic := '0';
    constant COLOR_BLACK  : std_logic := '1';

    -- Internal signals
    signal Reset : STD_LOGIC;
    signal promotion_piece : STD_LOGIC_VECTOR(1 downto 0);
    signal vga_r : STD_LOGIC_VECTOR(2 downto 0);
    signal vga_g : STD_LOGIC_VECTOR(2 downto 0);
    signal vga_b : STD_LOGIC_VECTOR(1 downto 0);
    
    -- Clock signals
    signal clk_100MHz : STD_LOGIC;
    signal full_clock : STD_LOGIC;
    signal DIV_CLK : unsigned(26 downto 0);
    
    -- Derived clocks
    signal game_logic_clk : STD_LOGIC;
    signal vga_clk : STD_LOGIC;
    signal debounce_clk : STD_LOGIC;
    
    -- Button signals
    -- signal BtnC_prev : STD_LOGIC;
    -- signal BtnC_edge : STD_LOGIC;
    signal BtnC_pulse : STD_LOGIC;
    signal BtnU_pulse : STD_LOGIC;
    signal BtnR_pulse : STD_LOGIC;
    signal BtnL_pulse : STD_LOGIC;
    signal BtnD_pulse : STD_LOGIC;

    -- Game logic signals
    signal board_change_addr : STD_LOGIC_VECTOR(5 downto 0);
    signal board_change_piece : STD_LOGIC_VECTOR(3 downto 0);
    signal cursor_addr : STD_LOGIC_VECTOR(5 downto 0);
    signal selected_piece_addr : STD_LOGIC_VECTOR(5 downto 0);
    signal hilite_selected_square : STD_LOGIC;
    signal logic_state : STD_LOGIC_VECTOR(2 downto 0);
    signal board_change_en_wire : STD_LOGIC;
    signal is_in_initial_state : STD_LOGIC;
    
    -- Board related signals
    signal board : STD_LOGIC_VECTOR(255 downto 0);
    signal passable_board : STD_LOGIC_VECTOR(255 downto 0);

    signal move_is_legal_internal : std_logic;
    signal internal_n1 : std_logic := '0';

    -- Component declarations
    component clock_generator
        port (
            CLK_IN1  : in  STD_LOGIC;
            RESET    : in  STD_LOGIC;
            CLK_OUT1 : out STD_LOGIC
        );
    end component;

    component button_debounce
        port (
            CLK       : in  STD_LOGIC;
            RESET     : in  STD_LOGIC;
            Btn       : in  STD_LOGIC;
            Btn_pulse : out STD_LOGIC
        );
    end component;

    component BUFG
        port (
            I : in  STD_LOGIC;
            O : out STD_LOGIC
        );
    end component;

    component chess_logic_module
        port (
            CLK                  : in  STD_LOGIC;
            RESET               : in  STD_LOGIC;
            board_input         : in  STD_LOGIC_VECTOR(255 downto 0);
            board_out_addr      : out STD_LOGIC_VECTOR(5 downto 0);
            board_out_piece     : out STD_LOGIC_VECTOR(3 downto 0);
            board_change_en_wire : out STD_LOGIC;
            BtnL                : in  STD_LOGIC;
            BtnU                : in  STD_LOGIC;
            BtnR                : in  STD_LOGIC;
            BtnD                : in  STD_LOGIC;
            BtnC                : in  STD_LOGIC;
            cursor_addr         : out STD_LOGIC_VECTOR(5 downto 0);
            selected_addr       : out STD_LOGIC_VECTOR(5 downto 0);
            hilite_selected_square : out STD_LOGIC;
            state               : out STD_LOGIC_VECTOR(2 downto 0);
            move_is_legal       : out STD_LOGIC;
            is_in_initial_state : out STD_LOGIC;
            Sw0                 : in  STD_LOGIC;
            Sw1                 : in  STD_LOGIC;
            promotion_piece     : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;

    component chess_display_controller
        port (
            CLK            : in  STD_LOGIC;
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
    end component;

begin
    -- Reset and promotion piece assignments
    Reset <= DIP8;
    -- VGA output assignments
    vga_r0 <= vga_r(2);
    vga_r1 <= vga_r(1);
    vga_r2 <= vga_r(0);
    vga_g0 <= vga_g(2);
    vga_g1 <= vga_g(1);
    vga_g2 <= vga_g(0);
    vga_b0 <= vga_b(1);
    vga_b1 <= vga_b(0);

    -- LED assignments
    Ld0 <= logic_state(0);
    Ld1 <= logic_state(1);
    Ld2 <= logic_state(2);
    internal_n1 <= '0';
    Ld3 <= internal_n1;
    Ld4 <= move_is_legal_internal;
    Ld5 <= promotion_piece(0);
    Ld6 <= promotion_piece(1);

    -- Clock buffer instantiation
    clock_buf: BUFG
        port map (
            I => clk_100MHz,
            O => full_clock
        );

    -- Clock generator instantiation
    clk_gen_inst: clock_generator
        port map (
            CLK_IN1  => ClkPort,
            RESET    => Reset,
            CLK_OUT1 => clk_100MHz
        );

    -- Clock divider process
    process(full_clock, Reset)
    begin
        if Reset = '1' then
            DIV_CLK <= (others => '0');
        elsif rising_edge(full_clock) then
            DIV_CLK <= DIV_CLK + 1;
        end if;
    end process;

    -- Derived clock assignments
    game_logic_clk <= std_logic(DIV_CLK(11));  -- 24.4 kHz
    vga_clk <= std_logic(DIV_CLK(1));          -- 25MHz
    debounce_clk <= std_logic(DIV_CLK(11));    -- 24.4 kHz

    -- Button debouncer instantiations
    L_debounce_inst: button_debounce
        port map (
            CLK => debounce_clk,
            RESET => Reset,
            Btn => BtnL,
            Btn_pulse => BtnL_pulse
        );

    R_debounce_inst: button_debounce
        port map (
            CLK => debounce_clk,
            RESET => Reset,
            Btn => BtnR,
            Btn_pulse => BtnR_pulse
        );

    U_debounce_inst: button_debounce
        port map (
            CLK => debounce_clk,
            RESET => Reset,
            Btn => BtnU,
            Btn_pulse => BtnU_pulse
        );

    D_debounce_inst: button_debounce
        port map (
            CLK => debounce_clk,
            RESET => Reset,
            Btn => BtnD,
            Btn_pulse => BtnD_pulse
        );

    C_debounce_inst: button_debounce
        port map (
            CLK => debounce_clk,
            RESET => Reset,
            Btn => BtnC,
            Btn_pulse => BtnC_pulse
        );

    -- BtnC_pulse <= BtnC_edge;

    -- Game logic module instantiation
    logic_module: chess_logic_module
        port map (
            CLK => game_logic_clk,
            RESET => Reset,
            board_input => passable_board,
            board_out_addr => board_change_addr,
            board_out_piece => board_change_piece,
            board_change_en_wire => board_change_en_wire,
            cursor_addr => cursor_addr,
            selected_addr => selected_piece_addr,
            hilite_selected_square => hilite_selected_square,
            BtnU => BtnU_pulse,
            BtnL => BtnL_pulse,
            BtnC => BtnC_pulse,
            BtnR => BtnR_pulse,
            BtnD => BtnD_pulse,
            state => logic_state,
            move_is_legal => move_is_legal_internal,
            is_in_initial_state => is_in_initial_state,
            Sw0 => Sw0,
            Sw1 => Sw1,
            promotion_piece => promotion_piece
        );

    -- Display interface instantiation
    display_interface: chess_display_controller
        port map (
            CLK => vga_clk,
            RESET => Reset,
            HSYNC => vga_hsync,
            VSYNC => vga_vsync,
            R => vga_r,
            G => vga_g,
            B => vga_b,
            BOARD => passable_board,
            CURSOR_ADDR => cursor_addr,
            SELECT_ADDR => selected_piece_addr,
            SELECT_EN => hilite_selected_square
        );

    -- Board array to passable_board conversion
    process(board)
    begin
        for i in 0 to 63 loop
            passable_board((i*4)+3 downto (i*4)) <= board((i*4)+3 downto (i*4));
        end loop;
    end process;

    -- Board update process
    process(game_logic_clk)
        variable j : integer;
    begin
        if Reset = '1' then
            for j in 0 to 63 loop
                board((j*4)+3 downto (j*4)) <= "0000";  -- Initialize all squares to empty
            end loop;
        elsif rising_edge(game_logic_clk) then
            if board_change_en_wire = '1' then
                board((to_integer(unsigned(board_change_addr))*4)+3 downto 
                    (to_integer(unsigned(board_change_addr))*4)) <= board_change_piece;
            end if;

            if is_in_initial_state = '1' then
                -- Initial board setup (same as in Verilog)
                -- Black pieces
                board(0*4+3 downto 0*4) <= "1100";  -- Black Rook
                board(1*4+3 downto 1*4) <= "1010";  -- Black Knight
                board(2*4+3 downto 2*4) <= "1011";  -- Black Bishop
                board(3*4+3 downto 3*4) <= "1101";  -- Black Queen
                board(4*4+3 downto 4*4) <= "1110";  -- Black King
                board(5*4+3 downto 5*4) <= "1011";  -- Black Bishop
                board(6*4+3 downto 6*4) <= "1010";  -- Black Knight
                board(7*4+3 downto 7*4) <= "1100";  -- Black Rook
                
                -- Black pawns
                for j in 8 to 15 loop
                    board(j*4+3 downto j*4) <= "1001";  -- Black Pawn
                end loop;
                
                -- Empty squares
                for j in 16 to 47 loop
                    board(j*4+3 downto j*4) <= "0000";  -- Empty
                end loop;
                
                -- White pawns
                for j in 48 to 55 loop
                    board(j*4+3 downto j*4) <= "0001";  -- White Pawn
                end loop;
                
                -- White pieces (continued)
                board(56*4+3 downto 56*4) <= "0100";  -- White Rook
                board(57*4+3 downto 57*4) <= "0010";  -- White Knight
                board(58*4+3 downto 58*4) <= "0011";  -- White Bishop
                board(59*4+3 downto 59*4) <= "0101";  -- White Queen
                board(60*4+3 downto 60*4) <= "0110";  -- White King
                board(61*4+3 downto 61*4) <= "0011";  -- White Bishop
                board(62*4+3 downto 62*4) <= "0010";  -- White Knight
                board(63*4+3 downto 63*4) <= "0100";  -- White Rook
            end if;
        end if;
    end process;

end Behavioral;