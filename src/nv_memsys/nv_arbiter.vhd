library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_utilities.all;

entity nv_arbiter is
    port (
        clk : in std_logic;
        reset : in std_logic;
        
        -- Instruction memory interface
        imem_address : in std_logic_vector(31 downto 0);
        imem_data : out std_logic_vector(31 downto 0);
        imem_req : in std_logic;
        imem_ack : out std_logic;

        -- Data memory interface
        dmem_address : in std_logic_vector(31 downto 0);
        dmem_data_in : in std_logic_vector(31 downto 0);
        dmem_data_out : out std_logic_vector(31 downto 0);
        dmem_data_size : in std_logic_vector(1 downto 0);
        dmem_read_req : in std_logic;
        dmem_read_ack : out std_logic;
        dmem_write_req : in std_logic;
        dmem_write_ack : out std_logic;
        
        -- Memory controller interface
        mem_address : out std_logic_vector(31 downto 0);
        mem_data_in : out std_logic_vector(31 downto 0);
        mem_data_out : in std_logic_vector(31 downto 0);
        mem_sel_in  : out std_logic_vector(3 downto 0);
        mem_read_req : out std_logic;
        mem_read_ack : in std_logic;
        mem_write_req : out std_logic;
        mem_write_ack : in std_logic
    );
end entity nv_arbiter;

architecture rtl of nv_arbiter is
    type arb_state_t is (IDLE, M1_BUSY, M2_BUSY);
    signal state, prev_state : arb_state_t := IDLE;

    signal r_mem_address : std_logic_vector(31 downto 0) := (others => '0');
    signal r_mem_data_in : std_logic_vector(31 downto 0) := (others => '0');
    signal r_mem_data_size : std_logic_vector(3 downto 0) := (others => '0');
    signal r_mem_read_req : std_logic := '0';
    signal r_mem_write_req : std_logic := '0';

    signal r_dmem_data_out : std_logic_vector(31 downto 0) := (others => '0');
    signal r_imem_data : std_logic_vector(31 downto 0) := (others => '0');

    signal r_dmem_read_ack : std_logic := '0';
    signal r_dmem_write_ack : std_logic := '0';
    signal r_imem_ack : std_logic := '0';

begin

    mem_address <= r_mem_address;
    mem_data_in <= r_mem_data_in;
    mem_sel_in <= r_mem_data_size;
    mem_read_req <= r_mem_read_req;
    mem_write_req <= r_mem_write_req;

    dmem_data_out <= r_dmem_data_out;
    dmem_read_ack <= r_dmem_read_ack;
    dmem_write_ack <= r_dmem_write_ack;
    imem_data <= r_imem_data;
    imem_ack <= r_imem_ack and (not dmem_read_req) and (not dmem_write_req);

    control_proc : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= IDLE;
                prev_state <= IDLE;
            else
                prev_state <= state;

                case state is
                    when IDLE =>
                        if (dmem_write_req = '1' or dmem_read_req = '1') and is_mem_addr(dmem_address) then
                            state <= M1_BUSY;
                        elsif is_mem_addr(imem_address) then 
                            state <= M2_BUSY;
                        else
                            state <= IDLE;
                        end if;

                    when M1_BUSY =>
                           if (r_dmem_read_ack = '1' or r_dmem_write_ack = '1') then
                                state <= M1_BUSY;
                           elsif (dmem_write_req = '1' or dmem_read_req = '1') and is_mem_addr(dmem_address) then
                                state <= M1_BUSY;
                           else
                                state <= M2_BUSY;
                           end if;

                    when M2_BUSY =>
                       if (dmem_write_req = '1' or dmem_read_req = '1') and is_mem_addr(dmem_address) then
                            state <= M1_BUSY;
                       end if;

                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

    datapath_proc : process (
    state, prev_state, dmem_address, dmem_data_in, dmem_data_size,
    imem_address, mem_data_out, mem_read_ack, mem_write_ack,
    dmem_read_req, dmem_write_req, imem_req
)
    begin

        r_dmem_read_ack <= '0';
        r_dmem_write_ack <= '0';
        r_imem_ack <= '0';

        case state is
            when IDLE =>
		    
		       r_mem_address <= r_mem_address;
        	   r_mem_data_in <= (others => '0');
        	   r_mem_data_size <= (others => '0');
        	   r_mem_read_req <= '0';
        	   r_mem_write_req <= '0';

        	   r_dmem_data_out <= (others => '0');
        	   r_imem_data <= (others => '0');
            
            when M1_BUSY =>
        
               r_mem_address   <= dmem_address;
               r_mem_data_in   <= dmem_data_in;
               r_mem_data_size <= wb_get_data_sel(dmem_data_size, dmem_address);
               r_mem_read_req  <= dmem_read_req;
               r_mem_write_req <= dmem_write_req;

               if prev_state = M1_BUSY then
                 if mem_read_ack = '1' then
                   r_dmem_data_out  <= std_logic_vector(shift_right(unsigned(mem_data_out),get_data_shift(dmem_data_size, dmem_address)));
                   r_dmem_read_ack  <= '1';
                 end if;
                 if mem_write_ack = '1' then
                   r_dmem_write_ack <= '1';
                 end if;
               end if;

           when M2_BUSY =>
       
               r_mem_address   <= imem_address;
               r_mem_data_size <= wb_get_data_sel("00", imem_address);
               r_mem_read_req  <= imem_req;
               r_mem_write_req <= '0';

               if prev_state = M2_BUSY and mem_read_ack = '1' then
                 r_imem_data <= mem_data_out;
                 r_imem_ack  <= '1';
               end if;

          when others =>
               -- 
          end case;
    end process;

end architecture rtl;