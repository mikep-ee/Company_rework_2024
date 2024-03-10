library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity message_receiver is
    port (
        CLK                : in  std_logic;
        RESET_N            : in  std_logic;
        
        IN_VALID           : in  std_logic;
        IN_START_OF_PACKET : in  std_logic;
        IN_END_OF_PACKET   : in  std_logic;
        IN_DATA            : in  std_logic_vector(63 downto 0);
        IN_EMPTY           : in  std_logic;
        IN_ERROR           : in  std_logic;
   
        IN_READY           : OUT  std_logic;
        OUT_VALID          : OUT  std_logic;
        OUT_BYTE_MASK      : OUT  std_logic_vector(31 downto 0);

        OUT_BYTES          : OUT  std_logic_vector(63 downto 0);
        OUT_BYTES_WEN_N    : OUT  std_logic_vector(7 downto 0);
        OUT_BYTES_VAL      : OUT  std_logic;
        MAX_BYTE_CNT       : OUT  std_logic_vector(2 downto 0);

        LAST_BYTE_CNT      : OUT  std_logic_vector(2 downto 0)
    );
end entity message_receiver;

architecture rtl of message_receiver is
    
begin

end architecture rtl;
