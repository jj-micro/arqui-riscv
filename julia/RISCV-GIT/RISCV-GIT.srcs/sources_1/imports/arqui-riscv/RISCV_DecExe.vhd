library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RISCV_DecExe is
  generic(
    ADDR_WIDTH : integer := 17
  );
  Port (
    clk : in std_logic; -- clk y rst se mantienen para el Regfile
    rst : in std_logic;
    
    IR : in std_logic_vector (31 downto 0);
    -- Data interface (para conectar con puerto B de la memoria)
    data_addr : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    data_wdata : out std_logic_vector(31 downto 0);
    data_rdata : in  std_logic_vector(31 downto 0);
    data_we : out std_logic;
    data_be : out std_logic_vector(3 downto 0);
    imm_PC : out std_logic_vector(31 downto 0)
    --pc_jump_o : out std_logic;
    --pc_jump_addr_o : out std_logic_vector(31 downto 0);
    -- ... etc
  );
end RISCV_DecExe;

architecture Behavioral of RISCV_DecExe is
  -- Señales de decodificación
  signal opcode : std_logic_vector (6 downto 0);
  signal funct3 : std_logic_vector (2 downto 0);
  signal funct7 : std_logic_vector (6 downto 0);

  signal rs1 : std_logic_vector (4 downto 0);
  signal rs2 : std_logic_vector (4 downto 0);
  signal rd : std_logic_vector (4 downto 0);

  -- Constantes de Opcode
  constant R_TYPE : std_logic_vector(6 downto 0) := "0110011";
  constant I_TYPE_1 : std_logic_vector(6 downto 0) := "0010011";
  constant I_TYPE_2 : std_logic_vector(6 downto 0) := "0000011";
  constant I_TYPE_3 : std_logic_vector(6 downto 0) := "1100111";
  constant I_TYPE_4 : std_logic_vector(6 downto 0) := "1110011";
  constant S_TYPE : std_logic_vector(6 downto 0) := "0100011";
  constant B_TYPE: std_logic_vector(6 downto 0) := "1100011";
  constant U_TYPE_1 : std_logic_vector(6 downto 0) := "0110111";
  constant U_TYPE_2 : std_logic_vector(6 downto 0) := "0010111";
  constant J_TYPE : std_logic_vector(6 downto 0) := "1101111";

  -- Señales de operandos del Regfile
  signal reg_op_1 : std_logic_vector (31 downto 0);
  signal reg_op_2 : std_logic_vector (31 downto 0);

  -- --- CAMBIO: Señales separadas para los 2 puertos de escritura del Regfile ---
  -- Puerto 1 (Etapa EXE: para R-Type, I-Type-1, U-Type, J-Type)
  signal exe_reg_destino : std_logic_vector (4 downto 0); -- Reemplaza 'reg_destino' para el puerto 1
  signal exe_reg_result  : std_logic_vector (31 downto 0); -- Reemplaza 'reg_result' para el puerto 1
  signal reg_we_1        : std_logic; -- Tu señal original para el puerto 1
  
  -- Puerto 2 (Etapa WB: solo para LOAD)
  signal wb_reg_destino  : std_logic_vector (4 downto 0); -- Señal para el puerto 2
  signal wb_reg_result   : std_logic_vector (31 downto 0); -- Señal para el puerto 2
  signal reg_we_2        : std_logic; -- Tu señal original para el puerto 2

  -- Señales de la ALU
  signal alu_op_1 : std_logic_vector (31 downto 0);
  signal alu_op_2 : std_logic_vector (31 downto 0);
  signal alu_op_sel : std_logic_vector (3 downto 0);
  signal alu_result : std_logic_vector (31 downto 0);
  signal alu_eq, alu_lt, alu_ltu : std_logic;
  
  -- --- SEÑALES NECESARIAS PARA EL REGISTRO DE PIPELINE (EXE/WB) ---
  -- Entradas (combinacionales) al registro de pipeline
  signal wb_reg_destino_next : std_logic_vector(4 downto 0);
  signal wb_reg_we_next      : std_logic;
  signal wb_funct3_next      : std_logic_vector(2 downto 0);
  signal wb_addr_lsb_next    : std_logic_vector(1 downto 0);
  
  -- Salidas (síncronas) del registro de pipeline
  signal wb_funct3_reg       : std_logic_vector(2 downto 0);
  signal wb_addr_lsb_reg     : std_logic_vector(1 downto 0);

  -- Componentes
  component RISCV_Regfile is
    generic(
      REG_WIDTH: integer := 32;
      REG_ADDR: integer := 5
    );
    port(
      clk: in std_logic;
      rst: in std_logic;
      rs_1: in std_logic_vector(REG_ADDR-1 downto 0);
      op_1: out std_logic_vector(REG_WIDTH -1 downto 0);
      rs_2: in std_logic_vector(REG_ADDR-1 downto 0);
      op_2: out std_logic_vector(REG_WIDTH -1 downto 0);
      rd_1: in std_logic_vector(REG_ADDR-1 downto 0);
      value_1: in std_logic_vector(REG_WIDTH -1 downto 0);
      we_1: in std_logic; 
      rd_2: in std_logic_vector(REG_ADDR-1 downto 0);
      value_2: in std_logic_vector(REG_WIDTH -1 downto 0);
      we_2: in std_logic
    );
  end component;
  
  component RISCV_Alu is
    Port ( 
      op1 : in std_logic_vector(31 downto 0);
      op2 : in std_logic_vector(31 downto 0);
      opcode : in std_logic_vector (3 downto 0);
      result : out std_logic_vector (31 downto 0);
      eq : out std_logic;
      lt : out std_logic;
      ltu : out std_logic
    );
  end component RISCV_Alu;
  
begin

  -- Asignaciones concurrentes
  opcode <= IR (6 downto 0);
  funct3 <= IR (14 downto 12);
  funct7 <= IR (31 downto 25);

  rs1 <= IR (19 downto 15);
  rs2 <= IR (24 downto 20);
  rd  <= IR (11 downto 7); 

  -- --- CAMBIO: Instanciación de Regfile CORREGIDA ---
  i_RISCV_Regfile : RISCV_Regfile
    generic map(
      REG_WIDTH => 32,
      REG_ADDR  => 5
    )
    port map(
      clk     => clk,
      rst     => rst,
      rs_1    => rs1,
      op_1    => reg_op_1,
      rs_2    => rs2,
      op_2    => reg_op_2,
      
      -- Puerto 1 (EXE): Conectado a la lógica combinacional de EXE
      rd_1    => exe_reg_destino,
      value_1 => exe_reg_result,
      we_1    => reg_we_1,
      
      -- Puerto 2 (WB): Conectado al registro de pipeline y al MUX de WB
      rd_2    => wb_reg_destino,  -- Viene del registro de pipeline
      value_2 => wb_reg_result,   -- Viene del MUX de selección/extensión
      we_2    => reg_we_2         -- Viene del registro de pipeline
    );
    
  -- Instanciación de ALU
  i_RISCV_Alu : RISCV_Alu 
    port map(
      op1    => alu_op_1,
      op2    => alu_op_2,
      opcode => alu_op_sel,
      result => alu_result,
      eq     => alu_eq,
      lt     => alu_lt,
      ltu    => alu_ltu
    );

  -- Proceso 1: Lógica de Decodificación/Ejecución (Combinacional)
  process(all)
    -- variable para el inmediato de S-Type
    variable imm_s : signed(11 downto 0);
  begin
    
    -- Valores por defecto (evitan latches)
    reg_we_1        <= '0';
    exe_reg_destino <= (others => 'X');
    exe_reg_result  <= (others => 'X');
    alu_op_1        <= reg_op_1;
    alu_op_2        <= reg_op_2;
    alu_op_sel      <= "1111";
    
    -- Valores por defecto para la Memoria
    data_addr       <= (others => 'X');
    data_wdata      <= (others => 'X');
    data_we         <= '0';
    data_be         <= "0000";
    
    -- Valores por defecto para el Pipeline WB
    wb_reg_we_next      <= '0';
    wb_reg_destino_next <= (others => 'X');
    wb_funct3_next      <= (others => 'X');
    wb_addr_lsb_next    <= (others => 'X');
    
    case opcode is
      when R_TYPE =>
        alu_op_1        <= reg_op_1;
        alu_op_2        <= reg_op_2;
        reg_we_1        <= '1';
        exe_reg_destino <= rd;
        
        case funct3 is
          when "000" => -- ADD/SUB
            case funct7 is
              when "0000000" =>
                alu_op_sel <= "0000"; -- ADD
                exe_reg_result <= alu_result;
              when "0100000" =>
                alu_op_sel <= "0001"; -- SUB
                exe_reg_result <= alu_result;
              when others =>
                alu_op_sel <= "1111"; -- ERROR
            end case;
          when "001" => -- SLL
            alu_op_sel <= "0010";
            exe_reg_result <= alu_result;
          when "010" => -- SLT
            alu_op_sel <= "0100"; 
            if alu_lt = '1' then
              exe_reg_result <= std_logic_vector(to_unsigned(1, 32));
            else
              exe_reg_result <= (others => '0');
            end if;    
          when "011" => -- SLTU
            alu_op_sel <= "0110"; 
            if alu_ltu = '1' then
              exe_reg_result <= std_logic_vector(to_unsigned(1, 32));
            else
              exe_reg_result <= (others => '0');
            end if;    
          when "100" => -- XOR
            alu_op_sel <= "1000";
            exe_reg_result <= alu_result;
          when "101" => -- SRL/SRA
            case funct7 is
              when "0000000" =>
                alu_op_sel <= "1010"; -- SRL
                exe_reg_result <= alu_result;
              when "0100000" =>
                alu_op_sel <= "1011"; -- SRA
                exe_reg_result <= alu_result;
              when others =>
                alu_op_sel <= "1111";
            end case;
          when "110" => -- OR
            alu_op_sel <= "1100";
            exe_reg_result <= alu_result;
          when "111" => -- AND
            alu_op_sel <= "1110";
            exe_reg_result <= alu_result;
          when others =>
            alu_op_sel <= "1111";
        end case;

      when I_TYPE_1 =>
        alu_op_1        <= reg_op_1;
        alu_op_2        <= std_logic_vector(resize(signed(IR(31 downto 20)), 32));
        reg_we_1        <= '1';
        exe_reg_destino <= rd;
        
        case funct3 is
          when "000" => -- ADDI
            alu_op_sel <= "0000";
            exe_reg_result <= alu_result;
          when "001" => -- SLLI
            alu_op_sel <= "0010";
            exe_reg_result <= alu_result;
          when "010" => -- SLTI
            alu_op_sel <= "0100";
            if alu_lt = '1' then
              exe_reg_result <= std_logic_vector(to_unsigned(1, 32));
            else
              exe_reg_result <= (others => '0');
            end if;
          when "011" => -- SLTIU
            alu_op_sel <= "0110";
            if alu_ltu = '1' then
              exe_reg_result <= std_logic_vector(to_unsigned(1, 32));
            else
              exe_reg_result <= (others => '0');
            end if;
          when "100" => -- XORI
            alu_op_sel <= "1000";
            exe_reg_result <= alu_result;
          when "101" => -- SRLI/SRAI
            case funct7 is
              when "0000000" =>
                alu_op_sel <= "1010"; -- SRLI
                exe_reg_result <= alu_result;
              when "0100000" =>
                alu_op_sel <= "1011"; -- SRAI
                exe_reg_result <= alu_result;
              when others =>
                alu_op_sel <= "1111";
            end case;
          when "110" => -- ORI
            alu_op_sel <= "1100";
            exe_reg_result <= alu_result;
          when "111" => -- ANDI
            alu_op_sel <= "1110";
            exe_reg_result <= alu_result;
          when others =>
            alu_op_sel <= "1111";
        end case;
        
      when I_TYPE_2 => -- LOAD (lw, lh, lb, lbu, lhu)
        -- No escribimos en la etapa EXE
        reg_we_1 <= '0'; 
        
        -- Preparamos la escritura para la etapa WB
        wb_reg_we_next      <= '1';
        wb_reg_destino_next <= rd;     -- Pasamos el 'rd'
        wb_funct3_next      <= funct3; -- Pasamos el 'funct3'
        wb_addr_lsb_next    <= alu_result(1 downto 0); -- Pasamos los 2 LSB de la dirección
        
        -- Usamos la ALU para calcular la dirección (rs1 + imm)
        alu_op_1   <= reg_op_1;
        alu_op_2   <= std_logic_vector(resize(signed(IR(31 downto 20)), 32));
        alu_op_sel <= "0000"; -- ADD
        
        -- Enviamos la dirección calculada a la memoria
        data_addr <= alu_result(ADDR_WIDTH-1 downto 0);
        data_we   <= '0'; -- Es una LECTURA (LOAD)

        data_be   <= "0000";

      when I_TYPE_3 => -- JALR
        -- Asumiendo que PC+4 viene del Fetch en reg_op_1
        reg_we_1        <= '1';
        exe_reg_destino <= rd;
        exe_reg_result  <= reg_op_1; -- Guardar PC+4
        -- La lógica de salto (alu_result(0) <= '0', etc.) iría aquí
        -- y se enviaría al PC
        
      when I_TYPE_4 =>
        null; -- Instrucciones de sistema (ECALL, EBREAK)

      when S_TYPE => -- STORE (sw, sh, sb)
        reg_we_1 <= '0'; -- Store NUNCA escribe en Regfile
        
        -- Construir el inmediato de S-Type
        imm_s := signed(IR(31 downto 25) & IR(11 downto 7));
        
        -- Usamos la ALU para la dirección (rs1 + imm_s)
        alu_op_1   <= reg_op_1;
        alu_op_2   <= std_logic_vector(resize(imm_s, 32));
        alu_op_sel <= "0000"; -- ADD
        
        -- Enviamos señales a la memoria
        data_addr  <= alu_result(ADDR_WIDTH-1 downto 0);
        data_wdata <= reg_op_2; -- Dato a escribir (viene de rs2)
        data_we    <= '1';      -- Es un STORE
        
        -- Asignamos 'byte enable' (be)
        case funct3 is
          when "000"  => data_be <= "0001" sll to_integer(unsigned(alu_result(1 downto 0))); -- sb
          when "001"  => data_be <= "0011" sll (to_integer(unsigned(alu_result(1 downto 0)))*2); -- sh
          when "010"  => data_be <= "1111"; -- sw
          when others => data_be <= "0000";
        end case;
        
      when B_TYPE => -- BRANCH
        reg_we_1 <= '0'; -- Branch NUNCA escribe en Regfile
        
        -- La ALU compara rs1 y rs2
        alu_op_1 <= reg_op_1;
        alu_op_2 <= reg_op_2;
        
        -- Seleccionamos la operación de ALU correcta
        case funct3 is
          when "000" | "001" => alu_op_sel <= "0001"; -- BEQ, BNE (necesita SUB para flag 'eq')
          when "100" | "101" => alu_op_sel <= "0100"; -- BLT, BGE (necesita SLT para flag 'lt')
          when "110" | "111" => alu_op_sel <= "0110"; -- BLTU, BGEU (necesita SLTU para flag 'ltu')
          when others => alu_op_sel <= "1111";
        end case;
        -- La lógica de salto (if alu_eq = '1'...) iría aquí
        -- y se enviaría al PC

      when U_TYPE_1 => -- LUI
        reg_we_1        <= '1';
        exe_reg_destino <= rd;
        exe_reg_result  <= IR(31 downto 12) & x"000";
        
      when U_TYPE_2 => -- AUIPC
        -- Asumiendo que el PC actual viene en reg_op_1
        reg_we_1        <= '1';
        exe_reg_destino <= rd;
        alu_op_1        <= reg_op_1; -- PC
        alu_op_2        <= IR(31 downto 12) & x"000";
        alu_op_sel      <= "0000"; -- ADD
        exe_reg_result  <= alu_result;
        
      when J_TYPE => -- JAL
        -- Asumiendo que PC+4 viene en reg_op_1
        reg_we_1        <= '1';
        exe_reg_destino <= rd;
        exe_reg_result  <= reg_op_1; -- Guardar PC+4
        -- La lógica de salto (PC + imm_j) iría aquí
        -- y se enviaría al PC
        
      when others =>
        -- No hacer nada (mantiene valores por defecto)
        null;
        
    end case;
  end process;

  -- Proceso 2: Registro de Pipeline (EXE/WB) (Síncrono)
  -- Este process "captura" las señales de control para la etapa WB
  process (clk, rst)
  begin
    if rst = '1' then
      wb_reg_destino <= (others => '0');
      reg_we_2       <= '0';
      wb_funct3_reg  <= (others => '0');
      wb_addr_lsb_reg<= (others => '0');
    elsif rising_edge(clk) then
      wb_reg_destino <= wb_reg_destino_next;
      reg_we_2       <= wb_reg_we_next;
      wb_funct3_reg  <= wb_funct3_next;
      wb_addr_lsb_reg<= wb_addr_lsb_next;
    end if;
  end process;

  -- Proceso 3: Lógica de Write-Back (Selección y Extensión) (Combinacional)
  -- Este MUX prepara el dato final para el puerto 2 del Regfile
  process (all)
    variable data_byte : std_logic_vector(7 downto 0);
    variable data_half : std_logic_vector(15 downto 0);
  begin
    
    -- Selección de Byte/Half-Word
    case wb_addr_lsb_reg is -- Viene del registro de pipeline
      when "00" =>
        data_byte := data_rdata(7 downto 0);
        data_half := data_rdata(15 downto 0);
      when "01" =>
        data_byte := data_rdata(15 downto 8);
        data_half := data_rdata(15 downto 0); -- Alinear esto es complejo
      when "10" =>
        data_byte := data_rdata(23 downto 16);
        data_half := data_rdata(31 downto 16);
      when others => -- "11"
        data_byte := data_rdata(31 downto 24);
        data_half := data_rdata(31 downto 16); -- Alinear esto es complejo
    end case;

    -- Extensión de Signo / Cero
    case wb_funct3_reg is -- Viene del registro de pipeline
      when "000" => wb_reg_result <= std_logic_vector(resize(signed(data_byte), 32));   -- lb
      when "001" => wb_reg_result <= std_logic_vector(resize(signed(data_half), 32));  -- lh
      when "010" => wb_reg_result <= data_rdata;                                      -- lw
      when "100" => wb_reg_result <= std_logic_vector(resize(unsigned(data_byte), 32)); -- lbu
      when "101" => wb_reg_result <= std_logic_vector(resize(unsigned(data_half), 32));-- lhu
      when others => wb_reg_result <= (others => 'X');
    end case;
    
  end process;

end Behavioral;