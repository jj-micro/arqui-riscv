library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity RISCV_Regfile is
generic(
 REG_WIDTH: integer := 32;
 REG_ADDR: integer := 5
 );
 port(
 clk: in std_logic;
 rst: in std_logic;

 rs_1: in std_logic_vector(REG_ADDR-1 downto 0);-- direccion registro lectura 1
 op_1: out std_logic_vector(REG_WIDTH -1 downto 0);--dato registro lectura 1

 rs_2: in std_logic_vector(REG_ADDR-1 downto 0);-- direccion registro lectura 2
 op_2: out std_logic_vector(REG_WIDTH -1 downto 0);--dato registro lectura 2

 rd_1: in std_logic_vector(REG_ADDR-1 downto 0);-- direccion registro escritura 1
 value_1: in std_logic_vector(REG_WIDTH -1 downto 0);--dato registro escritura 1
 we_1: in std_logic; 

 rd_2: in std_logic_vector(REG_ADDR-1 downto 0);-- direccion registro escritura 1
 value_2: in std_logic_vector(REG_WIDTH -1 downto 0);--dato registro escritura 1
 we_2: in std_logic
 
 );
end RISCV_Regfile;

architecture behav of RISCV_Regfile is
	type reg_t is array(0 to 2**(REG_ADDR)-1) of std_logic_vector(REG_WIDTH-1 downto 0);
	signal regi: reg_t:=(others=>(others=>'0'));
begin
	process(clk,rst)
	begin
	if rst = '1' then
		regi <= (others => (others => '0'));
	elsif rising_edge(clk) then
		if we_1 = '1' AND we_2='1' then
			if rd_2 = rd_1 then
				regi(to_integer(unsigned(rd_1))) <= value_1; -- Escritura síncrona
			else
				regi(to_integer(unsigned(rd_1))) <= value_1; -- Escritura síncrona
				regi(to_integer(unsigned(rd_2))) <= value_2; -- Escritura síncrona
			end if;
		else
			if we_1 = '1' then
				regi(to_integer(unsigned(rd_1))) <= value_1; -- Escritura síncrona
			end if;
			if we_2='1' then
				regi(to_integer(unsigned(rd_2))) <= value_2; -- Escritura síncrona
			end if;
		end if;
	end if;
	end process;
	process
	begin
	if unsigned(rs_1) = to_unsigned(0, rs_2'length)  then
		op_1 <= (others=>'0');
	else
		op_1 <= regi(to_integer(unsigned(rs_1))); -- Lectura asíncrona
	end if;
	if unsigned(rs_2) = to_unsigned(0, rs_2'length) then
		op_2 <= (others => '0');
	else
		op_2 <= regi(to_integer(unsigned(rs_2))); -- Lectura asíncrona
	end if;
	end process;

end behav;