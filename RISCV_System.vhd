----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.09.2025 15:42:32
-- Design Name: 
-- Module Name: RISCV_System - Behavioral
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

entity RISCV_System is
    Port ( 
        clk : in std_logic;
        rst : in std_logic
    );
end RISCV_System;

architecture Behavioral of RISCV_System is

signal instr_addr : std_logic_vector(16 downto 0);
signal instr_rdata : std_logic_vector(31 downto 0);
signal data_addr : std_logic_vector(16 downto 0);
signal data_wdata : std_logic_vector(31 downto 0);
signal data_rdata : std_logic_vector(31 downto 0);
signal data_we : std_logic;
signal data_be : std_logic_vector(3 downto 0); 

component Memory is
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

component RISCV_Core is
    port(
        clk : in  std_logic;
        rst : in  std_logic;
        
        -- Instruction interface (para conectar con puerto A de la memoria)
        instr_addr : out std_logic_vector(16 downto 0);
        instr_rdata : in  std_logic_vector(31 downto 0);
        
        -- Data interface (para conectar con puerto B de la memoria)
        data_addr : out std_logic_vector(16 downto 0);
        data_wdata : out std_logic_vector(31 downto 0);
        data_rdata : in std_logic_vector(31 downto 0);
        data_we : out std_logic;
        data_be : out std_logic_vector(3 downto 0)
    );
end component;
 
begin

i_Memory : Memory
    generic map(
        MEM_WIDTH=>32,
        NUM_BYTES=>4,
        ADDR_WIDTH=>17
    )
    port map(
        clk=>clk,
        addr_a=>instr_addr,
        wdata_a=>(others => '0'),--Considerando que el banco de instrcciones no se modifica
        rdata_a=>instr_rdata,
        we_a=>'0',
        be_a=>(others => '0'),
        
        addr_b=>data_addr,
        wdata_b=>data_wdata,
        rdata_b=>data_rdata,
        we_b=>data_we,
        be_b=>data_be   
    );

i_Core: RISCV_Core
    port map(
        clk => clk,
        rst => rst,
        instr_addr => instr_addr,
        instr_rdata=> instr_rdata,
        data_addr => data_addr,
        data_wdata => data_wdata,
        data_rdata => data_rdata,
        data_we => data_we,
        data_be => data_be
    );
end Behavioral;