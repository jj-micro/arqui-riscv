----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.09.2025 12:02:34
-- Design Name: 
-- Module Name: RISCV_Core - Behavioral
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

entity RISCV_Core is
generic(
    ADDR_WIDTH : integer := 17
  );
port(
    clk : in  std_logic;
    rst : in  std_logic;

    -- Instruction interface (para conectar con puerto A de la memoria)
    instr_addr : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    instr_rdata: in  std_logic_vector(31 downto 0);

    -- Data interface (para conectar con puerto B de la memoria)
    data_addr : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    data_wdata : out std_logic_vector(31 downto 0);
    data_rdata : in  std_logic_vector(31 downto 0);
    data_we : out std_logic;
    data_be : out std_logic_vector(3 downto 0)
  );
end RISCV_Core;

architecture Behavioral of RISCV_Core is

  -- Señales internas
signal ir        : std_logic_vector(31 downto 0);
signal ir_valid  : std_logic;

-- Puedes usar esto para stalls más adelante; por ahora siempre '1'
signal fetch_en  : std_logic := '1';

component RISCV_Fetch is
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
end component;

begin

i_fetch:RISCV_Fetch
    generic map (
      ADDR_WIDTH => ADDR_WIDTH
    )
    port map(
      clk => clk,
      rst => rst,
      instr_addr => instr_addr,
      instr_rdata => instr_rdata,
      fetch_en => fetch_en,
      ir => ir,
      ir_valid => ir_valid
    );


end Behavioral;
