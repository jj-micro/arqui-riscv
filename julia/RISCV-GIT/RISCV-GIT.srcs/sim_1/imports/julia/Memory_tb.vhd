----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.09.2025 19:09:38
-- Design Name: 
-- Module Name: Memory_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Memory_tb is
--  Port ( );
end Memory_tb;

architecture Behavioral of Memory_tb is
component Memory 
generic(
 MEM_WIDTH: integer := 32;
 NUM_BYTES: integer := 4;
 ADDR_WIDTH: integer := 17
 );
 port(
 clk: in std_logic;
 addr_a: in std_logic_vector(ADDR_WIDTH-1 downto 0);
 wdata_a: in std_logic_vector(MEM_WIDTH -1 downto 0);
 rdata_a: out std_logic_vector(MEM_WIDTH -1 downto 0);
 we_a: in std_logic;
 be_a: in std_logic_vector(3 downto 0);

 addr_b: in std_logic_vector(ADDR_WIDTH-1 downto 0);
 wdata_b: in std_logic_vector(MEM_WIDTH-1 downto 0);
 rdata_b: out std_logic_vector(MEM_WIDTH-1 downto 0);
 we_b: in std_logic;
 be_b: in std_logic_vector(NUM_BYTES-1 downto 0)
 );
end component;

signal clk: std_logic:='0';
--signal addr_a,addr_b: std_logic_vector(17-1 downto 0);
signal addr_a,addr_b: std_logic_vector(8-1 downto 0);
signal wdata_a,wdata_b: std_logic_vector(32-1 downto 0):=(others=>'0');
signal rdata_a,rdata_b: std_logic_vector(32-1 downto 0);
signal we_a,we_b: std_logic:='0';
signal be_a,be_b: std_logic_vector(3 downto 0):="0000";

constant clk_period : time := 40ns;
begin

DUT : Memory
generic map(
    MEM_WIDTH=>32,
    NUM_BYTES=>4,
    ADDR_WIDTH=>8
)
port map(
    clk=>clk,
    addr_a=>addr_a,
    wdata_a=>wdata_a,
    rdata_a=>rdata_a,
    we_a=>we_a,
    be_a=>be_a,
    
    addr_b=>addr_b,
    wdata_b=>wdata_b,
    rdata_b=>rdata_b,
    we_b=>we_b,
    be_b=>be_b
    
    
);


clk<=not clk after clk_period/2;

stim_proc : process
begin
    wdata_a <= x"01020304";
    addr_a <= x"01";
    be_a <= "1010";
    we_a <='1';
    wait for 2*clk_period;
    we_a <='0';
    wdata_b <= x"01020304";
    addr_b <= x"05";
    be_b <= "1100";
    we_b <='1';
    wait for 2*clk_period;
    we_a <='0';
    we_b <='0';
    wait for 2*clk_period;
    --Escritura simultánea
    wdata_a <= x"05060708";
    addr_a <= x"02";
    be_a <= "1110";
    wdata_b <= x"05060708";
    addr_b <= x"06";
    be_b <= "1010";
    we_a <='1';
    we_b <='1';
    wait for 2*clk_period;
    we_a <='0';
    we_b <='0';
    wait for 2*clk_period;
    addr_a<=x"01";
    addr_b<=x"01";
    wait for 2*clk_period;
    addr_a<=x"03";
    addr_b<=x"05";
    wait for 2*clk_period;
    addr_a<=x"02";
    addr_b<=x"06";
    
    wait;
end process;
end Behavioral;
