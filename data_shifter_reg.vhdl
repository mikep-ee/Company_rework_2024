library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_shift_reg is
    port (
        CLK           : in  std_logic;
        RESET_N       : in  std_logic;
        
        DATA_IN       : in  std_logic_vector(63 downto 0); -- 8bytes of data to be shifted in
        DATA_IN_RDY   : in  std_logic;                     
        DATA_IN_WEN_N : in  std_logic_vector(7 downto 0);
        
        MAX_BYTES     : in  std_logic_vector(2 downto 0);
        LAST_BYTE_CNT : in  std_logic_vector(2 downto 0);

        DATA_OUT      : out std_logic_vector(255 downto 0)
    );
end entity data_shift_reg;

architecture rtl of data_shift_reg is
    
begin

end architecture rtl;
