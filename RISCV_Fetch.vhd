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
    ADDR_WIDTH : integer := 17
  );
  Port (
    clk: in std_logic;
    rst: in std_logic;
    
    -- Interfaz a memoria de instrucciones (puerto A)
    PC_out : out std_logic_vector(ADDR_WIDTH + 1 downto 0)
   );
end RISCV_Fetch;

architecture Behavioral of RISCV_Fetch is

signal pc_reg : std_logic_vector(31 downto 0);


begin

-- Registro de PC
process(clk,rst)
begin
    if rst = '1' then
        pc_reg <= (others=>'0');
    elsif rising_edge(clk) then   
        pc_reg <= std_logic_vector(unsigned(pc_reg) + 4);  -- PC += 4
    end if;
end process;


PC_out <= std_logic_vector(resize(unsigned(pc_reg), 34));
end Behavioral;