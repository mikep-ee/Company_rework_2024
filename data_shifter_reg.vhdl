library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use work.pkg_company_rework_types.all;

entity data_shift_reg is
    port (
        CLK           : in std_logic;
        RESET_N       : in std_logic;
        
        DATA_IN       : in byte_array(0 to 7);           -- 8 bytes of data to be shifted in
        DATA_IN_VAL   : in std_logic;                    -- Validity of DATA_IN                            
        BASE_REGISTER : in std_logic_vector(2 downto 0); -- The base register in which DATA_IN will be shifted into
        
        DATA_OUT      : out byte_array(0 to 31)          -- 32 byte output of the shift register    
    );
end entity data_shift_reg;

architecture rtl of data_shift_reg is
    
begin

end architecture rtl;
