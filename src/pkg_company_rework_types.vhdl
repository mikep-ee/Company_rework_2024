library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

-- Package declaration
package pkg_company_rework_types is
    -- Temporarily keep the sm_state here for debugging. Move back to message_receiver.vhd when done.
    type sm_state is (WAIT_SOP, GET_DATA, LAST_CYCLE, EXTERNAL_STALL, INTERNAL_STALL, START_NEW_MESSAGE);
    
    -- Type definitions
    type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);
    
    -- Constants
    --constant MyConstant : integer := 10;
    
    -- Subprogram declarations
    --procedure MyProcedure(parameter : in MyType);
    
    --function MyFunction(parameter : in integer) return boolean;
    
end package pkg_company_rework_types;

-- Package body
package body pkg_company_rework_types is
 --   -- Implementation of subprograms
 --   procedure MyProcedure(parameter : in MyType) is
 --   begin
 --       -- Implementation code here
 --   end MyProcedure;
 --   
 --   function MyFunction(parameter : in integer) return boolean is
 --   begin
 --       -- Implementation code here
 --       return true;
 --   end MyFunction;
    
end package body pkg_company_rework_types;