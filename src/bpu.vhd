library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity bpu is
    generic (
        constant INDEX_WIDTH : integer := 6
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        jump_inst_id : in std_logic;
        jump_inst_ie : in std_logic;
        actual_taken : in std_logic;
        actual_target : in std_logic_vector(31 downto 0);
        pc_if : in std_logic_vector(31 downto 0);
        pc_id : in std_logic_vector(31 downto 0);
        pc_ie : in std_logic_vector(31 downto 0);

        do_flush : out std_logic;
        trg_addr_o : out std_logic_vector(31 downto 0)
    );
end bpu;

architecture Behavioral of bpu is

    type btb_valid_array is array (0 to 2 ** INDEX_WIDTH - 1) of std_logic;
    type btb_taken_array is array (0 to 2 ** INDEX_WIDTH - 1) of std_logic;
    type btb_tag_array is array (0 to 2 ** INDEX_WIDTH - 1) of std_logic_vector(31 - (INDEX_WIDTH + 2) downto 0);
    type btb_target_array is array (0 to 2 ** INDEX_WIDTH - 1) of std_logic_vector(31 downto 0);

    signal btb_valid : btb_valid_array := (others => '0');
    signal btb_taken : btb_taken_array := (others => '0');
    signal btb_tag : btb_tag_array := (others => (others => '0'));
    signal btb_target : btb_target_array := (others => (others => '0'));
    signal branch_history : std_logic;
    signal wrong_prdt : std_logic;

    signal index_if : integer range 0 to 2 ** INDEX_WIDTH - 1;
    signal index_id : integer range 0 to 2 ** INDEX_WIDTH - 1;
    signal index_ie : integer range 0 to 2 ** INDEX_WIDTH - 1;
    signal pcif_plus4 : std_logic_vector(31 downto 0);
    signal pcie_plus4 : std_logic_vector(31 downto 0);
    signal prdt_addr : std_logic_vector(31 downto 0);

    attribute ram_style : string;
    attribute ram_style of btb_valid : signal is "block";
    attribute ram_style of btb_taken : signal is "block";
    attribute ram_style of btb_tag : signal is "block";
    attribute ram_style of btb_target : signal is "block";

    shared variable next_address : std_logic_vector(31 downto 0);

begin

    wrong_prdt <= '1' when ((branch_history /= actual_taken) or
        (branch_history = actual_taken and prdt_addr /= actual_target))
        else '0';

    do_flush <= wrong_prdt;

    index_if <= to_integer(unsigned(pc_if(INDEX_WIDTH + 1  downto 2)));
    index_id <= to_integer(unsigned(pc_id(INDEX_WIDTH + 1  downto 2)));
    index_ie <= to_integer(unsigned(pc_ie(INDEX_WIDTH + 1  downto 2)));

    pcif_plus4 <= std_logic_vector(unsigned(pc_if) + 4);
    pcie_plus4 <= std_logic_vector(unsigned(pc_ie) + 4);

    BTB_update : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                for i in 0 to 2 ** INDEX_WIDTH - 1 loop
                    btb_valid(i) <= '0';
                end loop;
            else
                if jump_inst_ie = '1' and wrong_prdt = '1' then
                    if btb_valid(index_ie) = '1' and btb_tag(index_ie) = pc_ie(31 downto INDEX_WIDTH + 2) then
                        btb_taken(index_ie) <= actual_taken;
                        btb_target(index_ie) <= actual_target;
                    else
                        btb_valid(index_ie) <= '1';
                        btb_tag(index_ie) <= pc_ie(31 downto INDEX_WIDTH + 2);
                        btb_taken(index_ie) <= actual_taken;
                        btb_target(index_ie) <= actual_target;
                    end if;
                end if;
            end if;
        end if;
    end process BTB_update;

    BHT_check : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                branch_history <= '0';
            else
                branch_history <= '0';
                prdt_addr <= (others => '0');
                if jump_inst_id = '1'and wrong_prdt = '0' then
                    if btb_valid(index_id) = '1' and btb_tag(index_id) = pc_id(31 downto INDEX_WIDTH + 2) then
                        branch_history <= btb_taken(index_id);
                        prdt_addr <= btb_target(index_id);
                    end if;
                end if;
            end if;
        end if;
    end process BHT_check;

    Making_prediction : process (pc_if, pcif_plus4, btb_valid, btb_tag, btb_taken, btb_target, wrong_prdt, actual_target)
    begin
        if wrong_prdt = '1' then
            if actual_taken = '1' then
                trg_addr_o <= actual_target;
            else
                trg_addr_o <= pcie_plus4;
            end if;
        else
            if btb_valid(index_if) = '1' and btb_tag(index_if) = pc_if(31 downto INDEX_WIDTH + 2) and btb_taken(index_if) = '1' then
                trg_addr_o <= btb_target(index_if);
            else
                trg_addr_o <= pcif_plus4;
            end if;
        end if;
    end process Making_prediction;

end Behavioral;