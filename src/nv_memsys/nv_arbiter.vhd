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
    arb_read_req : out std_logic;
    arb_read_ack : in std_logic;
    arb_write_req : out std_logic;
    arb_write_ack : in std_logic;
    arb_data_in : in std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of nv_arbiter is

begin
      process (
    dmem_read_req, dmem_write_req, dmem_address, dmem_data_in, dmem_data_size,
    imem_req, imem_address,
    arb_data_in, arb_read_ack, arb_write_ack
  )
    variable shifted_dmem_data_in  : std_logic_vector(31 downto 0);
    variable shifted_arb_data_out  : std_logic_vector(31 downto 0);
    variable data_shift            : integer;
  begin

    -- Default assignments
    arb_address    <= (others => '1');
    arb_data_out   <= (others => '0');
    arb_sel_out    <= (others => '0');
    arb_read_req   <= '0';
    arb_write_req  <= '0';

    dmem_data_out  <= (others => '0');
    dmem_read_ack  <= '0';
    dmem_write_ack <= '0';

    imem_data      <= (others => '0');
    imem_ack       <= '0';
    arb_mout       <= '0';

    -- Prioritize DMEM if valid request and valid address
    -- if (dmem_read_req = '1' or dmem_write_req = '1') and is_mem_addr(dmem_address) then
    if (dmem_read_req = '1' or dmem_write_req = '1') then
      data_shift := get_data_shift(dmem_data_size, dmem_address);
      shifted_dmem_data_in := std_logic_vector(shift_left(unsigned(dmem_data_in), data_shift));

      arb_address    <= dmem_address;
      arb_sel_out    <= wb_get_data_sel(dmem_data_size, dmem_address);
      arb_data_out   <= shifted_dmem_data_in;
      arb_read_req   <= dmem_read_req;
      arb_write_req  <= dmem_write_req;
      
      arb_mout       <= '1';
      --dmem_data_out  <= (others => '0');

      if dmem_write_req = '1'then
        if arb_write_ack = '1' then
                dmem_write_ack <= arb_write_ack;
            end if;
      elsif dmem_read_req = '1' then 
        if arb_read_ack = '1' then
            shifted_arb_data_out := std_logic_vector(shift_right(unsigned(arb_data_in), data_shift));
            dmem_data_out  <= shifted_arb_data_out;
            dmem_read_ack  <= arb_read_ack;
       end if;
     end if;
    -- Else IMEM if valid and in memory
    -- elsif imem_req = '1' and is_mem_addr(imem_address) then
    elsif imem_req = '1' then
      data_shift := get_data_shift("00", imem_address);  -- Always word access
      arb_address    <= imem_address;
      arb_sel_out    <= wb_get_data_sel("00", imem_address);
      arb_data_out   <= (others => '0');
      arb_read_req   <= imem_req;
      arb_write_req  <= '0';

      if arb_read_ack = '1' then
        imem_data <= std_logic_vector(shift_right(unsigned(arb_data_in), data_shift));
        imem_ack  <= '1';
      end if;
    end if;

  end process;

end architecture rtl;