library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity chess_logic_module is
    Port ( 
        CLK                 : in  STD_LOGIC;
        RESET              : in  STD_LOGIC;
        board_input        : in  STD_LOGIC_VECTOR(255 downto 0);
        board_out_addr     : buffer STD_LOGIC_VECTOR(5 downto 0);
        board_out_piece    : buffer STD_LOGIC_VECTOR(3 downto 0);
        board_change_en_wire : buffer STD_LOGIC;
        BtnL               : in  STD_LOGIC;
        BtnU               : in  STD_LOGIC;
        BtnR               : in  STD_LOGIC;
        BtnD               : in  STD_LOGIC;
        BtnC               : in  STD_LOGIC;
        cursor_addr        : buffer STD_LOGIC_VECTOR(5 downto 0);
        selected_addr      : buffer STD_LOGIC_VECTOR(5 downto 0);
        hilite_selected_square : out STD_LOGIC;
        state              : out STD_LOGIC_VECTOR(2 downto 0);
        move_is_legal      : buffer STD_LOGIC;
        is_in_initial_state : out STD_LOGIC;
        Sw0                : in  STD_LOGIC;
        Sw1                : in  STD_LOGIC;
        promotion_piece    : buffer STD_LOGIC_VECTOR(1 downto 0)
    );
end chess_logic_module;

architecture Behavioral of chess_logic_module is
    -- Internal constants (piece types, colors, etc.)
    constant PIECE_NONE   : std_logic_vector(2 downto 0) := "000";
    constant PIECE_PAWN   : std_logic_vector(2 downto 0) := "001";
    constant PIECE_KNIGHT : std_logic_vector(2 downto 0) := "010";
    constant PIECE_BISHOP : std_logic_vector(2 downto 0) := "011";
    constant PIECE_ROOK   : std_logic_vector(2 downto 0) := "100";
    constant PIECE_QUEEN  : std_logic_vector(2 downto 0) := "101";
    constant PIECE_KING   : std_logic_vector(2 downto 0) := "110";

    constant COLOR_WHITE : std_logic := '0';
    constant COLOR_BLACK : std_logic := '1';

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

    -- Cursor Controller Component
    component cursor_controller 
        Port (
            CLK          : in  STD_LOGIC;
            RESET        : in  STD_LOGIC;
            BtnL         : in  STD_LOGIC;
            BtnU         : in  STD_LOGIC;
            BtnR         : in  STD_LOGIC;
            BtnD         : in  STD_LOGIC;
            cursor_addr   : out STD_LOGIC_VECTOR(5 downto 0)
        );
    end component;

    -- Move Validator Component
    component move_validator
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
    end component;

    -- Castling Controller Component
    component castling_controller
        Port (
            CLK              : in  STD_LOGIC;
            RESET            : in  STD_LOGIC;
            move_piece       : in  STD_LOGIC_VECTOR(3 downto 0);
            move_from       : in  STD_LOGIC_VECTOR(5 downto 0);
            move_to         : in  STD_LOGIC_VECTOR(5 downto 0);
            player_color    : in  STD_LOGIC;
            make_move      : in  STD_LOGIC;
            board_input    : in  STD_LOGIC_VECTOR(255 downto 0);
            castling_allowed : out STD_LOGIC;
            rook_move_from  : out STD_LOGIC_VECTOR(5 downto 0);
            rook_move_to    : out STD_LOGIC_VECTOR(5 downto 0)
        );
    end component;

    -- Chess State Machine Component
    component chess_state_machine 
        Port (
            CLK           : in  STD_LOGIC;
            RESET         : in  STD_LOGIC;
            BtnC          : in  STD_LOGIC;
            move_is_legal : in  STD_LOGIC;
            player_color  : in  STD_LOGIC;
            current_piece : in  STD_LOGIC_VECTOR(3 downto 0);
            state         : out STD_LOGIC_VECTOR(2 downto 0)
        );
    end component;

    -- Board Manager Component
    component board_manager
        Port (
            CLK              : in  STD_LOGIC;
            RESET            : in  STD_LOGIC;
            board_input : in STD_LOGIC_VECTOR(255 downto 0);
            state            : in  STD_LOGIC_VECTOR(2 downto 0);
            player_color     : in  STD_LOGIC;
            selected_pos     : in  STD_LOGIC_VECTOR(5 downto 0);
            target_pos       : in  STD_LOGIC_VECTOR(5 downto 0);
            rook_from_pos    : in  STD_LOGIC_VECTOR(5 downto 0);
            rook_to_pos      : in  STD_LOGIC_VECTOR(5 downto 0);
            promotion_piece  : in  STD_LOGIC_VECTOR(1 downto 0);
            board_out_addr   : buffer STD_LOGIC_VECTOR(5 downto 0);
            board_out_piece  : buffer STD_LOGIC_VECTOR(3 downto 0);
            board_change_en  : out STD_LOGIC;
            is_initial_state : out STD_LOGIC
        );
    end component;

    -- Path Checker Component
    component path_check
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
    end component;

    -- Internal signals
    signal current_state : STD_LOGIC_VECTOR(2 downto 0);
    signal player_to_move : STD_LOGIC := COLOR_WHITE;f
    signal h_delta, v_delta : STD_LOGIC_VECTOR(3 downto 0);
    signal cursor_contents, selected_contents : STD_LOGIC_VECTOR(3 downto 0);
    signal horizontal_clear, vertical_clear, diagonal_clear : STD_LOGIC;
    signal castling_allowed : STD_LOGIC;
    signal rook_move_from, rook_move_to : STD_LOGIC_VECTOR(5 downto 0);
    signal board_change_en_internal : STD_LOGIC;
    signal internal_selected_addr : STD_LOGIC_VECTOR(5 downto 0);
    signal is_castling : STD_LOGIC;
    signal should_move_rook : STD_LOGIC;
begin
    -- Position-based signal assignments
    cursor_contents <= board_input(to_integer(unsigned(cursor_addr)) * 4 + 3 downto 
                                to_integer(unsigned(cursor_addr)) * 4);
    selected_contents <= board_input(to_integer(unsigned(selected_addr)) * 4 + 3 downto 
                                  to_integer(unsigned(selected_addr)) * 4);

    -- Calculate delta values
    h_delta <= std_logic_vector(to_unsigned(
        abs(to_integer(unsigned(cursor_addr(2 downto 0))) - 
            to_integer(unsigned(selected_addr(2 downto 0)))), 4));
    v_delta <= std_logic_vector(to_unsigned(
        abs(to_integer(unsigned(cursor_addr(5 downto 3))) - 
            to_integer(unsigned(selected_addr(5 downto 3)))), 4));

    -- Component instantiations
    cursor_ctrl: cursor_controller
        port map (
            CLK => CLK,
            RESET => RESET,
            BtnL => BtnL,
            BtnU => BtnU,
            BtnR => BtnR,
            BtnD => BtnD,
            cursor_addr => cursor_addr
        );

    move_valid: move_validator
        port map (
            selected_piece => selected_contents,
            target_piece => cursor_contents,
            h_delta => h_delta,
            v_delta => v_delta,
            player_color => player_to_move,
            horizontal_clear => horizontal_clear,
            vertical_clear => vertical_clear,
            diagonal_clear => diagonal_clear,
            selected_pos => selected_addr,
            target_pos => cursor_addr,
            castling_allowed => castling_allowed,
            move_is_legal => move_is_legal
        );

    castling_ctrl: castling_controller
        port map (
            CLK => CLK,
            RESET => RESET,
            move_piece => selected_contents,
            move_from => selected_addr,
            move_to => cursor_addr,
            player_color => player_to_move,
            make_move => board_change_en_internal,
            board_input => board_input,
            castling_allowed => castling_allowed,
            rook_move_from => rook_move_from,
            rook_move_to => rook_move_to
        );

    state_machine: chess_state_machine
        port map (
            CLK => CLK,
            RESET => RESET,
            BtnC => BtnC,
            move_is_legal => move_is_legal,
            player_color => player_to_move,
            current_piece => cursor_contents,
            state => current_state
        );

    board_mgr: board_manager
        port map (
            CLK => CLK,
            RESET => RESET,
            board_input => board_input,
            state => current_state,
            player_color => player_to_move,
            selected_pos => selected_addr,
            target_pos => cursor_addr,
            rook_from_pos => rook_move_from,
            rook_to_pos => rook_move_to,
            promotion_piece => promotion_piece,
            board_out_addr => board_out_addr,
            board_out_piece => board_out_piece,
            board_change_en => board_change_en_internal,
            is_initial_state => is_in_initial_state
        );

    path_checker: path_check
        port map (
            board => board_input,
            cursor_addr => cursor_addr,      -- Changed from target_pos
            selected_addr => selected_addr,  -- Changed from selected_pos
            h_delta => h_delta,              -- Added missing port
            v_delta => v_delta,              -- Added missing port
            horizontal_clear => horizontal_clear,
            vertical_clear => vertical_clear,
            diagonal_clear => diagonal_clear
        );
        

    -- Output assignments
    state <= current_state;
    hilite_selected_square <= '1' when current_state = PIECE_MOVE else '0';
    board_change_en_wire <= board_change_en_internal;

    -- Turn management process
    process(CLK)
    begin
        if rising_edge(CLK) then
            if RESET = '1' then
                player_to_move <= COLOR_WHITE;
            elsif board_change_en_internal = '1' and current_state = ERASE_OLD_PIECE then
                player_to_move <= not player_to_move;
            end if;
        end if;
    end process;

    process(CLK, RESET)
    begin
        if RESET = '1' then
            internal_selected_addr <= (others => '0');
        elsif rising_edge(CLK) then
            if BtnC = '1' then
                -- Allow selecting a piece in PIECE_SEL state or reselecting in PIECE_MOVE state
                if (current_state = PIECE_SEL or current_state = PIECE_MOVE) and
                   cursor_contents(3) = player_to_move and
                   cursor_contents(2 downto 0) /= PIECE_NONE then
                    internal_selected_addr <= cursor_addr;
                end if;
            end if;
        end if;
    end process;
    selected_addr <= internal_selected_addr;

    hilite_selected_square <= '1' when 
        (current_state = PIECE_MOVE or 
        (current_state = PIECE_SEL and internal_selected_addr = cursor_addr)) else '0';

end Behavioral;