library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.numeric_std."&";
--use ieee.numeric_std.unsigned;
--use ieee.numeric_std.to_integer;
--use ieee.numeric_std.to_unsigned;
--use ieee.numeric_std.to_std_logic_vector;
use work.pkg_company_rework_types.all;

entity message_receiver is
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
   
        IN_READY           : IN   std_logic;
        OUT_READY          : OUT  std_logic;
        OUT_VALID          : OUT  std_logic;
        OUT_BYTE_MASK      : OUT  std_logic_vector(31 downto 0);

        OUT_BYTES          : OUT  byte_array(0 to 7);
        OUT_BYTES_WEN_N    : OUT  std_logic_vector(7 downto 0);
        OUT_BYTES_VAL      : OUT  std_logic;
        --MAX_BYTE_CNT       : OUT  std_logic_vector(2 downto 0);
        MSG_START          : OUT  std_logic;
        MSG_DONE           : OUT  std_logic;

        LAST_BYTE_CNT      : OUT  std_logic_vector(2 downto 0)
    );
end entity message_receiver;

architecture behav of message_receiver is
  -- Type definitions
  --type bus_in is array(0 to 7) of std_logic_vector(7 downto 0);
  type sm_state is (WAIT_SOP, GET_DATA, LAST_CYCLE, STALL, STALL_AND_OUTPUT_DATA, 
                    GET_LSB_LEN_AND_DATA, START_NEW_MESSAGE);

  -- Contstant definitions
  constant MAX_MSG_CNT_C : integer := 65535;
  constant MAX_MSG_LEN_C : integer := 32;
  constant MAX_NUM_CYC_C : integer := MAX_MSG_LEN_C/8;
  constant MAX_LAST_BYTE_CNT_C : integer := 8;

  -- Alias definitions
  alias sop_a : std_logic is IN_START_OF_PACKET;
  alias eop_a : std_logic is IN_END_OF_PACKET;

  --Function definitions
  function calc_mask(msg_len : integer range 0 to MAX_MSG_LEN_C-1) return std_logic_vector is
    variable mask    : std_logic_vector(31 downto 0);
    variable msg_len_in : integer range 0 to MAX_MSG_LEN_C-1;
  begin
    msg_len_in := msg_len;
    mask := (others => '0');
    for i in 0 to (MAX_MSG_LEN_C-1) loop -- 32 is the max message len
      if (msg_len_in /= 0) then
        mask(i) := '1';
        msg_len_in := msg_len_in - 1; -- What would this synthesize to?
      end if;
    end loop;
    return mask;
  end function calc_mask;

  function current_cycle(last_bytes : integer range 0 to MAX_NUM_CYC_C-1) return integer is    
  begin
    if(last_bytes > 4) then
      return 1;
    else
      return 0;
    end if;
  end function current_cycle;

  procedure output_last_payload(last_bytes : in integer range 0 to MAX_LAST_BYTE_CNT_C-1;
                                bus_in : in byte_array(0 to 7);
                                s_out_bytes_val : out std_logic;
                                s_out_bytes_wen_n : out std_logic_vector(7 downto 0);
                                s_payload : out byte_array(0 to 7)
                                ) is
    variable i : integer := 0;
    --variable w_en : std_logic_vector(s_out_bytes_wen_n'length-1 downto 0);
  begin

    i    := 1;
    while i <= 8 loop
      if(i /= 0) then
        s_payload(i-1) := bus_in(8-i);
        s_out_bytes_wen_n(i-1) := '1';     
      end if;
      i := i+1;
    end loop;
    
    if(last_bytes = 0) then
      s_out_bytes_val := '0'; 
    else
      s_out_bytes_val := '1';
    end if;        
  end procedure output_last_payload;

  procedure get_next_msg_data(last_bytes : in integer range 0 to MAX_LAST_BYTE_CNT_C-1;
                              bus_in : in byte_array(0 to 7); 
                              s_next_message_len : out integer range 0 to MAX_MSG_LEN_C-1;
                              s_next_message_data : out byte_array(0 to 7)
                              ) is
    variable i : integer := 0;
  begin

    s_next_message_len  := 0;
    s_next_message_data := (others => (others => '0'));

    case last_bytes is
      when 0 =>
        s_next_message_len  := 0;
        s_next_message_data := (others => (others => '0'));
      when 1 =>        
        s_next_message_len          := to_integer(unsigned(bus_in(1)) & unsigned(bus_in(2)));
        s_next_message_data(0 to 4) := bus_in(3 to 7);
      when 2 =>
        s_next_message_len          := to_integer(unsigned(bus_in(2)) & unsigned(bus_in(3))); 
        s_next_message_data(0 to 3) := bus_in(4 to 7);
      when 3 =>
        s_next_message_len          := to_integer(unsigned(bus_in(3)) & unsigned(bus_in(4)));
        s_next_message_data(0 to 2) := bus_in(5 to 7);
      when 4 =>
        s_next_message_len          := to_integer(unsigned(bus_in(4)) & unsigned(bus_in(5))); 
        s_next_message_data(0 to 1) := bus_in(6 to 7);
      when 5 =>
        s_next_message_len     := to_integer(unsigned(bus_in(5)) & unsigned(bus_in(6))); 
        s_next_message_data(0) := bus_in(7);
      when 6 =>
        s_next_message_len := to_integer(unsigned(bus_in(6)) & unsigned(bus_in(7))); 
      when others =>
        s_next_message_len  := 0;
        s_next_message_data := (others => (others => '0'));
    end case;
  end procedure get_next_msg_data;

  procedure get_next_state(last_bytes : in integer range 0 to MAX_LAST_BYTE_CNT_C-1;                           
                           stall_out : out boolean;
                           next_state : out sm_state                           
                           ) is  
   -- variable stall_out : boolean := false;                        
  begin

    stall_out := false;
    case last_bytes is   
      when 1 | 2 | 3 | 4 =>      
        next_state := STALL_AND_OUTPUT_DATA; -- Got length and data, stall to output data
        stall_out := true;                   -- This will require a stall to unload this cycle's
                                             -- data. Otherwise, the incoming will get dropped.
      when 5 =>      
        next_state := GET_DATA; -- Got length, now get the data       
      when 6 =>
        next_state := GET_LSB_LEN_AND_DATA; -- Got the MSB of length, get LSB and data       
      when others =>
        next_state := WAIT_SOP; -- Should never get to this state
    end case;

  end procedure get_next_state;

  -- Signal definitions
  signal s_state       : sm_state := WAIT_SOP;
  signal s_state_q     : sm_state;
  signal s_nxt_state   : sm_state;  
  --signal s_nxt_state_q : sm_state; 
  signal s_nxt_state_ptr   : sm_state;  
  signal s_nxt_state_ptr_q : sm_state; 

  signal s_msg_cnt_i   : integer range 0 to MAX_MSG_CNT_C-1;   
  signal s_msg_cnt_i_q : integer range 0 to MAX_MSG_CNT_C-1;
  signal s_msg_len_i   : integer range 0 to MAX_MSG_LEN_C-1;
  signal s_msg_len_i_q : integer range 0 to MAX_MSG_LEN_C-1;
  signal s_payload     : byte_array(0 to 7);
  signal s_payload_q   : byte_array(0 to 7);

  signal s_out_bytes_wen_n   : std_logic_vector(7 downto 0);
  signal s_out_bytes_wen_n_q : std_logic_vector(7 downto 0);
  signal s_out_byte_mask     : std_logic_vector(31 downto 0);
  signal s_out_byte_mask_q   : std_logic_vector(31 downto 0);
  signal s_out_bytes_val     : std_logic;
  signal s_out_bytes_val_q   : std_logic;
  signal s_msg_start         : std_logic;
  signal s_msg_start_q       : std_logic;
  signal s_msg_done          : std_logic;
  signal s_msg_done_q        : std_logic;

  signal s_num_cycles_i      : integer range 0 to MAX_NUM_CYC_C-1;
  signal s_num_cycles_i_q    : integer range 0 to MAX_NUM_CYC_C-1;
  signal s_last_byte_cnt_i   : integer range 0 to MAX_LAST_BYTE_CNT_C-1;
  signal s_last_byte_cnt_i_q : integer range 0 to MAX_LAST_BYTE_CNT_C-1;

  signal s_cyc_cnt_i         : integer range 0 to MAX_NUM_CYC_C-1;
  signal s_cyc_cnt_i_q       : integer range 0 to MAX_NUM_CYC_C-1;

  signal bus_in_array : byte_array(0 to 7);

  signal s_next_message_len_i   : integer range 0 to MAX_MSG_LEN_C-1;
  signal s_next_message_len_i_q : integer range 0 to MAX_MSG_LEN_C-1;
  signal s_next_message_data    : byte_array(0 to 7);
  signal s_next_message_data_q  : byte_array(0 to 7);

  signal s_stall_comb : boolean := false;

  --signals for WAIT_SOP state code hiding
  signal s_msg_len_minus_4             : std_logic_vector(15 downto 0);
  signal s_no_full_cycles_b            : boolean := false;
  signal s_msg_cnt_from_data_bus_i     : integer range 0 to MAX_MSG_CNT_C-1;
  signal s_msg_len_from_data_bus_i     : integer range 0 to MAX_MSG_LEN_C-1;
  signal s_calc_cycles_for_msg_i       : integer range 0 to MAX_NUM_CYC_C-1;
  signal s_calc_bytes_in_last_cycle_i  : integer range 0 to MAX_LAST_BYTE_CNT_C-1;

  --signals for LAST_CYCLE state code hiding
  signal s_last_cycle_bytes             : byte_array(0 to 7);
  signal s_last_cycle_bytes_wen_n       : std_logic_vector(7 downto 0);
  signal s_last_cycle_out_bytes_val     : std_logic; 

  --signals for GET_DATA state code hiding
  signal s_last_full_cycle_b           : boolean := false;
  signal s_additional_data_b           : boolean := false;
  signal s_eop_b                       : boolean := false;
  signal s_start_a_new_msg_b           : boolean := false;
  signal s_get_last_bytes_b            : boolean := false;
  signal s_wait_next_sop_b             : boolean := false;
  
begin    

    map_inbus : process(all)
         variable i : integer := 0;
       begin
          while i < 7 loop
            bus_in_array(i) <= IN_DATA(63-(8*i) downto 56-(8*i));
            i := i + 1;
          end loop;
       end process map_inbus;

    ----------------------------------------------------------------------------------------------------------
    -- These signals were created to hide code and make the flow of the state machine easier to read.
    ----------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------------
    -- WAIT_SOP state signals to hide code
    ----------------------------------------------------------------------------------------------------------
    -- Message count and length from the data bus. Only the bits necessary to represent the
    -- max values are used.
    -- Only valid in the WAIT_SOP state
    s_msg_cnt_from_data_bus_i <= to_integer(unsigned(IN_DATA(63 downto 48)));
    s_msg_len_from_data_bus_i <= to_integer(unsigned(IN_DATA(36 downto 32))); --Only need 32 bytes, so lop off upper bits

    -- Subtracts 4 from the message length, since 4 bytes are read on the SOP cycle
    -- Signal is only valid in the WAIT_SOP state
    s_msg_len_minus_4 <= std_logic_vector(
                              to_unsigned( (s_msg_len_from_data_bus_i - 4), s_msg_len_minus_4'length-1)); 
    
    -- Checks the message length (-4) divided by 8 (bottom 3 bits lopped off); This is the number of 8 byte bus
    -- cycles required to get the entire message. 
    -- Only 5 bits are checked because the max message length is 32
    -- Signal is only valid in the WAIT_SOP state
    s_no_full_cycles_b <= not (to_integer(unsigned(s_msg_len_minus_4(7 downto 3))) = 0);    

    -- The number of cycles required to get the entire message is calculated by dividing the message length-4
    -- (Because 4 bytes are read on the SOP cycle) by 8; the bottom 3 bits are lopped off to perform the divide by 8.
    s_calc_cycles_for_msg_i       <= to_integer(unsigned(s_msg_len_minus_4(7 downto 3))); 
    -- The number of bytes in the last cycle is calculated by taking the message length-4 mod 8
    s_calc_bytes_in_last_cycle_i  <= to_integer(unsigned(s_msg_len_minus_4(2 downto 0)));

   ----------------------------------------------------------------------------------------------------------
    -- GET_DATA state signals to hide code
    ----------------------------------------------------------------------------------------------------------
    s_last_full_cycle_b  <= (s_cyc_cnt_i_q = s_num_cycles_i_q); -- Last cycle with 8 bytes of data
    s_additional_data_b  <= (s_last_byte_cnt_i_q > 0);          -- Last cycle with 8 bytes of data, but <8 more bytes coming
    s_eop_b              <= (eop_a = '1');                      -- End of packet signal
    s_start_a_new_msg_b  <= (s_last_full_cycle_b and (not s_additional_data_b) and (not s_eop_b));
    s_get_last_bytes_b   <= (s_last_full_cycle_b and      s_additional_data_b                   );
    s_wait_next_sop_b    <= (s_last_full_cycle_b and                                    s_eop_b );
    

    -- End code hiding signals -------------------------------------------------------------------------------

    OUT_VALID          <= s_out_bytes_val_q;
    OUT_BYTE_MASK      <= (others => '0'); -- calculate this from message size
    OUT_BYTES          <= s_payload_q;
    OUT_BYTES_WEN_N    <= s_out_bytes_wen_n_q;
    OUT_BYTES_VAL      <= s_out_bytes_val_q;
    OUT_READY          <= '0' when s_stall_comb else '1'; -- This is a combinatorial output because, if stalled,
                                                          -- we can't accept data on the next cycle
    MSG_START          <= s_msg_start_q;
    MSG_DONE           <= '0'; --declare a signal for this
    LAST_BYTE_CNT      <= std_logic_vector(to_unsigned(s_last_byte_cnt_i_q, LAST_BYTE_CNT'length)); --declare a signal for this

    rcv_sm_comb : process(all)
         variable i                    : integer := 0;
         variable v_out_bytes_val      : std_logic;
         variable v_out_bytes_wen_n    : std_logic_vector(7 downto 0);
         variable v_payload            : byte_array(0 to 7);
         variable v_next_message_len_i : integer range 0 to MAX_MSG_LEN_C-1;
         variable v_next_message_data  : byte_array(0 to 7);
         variable v_nxt_state          : sm_state;
         variable v_stall_comb         : boolean;

       begin
           -- Default assignments
           s_state           <= WAIT_SOP;
           s_nxt_state_ptr   <= s_nxt_state_ptr_q;
           s_payload         <= s_payload_q;
           s_msg_cnt_i       <= s_msg_cnt_i_q;
           s_msg_len_i       <= s_msg_len_i_q;
           s_num_cycles_i    <= s_num_cycles_i_q;
           s_cyc_cnt_i       <= s_cyc_cnt_i_q;
           s_last_byte_cnt_i <= s_last_byte_cnt_i_q;
           s_out_byte_mask   <= s_out_byte_mask_q;
           s_out_bytes_wen_n <= (others => '0');
           s_out_bytes_val   <= '0';
           s_msg_start       <= '0';
           s_msg_done        <= '0';
           s_out_byte_mask   <= s_out_byte_mask;
           s_next_message_len_i <= s_next_message_len_i_q;
           s_next_message_data  <= s_next_message_data_q;
           s_stall_comb         <= false;

           case s_state_q is
              when WAIT_SOP =>
                s_msg_cnt_i <= s_msg_cnt_from_data_bus_i;
                s_msg_len_i <= s_msg_len_from_data_bus_i; 

                i := 0;
                while i < 3 loop                                
                  s_payload(i) <= bus_in_array(3-i);
                  i := i+1;
                end loop;

                s_num_cycles_i    <= s_calc_cycles_for_msg_i; 
                s_last_byte_cnt_i <= s_calc_bytes_in_last_cycle_i; 
                s_out_bytes_wen_n <= x"0F"; 
                s_out_byte_mask   <= calc_mask(s_msg_len_from_data_bus_i);                
                
                if(sop_a and (not IN_ERROR)) then                  
                  s_out_bytes_val   <= '1'; -- Output (payload) data is now valid
                  s_msg_start       <= '1'; -- Start of message  
                  s_cyc_cnt_i       <= 1;   --Initialize cycle counter

                  if(s_no_full_cycles_b) then 
                    s_nxt_state <= LAST_CYCLE; --Last cycle with less than 8 bytes
                  else
                    s_nxt_state <= GET_DATA; -- Cycle with 8 bytes of data       
                  end if;          
                else
                  s_nxt_state <= WAIT_SOP;
                end if;

              when GET_DATA => 
                i := 0;

                --Copy the payload data
                while i < 7 loop                                
                  s_payload(i) <= bus_in_array(7-i);
                  i := i+1;
                end loop;

                s_out_bytes_val   <= '1'; -- Output (payload) data is now valid
                s_out_bytes_wen_n <= x"FF";
                s_cyc_cnt_i       <= s_cyc_cnt_i_q + 1; -- Increment cycle counter

                if(IN_ERROR) then
                  s_nxt_state <= WAIT_SOP; -- Assume entire message is bad

                elsif(s_start_a_new_msg_b) then
                  s_msg_done  <= '1'; -- Message is done
                  
                  s_nxt_state     <= START_NEW_MESSAGE; 
                  s_nxt_state_ptr <= START_NEW_MESSAGE; -- Save next pointer state in case we need to stall

                elsif(s_get_last_bytes_b) then
                  
                  s_nxt_state     <= LAST_CYCLE; -- Last cycle with less than 8 bytes
                  s_nxt_state_ptr <= LAST_CYCLE; -- Save next pointer state in case we need to stall
                
                elsif(s_wait_next_sop_b) then
                  s_msg_done  <= '1';      -- Message is done
                  s_nxt_state <= WAIT_SOP; -- Wait for the next packet

                else

                  s_nxt_state     <= GET_DATA; -- Get the next 8 bytes of data
                  s_nxt_state_ptr <= GET_DATA;
                end if;

                if(not IN_READY) then
                  s_nxt_state     <= STALL;    -- Override next state, if not ready
                                               -- The s_next_state_ptr will know where to
                                               -- go after the stall                 
                end if;                  

              when LAST_CYCLE =>
               
                s_msg_done  <= '1'; -- Message is done

                output_last_payload(s_last_byte_cnt_i_q , bus_in_array,                  -- Procedure inputs
                                    v_out_bytes_val     , v_out_bytes_wen_n , v_payload  -- Procedure outputs
                                    );
                s_out_bytes_val   <= v_out_bytes_val;
                s_out_bytes_wen_n <= v_out_bytes_wen_n;
                s_payload         <= v_payload;

                get_next_msg_data(s_last_byte_cnt_i_q, bus_in_array,         -- Procedure inputs
                                  v_next_message_len_i, v_next_message_data  -- Procedure outputs
                                  );
                s_next_message_len_i <= v_next_message_len_i;
                s_next_message_data  <= v_next_message_data;

                get_next_state(s_last_byte_cnt_i_q,  -- Procedure inputs
                               v_stall_comb,         -- Procedure outputs
                               v_nxt_state           -- Procedure outputs 
                              );
                s_nxt_state     <= v_nxt_state;
                s_nxt_state_ptr <= v_nxt_state;
                s_stall_comb    <= v_stall_comb; -- combinatorial output because, if stalled,
                                                 -- we can't accept data on the next cycle

                -- Override the next state if any of the following conditions are met                
                if(IN_ERROR) then
                  s_nxt_state <= WAIT_SOP; -- Assume entire message is bad
                elsif(not IN_READY) then                  
                  s_nxt_state     <= STALL; -- Override next state, if not ready
                                            -- The s_next_state_ptr will know where to
                                            -- go after the stall              
                end if;
                
              when STALL =>                
                if(IN_ERROR) then
                  s_nxt_state <= WAIT_SOP; -- Assume entire message is bad
                elsif(not IN_READY) then
                  s_nxt_state <= STALL; 
                else   
                  s_nxt_state <= s_nxt_state_ptr_q; -- Go back to designated next state, before stall                  
                end if;
              when STALL_AND_OUTPUT_DATA =>

              when START_NEW_MESSAGE =>
             
              when GET_LSB_LEN_AND_DATA =>  
                -- May need to break this up into two states
                -- GOT_LEN and GOT_LEN and DATA
                -- Maybe GOT_HI_LEN and also handle data
                -- But if there is data, there will need to be a stall 
                -- because there will also be incoming data
                -- but only stall if total bytes is greater than 8
                -- Actaully it wouldn't matter if greater than 8 because
                -- And what if a cycle is the last cycle? Say, if a message length
                -- is 8, and you have 5 bytes from the previous cycle. This cycle
                -- would be the last. So, the get_next_state function should be
                -- updated to consider that case.

              when others =>
                 s_nxt_state <= WAIT_SOP;
           end case;
       end process rcv_sm_comb;

    rcv_sm_reg : process(CLK, RESET_N)
       begin

          if RESET_N = '0' then
            s_state_q           <= WAIT_SOP;  
            s_nxt_state_ptr     <= WAIT_SOP;         
            s_msg_cnt_i_q       <= 0;
            s_msg_len_i_q       <= 0;
            s_payload_q         <= (others => (others => '0'));
            s_num_cycles_i_q    <= 0;
            s_last_byte_cnt_i_q <= 0; 
            s_out_byte_mask_q   <= (others => '0');
            s_out_bytes_wen_n_q <= (others => '0');
            s_out_bytes_val_q   <= '0';
            s_msg_start_q       <= '0';
            s_msg_done_q        <= '0';
            s_cyc_cnt_i         <= 0;
            s_next_message_len_i_q  <= 0;
            s_next_message_data_q   <= (others => (others => '0'));
          elsif rising_edge(CLK) then 
            s_state_q           <= s_state  ;  
            s_nxt_state_ptr_q   <= s_nxt_state_ptr;          
            s_msg_cnt_i_q       <= s_msg_cnt_i;
            s_msg_len_i_q       <= s_msg_len_i;
            s_payload_q         <= s_payload;
            s_num_cycles_i_q    <= s_num_cycles_i;
            s_last_byte_cnt_i_q <= s_last_byte_cnt_i;
            s_out_byte_mask_q   <= s_out_byte_mask;
            s_out_bytes_wen_n_q <= s_out_bytes_wen_n;
            s_out_bytes_val_q   <= s_out_bytes_val;
            s_msg_start_q       <= s_msg_start;
            s_msg_done_q        <= s_msg_done;
            s_cyc_cnt_i         <= s_cyc_cnt_i_q;
            S_next_message_len_i_q  <= s_next_message_len_i;
            s_next_message_data_q   <= s_next_message_data;
          end if; 
    end process rcv_sm_reg;

end architecture behav;
