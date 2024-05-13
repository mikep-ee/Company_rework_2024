--------------------------------------------------------------------------------
--
-- File: pkg_sink_test_vectors.vhd

-- Description: 
-- This package contains test vectors for the sink module
--
-- Date   : 04/10/2024
-- Author : Michael Pleasant
--------------------------------------------------------------------------------

library ieee;
  
use ieee.std_logic_1164.all;   
use work.pkg_company_rework_types.all; -- defined types

package pkg_sink_test_vectors is    
  --Number of test vectors
  constant C_VECTOR_QTY   : integer := 18 ;

  type sink_vect_input  is array (14 downto 0) of std_logic_vector(70 downto 0);
  type sink_vect_output is array (7 downto  0) of std_logic_vector(255 downto 0);
  type sink_vect_mask   is array (7 downto  0) of std_logic_vector(31 downto 0);
  type sink_vect_out_validate is array (C_VECTOR_QTY-1 downto  0) of std_logic_vector(46 downto 0);
  type sink_vect_data_validate is array (C_VECTOR_QTY-1 downto  0) of byte_array(7 downto 0);

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
  
  --constant C_OUTPUT_TEST_VECTOR_1 : sink_vect_output := 
  --(--|Output Data                           | Output Mask
  --  x"0000000000000000_0000000000000000_0000000000000000_6262626262626262" ,
  --  x"0000000000000000_0000000000000000_0000000068686868_6868686868686868" ,
  --  x"0000000000000000_0000000000000000_0000000000007070_7070707070707070" ,
  --  x"0000000000000000_0000000000000000_007a7a7a7a7a7a7a_7a7a7a7a7a7a7a7a" ,
  --  x"0000000000000000_0000000000000000_00004d4d4d4d4d4d_4d4d4d4d4d4d4d4d" ,
  --  x"0000000000000000_0000000000000038_3838383838383838_3838383838383838" ,
  --  x"0000000000000000_0000000000000000_0000000000313131_3131313131313131" ,
  --  x"0000000000000000_0000000000000000_000000000000005a_5a5a5a5a5a5a5a5a"
  --);
  
 --constant C_OUTPUT_VECTOR_MASK_1 : sink_vect_mask := 
 --(--|Output Data                           
 --  x"0000_00FF" ,
 --  x"0000_0FFF" ,
 --  x"0000_03FF" ,
 --  x"0000_7FFF" ,
 --  x"0000_3FFF" ,
 --  x"0001_FFFF" ,
 --  x"0000_07FF" ,
 --  x"0000_01FF" 
 --);

  -- Constant used for indexing into the input test vector
  constant C_CNT_HI_BIT   : integer := 46 ;
  constant C_CNT_LO_BIT   : integer := 44 ; 
  constant C_READY_BIT    : integer := 43 ; 
  constant C_MASK_HI_BIT  : integer := 42 ; 
  constant C_MASK_LO_BIT  : integer := 11 ; 
  constant C_WEN_HI_BIT   : integer := 10 ;
  constant C_WEN_LO_BIT   : integer :=  3 ; 
  constant C_BVAL_BIT     : integer :=  2 ; 
  constant C_START_BIT    : integer :=  1 ; 
  constant C_DONE_BIT     : integer :=  0 ;

constant OUT_VECTOR_START_MSG_1 : sink_vect_out_validate := 
  (
   --|LAST_BYTE_CNT | OUT_READY | BYTE_MASK              | BYTE_WEN | BYTES_VAL | MSG_START | MSG_DONE
      "100"         & '0'       & x"0000_00FF" &           x"0F"    & '1'       &  '1'      & '0' , -- Cycle 1
      "100"         & '1'       & x"0000_0FFF" &           x"0F"    & '1'       &  '0'      & '1' , -- Cycle 2
      "100"         & '1'       & x"0000_0FFF" &           x"03"    & '1'       &  '1'      & '0' , -- Cycle 3
      "100"         & '0'       & x"0000_0FFF" &           x"FF"    & '1'       &  '0'      & '0' , -- Cycle 4
      "100"         & '1'       & x"0000_0FFF" &           x"03"    & '1'       &  '0'      & '1' , -- Cycle 5
      "010"         & '1'       & x"0000_03FF" &           x"0F"    & '1'       &  '1'      & '0' , -- Cycle 6
      "010"         & '1'       & x"0000_03FF" &           x"3F"    & '1'       &  '0'      & '1' , -- Cycle 7
      "111"         & '1'       & x"0000_7FFF" &           x"FF"    & '1'       &  '1'      & '0' , -- Cycle 8
      "111"         & '1'       & x"0000_7FFF" &           x"7F"    & '1'       &  '0'      & '1' , -- Cycle 9
      "111"         & '1'       & x"0000_3FFF" &           x"7F"    & '1'       &  '1'      & '0' , -- Cycle 10
      "111"         & '1'       & x"0000_3FFF" &           x"7F"    & '1'       &  '0'      & '1' , -- Cycle 11
      "010"         & '1'       & x"0001_FFFF" &           x"7F"    & '1'       &  '1'      & '0' , -- Cycle 12
      "010"         & '0'       & x"0001_FFFF" &           x"FF"    & '1'       &  '0'      & '0' , -- Cycle 13
      "010"         & '1'       & x"0001_FFFF" &           x"03"    & '1'       &  '0'      & '1' , -- Cycle 14
      "111"         & '1'       & x"0000_07FF" &           x"0F"    & '1'       &  '1'      & '0' , -- Cycle 15
      "111"         & '1'       & x"0000_07FF" &           x"7F"    & '1'       &  '0'      & '1' , -- Cycle 16
      "010"         & '1'       & x"0000_01FF" &           x"7F"    & '1'       &  '1'      & '0' , -- Cycle 17
      "010"         & '1'       & x"0000_01FF" &           x"03"    & '1'       &  '0'      & '1'   -- Cycle 18
  );

  --constant OUT_VECTOR_DATA_1 : sink_vect_data_validate := 
  --(
  -- --|Data Byte 0 | Data Byte 1 | Data Byte 2 | Data Byte 3 | Data Byte 4 | Data Byte 5 | Data Byte 6 | Data Byte 7
  --    (x"62",       x"62",       x"62",       x"62",       x"00",       x"00",       x"00",       x"00"), -- Cycle 1
  --    (x"62",       x"62",       x"62",       x"62",       x"00",       x"00",       x"00",       x"00"), -- Cycle 2
  --    (x"68",       x"68",       x"00",       x"00",       x"00",       x"00",       x"00",       x"00"), -- Cycle 3
  --    (x"68",       x"68",       x"68",       x"68",       x"68",       x"68",       x"68",       x"68"), -- Cycle 4
  --    (x"68",       x"68",       x"00",       x"00",       x"00",       x"00",       x"00",       x"00"), -- Cycle 5
  --    (x"70",       x"70",       x"70",       x"70",       x"00",       x"00",       x"00",       x"00"), -- Cycle 6
  --    (x"70",       x"70",       x"70",       x"70",       x"70",       x"70",       x"00",       x"00"), -- Cycle 7
  --    (x"7a",       x"7a",       x"7a",       x"7a",       x"7a",       x"7a",       x"7a",       x"7a"), -- Cycle 8
  --    (x"7a",       x"7a",       x"7a",       x"7a",       x"7a",       x"7a",       x"7a",       x"00"), -- Cycle 9
  --    (x"4d",       x"4d",       x"4d",       x"4d",       x"4d",       x"4d",       x"4d",       x"00"), -- Cycle 10
  --    (x"4d",       x"4d",       x"4d",       x"4d",       x"4d",       x"4d",       x"4d",       x"00"), -- Cycle 11
  --    (x"38",       x"38",       x"38",       x"38",       x"38",       x"38",       x"38",       x"00"), -- Cycle 12
  --    (x"38",       x"38",       x"38",       x"38",       x"38",       x"38",       x"38",       x"38"), -- Cycle 13
  --    (x"38",       x"38",       x"38",       x"38",       x"00",       x"00",       x"00",       x"00"), -- Cycle 14
  --    (x"31",       x"31",       x"31",       x"31",       x"00",       x"00",       x"00",       x"00"), -- Cycle 15
  --    (x"31",       x"31",       x"31",       x"31",       x"31",       x"31",       x"31",       x"00"), -- Cycle 16
  --    (x"5a",       x"5a",       x"5a",       x"5a",       x"5a",       x"5a",       x"5a",       x"00"), -- Cycle 17
  --    (x"5a",       x"5a",       x"00",       x"00",       x"00",       x"00",       x"00",       x"00")  -- Cycle 18
  --);  

 constant OUT_VECTOR_DATA_1 : sink_vect_data_validate := 
 (
  --|Data Byte 0 | Data Byte 1 | Data Byte 2 | Data Byte 3 | Data Byte 4 | Data Byte 5 | Data Byte 6 | Data Byte 7
     (x"62",       x"62",       x"62",       x"62",       x"00",       x"00",       x"00",       x"00"), -- Cycle 1
     (x"62",       x"62",       x"62",       x"62",       x"00",       x"00",       x"00",       x"00"), -- Cycle 2
     (x"68",       x"68",       x"00",       x"00",       x"00",       x"00",       x"00",       x"00"), -- Cycle 3
     (x"68",       x"68",       x"68",       x"68",       x"68",       x"68",       x"68",       x"68"), -- Cycle 4
     (x"68",       x"68",       x"00",       x"00",       x"00",       x"00",       x"00",       x"00"), -- Cycle 5
     (x"70",       x"70",       x"70",       x"70",       x"00",       x"00",       x"00",       x"00"), -- Cycle 6
     (x"70",       x"70",       x"70",       x"70",       x"70",       x"70",       x"00",       x"00"), -- Cycle 7
     (x"7a",       x"7a",       x"7a",       x"7a",       x"7a",       x"7a",       x"7a",       x"7a"), -- Cycle 8
     (x"7a",       x"7a",       x"7a",       x"7a",       x"7a",       x"7a",       x"7a",       x"00"), -- Cycle 9
     (x"4d",       x"4d",       x"4d",       x"4d",       x"4d",       x"4d",       x"4d",       x"00"), -- Cycle 10
     (x"4d",       x"4d",       x"4d",       x"4d",       x"4d",       x"4d",       x"4d",       x"00"), -- Cycle 11
     (x"38",       x"38",       x"38",       x"38",       x"38",       x"38",       x"38",       x"00"), -- Cycle 12
     (x"38",       x"38",       x"38",       x"38",       x"38",       x"38",       x"38",       x"38"), -- Cycle 13
     (x"38",       x"38",       x"38",       x"38",       x"00",       x"00",       x"00",       x"00"), -- Cycle 14
     (x"31",       x"31",       x"31",       x"31",       x"00",       x"00",       x"00",       x"00"), -- Cycle 15
     (x"31",       x"31",       x"31",       x"31",       x"31",       x"31",       x"31",       x"00"), -- Cycle 16
     (x"5a",       x"5a",       x"5a",       x"5a",       x"5a",       x"5a",       x"5a",       x"00"), -- Cycle 17
     (x"5a",       x"5a",       x"00",       x"00",       x"00",       x"00",       x"00",       x"00")  -- Cycle 18
 );  

-- Just in case we need to reverse the output data  
--constant REVERSED_OUT_VECTOR_DATA_1 : sink_vect_data_validate := 
--  (
--      -- Manually reversed byte order for each entry
--      (x"00", x"00", x"00", x"00", x"62", x"62", x"62", x"62"), -- Cycle 1
--      (x"00", x"00", x"00", x"00", x"62", x"62", x"62", x"62"), -- Cycle 2
--      (x"00", x"00", x"00", x"00", x"00", x"00", x"68", x"68"), -- Cycle 3
--      (x"68", x"68", x"68", x"68", x"68", x"68", x"68", x"68"), -- Cycle 4
--      (x"00", x"00", x"00", x"00", x"00", x"00", x"68", x"68"), -- Cycle 5
--      (x"00", x"00", x"00", x"00", x"70", x"70", x"70", x"70"), -- Cycle 6
--      (x"00", x"00", x"70", x"70", x"70", x"70", x"70", x"70"), -- Cycle 7
--      (x"7a", x"7a", x"7a", x"7a", x"7a", x"7a", x"7a", x"7a"), -- Cycle 8
--      (x"00", x"7a", x"7a", x"7a", x"7a", x"7a", x"7a", x"7a"), -- Cycle 9
--      (x"00", x"4d", x"4d", x"4d", x"4d", x"4d", x"4d", x"4d"), -- Cycle 10
--      (x"00", x"4d", x"4d", x"4d", x"4d", x"4d", x"4d", x"4d"), -- Cycle 11
--      (x"00", x"38", x"38", x"38", x"38", x"38", x"38", x"38"), -- Cycle 12
--      (x"38", x"38", x"38", x"38", x"38", x"38", x"38", x"38"), -- Cycle 13
--      (x"00", x"00", x"00", x"00", x"38", x"38", x"38", x"38"), -- Cycle 14
--      (x"00", x"00", x"00", x"00", x"31", x"31", x"31", x"31"), -- Cycle 15
--      (x"00", x"31", x"31", x"31", x"31", x"31", x"31", x"31"), -- Cycle 16
--      (x"00", x"5a", x"5a", x"5a", x"5a", x"5a", x"5a", x"5a"), -- Cycle 17
--      (x"00", x"00", x"00", x"00", x"00", x"00", x"5a", x"5a")  -- Cycle 18
--  );
--


 end package pkg_sink_test_vectors;