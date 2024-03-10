--Include the standard library headers
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- use work.pkg_company_rework_types.all;
use work.all;

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
        OUT_DATA           : out std_logic_vector(255 downto 0);
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
        IN_EMPTY           : in  std_logic;
        IN_ERROR           : in  std_logic;
   
        IN_READY           : OUT  std_logic;
        OUT_VALID          : OUT  std_logic;
        OUT_BYTE_MASK      : OUT  std_logic_vector(31 downto 0);

        OUT_BYTES          : OUT  std_logic_vector(63 downto 0);
        OUT_BYTES_WEN_N    : OUT  std_logic_vector(7 downto 0);
        OUT_BYTES_VAL      : OUT  std_logic;
        MAX_BYTE_CNT       : OUT  std_logic_vector(2 downto 0);

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
        
        --BASE_REGISTER  : in std_logic_vector(2 downto 0);  -- The base register in which DATA_IN will be shifted into
        MSG_START      : in std_logic;                     -- A new message has started
        LAST_BYTE_CNT  : in std_logic_vector(2 downto 0);  -- The number of bytes to be shifted in the last shift operation
        MSG_BYTE_CNT   : in std_logic_vector(15 downto 0); -- The number of bytes in the message (Used to calc BASE_REGISTER_OUT)
        
        BASE_REGISTER_OUT : out std_logic_vector(2 downto 0); -- The buffered base register
        LAST_BYTE_CNT_OUT : out std_logic_vector(2 downto 0); -- The buffered last byte count

        DATA_OUT          : out byte_array(0 to 7);           -- 8x8 byte output to shift register  
        MSG_DONE          : out std_logic;                    -- All bytes of the message have been received and entered into the shift register
        FEEDER_RDY        : out std_logic                     -- Feeder ready for more data   
    )
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
        SHIFT_AMOUNT        : in std_logic_vector(2 downto 0); 
        
        PREV_BYTE_ARRAY_32  : in byte_array(0 to 31);        
        INPUT_BYTE_ARRAY_32 : in byte_array(0 to 31);

        OUTPUT_BYTE_ARRAY_32 : out byte_array(0 to 31)     
        
    );
   end component output_shift_mux_wrapper;

   

    begin

end architecture rtl;
```
