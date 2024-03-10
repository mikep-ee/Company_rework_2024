library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use work.pkg_company_rework_types.all;

entity data_shifter_reg_feeder is
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
    );
end entity data_shifter_reg_feeder;

architecture rtl of data_shifter_reg_feeder is
    
begin

end architecture rtl;
