--Include the standard library headers
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Entity declaration
entity company_rework_2024_top is
    port(
        clk                : in std_logic;
        reset              : in std_logic;
        in_ready           : out std_logic;
        in_valid           : in std_logic;
        in_start_of_packet : in std_logic;
        in_end_of_packet   : in std_logic;
        in_data            : in std_logic_vector(63 downto 0);
        in_empty           : in std_logic_vector(2 downto 0);
        in_error           : in std_logic;
        OUT_VALID          : out std_logic;
        OUT_DATA           : out std_logic_vector(255 downto 0);
        out_byte_mask      : out std_logic_vector(31 downto 0)
    );
end company_rework_2024_top;