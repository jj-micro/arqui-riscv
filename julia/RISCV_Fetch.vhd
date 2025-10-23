----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.09.2025 15:43:52
-- Design Name: 
-- Module Name: RISCV_Fetch - Behavioral
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
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RISCV_Fetch is
generic(
    ADDR_WIDTH   : integer := 17
  );
  Port (
    clk: in std_logic;
    rst: in std_logic;
    
    -- Interfaz a memoria de instrucciones (puerto A)
    instr_addr  : out std_logic_vector(ADDR_WIDTH-1 downto 0);--dirección a memoria = PC
    instr_rdata : in  std_logic_vector(31 downto 0); --salida del puerto A de la memoria
    
    fetch_en : in std_logic; --habilita avanzar el PC y capturar la instrucción
    
    -- Salida hacia DecExe 
    ir : out std_logic_vector(31 downto 0); --registro de instrucción hacia DecExe
    ir_valid : out std_logic --opcional, muy útil para saber cuándo el IR contiene algo válido
   );
end RISCV_Fetch;

architecture Behavioral of RISCV_Fetch is

signal pc_reg : std_logic_vector(31 downto 0);
signal ir_reg : std_logic_vector(31 downto 0);
signal valid_reg: std_logic;

begin

-- Registro de PC
process(clk,rst)
begin
    if rst = '1' then
        pc_reg <= (others=>'0');
    elsif rising_edge(clk) then   
        if fetch_en = '1' then
            pc_reg <= std_logic_vector(unsigned(pc_reg) + 4);  -- PC += 4
        end if;
    end if;
end process;

-- Registro de instrucción (IR) y válido
process(clk,rst)
begin
    if rst = '1' then
        ir_reg    <= (others => '0');
        valid_reg <= '0';
    elsif rising_edge(clk) then   
        if fetch_en = '1' then
            ir_reg <= instr_rdata; -- captura la instrucción devuelta este ciclo
            valid_reg <= '1';
        end if;
    end if;
end process;

ir <= ir_reg;
ir_valid <= valid_reg;

-- Dirección a memoria = PC 
instr_addr <= pc_reg(ADDR_WIDTH-1 downto 0);
end Behavioral;
