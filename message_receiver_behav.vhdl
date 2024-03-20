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
        
        IN_VALID           : in  std_logic;
        IN_START_OF_PACKET : in  std_logic;
        IN_END_OF_PACKET   : in  std_logic;
        IN_DATA            : in  std_logic_vector(63 downto 0);
        IN_EMPTY           : in  std_logic_vector(2 downto 0);
        IN_ERROR           : in  std_logic;
   
        IN_READY           : IN   std_logic;
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
  type sm_state is (WAIT_SOP, GET_DATA, LAST_CYCLE, STALL, GET_LEN, GET_LO_LEN);

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

  -- Signal definitions
  signal s_state       : sm_state := WAIT_SOP;
  signal s_state_q     : sm_state;
  signal s_nxt_state   : sm_state;  
  signal s_nxt_state_q : sm_state; 

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

  signal s_num_cycles_i      : integer range 0 to MAX_NUM_CYC_C-1;
  signal s_num_cycles_i_q    : integer range 0 to MAX_NUM_CYC_C-1;
  signal s_last_byte_cnt_i   : integer range 0 to MAX_LAST_BYTE_CNT_C-1;
  signal s_last_byte_cnt_i_q : integer range 0 to MAX_LAST_BYTE_CNT_C-1;

  signal s_cyc_cnt_i         : integer range 0 to MAX_NUM_CYC_C-1;
  signal s_cyc_cnt_i_q       : integer range 0 to MAX_NUM_CYC_C-1;

  signal bus_in_array : byte_array(0 to 7);

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
    -- LAST_CYCLE state signals to hide code
    ----------------------------------------------------------------------------------------------------------

    -- End code hiding signals -------------------------------------------------------------------------------

    OUT_VALID          <= s_out_bytes_val_q;
    OUT_BYTE_MASK      <= (others => '0'); -- calculate this from message size
    OUT_BYTES          <= s_payload_q;
    OUT_BYTES_WEN_N    <= s_out_bytes_wen_n_q;
    OUT_BYTES_VAL      <= s_out_bytes_val_q;
    MSG_START          <= s_msg_start_q;
    MSG_DONE           <= '0'; --declare a signal for this
    LAST_BYTE_CNT      <= std_logic_vector(to_unsigned(s_last_byte_cnt_i_q, LAST_BYTE_CNT'length)); --declare a signal for this

    rcv_sm_comb : process(all)
         variable i : integer := 0;
         
       begin
           -- Default assignments
           s_state           <= WAIT_SOP;
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
           s_out_byte_mask   <= s_out_byte_mask;

           case s_state is
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
                while i < 7 loop                                
                  s_payload(i) <= bus_in_array(7-i);
                  i := i+1;
                end loop;

                s_out_bytes_val   <= '1'; -- Output (payload) data is now valid
                s_out_bytes_wen_n <= x"FF";
                s_cyc_cnt_i       <= s_cyc_cnt_i_q + 1; -- Increment cycle counter

                if(IN_ERROR) then
                  s_nxt_state <= WAIT_SOP; -- Assume entire message is bad
                elsif(not IN_READY) then
                  s_out_bytes_val <= '0'; -- Hold off on outputting data until ready
                  s_nxt_state     <= STALL; -- Stall until ready
                else                  
                  if(s_cyc_cnt_i_q = s_num_cycles_i_q) then
                    s_nxt_state <= LAST_CYCLE; --Last cycle with less than 8 bytes
                  else
                    s_nxt_state <= GET_DATA; -- Cycle with 8 bytes of data
                  end if;
                end if;

              when LAST_CYCLE =>
                 
              when STALL =>
                
                if(IN_ERROR) then
                  s_nxt_state <= WAIT_SOP; -- Assume entire message is bad
                elsif(not IN_READY) then
                  s_nxt_state <= STALL; 
                else                  
                  s_out_bytes_val <= '1'; -- Output payload from data captured before the stall
                  if(s_cyc_cnt_i_q = s_num_cycles_i_q) then
                    s_nxt_state <= LAST_CYCLE; --Last cycle with less than 8 bytes
                  else
                    s_nxt_state <= GET_DATA; -- Cycle with 8 bytes of data
                  end if;
                end if;
              when GET_LEN =>  

              when GET_LO_LEN =>

              when others =>
                 s_nxt_state <= WAIT_SOP;
           end case;
       end process rcv_sm_comb;

    rcv_sm_reg : process(CLK, RESET_N)
       begin

          if RESET_N = '0' then
            s_state_q           <= WAIT_SOP;           
            s_msg_cnt_i_q       <= 0;
            s_msg_len_i_q       <= 0;
            s_payload_q         <= (others => (others => '0'));
            s_num_cycles_i_q    <= 0;
            s_last_byte_cnt_i_q <= 0; 
            s_out_byte_mask_q   <= (others => '0');
            s_out_bytes_wen_n_q <= (others => '0');
            s_out_bytes_val_q   <= '0';
            s_msg_start_q       <= '0';
            s_cyc_cnt_i         <= 0;
          elsif rising_edge(CLK) then 
            s_state_q           <= s_state  ;            
            s_msg_cnt_i_q       <= s_msg_cnt_i;
            s_msg_len_i_q       <= s_msg_len_i;
            s_payload_q         <= s_payload;
            s_num_cycles_i_q    <= s_num_cycles_i;
            s_last_byte_cnt_i_q <= s_last_byte_cnt_i;
            s_out_byte_mask_q   <= s_out_byte_mask;
            s_out_bytes_wen_n_q <= s_out_bytes_wen_n;
            s_out_bytes_val_q   <= s_out_bytes_val;
            s_msg_start_q       <= s_msg_start;
            s_cyc_cnt_i         <= s_cyc_cnt_i_q;
          end if; 
    end process rcv_sm_reg;

end architecture behav;
