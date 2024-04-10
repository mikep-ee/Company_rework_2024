--------------------------------------------------------------------------------
--
-- File: test_bench_sink_module.vhd

-- Description: 
-- This bench is a self checking module that excercises the sink_module.vhd
-- design.
-- 
--
-- Date   : 06/10/2018
-- Author : Michael Pleasant
--------------------------------------------------------------------------------

library IEEE;

use ieee.std_logic_1164.all;
use work.pkg_sink_test_vectors.all; -- defined test vectors

entity test_bench_sink_module is
end test_bench_sink_module ;

architecture behav of test_bench_sink_module is

  component sink_module is 
   port
   (
     CLK             : in std_logic  ; -- System clock
     RESET_N         : in std_logic  ; -- Active low reset
     
     -- Module logical inputs
     IN_VALID        : in std_logic  ; -- valid incoming data
     START_OF_PACKET : in std_logic  ; -- Start of data packet
     END_OF_PACKET   : in std_logic  ; -- End of data packet
     IN_DATA         : in std_logic_vector(63 downto 0);
                                       -- Incoming payload data
     EMPTY           : in std_logic_vector(2 downto 0 );
                                       -- Empty bytes during End Of Payload
     ERROR           : in std_logic  ; -- Error in data input stream
     
     -- Module outputs
     READY           : out std_logic ; -- Sink module ready for data 
     OUT_VALID       : out std_logic ; -- Output data valid
     OUT_DATA        : out std_logic_vector(255 downto 0);
                                      -- Out going payload
     BYTE_MASK       : out std_logic_vector(31 downto 0)  
                                          -- Output message byte mask
   )            ;
  end component ;  
 
  -- Test bench input/output signals
  signal s_clk             : std_logic  := '0' ; -- System clock
  signal s_reset_n         : std_logic  := '0' ; -- Active low reset 
  signal s_in_data         : std_logic_vector(63 downto 0) :=  (others=>'0');
  
  signal s_in_sop          : std_logic  := '0' ; -- Start of data packet
  signal s_in_eop          : std_logic  := '0' ; -- End of data packet
  signal s_in_valid        : std_logic  := '0' ; -- valid incoming data
                                                 -- Incoming payload data
  signal s_in_empty        : std_logic_vector(2 downto 0 ) := "000";     
                                         -- Empty bytes during End Of Payload 
                                          
  signal s_in_error        : std_logic := '0' ; -- Error in data input stream 
          
  signal s_out_ready       : std_logic ; -- Sink module ready for data         
  signal s_out_valid       : std_logic ; -- Output data valid 
                   
  signal s_out_data        : std_logic_vector(255 downto 0);   
                                         -- Out going payload                   
  signal s_byte_mask       : std_logic_vector(31 downto 0)  ;   
                                         -- Output message byte mask       
  begin
  
   inst_sink_module : sink_module
   port map   
   (
     CLK             => s_clk             , -- System clock
     RESET_N         => s_reset_n         , -- Active low reset
     
     -- Module logical inputs
     IN_VALID        => s_in_valid        , -- valid incoming data
     START_OF_PACKET => s_in_sop          , -- Start of data packet
     END_OF_PACKET   => s_in_eop          , -- End of data packet
     IN_DATA         => s_in_data         , -- Incoming payload data
     EMPTY           => s_in_empty        , -- Empty bytes during End Of Payload
     ERROR           => s_in_error        , -- Error in data input stream
     -- Module outputs                    ,
     READY           => s_out_ready       , -- Sink module ready for data 
     OUT_VALID       => s_out_valid       , -- Output data valid
     OUT_DATA        => s_out_data        , -- Out going payload
     BYTE_MASK       => s_byte_mask         -- Output message byte mask
   )                                      ;
  
   tb_sim_clk : process                                                  
    begin                                                
      wait for 5 ns      ; -- 200Mhz clk
      s_clk <= not s_clk ;                      
   end process           ;                                         

   tb_sim_reset_n : process                                               
    begin 
      s_reset_n <= '0'       ; -- Hold design in reset                                                
      wait for 50 ns         ; 
      s_reset_n <= '1'       ; -- Run design      
      wait                   ;               
   end process               ;

   tb_proc_sink_module : process
       variable v_index : integer := 0 ; -- loop variable 
     begin
     
     wait until s_reset_n = '1' ;
     
     wait until rising_edge(s_clk);
     wait until s_out_ready = '1';
     
     -- Excercise design with test vectors
     v_index := C_VECTOR_CNT - 1;
     while v_index >= 0 loop
       wait until rising_edge(s_clk) ;
       if(s_out_ready = '1') then
         s_in_valid  <= C_INPUT_TEST_VECTOR_1(v_index)(C_VAL_BIT);
         s_in_sop    <= C_INPUT_TEST_VECTOR_1(v_index)(C_SOP_BIT);
         s_in_eop    <= C_INPUT_TEST_VECTOR_1(v_index)(C_EOP_BIT);
         s_in_data   <= C_INPUT_TEST_VECTOR_1(v_index)(C_DBUS_HI_BIT 
                                                        downto C_DBUS_LO_BIT);
         s_in_empty  <= C_INPUT_TEST_VECTOR_1(v_index)(C_EMPTY_HI_BIT 
                                                        downto C_EMPTY_LO_BIT);
         s_in_error  <= C_INPUT_TEST_VECTOR_1(v_index)(C_ERROR_BIT);
         
         v_index := v_index - 1;
       else
         s_in_valid <= '0' ;  
       end if ; 
     end loop ;
     
     wait for 1 us;
     wait until rising_edge(s_clk) ;
     s_in_valid  <= '0'            ;
     s_in_sop    <= '0'            ;
     s_in_eop    <= '0'            ;
     s_in_data   <= (others => '0');
     s_in_empty  <= (others => '0');
     s_in_error  <= '0'            ;
         
     
    wait ;
   end process ;
   
   proc_checker : process
   begin
   
     wait until s_reset_n = '1' ;
     
     -- Check design output against vectors
     for i in C_VECTOR_QTY-1 downto 0 loop
        
       wait until rising_edge(s_clk);
       wait until s_out_valid = '1' ;
       
       if (s_out_data  /= C_OUTPUT_TEST_VECTOR_1(i)) or
          (s_byte_mask /= C_OUTPUT_VECTOR_MASK_1(i)) then
          
         assert  false                       
           report "SIMULATION FAILED!!" 
           severity failure;
       end if    ;
     end loop    ;
     
     assert false                             
        report "SIMULATION ENDED. TEST PASSED!!!" 
        severity failure;                     
   end process ;

end architecture ;