library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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
   
        IN_READY           : OUT  std_logic;
        OUT_VALID          : OUT  std_logic;
        OUT_BYTE_MASK      : OUT  std_logic_vector(31 downto 0);

        OUT_BYTES          : OUT  byte_array(0 to 7);
        OUT_BYTES_WEN_N    : OUT  std_logic_vector(7 downto 0);
        OUT_BYTES_VAL      : OUT  std_logic;
        MAX_BYTE_CNT       : OUT  std_logic_vector(2 downto 0);
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

  -- Alias definitions
  alias sop_a : std_logic is IN_START_OF_PACKET;
  alias eop_a : std_logic is IN_END_OF_PACKET;

  -- Signal definitions
  signal s_state       : sm_state := WAIT_SOP;
  signal s_state_q     : sm_state;
  signal s_nxt_state   : sm_state;  
  signal s_nxt_state_q : sm_state; 

  signal s_msg_cnt   : std_logic_vector(15 downto 0);   
  signal s_msg_cnt_q : std_logic_vector(15 downto 0);
  signal s_msg_len   : std_logic_vector(15 downto 0);
  signal s_msg_len_q : std_logic_vector(15 downto 0);
  signal s_payload   : byte_array(0 to 7);
  signal s_payload_q : byte_array(0 to 7);

  signal s_out_bytes_wen_n   : std_logic_vector(7 downto 0);
  signal s_out_bytes_wen_n_q : std_logic_vector(7 downto 0);
  signal s_out_bytes_val     : std_logic;
  signal s_out_bytes_val_q   : std_logic;
  signal s_msg_start         : std_logic;
  signal s_msg_start_q       : std_logic;

  signal s_num_cycles      : std_logic_vector(15 downto 0);
  signal s_num_cycles_q    : std_logic_vector(15 downto 0);
  signal s_last_byte_cnt   : std_logic_vector(2 downto 0);
  signal s_last_byte_cnt_q : std_logic_vector(2 downto 0);

  signal bus_in_array : byte_array(0 to 7);
     
begin

    map_inbus : process(all)
         variable i : integer := 0;
       begin
          while i < 7 loop
            bus_in_array(i) <= IN_DATA(63-(8*i) downto 56-(8*i));
            i := i + 1;
          end loop;
       end process map_inbus;

    rcv_sm_comb : process(all)
         variable i : integer := 0;
       begin
           -- Default assignments
           s_state           <= WAIT_SOP;
           s_payload         <= s_payload_q;
           s_msg_cnt         <= s_msg_cnt_q;
           s_msg_len         <= s_msg_len_q;
           s_num_cycles      <= s_num_cycles_q;
           s_last_byte_cnt   <= s_last_byte_cnt_q;
           s_out_bytes_wen_n <= (others => '0');
           s_out_bytes_val   <= '0';
           s_msg_start       <= '0';

           case s_state is
              when WAIT_SOP =>
                s_msg_cnt <= IN_DATA(63 downto 48);
                s_msg_len <= IN_DATA(47 downto 32);

                i := 0;
                while i < 3 loop
                 -- Pick up here; decide on how to preset the payload data, 0 to 7, or 7 downto 0                  
                  s_payload(i) <= bus_in_array(3-i);
                  i := i+1;
                end loop;
                s_num_cycles      <= s_msg_len(15 downto 3) & "000"; --divide by 8
                s_last_byte_cnt   <= s_msg_len(2 downto 0); -- mod 8   
                s_out_bytes_wen_n <= x"0F";
                
                if(sop_a = '1') then                  
                  s_out_bytes_val   <= '1';
                  s_msg_start       <= '1';    
                  s_nxt_state       <= GET_DATA;           
                else
                  s_nxt_state       <= WAIT_SOP;
                end if;

              when GET_DATA => 

              when LAST_CYCLE =>

              when STALL =>

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
            s_payload_q         <= (others => (others => '0'));
            s_msg_cnt_q         <= (others => '0');
            s_msg_len_q         <= (others => '0');
            s_payload_q         <= (others => (others => '0'));
            s_num_cycles_q      <= (others => '0');
            s_last_byte_cnt_q   <= (others => '0'); 
            s_out_bytes_wen_n_q <= (others => '0');
            s_out_bytes_val_q   <= '0';
            s_msg_start_q       <= '0';
          elsif rising_edge(CLK) then 
            s_state_q           <= s_state  ;
            s_payload_q         <= s_payload;
            s_msg_cnt_q         <= s_msg_cnt;
            s_msg_len_q         <= s_msg_len;
            s_payload_q         <= s_payload;
            s_num_cycles_q      <= s_num_cycles;
            s_last_byte_cnt_q   <= s_last_byte_cnt;
            s_out_bytes_wen_n_q <= s_out_bytes_wen_n;
            s_out_bytes_val_q   <= s_out_bytes_val;
            s_msg_start_q       <= s_msg_start;
          end if; 
    end process rcv_sm_reg;

end architecture behav;
