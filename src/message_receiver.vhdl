library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.numeric_std."&";
--use ieee.numeric_std.unsigned;
--use ieee.numeric_std.to_integer;
--use ieee.numeric_std.to_unsigned;
--use ieee.numeric_std.to_std_logic_vector;
use work.pkg_company_rework_types.all;

--* Next steps:
--- Copy over and modify old test bench to test the message receiver
--  C:\Users\mikep\OneDrive\Mikes_stuff\Resume\2018 and Before\Sarte_Group\IMC\Interview_project\fully functional_cleaned_up_code
--- Update scripts to compile and run the test bench
--- Debug the test bench
--- Sythesize:
--  - While loop as an experiment
--  - Sythesize message message_receiver
--  - When working use Git to label the working version
--- refactor message_receiver or continue with other modules 
--    (Refactor is probably best. The point is to practice, not finish the code)
--- <Remember to use git as necessary and for practice. Try some things out.>

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
  end entity message_receiver;


architecture behav of message_receiver is
  -- Type definitions
  --type bus_in is array(0 to 7) of std_logic_vector(7 downto 0);
  type sm_state is (WAIT_SOP, GET_DATA, LAST_CYCLE, STALL, STALL_AND_OUTPUT_DATA, START_NEW_MESSAGE);

  type msg_type_t is (no_length_no_data, length_no_data, length_with_data, msb_length_only, dont_care);

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

 -- function current_cycle(last_bytes : integer range 0 to MAX_NUM_CYC_C-1) return integer is    
 -- begin
 --   if(last_bytes > 4) then
 --     return 1;
 --   else
 --     return 0;
 --   end if;
 -- end function current_cycle;

--*******************************************************************************************
-- PROCEDURE: output_last_payload
--*******************************************************************************************
  procedure output_last_payload(last_bytes : in integer range 0 to MAX_LAST_BYTE_CNT_C-1;
                                bus_in : in byte_array(0 to 7);
                                s_out_bytes_val : out std_logic;
                                s_out_bytes_wen_n : out std_logic_vector(7 downto 0);
                                s_payload : out byte_array(0 to 7)
                                ) is
    variable i : integer := 0;
    --variable w_en : std_logic_vector(s_out_bytes_wen_n'length downto 0);
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

--*******************************************************************************************
-- PROCDURE: is_last_cycle
--*******************************************************************************************
  procedure get_next_msg_data(last_bytes : in integer range 0 to MAX_LAST_BYTE_CNT_C-1;
                              bus_in : in byte_array(0 to 7); 
                              next_message_len : out integer range 0 to MAX_MSG_LEN_C-1;
                              next_message_data : out byte_array(0 to 7);
                              next_message_bytes : out integer range 0 to MAX_MSG_LEN_C-1
                              ) is
    variable i : integer := 0;
  begin

    next_message_len  := 0;
    next_message_data := (others => (others => '0'));

    case last_bytes is
      when 0 =>
        next_message_len  := 0;
        next_message_data := (others => (others => '0'));
        next_message_bytes := 6; -- Since there are no length bytes, 2 bytes will take up space on the bus.
                                 -- which leaves space for 6 bytes of data.
      when 1 =>        
        next_message_len          := to_integer(unsigned(bus_in(6)) & unsigned(bus_in(5)));
        next_message_data(3 to 7) := bus_in(0 to 4);
        next_message_bytes := 5;
      when 2 =>
        next_message_len          := to_integer(unsigned(bus_in(5)) & unsigned(bus_in(4))); 
        next_message_data(4 to 7) := bus_in(0 to 3);
        next_message_bytes := 4;
      when 3 =>
        next_message_len          := to_integer(unsigned(bus_in(4)) & unsigned(bus_in(3)));
        next_message_data(5 to 7) := bus_in(0 to 2);
        next_message_bytes := 3;
      when 4 =>
        next_message_len          := to_integer(unsigned(bus_in(3)) & unsigned(bus_in(2))); 
        --next_message_data(6 to 7) := bus_in(0 to 1);
        --next_message_data(7) := bus_in(1);
        --next_message_data(6) := bus_in(0);
        next_message_data(7 from 6) := bus_in(0 to 1);
        next_message_bytes := 2;
      when 5 =>
        next_message_len     := to_integer(unsigned(bus_in(2)) & unsigned(bus_in(1))); 
        next_message_data(7) := bus_in(0);
        next_message_bytes := 1;
      when 6 =>
        next_message_len := to_integer(unsigned(bus_in(1)) & unsigned(bus_in(0)));
        next_message_bytes := 8; -- This is 8 because [in this case only] the length bytes 
                                 -- will not take up space on the next bus cycle
      when 7 =>
        next_message_len := to_integer(unsigned(bus_in(0)) & x"00");
        next_message_bytes := 7; -- This is 7 because [in this case only] the length bytes 
                                 -- will only take up 1 byte on the next bus cycle
      when others =>
        next_message_len  := 0;
        next_message_data := (others => (others => '0'));
        next_message_bytes := 0;
    end case;
  end procedure get_next_msg_data;

  --procedure get_next_state(last_bytes : in integer range 0 to MAX_LAST_BYTE_CNT_C-1;                           
  --                         stall_out  : out boolean;
  --                         next_state : out sm_state                       
  --                         ) is  
  -- -- variable stall_out : boolean := false;                        
  --begin
--
  --  stall_out := false;
  --  case last_bytes is   
  --    when 1 | 2 | 3 | 4 =>      
  --      next_state := STALL_AND_OUTPUT_DATA; -- Got length and data, stall to output data
  --      stall_out := true;                   -- This will require a stall to unload this cycle's
  --                                           -- data. Otherwise, the incoming will get dropped.
  --    when 5 =>      
  --      next_state := GET_DATA; -- Got length, now get the data       
  --    when 6 =>
  --      next_state := GET_LSB_LEN_AND_DATA; -- Got the MSB of length, get LSB and data   
  --    when others =>
  --      next_state := WAIT_SOP; -- Should never get to this state
  --  end case;
--
  --end procedure get_next_state;
--*******************************************************************************************
-- FUNCTION: is_last_cycle
--*******************************************************************************************
function is_stall_required(last_bytes : in integer range 0 to MAX_LAST_BYTE_CNT_C-1                      
                         ) return boolean is                        
begin

  if(last_bytes = 1 or last_bytes = 2 or last_bytes = 3 or last_bytes = 4) then
    return true; 
  else
    return false;
  end if;
end function is_stall_required;  

--*******************************************************************************************
-- FUNCTION: is_last_cycle
--*******************************************************************************************
  function get_next_msg_type(last_bytes : integer range 0 to MAX_LAST_BYTE_CNT_C-1
                             ) return msg_type_t is
  begin
    case last_bytes is
      when 0 =>
        return no_length_no_data;
      when 1 | 2 | 3 | 4 =>      
        return length_with_data;                   
      when 5 =>      
        return length_no_data;                    
      when 6 =>
        return msb_length_only;                    
      when others =>
        return dont_care;                       
    end case;
  end function get_next_msg_type;
--*******************************************************************************************
-- FUNCTION: is_last_cycle
--*******************************************************************************************
  function is_last_cycle(msg_len : integer;
                         bytes_captured : integer range 0 to MAX_MSG_LEN_C-1
                                  ) return boolean is
    --variable msg_len_i : integer range 0 to MAX_MSG_LEN_C-1;
    variable msg_len_minus_bytes_captured : std_logic_vector(15 downto 0);
  begin
    -- The next cycle will be the last cycle if the message length - bytes captured is <= 8. 
    --msg_len_i := to_integer(unsigned(msg_len(4 downto 0)));
    msg_len_minus_bytes_captured := std_logic_vector(to_unsigned(msg_len - bytes_captured, 
                                                         msg_len_minus_bytes_captured'length));    

    return not (to_integer(unsigned(msg_len_minus_bytes_captured(7 downto 3))) = 0);
  end function is_last_cycle;

----*******************************************************************************************
---- FUNCTION: is_last_cycle
----*******************************************************************************************
--  function remaining_cycles(msg_len        : std_logic_vector(15 downto 0);
--                            bytes_captured : integer range 0 to MAX_MSG_LEN_C-1
--                                  ) return integer is
--    variable msg_len_i : integer range 0 to MAX_MSG_LEN_C-1;
--    variable msg_len_minus_bytes_captured : std_logic_vector(15 downto 0);
--  begin
--    -- The number of cycles required to get the remainder of the message is 
--    -- (message_length - bytes_captured) / 8. 
--    -- Divide by 8 is done by lopping off the bottom 3 bits.
--    -- Only deal with 5 bits because the max message length is 32 (We can think of a way to make this code scalable later)
--    msg_len_i := to_integer(unsigned(msg_len(4 downto 0))); 
--    msg_len_minus_bytes_captured := std_logic_vector(to_unsigned(msg_len_i - bytes_captured, 
--                                                         msg_len_minus_bytes_captured'length));    
--
--    return to_integer(unsigned(msg_len_minus_bytes_captured(4 downto 3)));
--
--  end function remaining_cycles;


--*******************************************************************************************
-- FUNCTION: remaining_cycles
--*******************************************************************************************
  function remaining_cycles(msg_len        : integer;
                            bytes_captured : integer range 0 to MAX_MSG_LEN_C-1
                                  ) return integer is
    --variable msg_len_i : integer range 0 to MAX_MSG_LEN_C-1;
    variable msg_len_minus_bytes_captured : std_logic_vector(15 downto 0);
  begin
    -- The number of cycles required to get the remainder of the message is 
    -- (message_length - bytes_captured) / 8. 
    -- Divide by 8 is done by lopping off the bottom 3 bits.
    -- Only deal with 5 bits because the max message length is 32 (We can think of a way to make this code scalable later)
    --msg_len_i := to_integer(unsigned(msg_len(4 downto 0))); 
    msg_len_minus_bytes_captured := std_logic_vector(to_unsigned(msg_len - bytes_captured, 
                                                         msg_len_minus_bytes_captured'length));    

    return to_integer(unsigned(msg_len_minus_bytes_captured(4 downto 3)));

  end function remaining_cycles;

----*******************************************************************************************
---- FUNCTION: calc_last_byte_cnt
----*******************************************************************************************
--    function calc_last_byte_cnt(msg_len        : std_logic_vector(15 downto 0);
--                            bytes_captured : integer range 0 to MAX_MSG_LEN_C-1
--                                  ) return integer is
--    variable msg_len_i : integer range 0 to MAX_MSG_LEN_C-1;
--    variable msg_len_minus_bytes_captured : std_logic_vector(15 downto 0);
--  begin
--    -- The number of bytes in the last cycle is 
--    -- (message_length - bytes_captured) mod 8.
--    -- mod 8 is done by taking the bottom 3 bits.
--    msg_len_i := to_integer(unsigned(msg_len(4 downto 0))); 
--    msg_len_minus_bytes_captured := std_logic_vector(to_unsigned(msg_len_i - bytes_captured, 
--                                                         msg_len_minus_bytes_captured'length));    
--
--    return to_integer(unsigned(msg_len_minus_bytes_captured(2 downto 0)));
--  end function calc_last_byte_cnt;

--*******************************************************************************************
-- FUNCTION: calc_last_byte_cnt
--*******************************************************************************************
    function calc_last_byte_cnt(msg_len        : integer;
                                bytes_captured : integer range 0 to MAX_MSG_LEN_C-1
                                  ) return integer is
    --variable msg_len_i : integer range 0 to MAX_MSG_LEN_C-1;
    variable msg_len_minus_bytes_captured : std_logic_vector(15 downto 0);
  begin
    -- The number of bytes in the last cycle is 
    -- (message_length - bytes_captured) mod 8.
    -- mod 8 is done by taking the bottom 3 bits.
    --msg_len_i := to_integer(unsigned(msg_len(4 downto 0))); 
    msg_len_minus_bytes_captured := std_logic_vector(to_unsigned(msg_len - bytes_captured, 
                                                         msg_len_minus_bytes_captured'length));    

    return to_integer(unsigned(msg_len_minus_bytes_captured(2 downto 0)));
  end function calc_last_byte_cnt;

--*******************************************************************************************
-- FUNCTION: calc_byte_wen
--*******************************************************************************************
    function calc_byte_wen( bytes_captured : integer range 0 to MAX_MSG_LEN_C-1
                          ) return std_logic_vector is
    variable w_enable : std_logic_vector(7 downto 0);
    variable i : integer := 0;
  begin
    i := 0;
    w_enable := (others => '0');
    while i < 8 loop 
      if(i < bytes_captured) then
        w_enable(i) := '1';
      end if;
      i := i+1;
    end loop;

    return w_enable;
  end function calc_byte_wen;

--*******************************************************************************************
-- FUNCTION: map_msg_data
--*******************************************************************************************
  function map_msg_data (byte_in_array : byte_array(0 to 7); 
                         start_index   : integer
                         ) return byte_array is
    variable i : integer := 0;
    variable byte_array_out : byte_array(0 to 7) := (others => (others => '0'));
  begin    

   while i < 8 loop 
     if(i < start_index) then
       byte_array_out(i) := byte_in_array(i);
     end if;
     i := i+1;
   end loop;

    return byte_array_out;

  end function map_msg_data;

----*******************************************************************************************
---- FUNCTION: 
----*******************************************************************************************
--  function calc_byte_wen (byte_in_array : byte_array(0 to 7); 
--                         start_index   : integer
--                         ) return std_logic_vector is
--    variable i : integer := 0;
--    variable byte_array_out : byte_array(0 to 7) := (others => (others => '0'));
--  begin    
--
--   while i < 8 loop 
--     if(i < start_index) then
--       byte_array_out(i) := byte_in_array(i);
--     end if;
--     i := i+1;
--   end loop;
--
--    return byte_array_out;
--
--  end function calc_byte_wen;

  -- Signal definitions
  --signal s_state       : sm_state := WAIT_SOP;
  signal s_state_q     : sm_state;
  signal s_nxt_state   : sm_state;  
  --signal s_nxt_state_q : sm_state; 
  signal s_nxt_state_ptr   : sm_state;  
  signal s_nxt_state_ptr_q : sm_state; 

  signal s_next_msg_type   : msg_type_t;
  signal s_next_msg_type_q : msg_type_t;

  --signal in_valid_b    : boolean := false;
  signal s_in_error_b    : boolean := false;
  signal s_in_ready_b    : boolean := false;
  signal s_in_sop_b      : boolean := false;
  signal s_in_eop_b      : boolean := false;

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

  signal s_stall_comb        : boolean := false;
  signal s_stall_comb_save   : boolean := false;
  signal s_stall_comb_save_q : boolean := false;
  

  --signals for WAIT_SOP state code hiding
  signal s_msg_len_minus_4             : std_logic_vector(15 downto 0);
  signal s_no_full_cycles_b            : boolean := false;
  signal s_msg_cnt_from_data_bus_i     : integer range 0 to MAX_MSG_CNT_C-1;
  signal s_msg_len_from_data_bus_i     : integer range 0 to MAX_MSG_LEN_C-1;
  signal s_calc_cycles_for_msg_i       : integer range 0 to MAX_NUM_CYC_C-1;
  signal s_calc_bytes_in_last_cycle_i  : integer range 0 to MAX_LAST_BYTE_CNT_C-1;

  --signals for LAST_CYCLE state code hiding
  --signal s_last_cycle_bytes             : byte_array(0 to 7);
  --signal s_last_cycle_bytes_wen_n       : std_logic_vector(7 downto 0);
  --signal s_last_cycle_out_bytes_val     : std_logic; 

  --signals for GET_DATA state code hiding
  signal s_last_full_cycle_b           : boolean := false;
  signal s_additional_data_b           : boolean := false;
  signal s_message_done_b              : boolean := false;

  --signal s_eop_b                       : boolean := false;
  signal s_start_a_new_msg_b           : boolean := false;
  signal s_get_last_bytes_b            : boolean := false;
  signal s_wait_next_sop_b             : boolean := false;

  --signals for START_NEW_MESSAGE state code hiding
  signal s_new_msg_bytes_i          : integer range 0 to MAX_MSG_LEN_C-1       := 0;
  signal s_new_msg_bytes_i_q        : integer range 0 to MAX_MSG_LEN_C-1       := 0;
  signal s_new_msg_length_i         : integer range 0 to MAX_MSG_LEN_C-1       := 0;
  signal s_new_msg_data             : byte_array(0 to 7)                       := (others => (others => '0'));
  signal s_new_msg_cycle_calc_i     : integer range 0 to MAX_NUM_CYC_C-1       := 0;
  signal s_new_msg_last_byte_cnt_i  : integer range 0 to MAX_LAST_BYTE_CNT_C-1 := 0;
  signal s_new_msg_out_bytes_wen_n  : std_logic_vector(7 downto 0)             := (others => '0');
  signal s_new_msg_mask             : std_logic_vector(31 downto 0)            := (others => '0');
  signal s_new_msg_no_full_cycles_b : boolean                                  := false;
    ----------------------------------------------------------------------------------------------------------

  begin
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
                              to_unsigned( (s_msg_len_from_data_bus_i - 4), s_msg_len_minus_4'length)); 
    
    -- Checks the message length (-4) divided by 8 (bottom 3 bits lopped off); This is the number of 8 byte bus
    -- cycles required to get the entire message. If 0, then the message is less than 8 bytes. So
    -- the next cycle will be the last cycle (i.e. no full 8 byte cycle)
    -- Only 5 bits are checked because the max message length is 32
    -- Signal is only valid in the WAIT_SOP state
    s_no_full_cycles_b <= (to_integer(unsigned(s_msg_len_minus_4(4 downto 3))) = 0);    

    -- The number of cycles required to get the entire message is calculated by dividing the message length-4
    -- (Because 4 bytes are read on the SOP cycle) by 8; the bottom 3 bits are lopped off to perform the divide by 8.
    s_calc_cycles_for_msg_i       <= to_integer(unsigned(s_msg_len_minus_4(7 downto 3))); 
    -- The number of bytes in the last cycle is calculated by taking the message length-4 mod 8
    s_calc_bytes_in_last_cycle_i  <= to_integer(unsigned(s_msg_len_minus_4(2 downto 0)));

    s_in_sop_b   <= IN_START_OF_PACKET = '1';
    s_in_eop_b   <= IN_END_OF_PACKET   = '1';
    s_in_error_b <= IN_ERROR           = '1';
   ----------------------------------------------------------------------------------------------------------
    -- GET_DATA state signals to hide code
    ----------------------------------------------------------------------------------------------------------
    s_last_full_cycle_b  <= (s_cyc_cnt_i_q = s_num_cycles_i_q); -- Last cycle with 8 bytes of data
    s_additional_data_b  <= (s_last_byte_cnt_i_q > 0);          -- Last cycle with 8 bytes of data, but <8 more bytes coming
    --s_eop_b              <= (eop_a = '1');                      -- End of packet signal
    s_start_a_new_msg_b  <= (s_last_full_cycle_b and (not s_additional_data_b) and (not s_in_eop_b));
    s_get_last_bytes_b   <= (s_last_full_cycle_b and      s_additional_data_b                      );
    s_message_done_b     <= (s_last_full_cycle_b and                                    s_in_eop_b );
    
    ----------------------------------------------------------------------------------------------------------
    -- START_NEW_MESSAGE state signals to hide code
    ----------------------------------------------------------------------------------------------------------
    
    new_msg_input_proc : process(all) 
      variable v_converted_msg_len_i : integer := 0;
      variable v_msg_len_vector      : std_logic_vector(15 downto 0);
    begin
      case s_next_msg_type_q is
        when no_length_no_data =>
          v_converted_msg_len_i      := to_integer(unsigned(IN_DATA(63 downto 48)));

          s_new_msg_length_i         <= v_converted_msg_len_i;
          s_new_msg_data             <= map_msg_data(bus_in_array, 2);
          s_new_msg_cycle_calc_i     <= remaining_cycles(v_converted_msg_len_i, 0); 
          s_new_msg_last_byte_cnt_i  <= calc_last_byte_cnt(v_converted_msg_len_i, 0);
          s_new_msg_out_bytes_wen_n  <= calc_byte_wen(s_new_msg_bytes_i_q); --x"3F"; -- 6 bytes of data
          s_new_msg_mask             <= calc_mask(v_converted_msg_len_i);
          s_new_msg_no_full_cycles_b <= is_last_cycle(v_converted_msg_len_i, 0);
        when length_with_data =>
          s_new_msg_length_i         <= s_next_message_len_i_q;
          s_new_msg_data             <= s_next_message_data_q;
          s_new_msg_cycle_calc_i     <= remaining_cycles(s_next_message_len_i_q, s_new_msg_bytes_i_q);
          s_new_msg_last_byte_cnt_i  <= calc_last_byte_cnt(s_next_message_len_i_q, s_new_msg_bytes_i_q);
          s_new_msg_out_bytes_wen_n  <= calc_byte_wen(s_new_msg_bytes_i_q);
          s_new_msg_mask             <= calc_mask(s_next_message_len_i_q);
          s_new_msg_no_full_cycles_b <= is_last_cycle(s_next_message_len_i_q, s_new_msg_bytes_i_q);
        when length_no_data =>
          s_new_msg_length_i         <= s_next_message_len_i_q;
          s_new_msg_data             <= map_msg_data(bus_in_array, 0);
          s_new_msg_cycle_calc_i     <= remaining_cycles(s_next_message_len_i_q, s_new_msg_bytes_i_q);
          s_new_msg_last_byte_cnt_i  <= calc_last_byte_cnt(s_next_message_len_i_q, s_new_msg_bytes_i_q);
          s_new_msg_out_bytes_wen_n  <= calc_byte_wen(s_new_msg_bytes_i_q);
          s_new_msg_mask             <= calc_mask(s_next_message_len_i_q);
          s_new_msg_no_full_cycles_b <= is_last_cycle(s_next_message_len_i_q, s_new_msg_bytes_i_q);
        when msb_length_only =>
          v_msg_len_vector           := std_logic_vector(to_unsigned(s_next_message_len_i_q, v_msg_len_vector'length)); 
          -- Concatenate the MSB of the message length (captured on the previous bus cycle) with the LSB of the message length
          -- Captured on the present bus cycle to get the full message length.
          -- Note: Technically this is not necessary, since the minimum message length is 32 bytes, the MSB is never needed.
          --       But for the sake of future expansion, it is included.
          v_converted_msg_len_i      := to_integer(unsigned(v_msg_len_vector(15 downto 8)) & unsigned(IN_DATA(63 downto 56)));

          s_new_msg_length_i         <= v_converted_msg_len_i;
          s_new_msg_data             <= map_msg_data(bus_in_array, s_new_msg_bytes_i_q);
          s_new_msg_cycle_calc_i     <= remaining_cycles(v_converted_msg_len_i, s_new_msg_bytes_i_q);
          s_new_msg_last_byte_cnt_i  <= calc_last_byte_cnt(v_converted_msg_len_i, s_new_msg_bytes_i_q);
          s_new_msg_out_bytes_wen_n  <= calc_byte_wen(s_new_msg_bytes_i_q);
          s_new_msg_mask             <= calc_mask(v_converted_msg_len_i);
          s_new_msg_no_full_cycles_b <= is_last_cycle(v_converted_msg_len_i, s_new_msg_bytes_i_q);
        when others =>
      end case;
    end process;
    
    -- End code hiding signals -------------------------------------------------------------------------------

    map_proc_bus_in : process(all)
    begin
      -- Map the input data bus to an array of bytes
      for i in 0 to 7 loop
        bus_in_array(i) <= IN_DATA((i+1)*8-1 downto i*8);
      end loop;
    end process map_proc_bus_in;
    --bus_in_array(0) <= IN_DATA(7 downto 0);
    --bus_in_array(1) <= IN_DATA(15 downto 8);
    --bus_in_array(2) <= IN_DATA(23 downto 16);
    --bus_in_array(3) <= IN_DATA(31 downto 24);
    --bus_in_array(4) <= IN_DATA(39 downto 32);
    --bus_in_array(5) <= IN_DATA(47 downto 40);
    --bus_in_array(6) <= IN_DATA(55 downto 48);
    --bus_in_array(7) <= IN_DATA(63 downto 56);

    --OUT_VALID          <= s_out_bytes_val_q;
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
         variable v_new_msg_index_i    : integer range 0 to MAX_MSG_LEN_C-1;

       begin
           -- Default assignments
           s_nxt_state       <= s_state_q;
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
           s_next_message_len_i <= s_next_message_len_i_q;
           s_next_message_data  <= s_next_message_data_q;
           s_stall_comb         <= false;
           s_next_msg_type      <= s_next_msg_type_q;

           case s_state_q is
              when WAIT_SOP =>
                s_msg_cnt_i <= s_msg_cnt_from_data_bus_i;
                s_msg_len_i <= s_msg_len_from_data_bus_i; 

                i := 0;
                while i < 4 loop                                
                  s_payload(i) <= bus_in_array(3-i);
                  i := i+1;
                end loop;

                s_num_cycles_i    <= s_calc_cycles_for_msg_i; 
                s_last_byte_cnt_i <= s_calc_bytes_in_last_cycle_i; 
                s_out_bytes_wen_n <= x"0F"; 
                s_out_byte_mask   <= calc_mask(s_msg_len_from_data_bus_i);                
                
                if(s_in_sop_b and (not s_in_error_b)) then                  
                  s_out_bytes_val   <= '1'; -- Output (payload) data is now valid
                  s_msg_start       <= '1'; -- Start of message  
                  s_cyc_cnt_i       <=  1 ; --Initialize cycle counter

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
                while i < 8 loop                                
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
                  
                  -- -- This (When the message ends on the last full 8 byte bus cycle) is a 
                  -- -- special case. There will be no length or data on the bus and v_new_msg_index_i 
                  -- -- will also be 6 (i.e. It could be hard coded rather than having the overhead of 
                  -- -- the procedure call).
                  -- -- The get_next_msg_data procedure is only called here to demonstrate the need
                  -- -- for the next message information whenever a new message is started.
                  -- get_next_msg_data(s_last_byte_cnt_i_q, (others=>(others =>'0')),  -- Procedure inputs
                  --                   v_next_message_len_i, v_next_message_data,  -- Procedure outputs
                  --                   v_new_msg_index_i
                  --                  );
                  -- s_next_message_len_i <= v_next_message_len_i;
                  -- s_next_message_data  <= v_next_message_data;
                  -- s_new_msg_bytes_i    <= v_new_msg_index_i;
                  s_new_msg_bytes_i    <= 6;

                  s_next_msg_type <= get_next_msg_type(s_last_byte_cnt_i_q); 
                elsif(s_get_last_bytes_b) then
                  
                  s_nxt_state     <= LAST_CYCLE; -- Last cycle with less than 8 bytes
                  s_nxt_state_ptr <= LAST_CYCLE; -- Save next pointer state in case we need to stall
                
                elsif(s_message_done_b) then
                  s_msg_done  <= '1';      -- Message is done
                  s_nxt_state <= WAIT_SOP; -- Wait for the next packet

                else

                  s_nxt_state     <= GET_DATA; -- Get the next 8 bytes of data
                  s_nxt_state_ptr <= GET_DATA;
                end if;

                if(not s_in_ready_b) then
                  s_nxt_state     <= STALL;    -- Override next state, if not ready
                                               -- The s_next_state_ptr will know where to
                                               -- go after the stall                 
                end if;                  

              when LAST_CYCLE =>
               
                s_msg_done        <= '1'; -- Message is done
                s_stall_comb_save <= false;
                v_stall_comb      := false;

                output_last_payload(s_last_byte_cnt_i_q , bus_in_array,                  -- Procedure inputs
                                    v_out_bytes_val     , v_out_bytes_wen_n , v_payload  -- Procedure outputs
                                    );
                s_out_bytes_val   <= v_out_bytes_val;
                s_out_bytes_wen_n <= v_out_bytes_wen_n;
                s_payload         <= v_payload;

                get_next_msg_data(s_last_byte_cnt_i_q, bus_in_array,          -- Procedure inputs
                                  v_next_message_len_i, v_next_message_data,  -- Procedure outputs
                                  v_new_msg_index_i
                                  );
                s_next_message_len_i <= v_next_message_len_i;
                s_next_message_data  <= v_next_message_data;
                s_new_msg_bytes_i    <= v_new_msg_index_i;

                s_next_msg_type <= get_next_msg_type(s_last_byte_cnt_i_q);

                s_nxt_state     <= WAIT_SOP when s_in_eop_b else START_NEW_MESSAGE;
                s_nxt_state_ptr <= START_NEW_MESSAGE;
                s_stall_comb    <= is_stall_required(s_last_byte_cnt_i_q);
                                                 -- Stall allows the next message data to be output
                                                 -- without losing the next cycle's data

                -- Override the next state if any of the following conditions are met                
                if(s_in_error_b) then
                  s_nxt_state <= WAIT_SOP; -- Assume entire message is bad
                elsif(not s_in_ready_b) then                  
                  s_nxt_state     <= STALL; -- Override next state, if not ready
                                            -- The s_next_state_ptr will know where to
                                            -- go after the stall 
                  s_stall_comb      <= false; -- Cancel the combinatorial stall (if set)                      
                  s_stall_comb_save <= is_stall_required(s_last_byte_cnt_i_q); -- Save the combinatorial stall           
                end if;
                
              when STALL =>    
                s_stall_comb_save <= false; -- Clear the register in case we entered from the STALL state            
                if(s_in_error_b) then
                  s_nxt_state <= WAIT_SOP; -- Assume entire message is bad
                elsif(not s_in_ready_b) then
                  s_nxt_state       <= STALL; 
                else   
                  s_nxt_state  <= s_nxt_state_ptr_q; -- Go back to designated next state, before stall 
                  s_stall_comb <= s_stall_comb_save_q;                  
                end if;
              
              when START_NEW_MESSAGE =>                
                s_msg_len_i <= s_new_msg_length_i; 

                i := 0;
                while i < 8 loop 
                  if(i <= s_new_msg_bytes_i_q) then
                    s_payload(i) <= s_new_msg_data(i);
                  end if;
                  i := i+1;
                end loop;

                s_num_cycles_i    <= s_new_msg_cycle_calc_i; 
                s_last_byte_cnt_i <= s_new_msg_last_byte_cnt_i; 
                s_out_bytes_wen_n <= s_new_msg_out_bytes_wen_n; 
                s_out_byte_mask   <= s_new_msg_mask;                
                
                if(s_in_error_b) then
                  s_nxt_state <= WAIT_SOP; -- Assume entire message is bad
                else                  
                  s_out_bytes_val   <= '1'; -- Output (payload) data is now valid
                  s_msg_start       <= '1'; -- Start of message  
                  s_cyc_cnt_i       <=  1 ; --Initialize cycle counter

                  if(s_new_msg_no_full_cycles_b) then 
                    s_nxt_state <= LAST_CYCLE; --Last cycle with less than 8 bytes
                  else
                    s_nxt_state <= GET_DATA; -- Cycle with 8 bytes of data       
                  end if;               
                end if;

              when others =>
                 s_nxt_state <= WAIT_SOP;
           end case;
       end process rcv_sm_comb;

    rcv_sm_reg : process(CLK, RESET_N)
       begin

          if RESET_N = '0' then
            s_state_q           <= WAIT_SOP;  
            s_nxt_state_ptr_q   <= WAIT_SOP;         
            s_msg_cnt_i_q       <= 0;
            s_msg_len_i_q       <= 0;
            s_payload_q         <= (others => (others => '1'));
            s_num_cycles_i_q    <= 0;
            s_last_byte_cnt_i_q <= 0; 
            s_out_byte_mask_q   <= (others => '0');
            s_out_bytes_wen_n_q <= (others => '0');
            s_out_bytes_val_q   <= '0';
            s_msg_start_q       <= '0';
            s_msg_done_q        <= '0';
            s_cyc_cnt_i_q       <= 0;
            s_next_message_len_i_q  <= 0;
            s_next_message_data_q   <= (others => (others => '0'));
            s_stall_comb_save_q     <= false;
            s_next_msg_type_q       <= dont_care;
            s_new_msg_bytes_i_q     <= 0;
          elsif rising_edge(CLK) then 
            s_state_q           <= s_nxt_state  ;  
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
            s_cyc_cnt_i_q       <= s_cyc_cnt_i;
            S_next_message_len_i_q  <= s_next_message_len_i;
            s_next_message_data_q   <= s_next_message_data;
            s_stall_comb_save_q     <= s_stall_comb_save;
            s_next_msg_type_q       <= s_next_msg_type;
            s_new_msg_bytes_i_q     <= s_new_msg_bytes_i;
          end if; 
    end process rcv_sm_reg;

end architecture behav;
