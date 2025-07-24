library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;
use work.pp_utilities.all;

entity nv_memsys is
  generic (
    RESET_ADDRESS : std_logic_vector(31 downto 0)
  );
  port (
    clk : in std_logic;
    reset : in std_logic;

    
    master_in : in std_logic;
    mem_address : in std_logic_vector(31 downto 0);
    mem_data_out : out std_logic_vector(31 downto 0); 
    mem_data_in  : in  std_logic_vector(31 downto 0);
    mem_byte_sel : in  std_logic_vector(3  downto 0);
    mem_we_in    : in std_logic;
    mem_ack_out  : out std_logic
  );
end entity nv_memsys;

architecture rtl of nv_memsys is

  -- Memory region type
  signal mem_select : std_logic_vector (3 downto 0);

  -- FSBL ROM signals
  signal fsbl_rom_adr_in : std_logic_vector(9 downto 0);
  signal fsbl_rom_dat_out : std_logic_vector(31 downto 0);
  signal fsbl_rom_cyc_in : std_logic;
  signal fsbl_rom_sel_in : std_logic_vector(3 downto 0);

  --SSBL RAM signals
  signal ssbl_ram_adr_in : std_logic_vector(10 downto 0);
  signal ssbl_ram_dat_in : std_logic_vector(31 downto 0);
  signal ssbl_ram_dat_out : std_logic_vector(31 downto 0);
  signal ssbl_ram_cyc_in : std_logic;
  signal ssbl_ram_sel_in : std_logic_vector(3 downto 0);
  signal ssbl_ram_we_in : std_logic;

  -- AEE RAM signals
--  signal aee_ram_adr_in : std_logic_vector(10 downto 0);
--  signal aee_ram_dat_in : std_logic_vector(31 downto 0);
--  signal aee_ram_dat_out : std_logic_vector(31 downto 0);
--  signal aee_ram_cyc_in : std_logic;
--  signal aee_ram_sel_in : std_logic_vector(3 downto 0);
--  signal aee_ram_we_in : std_logic;
--  signal aee_ram_rd_ack : std_logic;
--  signal aee_ram_wr_ack : std_logic;

  -- Main memory signals
  signal main_memory_adr_in : std_logic_vector(12 downto 0);
  signal main_memory_dat_in : std_logic_vector(31 downto 0);
  signal main_memory_dat_out : std_logic_vector(31 downto 0);
  signal main_memory_cyc_in : std_logic;
  signal main_memory_sel_in : std_logic_vector(3 downto 0);
  signal main_memory_we_in : std_logic;
  signal main_memory_rd_ack : std_logic;
  signal main_memory_wr_ack : std_logic;

  -- memory ack signals 

  signal read_ack : std_logic; 
  signal write_ack : std_logic;
  signal read_ack_pending : std_logic;
  signal write_ack_pending : std_logic;
  signal prev_master : std_logic;

begin
    
    mem_ack_out <= write_ack when mem_we_in = '1' and (prev_master = master_in) else 
                    read_ack when mem_we_in = '0' and (prev_master = master_in) else '0'; 

  fsbl_rom_inst : entity work.fsbl_rom_wrapper
    generic map(MEMORY_SIZE => 1024)
    port map(
      clk => clk,
      reset => reset,
      fsbl_adr_in => fsbl_rom_adr_in,
      fsbl_dat_out => fsbl_rom_dat_out,
      fsbl_cyc_in => fsbl_rom_cyc_in,
      fsbl_req => mem_we_in,
      fsbl_sel_in => fsbl_rom_sel_in
    );
  fsbl_rom_sel_in <= mem_byte_sel;
  fsbl_rom_adr_in <= mem_address(fsbl_rom_adr_in'range);
  fsbl_rom_cyc_in <= mem_select(0);

  ssbl_sram_inst : entity work.ssbl_ram_wrapper
    port map(
      clk => clk,
      rst => reset,
      addr => ssbl_ram_adr_in,
      din => ssbl_ram_dat_in,
      dout => ssbl_ram_dat_out,
      csb => ssbl_ram_cyc_in,
      wmask => ssbl_ram_sel_in,
      web => ssbl_ram_we_in
    );
  ssbl_ram_adr_in <= mem_address(ssbl_ram_adr_in'range);
  ssbl_ram_dat_in <= mem_data_in;
  ssbl_ram_we_in  <= mem_we_in;
  ssbl_ram_sel_in <= mem_byte_sel;
  ssbl_ram_cyc_in <= mem_select(1);

--  aee_ram_inst : entity work.aee_ram_wrapper
--    port map(
--      clk => clk,
--      rst => reset,
--      addr => aee_ram_adr_in,
--      din => aee_ram_dat_in,
--      dout => aee_ram_dat_out,
--      csb => aee_ram_cyc_in,
--      wmask => aee_ram_sel_in,
--      web => aee_ram_we_in
--    );
--  aee_ram_adr_in <= mem_address(aee_ram_adr_in'range);
--  aee_ram_dat_in <= mem_data_in;
--  aee_ram_we_in  <= mem_we_in ;
--  aee_ram_sel_in <= mem_byte_sel;
--  aee_ram_cyc_in <= mem_select(2);

  main_memory_inst : entity work.main_memory_wrapper
    port map(
      clk => clk,
      rst => reset,
      addr => main_memory_adr_in,
      din => main_memory_dat_in,
      dout => main_memory_dat_out,
      csb => main_memory_cyc_in,
      wmask => main_memory_sel_in,
      web => main_memory_we_in
    );
  main_memory_adr_in <= mem_address(main_memory_adr_in'range);
  main_memory_dat_in <= mem_data_in;
  main_memory_we_in  <= mem_we_in;
  main_memory_sel_in <= mem_byte_sel;
  main_memory_cyc_in <= mem_select(3);

  memory_select : process (mem_address)
  begin
    mem_select <= std_logic_vector(to_unsigned(get_selected_memory(mem_address), 4));
  end process;
  memory_controller : process (
    mem_select, mem_we_in, read_ack,
    fsbl_rom_dat_out, ssbl_ram_dat_out,
    main_memory_dat_out -- aee_ram_dat_out
    )
  begin
    mem_data_out <= (others => '0');
    if mem_we_in = '0' and read_ack = '1' then
      case mem_select is
        when x"1" => mem_data_out <= fsbl_rom_dat_out;
        when x"2" => mem_data_out <= ssbl_ram_dat_out;
        --when x"4" => mem_data_out <= aee_ram_dat_out;
        when x"8" => mem_data_out <= main_memory_dat_out;
        when others => null;
      end case;
    end if;
  end process;

  ack_proc : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        read_ack <= '0';
        write_ack <= '0';
        read_ack_pending <= '0';
        write_ack_pending <= '0';
        prev_master <= '0';
      else
        -- Default values
        read_ack <= '0';
        write_ack <= '0';
        prev_master <= master_in;
        case mem_select is
          when x"1" => -- FSBL ROM (read-only)
            write_ack_pending <= '0'; -- Not writable
            if mem_we_in = '0' then
              if read_ack_pending = '0' then
                read_ack <= '1';
                read_ack_pending <= '1';
              else
                read_ack_pending <= '0';
              end if;
            else
              read_ack_pending <= '0';
            end if;

          when x"2" | x"8" => -- Writable regions
            if mem_we_in = '0' then
              write_ack_pending <= '0';
              if read_ack_pending = '0' then
                read_ack <= '1';
                read_ack_pending <= '1';
              else
                read_ack_pending <= '0';
              end if;
            elsif mem_we_in = '1' then
              read_ack_pending <= '0';
              if write_ack_pending = '0' then
                write_ack <= '1';
                write_ack_pending <= '1';
              else
                write_ack_pending <= '0';
              end if;
            end if;

          when others =>
            write_ack_pending <= '0';
            read_ack_pending <= '0';
        end case;
      end if;
    end if;
  end process;

end architecture rtl;