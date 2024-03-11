--Include the standard library headers
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_company_rework_types.all;
--use work.all;

--Entity declaration
entity company_rework_2024_top is
    port(
        CLK                : in std_logic;
        RESET              : in std_logic;
        
        IN_VALID           : in std_logic;
        IN_START_OF_PACKET : in std_logic;
        IN_END_OF_PACKET   : in std_logic;
        IN_DATA            : in std_logic_vector(63 downto 0);
        IN_EMPTY           : in std_logic_vector(2 downto 0);
        IN_ERROR           : in std_logic;
        
        IN_READY           : out std_logic;
        OUT_VALID          : out std_logic;
        --OUT_DATA           : out std_logic_vector(255 downto 0);
        OUT_DATA           : out byte_array(0 to 31);
        OUT_BYTE_MASK      : out std_logic_vector(31 downto 0)
    );
end company_rework_2024_top;

--Architecture declaration
architecture rtl of company_rework_2024_top is
   
   component message_receiver is
    port (
        CLK                : in  std_logic;
        RESET_N            : in  std_logic;
        
        IN_VALID           : in  std_logic;
        IN_START_OF_PACKET : in  std_logic;
        IN_END_OF_PACKET   : in  std_logic;
        IN_DATA            : in  std_logic_vector(63 downto 0);
        IN_EMPTY           : in  std_logic_vector(2 downto 0);
        IN_ERROR           : in  std_logic;
        IN_READY           : in  std_logic; -- From the data_shifter_reg_feeder module

        OUT_READY          : OUT  std_logic; -- To top level module
        OUT_VALID          : OUT  std_logic;
        OUT_BYTE_MASK      : OUT  std_logic_vector(31 downto 0);

        OUT_BYTES_8        : OUT  byte_array(0 to 7);
        OUT_BYTES_WEN_N    : OUT  std_logic_vector(7 downto 0);
        OUT_BYTES_VAL      : OUT  std_logic;
        -- MAX_BYTE_CNT       : OUT  std_logic_vector(2 downto 0);
        MSG_BYTE_CNT       : OUT  std_logic_vector(15 downto 0);

        MSG_START          : OUT  std_logic;
        MSG_DONE           : OUT  std_logic;

        LAST_BYTE_CNT      : OUT  std_logic_vector(2 downto 0)
    );
   end component message_receiver;


   component data_shifter_reg_feeder is
    port (
        CLK           : in std_logic;
        RESET_N       : in std_logic;
        
        DATA_IN       : in byte_array(0 to 7);           -- 8 bytes of data to be shifted in
        DATA_IN_VAL   : in std_logic;                    -- Validity of DATA_IN                  
        DATA_IN_WEN_N : in std_logic_vector(7 downto 0); -- Write enable for each byte of DATA_IN
        
        -- BASE_REGISTER  : in std_logic_vector(2 downto 0);  -- The base register in which DATA_IN will be shifted into
        -- Calculate the base register from the number of bytes in the message instead of using a separate input
        MSG_START      : in std_logic;                     -- A new message has started
        MSG_DONE_IN    : in std_logic;                     -- All bytes of the message have been received and entered into the shift register
        LAST_BYTE_CNT  : in std_logic_vector(2 downto 0);  -- The number of bytes to be shifted in the last shift operation
        MSG_BYTE_CNT   : in std_logic_vector(15 downto 0); -- The number of bytes in the message (Used to calc BASE_REGISTER_OUT)
        
        BASE_REGISTER_OUT : out std_logic_vector(2 downto 0); -- The buffered base register
        LAST_BYTE_CNT_OUT : out std_logic_vector(2 downto 0); -- The buffered last byte count

        OUT_BYTE_MASK     : out std_logic_vector(31 downto 0); -- calculated from msg_byte_cnt
        DATA_OUT_8        : out byte_array(0 to 7);           -- 8x8 byte output to shift register  
        DATA_OUT_VAL      : out std_logic;                    -- Validity of DATA_OUT_8

        MSG_DONE_OUT      : out std_logic;                    -- All bytes of the message have been received and entered into the shift register
        FEEDER_RDY        : out std_logic                     -- Feeder ready for more data   
    );
   end component data_shifter_reg_feeder;
 
   component data_shift_reg is
    port (
        CLK           : in std_logic;
        RESET_N       : in std_logic;
        
        DATA_IN       : in byte_array(0 to 7);           -- 8 bytes of data to be shifted in
        DATA_IN_VAL   : in std_logic;                    -- Validity of DATA_IN                            
        BASE_REGISTER : in std_logic_vector(2 downto 0); -- The base register in which DATA_IN will be shifted into
        
        DATA_OUT      : out byte_array(0 to 31)          -- 32 byte output of the shift register    
    );
   end component data_shift_reg;

   component output_shift_mux_wrapper is
    port (
        LAST_BYTE_SHFT_AMT  : in std_logic_vector(2 downto 0); 
        
        --PREV_BYTE_ARRAY_32  : in byte_array(0 to 31);        
        INPUT_BYTE_ARRAY_32 : in byte_array(0 to 31);

        OUTPUT_BYTE_ARRAY_32 : out byte_array(0 to 31)     
        
    );
   end component output_shift_mux_wrapper;

    -- Module message_receiver signals
    signal s_ready_msg_rcv            : std_logic;
    signal s_out_valid_msg_rcv        : std_logic;
    signal s_out_byte_mask_msg_rcv    : std_logic_vector(31 downto 0);
    signal s_out_byte_array_8_msg_rcv      : byte_array(0 to 7);
    signal s_out_bytes_wen_n_msg_rcv  : std_logic_vector(7 downto 0);
    signal s_out_bytes_val_msg_rcv    : std_logic;
    signal s_msg_byte_cnt_msg_rcv     : std_logic_vector(15 downto 0);    
    signal s_msg_start_msg_rcv        : std_logic;
    signal s_msg_done_msg_rcv         : std_logic;
    signal s_last_byte_cnt_msg_rcv    : std_logic_vector(2 downto 0);

    -- Module data_shifter_reg_feeder signals
    signal s_base_register_out_reg_fd      : std_logic_vector(2 downto 0);
    signal s_last_byte_cnt_out_shft_reg_fd : std_logic_vector(2 downto 0);
    signal s_out_byte_mask_shft_reg_fd      : std_logic_vector(31 downto 0);
    signal s_data_out_array_8_shft_reg_fd  : byte_array(0 to 7);
    signal s_data_out_val_shft_reg_fd      : std_logic;
    signal s_msg_done_out_shft_reg_fd      : std_logic;
    signal s_feeder_rdy_shft_reg_fd        : std_logic;

    -- Module data_shift_reg signals
    signal s_data_out_array_32_dat_shft_reg : byte_array(0 to 31);

    -- Module output_shift_mux_wrapper signals
    signal s_prev_data_out_array_32_shft_reg : byte_array(0 to 31);
    signal s_output_byte_array_32_out_shft_mux_wrpr : byte_array(0 to 31);

    begin

    -- Top level module (company_rework_2024_top) outputs
    IN_READY      <= s_ready_msg_rcv;
    OUT_VALID     <= s_msg_done_out_shft_reg_fd;
    OUT_DATA      <= s_output_byte_array_32_out_shft_mux_wrpr;
    OUT_BYTE_MASK <= s_out_byte_mask_shft_reg_fd;

    -- Instantiate the message_receiver module
    U_message_receiver : message_receiver
    port map (
        CLK                => CLK,
        RESET_N            => RESET,
        
        IN_VALID           => IN_VALID,
        IN_START_OF_PACKET => IN_START_OF_PACKET,
        IN_END_OF_PACKET   => IN_END_OF_PACKET,
        IN_DATA            => IN_DATA,
        IN_EMPTY           => IN_EMPTY,
        IN_ERROR           => IN_ERROR,
        IN_READY           => s_feeder_rdy_shft_reg_fd,
   
        OUT_READY          => s_ready_msg_rcv,
        OUT_VALID          => s_out_valid_msg_rcv,
        OUT_BYTE_MASK      => s_out_byte_mask_msg_rcv,
        OUT_BYTES_8        => s_out_byte_array_8_msg_rcv,
        OUT_BYTES_WEN_N    => s_out_bytes_wen_n_msg_rcv,
        OUT_BYTES_VAL      => s_out_bytes_val_msg_rcv,
        --MAX_BYTE_CNT       => s_max_byte_cnt_msg_rcv,
        MSG_BYTE_CNT       => s_msg_byte_cnt_msg_rcv,

        MSG_START          => s_msg_start_msg_rcv,
        MSG_DONE           => s_msg_done_msg_rcv,
        LAST_BYTE_CNT      => s_last_byte_cnt_msg_rcv
    );    

    -- Instantiate the data_shifter_reg_feeder module
    U_data_shifter_reg_feeder : data_shifter_reg_feeder
    port map (
        CLK           => CLK,
        RESET_N       => RESET,
        
        DATA_IN       => s_out_byte_array_8_msg_rcv,
        DATA_IN_VAL   => s_out_bytes_val_msg_rcv,
        DATA_IN_WEN_N => s_out_bytes_wen_n_msg_rcv,

        MSG_START      => s_msg_start_msg_rcv,
        MSG_DONE_IN    => s_msg_done_msg_rcv,
        LAST_BYTE_CNT  => s_last_byte_cnt_msg_rcv,
        MSG_BYTE_CNT   => s_msg_byte_cnt_msg_rcv,
        
        BASE_REGISTER_OUT => s_base_register_out_reg_fd,
        LAST_BYTE_CNT_OUT => s_last_byte_cnt_out_shft_reg_fd,

        OUT_BYTE_MASK     => s_out_byte_mask_shft_reg_fd, -- calculated from msg_byte_cnt
        DATA_OUT_8        => s_data_out_array_8_shft_reg_fd,
        DATA_OUT_VAL      => s_data_out_val_shft_reg_fd,
        
        MSG_DONE_OUT      => s_msg_done_out_shft_reg_fd,
        FEEDER_RDY        => s_feeder_rdy_shft_reg_fd
    );

    -- Instantiate the data_shift_reg module
    U_data_shift_reg : data_shift_reg
    port map (
        CLK           => CLK,
        RESET_N       => RESET,
        
        DATA_IN       => s_data_out_array_8_shft_reg_fd,
        DATA_IN_VAL   => s_data_out_val_shft_reg_fd,
        BASE_REGISTER => s_base_register_out_reg_fd,
        
        DATA_OUT      => s_data_out_array_32_dat_shft_reg
    );

    -- Instantiate the output_shift_mux_wrapper module
    U_output_shift_mux_wrapper : output_shift_mux_wrapper
    port map (
        LAST_BYTE_SHFT_AMT   => s_last_byte_cnt_out_shft_reg_fd,
        INPUT_BYTE_ARRAY_32  => s_data_out_array_32_dat_shft_reg,
        OUTPUT_BYTE_ARRAY_32 => s_output_byte_array_32_out_shft_mux_wrpr
    );
end architecture rtl;
