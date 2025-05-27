library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;
use work.pp_utilities.all;

entity nv_memsys is
	generic (
		RESET_ADDRESS : STD_LOGIC_VECTOR(31 downto 0)
	);
    port (
        clk : in std_logic;
        reset : in std_logic;
        
        -- Instruction memory signals
        imem_address : in std_logic_vector(31 downto 0);
        imem_data : out std_logic_vector(31 downto 0);
        imem_req : in std_logic;
        imem_ack : out std_logic;
        
        -- Data memory signals
        dmem_address : in std_logic_vector(31 downto 0);
        dmem_data_in : in std_logic_vector(31 downto 0);
        dmem_data_out : out std_logic_vector(31 downto 0);
        dmem_data_size : in std_logic_vector(1 downto 0);
        dmem_read_req : in std_logic;
        dmem_read_ack : out std_logic;
        dmem_write_req : in std_logic;
        dmem_write_ack : out std_logic
    );
end entity nv_memsys;

architecture rtl of nv_memsys is

    -- Memory region type
    signal selected_memory : memory_region_t := NON_MEM;

    -- Memory interface signals
    signal mem_address : std_logic_vector(31 downto 0);
    signal mem_data_in : std_logic_vector(31 downto 0);
    signal mem_data_out : std_logic_vector(31 downto 0);
    signal mem_sel_in  : std_logic_vector(3 downto 0);
    signal mem_read_req : std_logic;
    signal mem_read_ack : std_logic;
    signal mem_write_req : std_logic;
    signal mem_write_ack : std_logic;

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
     signal aee_ram_adr_in : std_logic_vector(10 downto 0);
     signal aee_ram_dat_in : std_logic_vector(31 downto 0);
     signal aee_ram_dat_out : std_logic_vector(31 downto 0);
     signal aee_ram_cyc_in : std_logic;
     signal aee_ram_sel_in : std_logic_vector(3 downto 0);
     signal aee_ram_we_in : std_logic;
     signal aee_ram_rd_ack : std_logic;
     signal aee_ram_wr_ack : std_logic;   
     
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
    signal read_ack_pending : std_logic;
    signal write_ack_pending : std_logic;
    signal mem_read_ack_pending : std_logic;

begin
    
    -- Arbiter
    arbiter_inst : entity work.nv_arbiter
        port map(
            clk => clk,
            reset => reset,
            -- Core <-> Arbiter
            imem_address => imem_address,
            imem_data => imem_data,
            imem_req => imem_req,
            imem_ack => imem_ack,
            dmem_address => dmem_address,
            dmem_data_in => dmem_data_in,       
            dmem_data_out => dmem_data_out,
            dmem_data_size => dmem_data_size,
            dmem_read_req => dmem_read_req,
            dmem_read_ack => dmem_read_ack,
            dmem_write_req => dmem_write_req,
            dmem_write_ack => dmem_write_ack,
            -- Arbiter <-> Memory
            arb_address => mem_address,
            arb_data_in => mem_data_out,
            arb_data_out => mem_data_in,
            arb_sel_out => mem_sel_in,
            arb_read_req => mem_read_req,
            arb_read_ack => mem_read_ack,
            arb_write_req => mem_write_req,
            arb_write_ack => mem_write_ack
        );

    fsbl_rom_inst : entity work.fsbl_rom_wrapper
        generic map(MEMORY_SIZE => 1024)
        port map(
            clk => clk,
            reset => reset,
            fsbl_adr_in => fsbl_rom_adr_in,
            fsbl_dat_out => fsbl_rom_dat_out,
            fsbl_cyc_in => fsbl_rom_cyc_in,
            fsbl_req => mem_read_req,
            fsbl_sel_in => fsbl_rom_sel_in
        );
    fsbl_rom_sel_in <= mem_sel_in;
    fsbl_rom_adr_in <= mem_address(fsbl_rom_adr_in'range);
    fsbl_rom_cyc_in <= '1' when selected_memory = FSBL_ROM else '0';

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
     ssbl_ram_we_in <= '1' when mem_write_req = '1' else '0';
     ssbl_ram_sel_in <= mem_sel_in;
     ssbl_ram_cyc_in <= '1' when selected_memory = SSBL_SRAM else '0';   

     aee_ram_inst : entity work.aee_ram_wrapper
         port map(
             clk => clk,
             rst => reset,
             addr => aee_ram_adr_in,
             din => aee_ram_dat_in,
             dout => aee_ram_dat_out,
             csb => aee_ram_cyc_in,
             wmask => aee_ram_sel_in,
             web => aee_ram_we_in
         );   
     aee_ram_adr_in <= mem_address(aee_ram_adr_in'range);
     aee_ram_dat_in <= mem_data_in;
     aee_ram_we_in <= '1' when mem_write_req = '1' else '0';
     aee_ram_sel_in <= mem_sel_in;
     aee_ram_cyc_in <= '1' when selected_memory = AEE_SRAM else '0';   

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
     main_memory_we_in <= '1' when mem_write_req = '1' else '0';
     main_memory_sel_in <= mem_sel_in;
     main_memory_cyc_in <= '1' when selected_memory = MAIN_MEM else '0';
     
    addr_decode_proc : process(dmem_read_req, dmem_write_req, dmem_address, imem_req, imem_address)
    begin
        if (dmem_read_req = '1' or dmem_write_req = '1') then
            selected_memory <= get_selected_memory(dmem_address);
        elsif imem_req = '1' then
            selected_memory <= get_selected_memory(imem_address);
        else
            selected_memory <= NON_MEM;
        end if;
    end process;

    
    memory_controller : process (
    selected_memory, mem_read_req, 
    fsbl_rom_dat_out, ssbl_ram_dat_out,
    aee_ram_dat_out, main_memory_dat_out
    )
    begin 
        if mem_read_req = '1' then
            case selected_memory is
                when FSBL_ROM   => mem_data_out <= fsbl_rom_dat_out;
                when SSBL_SRAM  => mem_data_out <= ssbl_ram_dat_out;
                when AEE_SRAM   => mem_data_out <= aee_ram_dat_out;
                when MAIN_MEM   => mem_data_out <= main_memory_dat_out;
                when others     => null;
            end case;
        end if;
    end process;
    
    
    
    ack_proc:process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mem_read_ack <= '0';
                mem_write_ack <= '0';
                read_ack_pending <= '0';
                write_ack_pending <= '0';
            else      
                mem_read_ack <= '0';
                mem_write_ack <= '0';
                case selected_memory is
                    when MAIN_MEM | SSBL_SRAM | AEE_SRAM | FSBL_ROM =>
                         if mem_write_req = '1' and write_ack_pending = '0' then
                            mem_write_ack <= '1';
                            write_ack_pending <= '1';
                         elsif mem_read_req = '1' and read_ack_pending = '0' then
                            mem_read_ack <= '1';
                            read_ack_pending <= '1';
                         else
                             read_ack_pending <= '0';
                             write_ack_pending <= '0';
                         end if;
                     when others =>
                            write_ack_pending <= '0';
                            read_ack_pending <= '0';
                end case;        
            end if;
        end if;
    end process;
    
end architecture rtl;