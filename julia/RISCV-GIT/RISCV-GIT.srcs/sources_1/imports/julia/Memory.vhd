----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.09.2025 18:32:47
-- Design Name: 
-- Module Name: Memory - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating


entity Memory is
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
end Memory;

architecture behav of memory is
	type mem_t is array(0 to 2**ADDR_WIDTH-1) of std_logic_vector(MEM_WIDTH-1 downto 0);
	shared variable memi: mem_t:=(others=>(others=>'0'));
begin
process(clk)
	begin
	if rising_edge(clk) then
		rdata_a<=memi(to_integer(unsigned(addr_a)));
		if we_a='1' then
			for i in 0 to NUM_BYTES-1 loop
--			for i in NUM_BYTES-1 to 0 loop
 				if be_a(i) = '1' then
--    					memi(to_integer(unsigned(addr_a)))((i+1)*8-1 downto i*8) := wdata_a((i+1)*8-1 downto i*8);
    					memi(to_integer(unsigned(addr_a)))((MEM_WIDTH-1)-i*8 downto (MEM_WIDTH)-i*8-8) := wdata_a((MEM_WIDTH-1)-i*8 downto (MEM_WIDTH)-i*8-8);
				end if;
			end loop;
        end if;
    end if;
end process;

process(clk)
	begin
	if rising_edge(clk) then
		rdata_b<=memi(to_integer(unsigned(addr_b)));
		if we_b='1' then
			for i in 0 to NUM_BYTES-1 loop
--			for i in NUM_BYTES-1 to 0 loop
 				if be_b(i) = '1' then
--    					memi(to_integer(unsigned(addr_b)))((i+1)*8-1 downto i*8) := wdata_b((i+1)*8-1 downto i*8);
    					memi(to_integer(unsigned(addr_b)))((MEM_WIDTH-1)-i*8 downto (MEM_WIDTH)-i*8-8) := wdata_b((MEM_WIDTH-1)-i*8 downto (MEM_WIDTH)-i*8-8);
				end if;
			end loop;
		end if;
		end if;
end process;
end behav;