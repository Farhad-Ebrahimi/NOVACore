library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_utilities.all; 

entity nv_arbiter is
    port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        ------------------------
        -- Core <-> Arbiter
        ------------------------
        -- Instruction port
        imem_address    : in  std_logic_vector(31 downto 0);
        imem_data       : out std_logic_vector(31 downto 0);
        imem_req        : in  std_logic;
        imem_ack        : out std_logic;
        -- Data port
        dmem_address    : in  std_logic_vector(31 downto 0);
        dmem_data_in    : in  std_logic_vector(31 downto 0);
        dmem_data_out   : out std_logic_vector(31 downto 0);
        dmem_data_size  : in  std_logic_vector(1 downto 0);
        dmem_read_req   : in  std_logic;
        dmem_read_ack   : out std_logic;
        dmem_write_req  : in  std_logic;
        dmem_write_ack  : out std_logic;
        ------------------------
        -- Arbiter <-> Memory
        ------------------------
        arb_address     : out std_logic_vector(31 downto 0);
        arb_data_out    : out std_logic_vector(31 downto 0);
        arb_sel_in      : out std_logic_vector(3 downto 0);
        arb_read_req    : out std_logic;
        arb_read_ack    : in  std_logic;
        arb_write_req   : out std_logic;
        arb_write_ack   : in  std_logic;
        arb_data_in     : in  std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of nv_arbiter is

  type state_t is (IDLE, DMEM_BUSY, IMEM_BUSY);
  signal state, prev_state : state_t := IDLE;

  -- Registered outputs to memory
  signal r_arb_address   : std_logic_vector(31 downto 0);
  signal r_arb_data_out  : std_logic_vector(31 downto 0);
  signal r_arb_sel_in    : std_logic_vector(3 downto 0);
  signal r_arb_read_req  : std_logic;
  signal r_arb_write_req : std_logic;

  -- Registered acks back to core
  signal r_dmem_read_ack  : std_logic;
  signal r_dmem_write_ack : std_logic;
  signal r_imem_ack       : std_logic;

  -- Registered read data out to core
  signal r_dmem_data_out : std_logic_vector(31 downto 0);
  signal r_imem_data     : std_logic_vector(31 downto 0);

begin

  arb_address   <= r_arb_address;
  arb_data_out  <= r_arb_data_out;
  arb_sel_in    <= r_arb_sel_in;
  arb_read_req  <= r_arb_read_req;
  arb_write_req <= r_arb_write_req;

  dmem_read_ack  <= r_dmem_read_ack;
  dmem_write_ack <= r_dmem_write_ack;
  imem_ack       <= r_imem_ack;

  dmem_data_out <= r_dmem_data_out;
  imem_data     <= r_imem_data;

  control_proc: process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state      <= IDLE;
        prev_state <= IDLE;
      else
        prev_state <= state;
        case state is

          when IDLE =>
            if (dmem_write_req = '1' or dmem_read_req = '1') and is_mem_addr(dmem_address) then
              state <= DMEM_BUSY;
            elsif imem_req = '1' and is_mem_addr(imem_address) then
              state <= IMEM_BUSY;
            else
              state <= IDLE;
            end if;

          when DMEM_BUSY =>
            if prev_state = DMEM_BUSY then
              if arb_read_ack = '1' or arb_write_ack = '1' then
                 state <= DMEM_BUSY;
              elsif (dmem_write_req = '1' or dmem_read_req = '1') and is_mem_addr(dmem_address) then
                  state <= DMEM_BUSY;
              elsif imem_req = '1' and is_mem_addr(imem_address) then
                  state <= IMEM_BUSY;
              else
                  state <= IDLE;
              end if;
            end if;

          when IMEM_BUSY =>
            if prev_state = IMEM_BUSY then
              if arb_read_ack = '1' then
                if (dmem_write_req = '1' or dmem_read_req = '1') and is_mem_addr(dmem_address) then
                  state <= DMEM_BUSY;
                elsif imem_req = '1' and is_mem_addr(imem_address) then
                  state <= IMEM_BUSY;
                else
                  state <= IDLE;
                end if;
              else
                state <= IMEM_BUSY;
              end if;
            end if;

          when others =>
            state <= IDLE;

        end case;
      end if;
    end if;
  end process;

  datapath_proc: process(state, prev_state,
                        dmem_address, dmem_data_in, dmem_data_size,
                        imem_address, imem_req,
                        arb_read_ack, arb_write_ack, arb_data_in,
                        dmem_read_req, dmem_write_req)
  begin

    r_dmem_read_ack  <= '0';
    r_dmem_write_ack <= '0';
    r_imem_ack       <= '0';

    case state is

      when IDLE =>
        -- default: deassert everything
        r_arb_address   <= (others => '1');
        r_arb_data_out  <= (others => '0');
        r_arb_sel_in    <= (others => '0');
        r_arb_read_req  <= '0';
        r_arb_write_req <= '0';
    
        r_dmem_data_out <= (others => '0');
        r_imem_data     <= (others => '0');

      when DMEM_BUSY =>
        
        r_arb_address   <= dmem_address;
        r_arb_sel_in    <= wb_get_data_sel(dmem_data_size, dmem_address);
        r_arb_read_req  <= dmem_read_req;
        r_arb_write_req <= dmem_write_req;
        r_arb_data_out  <= std_logic_vector( shift_left(unsigned(dmem_data_in), get_data_shift(dmem_data_size, dmem_address)));

        if (prev_state = DMEM_BUSY) then
          if arb_read_ack = '1' and dmem_read_req = '1' then
            r_dmem_data_out <= std_logic_vector( shift_right(unsigned(arb_data_in), get_data_shift(dmem_data_size, dmem_address)));
            r_dmem_read_ack <= '1';
          elsif arb_write_ack = '1' and dmem_write_req = '1' then
            r_dmem_write_ack <= '1';
          end if;
        end if;

      when IMEM_BUSY =>
        r_arb_address   <= imem_address;
        r_arb_sel_in    <= wb_get_data_sel("00", imem_address);  -- always full‐word for instr
        r_arb_read_req  <= imem_req;
        r_arb_write_req <= '0';

        if (prev_state = IMEM_BUSY) then
          if arb_read_ack = '1' and imem_req = '1' then
            r_imem_data <= arb_data_in;
            r_imem_ack  <= '1';
          end if;
        end if;

      when others =>
        null;
    end case;
  end process;

end architecture rtl;
