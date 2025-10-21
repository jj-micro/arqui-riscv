library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- PC en BYTES (suma +4 cada instrucción).
-- La memoria se indexa por PALABRA: addr_a = PC >> 2  (equivalente a PC(PC_WIDTH-1 downto 2)).

entity RISCV_DecExe is
  generic(
    ADDR_WIDTH : integer := 17;      -- ancho de la dirección de la MEMORIA (índice de palabra)
    NUM_BYTES  : integer := 4        -- bytes por palabra (32b ? 4)
  );
  port(
	clk      : in  std_logic;
	rst      : in  std_logic;
   	-- Salidas al resto del core / trazas
	IR       : in std_logic_vector(31 downto 0)            -- Instruction Register

  );
end RISCV_DecExe;

architecture behav of RISCV_DecExe is

signal funct3 : std_logic_vector(5 downto 0);
signal funct7 : std_logic_vector(5 downto 0);
signal opcode : std_logic_vector(5 downto 0);

component RISCV_Regfile is
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

 rd_2: in std_logic_vector(REG_ADDR-1 downto 0);-- direccion registro escritura 2
 value_2: in std_logic_vector(REG_WIDTH -1 downto 0);--dato registro escritura 2
 we_2: in std_logic
   );
end component;

begin

process(clk,rst)
begin
if rst='0' then
	funct3<=(others=>'0');
	funct7<=(others=>'0');
	opcode<=(others=>'0');
elsif rising_edge(clk) then
	opcode<=IR(5 downto 0);
end if;
end process;
end behav;


	






















