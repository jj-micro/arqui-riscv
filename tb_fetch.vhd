library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_fetch is
end tb_fetch;

architecture sim of tb_fetch is
  -- Parámetros (deben casar con tus entidades)
  constant MEM_WIDTH  : integer := 32;
  constant NUM_BYTES  : integer := 4;
  constant ADDR_WIDTH : integer := 17;

  -- Reloj/Reset
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';

  -- Interfaz puerto A (instrucciones)
  signal addr_a  : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal rdata_a : std_logic_vector(MEM_WIDTH-1 downto 0);

  -- Interfaz puerto B (precarga)
  signal addr_b  : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others=>'0');
  signal wdata_b : std_logic_vector(MEM_WIDTH-1 downto 0) := (others=>'0');
  signal rdata_b : std_logic_vector(MEM_WIDTH-1 downto 0);
  signal we_b    : std_logic := '0';
  signal be_b    : std_logic_vector(NUM_BYTES-1 downto 0) := (others=>'0');

  -- Fetch
  signal IR        : std_logic_vector(31 downto 0);
  signal PC_bytes  : std_logic_vector(ADDR_WIDTH+1 downto 0);

  -- "Programa" de prueba (8 palabras)
  type rom_t is array (natural range <>) of std_logic_vector(31 downto 0);
  constant ROM : rom_t := (
    x"DEADBEEF", x"CAFEBABE", x"12345678", x"0BADF00D",
    x"89ABCDEF", x"0F0F0F0F", x"AAAAAAAA", x"55555555"
  );

  -- Índice para comprobación con latencia de 1 ciclo
  signal seen_count : integer := 0;        -- cuántas IR válidas hemos visto
begin
  ---------------------------------------------------------------------------
  -- Reloj: 10 ns periodo
  ---------------------------------------------------------------------------
  clk <= not clk after 5 ns;

  ---------------------------------------------------------------------------
  -- DUTs
  ---------------------------------------------------------------------------
  U_MEM: entity work.Memory
    generic map(
      MEM_WIDTH  => MEM_WIDTH,
      NUM_BYTES  => NUM_BYTES,
      ADDR_WIDTH => ADDR_WIDTH
    )
    port map(
      clk      => clk,
      -- Puerto A: instrucciones (solo lectura)
      addr_a   => addr_a,
      wdata_a  => (others=>'0'),
      rdata_a  => rdata_a,
      we_a     => '0',
      be_a     => (others=>'1'),
      -- Puerto B: datos (usado aquí para PRECARGAR la memoria)
      addr_b   => addr_b,
      wdata_b  => wdata_b,
      rdata_b  => rdata_b,
      we_b     => we_b,
      be_b     => be_b
    );

  U_FETCH: entity work.RISCV_Fetch
    generic map(
      ADDR_WIDTH => ADDR_WIDTH,
      NUM_BYTES  => NUM_BYTES
    )
    port map(
      clk       => clk,
      rst       => rst,
      mem_addr  => addr_a,     -- PC >> 2 desde dentro del Fetch
      mem_we    => open,       -- fetch no escribe
      mem_be    => open,       -- fetch no escribe
      mem_rdata => rdata_a,
      IR        => IR,
      PC_bytes  => PC_bytes
    );

  ---------------------------------------------------------------------------
  -- Estímulos: 1) Precarga por puerto B, 2) Liberar reset, 3) Dejar leer
  ---------------------------------------------------------------------------
  stim_proc : process
  begin
    -- 0) Reset activo mientras precargamos
    rst <= '1';

    -- 1) Precarga ROM por puerto B: 1 palabra por flanco
    be_b <= (others => '1');
    we_b <= '1';
    for i in 0 to ROM'length-1 loop
      addr_b  <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));  -- índice de palabra
      wdata_b <= ROM(i);
      wait until rising_edge(clk);  -- escritura síncrona
    end loop;
    we_b <= '0';
    be_b <= (others => '0');

    -- 2) Un par de ciclos con reset aún activo para seguridad
    wait until rising_edge(clk);
    wait until rising_edge(clk);

    -- 3) Liberamos reset ? el Fetch empieza en PC=0 bytes (addr_a=0) y avanza +4
    rst <= '0';

    -- 4) Dejamos correr suficientes ciclos para leer todo el ROM + margen
    for k in 0 to ROM'length+3 loop
      wait until rising_edge(clk);
    end loop;

    -- 5) Fin de simulación
    assert false report "FIN de la simulación" severity failure;
  end process;

  ---------------------------------------------------------------------------
  -- Comprobación: IR debe ir saliendo ROM(0), ROM(1), ... con +1 ciclo de latencia
  ---------------------------------------------------------------------------
  check_proc : process(clk)
    variable expected : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '0' then
        -- La primera IR válida aparece 1 ciclo después de desactivar reset.
        if seen_count < ROM'length then
          -- expected = ROM(seen_count) porque el Fetch pone addr_a=n y la memoria
          -- entrega rdata_a(n) en el siguiente ciclo, que capturamos en IR.
          expected := ROM(seen_count);

          -- Comprobamos
          assert IR = expected
            report "IR mismatch en idx=" & integer'image(seen_count)
                   & "  IR=" & to_hstring(IR)
                   & "  exp=" & to_hstring(expected)
            severity error;

          -- Mensaje informativo
          report "OK  idx=" & integer'image(seen_count)
                 & "  PC_bytes=" & to_hstring(PC_bytes)
                 & "  IR=" & to_hstring(IR);

          seen_count <= seen_count + 1;
        end if;
      end if;
    end if;
  end process;

end sim;

