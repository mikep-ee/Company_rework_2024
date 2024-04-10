--------------------------------------------------------------------------------
--
-- File: pkg_sink_test_vectors.vhd

-- Description: 
-- This package contains test vectors for the sink module
--
-- Date   : 06/10/2018
-- Author : Michael Pleasant
--------------------------------------------------------------------------------

library ieee;
  
use ieee.std_logic_1164.all;   

package pkg_sink_test_vectors is

  type sink_vect_input  is array (14 downto 0) of std_logic_vector(70 downto 0);
  type sink_vect_output is array (7 downto  0) of std_logic_vector(255 downto 0);
  type sink_vect_mask   is array (7 downto  0) of std_logic_vector(31 downto 0);
  
  constant C_INPUT_TEST_VECTOR_1 : sink_vect_input := 
  (--|Input data bus     | SOP | EOP | VAL | EMPTY  | ERROR
     x"0008000862626262" & '1' & '0' & '1' & "000"  &  '0' ,
     x"62626262000c6868" & '0' & '0' & '1' & "000"  &  '0' ,
     x"6868686868686868" & '0' & '0' & '1' & "000"  &  '0' ,
     x"6868000a70707070" & '0' & '0' & '1' & "000"  &  '0' ,
     x"707070707070000f" & '0' & '0' & '1' & "000"  &  '0' ,
     x"7a7a7a7a7a7a7a7a" & '0' & '0' & '1' & "000"  &  '0' ,
     x"7a7a7a7a7a7a7a00" & '0' & '0' & '1' & "000"  &  '0' ,
     x"0e4d4d4d4d4d4d4d" & '0' & '0' & '1' & "000"  &  '0' ,
     x"4d4d4d4d4d4d4d00" & '0' & '0' & '1' & "000"  &  '0' ,
     x"1138383838383838" & '0' & '0' & '1' & "000"  &  '0' ,
     x"3838383838383838" & '0' & '0' & '1' & "000"  &  '0' ,
     x"3838000b31313131" & '0' & '0' & '1' & "000"  &  '0' ,
     x"3131313131313100" & '0' & '0' & '1' & "000"  &  '0' ,
     x"095a5a5a5a5a5a5a" & '0' & '0' & '1' & "000"  &  '0' ,
     x"5a5a000000000000" & '0' & '1' & '1' & "101"  &  '0' 
  );
  
  constant C_OUTPUT_TEST_VECTOR_1 : sink_vect_output := 
  (--|Output Data                           | Output Mask
    x"0000000000000000_0000000000000000_0000000000000000_6262626262626262" ,
    x"0000000000000000_0000000000000000_0000000068686868_6868686868686868" ,
    x"0000000000000000_0000000000000000_0000000000007070_7070707070707070" ,
    x"0000000000000000_0000000000000000_007a7a7a7a7a7a7a_7a7a7a7a7a7a7a7a" ,
    x"0000000000000000_0000000000000000_00004d4d4d4d4d4d_4d4d4d4d4d4d4d4d" ,
    x"0000000000000000_0000000000000038_3838383838383838_3838383838383838" ,
    x"0000000000000000_0000000000000000_0000000000313131_3131313131313131" ,
    x"0000000000000000_0000000000000000_000000000000005a_5a5a5a5a5a5a5a5a"
  );
  
  constant C_OUTPUT_VECTOR_MASK_1 : sink_vect_mask := 
  (--|Output Data                           | Output Mask
    x"0000_00FF" ,
    x"0000_0FFF" ,
    x"0000_03FF" ,
    x"0000_7FFF" ,
    x"0000_3FFF" ,
    x"0001_FFFF" ,
    x"0000_07FF" ,
    x"0000_01FF" 
  );
  -- Constant used for indexing into the input test vector
  constant C_DBUS_HI_BIT  : integer := 70 ;
  constant C_DBUS_LO_BIT  : integer :=  7 ; 
  constant C_SOP_BIT      : integer :=  6 ; 
  constant C_EOP_BIT      : integer :=  5 ; 
  constant C_VAL_BIT      : integer :=  4 ; 
  constant C_EMPTY_HI_BIT : integer :=  3 ; 
  constant C_EMPTY_LO_BIT : integer :=  1 ; 
  constant C_ERROR_BIT    : integer :=  0 ; 
  constant C_VECTOR_CNT   : integer := 15 ;
  
  --Number of test vectors
  constant C_VECTOR_QTY   : integer := 8 ;

 end package pkg_sink_test_vectors;