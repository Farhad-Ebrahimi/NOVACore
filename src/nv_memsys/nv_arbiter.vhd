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

  type state_t is (IDLE, DMEM_BUSY, IMEM_BUSY);
  signal state, prev_state : state_t := IDLE;

  -- Registered outputs to memory
  signal r_arb_address : std_logic_vector(31 downto 0);
  signal r_arb_data_out : std_logic_vector(31 downto 0);
  signal r_arb_sel_out : std_logic_vector(3 downto 0);
  signal r_arb_read_req : std_logic;
  signal r_arb_write_req : std_logic;

  -- Registered acks back to core
  signal r_dmem_read_ack : std_logic;
  signal r_dmem_write_ack : std_logic;
  signal r_imem_ack : std_logic;

  -- Registered read data out to core
  signal r_dmem_data_out : std_logic_vector(31 downto 0);
  signal r_imem_data : std_logic_vector(31 downto 0);

begin

  arb_address <= r_arb_address;
  arb_data_out <= r_arb_data_out;
  arb_sel_out <= r_arb_sel_out;
  arb_read_req <= r_arb_read_req;
  arb_write_req <= r_arb_write_req;

  dmem_read_ack <= r_dmem_read_ack;
  dmem_write_ack <= r_dmem_write_ack;
  imem_ack <= r_imem_ack;

  dmem_data_out <= r_dmem_data_out;
  imem_data <= r_imem_data;

  process(clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      state <= IDLE;
      prev_state <= IDLE;

      r_dmem_read_ack  <= '0';
      r_dmem_write_ack <= '0';
      r_imem_ack       <= '0';

      r_arb_address    <= (others => '1');
      r_arb_sel_out    <= (others => '0');
      r_arb_read_req   <= '0';
      r_arb_write_req  <= '0';
      r_arb_data_out   <= (others => '0');

      r_dmem_data_out  <= (others => '0');
      r_imem_data      <= (others => '0');

    else

      case state is
        when IDLE =>
          -- default: deassert everything
          r_dmem_read_ack  <= '0';
          r_dmem_write_ack <= '0';
          r_imem_ack       <= '0';

          r_arb_address    <= (others => '1');
          r_arb_sel_out    <= (others => '0');
          r_arb_read_req   <= '0';
          r_arb_write_req  <= '0';

          r_dmem_data_out  <= (others => '0');
          r_imem_data      <= (others => '0');

          if (dmem_write_req = '1' or dmem_read_req = '1') then
            if is_mem_addr(dmem_address) then
              state <= DMEM_BUSY;
            else
              state <= IDLE;
            end if;
          elsif imem_req = '1' then
            if is_mem_addr(imem_address) then
              state <= IMEM_BUSY;
            else
              state <= IDLE;
            end if;
          end if;

        when DMEM_BUSY =>
          
          r_arb_address   <= dmem_address;
          r_arb_sel_out    <= wb_get_data_sel(dmem_data_size, dmem_address);
          r_arb_read_req  <= dmem_read_req;
          r_arb_write_req <= dmem_write_req;
          r_arb_data_out  <= std_logic_vector(shift_left(unsigned(dmem_data_in), get_data_shift(dmem_data_size, dmem_address)));

          r_dmem_read_ack  <= '0';
          r_dmem_write_ack <= '0';

          if prev_state = DMEM_BUSY then
            if arb_read_ack = '1' and dmem_read_req = '1' then
              r_dmem_data_out <= std_logic_vector(shift_right(unsigned(arb_data_in), get_data_shift(dmem_data_size, dmem_address)));
              r_dmem_read_ack <= '1';
            elsif arb_write_ack = '1' and dmem_write_req = '1' then
              r_dmem_write_ack <= '1';
            end if;

            -- transition decision
            if (dmem_write_req = '1' or dmem_read_req = '1') then
              if is_mem_addr(dmem_address) then
                state <= DMEM_BUSY;
              else
                state <= IDLE;
              end if;
            elsif imem_req = '1' then
              if is_mem_addr(imem_address) then
                state <= IMEM_BUSY;
              else
                state <= IDLE;
              end if;
            end if;
          end if;

        when IMEM_BUSY =>
          -- drive arbiter signals
          r_arb_address   <= imem_address;
          r_arb_sel_out    <= wb_get_data_sel("00", imem_address); -- full-word fetch
          r_arb_read_req  <= imem_req;
          r_arb_write_req <= '0';

          r_imem_ack      <= '0';

          if prev_state = IMEM_BUSY then
            if arb_read_ack = '1' and imem_req = '1' then
              r_imem_data <= arb_data_in;
              r_imem_ack  <= '1';
            end if;

            -- transition decision
            if (dmem_write_req = '1' or dmem_read_req = '1') then
              if is_mem_addr(dmem_address) then
                state <= DMEM_BUSY;
              else
                state <= IDLE;
              end if;
            elsif is_mem_addr(imem_address) then
              state <= IMEM_BUSY;
            else
              state <= IDLE;
            end if;
          end if;

        when others =>
          state <= IDLE;
      end case;
    end if;
  end if;
end process;


end architecture rtl;