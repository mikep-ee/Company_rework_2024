library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use work.pkg_company_rework_types.all;

entity output_shift_mux is
    port (
        SHIFT_AMOUNT                : in std_logic_vector(2 downto 0);


        PREVIOUS_BYTE_ARRAY_8       : in byte_array(0 to 7);
        INPUT_BYTE_ARRAY_8          : in byte_array(0 to 7);
       
        SHIFTED_OUTPUT_BYTE_ARRAY_8 : out byte_array(0 to 7)
    );
end entity output_shift_mux;

architecture rtl of output_shift_mux is
    
begin

end architecture rtl;