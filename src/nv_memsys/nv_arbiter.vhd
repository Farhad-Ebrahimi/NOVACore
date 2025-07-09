library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_utilities.all;

entity nv_arbiter is
  port (
    clk : in std_logic;
    reset : in std_logic;
    ------------------------
    -- Core <-> Arbiter
    ------------------------
    -- Instruction port
    imem_address : in std_logic_vector(31 downto 0);
    imem_data : out std_logic_vector(31 downto 0);
    imem_req : in std_logic;
    imem_ack : out std_logic;
    -- Data port
    dmem_address : in std_logic_vector(31 downto 0);
    dmem_data_in : in std_logic_vector(31 downto 0);
    dmem_data_out : out std_logic_vector(31 downto 0);
    dmem_data_size : in std_logic_vector(1 downto 0);
    dmem_read_req : in std_logic;
    dmem_read_ack : out std_logic;
    dmem_write_req : in std_logic;
    dmem_write_ack : out std_logic;
    ------------------------
    -- Arbiter <-> Memory
    ------------------------
    arb_mout : out std_logic;
    arb_address : out std_logic_vector(31 downto 0);
    arb_data_out : out std_logic_vector(31 downto 0);
    arb_sel_out : out std_logic_vector(3 downto 0);
    arb_data_in : in std_logic_vector(31 downto 0);
    arb_we_out : out std_logic;
    arb_ack_in : in std_logic
  );
end entity;

architecture rtl of nv_arbiter is

--signal imem_ack_r : std_logic;
--signal imem_data_r : std_logic_vector(31 downto 0);

begin

  process (
    dmem_write_req, dmem_read_req,
    dmem_address, dmem_data_size, dmem_data_in,
    imem_req, imem_address,
    arb_ack_in, arb_data_in)
    
    
    variable dmem_data_shift : integer;
    variable imem_data_shift : integer;
  
    begin
    
        -- Default assignments every cycle
        dmem_data_out <= (others => '0');
        imem_data <= (others => '0');
        dmem_read_ack <= '0';
        dmem_write_ack <= '0';
        imem_ack <= '0';
        
        arb_mout <= '0';
        arb_we_out <= '0';
        arb_address <= (others => '1');
        arb_data_out <= (others =>'0');
        arb_sel_out <= (others => '0');
        -- DMEM request has priority
        if dmem_write_req = '1' then
          dmem_data_shift := get_data_shift(dmem_data_size, dmem_address);
          arb_address <= dmem_address;
          arb_data_out <= std_logic_vector(shift_left(unsigned(dmem_data_in), dmem_data_shift));
          arb_sel_out <= wb_get_data_sel(dmem_data_size, dmem_address);
          arb_we_out <= '1';
          arb_mout <= '1';
          if arb_ack_in = '1' then
            dmem_write_ack <= '1';
          end if;
    
        elsif dmem_read_req = '1' then
          dmem_data_shift := get_data_shift(dmem_data_size, dmem_address);
          arb_address <= dmem_address;
          arb_data_out <= (others => '0');
          arb_sel_out <= wb_get_data_sel(dmem_data_size, dmem_address);
          arb_we_out <= '0';
          arb_mout <= '1';
    
          if arb_ack_in = '1' then
            dmem_data_out <= std_logic_vector(shift_right(unsigned(arb_data_in), dmem_data_shift));
            dmem_read_ack <= '1';
          end if;
    
        else
          imem_data_shift := get_data_shift("00", imem_address);
          arb_address <= imem_address;
          arb_data_out <= (others => '0');
          arb_sel_out <= wb_get_data_sel("00", imem_address);
          arb_we_out <= '0';
    
          if arb_ack_in = '1' then
            imem_data <= std_logic_vector(shift_right(unsigned(arb_data_in), imem_data_shift));
            imem_ack <= arb_ack_in;
          end if;
    
        end if;
    end process;

end architecture;