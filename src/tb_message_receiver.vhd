--------------------------------------------------------------------------------
--
-- File: tb_message_receiver.vhd

-- Description: 
-- This bench is a self checking module that excercises the tb_message_receiver.vhd
-- design.
-- 
--
-- Date   : 04/10/2024
-- Author : Michael Pleasant
--------------------------------------------------------------------------------

library IEEE;

use ieee.std_logic_1164.all;
use work.pkg_company_rework_types.all; -- defined types
use work.pkg_sink_test_vectors.all; -- defined test vectors


entity tb_message_receiver is
end tb_message_receiver ;

architecture behav of tb_message_receiver is

  component message_receiver is
    port (
        CLK                : in  std_logic;
        RESET_N            : in  std_logic;
        
        IN_VALID           : in  std_logic; -- For now, assume IN_VALID is only asserted as a result of 
                                           -- bus stall initiated by me. So, no need to monitor IN_VALID
        IN_START_OF_PACKET : in  std_logic;
        IN_END_OF_PACKET   : in  std_logic;
        IN_DATA            : in  std_logic_vector(63 downto 0);
        IN_EMPTY           : in  std_logic_vector(2 downto 0);
        IN_ERROR           : in  std_logic;
   
        IN_READY           : IN   std_logic; -- Ready from module being fed OUT_BYTES
        OUT_READY          : OUT  std_logic; -- Ready to the top level module
        --OUT_VALID          : OUT  std_logic;
        OUT_BYTE_MASK      : OUT  std_logic_vector(31 downto 0);

        OUT_BYTES          : OUT  byte_array(0 to 7);
        OUT_BYTES_WEN_N    : OUT  std_logic_vector(7 downto 0);
        OUT_BYTES_VAL      : OUT  std_logic;
        --MAX_BYTE_CNT       : OUT  std_logic_vector(2 downto 0);
        MSG_START          : OUT  std_logic;
        MSG_DONE           : OUT  std_logic;

        LAST_BYTE_CNT      : OUT  std_logic_vector(2 downto 0)
    );
end component message_receiver;  
 
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

  signal s_in_ready        : std_logic  := '0' ; -- Ready from module being fed OUT_BYTES                                    
  signal s_in_error        : std_logic := '0' ; -- Error in data input stream 
          
  signal s_out_ready       : std_logic ; -- Sink module ready for data         
  signal s_out_valid       : std_logic ; -- Output data valid 
                   
  signal s_out_data        : std_logic_vector(255 downto 0);   
                                         -- Out going payload                   
  signal s_byte_mask       : std_logic_vector(31 downto 0)  ;   
                                         -- Output message byte mask   

   signal s_out_bytes      : byte_array(0 to 7) ; -- Output bytes
   signal s_out_bytes_wen_n: std_logic_vector(7 downto 0) ; -- Output bytes write enable
   signal s_out_bytes_val  : std_logic ; -- Output bytes valid
   signal s_msg_start      : std_logic ; -- Message start
   signal s_msg_done       : std_logic ; -- Message done   
   signal s_last_byte_cnt  : std_logic_vector(2 downto 0) ; -- Last byte count 

  begin
  
   inst_msg_rcvr : message_receiver
   port map   
   (
     CLK             => s_clk             , -- System clock
     RESET_N         => s_reset_n         , -- Active low reset
     
     -- Module logical inputs
     IN_VALID           => s_in_valid        , -- valid incoming data
     IN_START_OF_PACKET => s_in_sop          , -- Start of data packet
     IN_END_OF_PACKET   => s_in_eop          , -- End of data packet
     IN_DATA            => s_in_data         , -- Incoming payload data
     IN_EMPTY           => s_in_empty        , -- Empty bytes during End Of Payload
     IN_ERROR           => s_in_error        , -- Error in data input stream

     IN_READY           => s_in_ready        , -- Ready from module being fed OUT_BYTES
     -- Module outputs                    ,
     OUT_READY           => s_out_ready       , -- Sink module ready for data 
     --OUT_VALID       => s_out_valid       , -- Output data valid
     --OUT_DATA          => s_out_data        , -- Out going payload
     OUT_BYTE_MASK     => s_byte_mask       , -- Output message byte mask

     OUT_BYTES       => s_out_bytes       , -- Output bytes
     OUT_BYTES_WEN_N => s_out_bytes_wen_n , -- Output bytes write enable
     OUT_BYTES_VAL   => s_out_bytes_val   , -- Output bytes valid
     MSG_START       => s_msg_start       , -- Message start
     MSG_DONE        => s_msg_done        , -- Message done
     LAST_BYTE_CNT   => s_last_byte_cnt   -- Last byte count
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

   tb_proc_msg_rcv : process
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
         s_in_ready  <= '1' ; -- Driven by module being fed OUT_BYTES; Will test later.

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
     variable test_pass_b : boolean_vector(0 to 7) ; -- Test pass boolean vector
     --variable j           : integer := 0 ; -- loop variable
   begin
   
     wait until s_reset_n = '1' ;
     
     -- Check design output against vectors
     for i in C_VECTOR_QTY-1 downto 0 loop
        
       wait until rising_edge(s_clk);

       test_pass_b(0) := s_last_byte_cnt   = OUT_VECTOR_START_MSG_1(i)(C_CNT_HI_BIT downto C_CNT_LO_BIT);
       test_pass_b(1) := s_out_ready       = OUT_VECTOR_START_MSG_1(i)(C_READY_BIT);
       test_pass_b(2) := s_byte_mask       = OUT_VECTOR_START_MSG_1(i)(C_MASK_HI_BIT downto C_MASK_LO_BIT);
       test_pass_b(3) := s_out_bytes_wen_n = OUT_VECTOR_START_MSG_1(i)(C_WEN_HI_BIT  downto C_WEN_LO_BIT);
       test_pass_b(4) := s_out_bytes_val   = OUT_VECTOR_START_MSG_1(i)(C_BVAL_BIT);
       test_pass_b(5) := s_msg_start       = OUT_VECTOR_START_MSG_1(i)(C_START_BIT);
       test_pass_b(6) := s_msg_done        = OUT_VECTOR_START_MSG_1(i)(C_DONE_BIT);
       test_pass_b(7) := s_out_bytes       = OUT_VECTOR_DATA_1(i); 

       for j in 0 to 7 loop
         if not test_pass_b(j) then          
          assert  false                       
            report "MESSAGE_RECEIVER: SIMULATION FAILED!!" 
            severity failure;
         end if    ;
       end loop ;

       --wait until rising_edge(s_clk);
       --wait until s_msg_done = '1' ;
--
       --done_msg_t.s_out_bytes_wen_n := OUT_VECTOR_DONE_MSG_1(i)(C_WEN_BIT);
       --done_msg_t.s_out_bytes_val   := OUT_VECTOR_DONE_MSG_1(i)(C_VAL_BIT); 
       --done_msg_t.s_msg_start       := OUT_VECTOR_DONE_MSG_1(i)(C_DONE_BIT);
       --done_msg_t.s_last_byte_cnt   := OUT_VECTOR_DONE_MSG_1(i)(C_CNT_HI_BIT 
       --                                                      downto C_CNT_LO_BIT);
       --done_msg_t.s_out_ready       := OUT_VECTOR_DONE_MSG_1(i)(C_READY_BIT);
       --done_msg_t.s_byte_mask       := OUT_VECTOR_DONE_MSG_1(i)(C_MASK_HI_BIT 
       --                                                      downto C_MASK_LO_BIT);
       --                                                      
       --test_status := check_done_of_message(done_msg_t     , s_out_bytes_wen_n , 
       --                                     s_out_bytes_val , s_msg_start       ,
       --                                     s_last_byte_cnt , s_out_ready       ,
       --                                     s_byte_mask     , s_out_bytes 
       --                                     );
     end loop    ;
     
     assert false                             
        report "MESSAGE_RECEIVER: TEST PASSED!!!" 
        severity failure;                     
   end process ;

end architecture ;