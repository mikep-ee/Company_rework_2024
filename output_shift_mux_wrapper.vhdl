library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use work.pkg_company_rework_types.all;

entity output_shift_mux_wrapper is
    port (
        LAST_BYTE_SHFT_AMT  : in std_logic_vector(2 downto 0); 
        
        -- PREV_BYTE_ARRAY_32  : in byte_array(0 to 31);        
        INPUT_BYTE_ARRAY : in byte_array(0 to 31);

        OUTPUT_BYTE_ARRAY : out byte_array(0 to 31)     
        
    );
end entity output_shift_mux_wrapper;

architecture rtl of output_shift_mux_wrapper is

   component output_shift_mux is
    port (
        LAST_BYTE_SHFT_AMT        : in std_logic_vector(2 downto 0);

        PREVIOUS_BYTE_ARRAY       : in byte_array(0 to 31);
        INPUT_BYTE_ARRAY          : in byte_array(0 to 31);
       
        SHIFTED_OUTPUT_BYTE_ARRAY : out byte_array(0 to 31)
    );
   end component output_shift_mux;

   signal s_prev_byte_array : byte_array(0 to 31);

begin

   output_shift_mux_inst : output_shift_mux
    port map (
        LAST_BYTE_SHFT_AMT        => LAST_BYTE_SHFT_AMT,
        PREVIOUS_BYTE_ARRAY       => s_prev_byte_array,
        INPUT_BYTE_ARRAY          => INPUT_BYTE_ARRAY,
        SHIFTED_OUTPUT_BYTE_ARRAY => OUTPUT_BYTE_ARRAY
    );
   
   process (INPUT_BYTE_ARRAY)
    begin
        s_prev_byte_array(0) <= (others => '0');
        for i in 1 to (INPUT_BYTE_ARRAY'length - 1) loop
            s_prev_byte_array(i) <= INPUT_BYTE_ARRAY(i-1);
        end loop;        
    end process;

end architecture rtl;
