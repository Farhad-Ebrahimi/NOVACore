library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Normalize is
  generic (
    WORDLENGTH : integer := 32
  );

  port (
    sd_nr_pos_in,  sd_nr_neg_in  : in std_logic_vector(WORDLENGTH+1 downto 0);
    sd_nr_pos_out, sd_nr_neg_out : out std_logic_vector(WORDLENGTH+1 downto 0)
  );
end entity;

architecture rtl of Normalize is
begin
  process(sd_nr_pos_in, sd_nr_neg_in)
    variable input_strict_pos, input_strict_neg : std_logic_vector(WORDLENGTH+1 downto 0);
    variable pos_tmp, neg_tmp : std_logic_vector(WORDLENGTH+1 downto 0);
    variable MSD_pos, MSD_neg : std_logic;
    variable MSD1_pos, MSD1_neg : std_logic;
    variable MSD2_pos, MSD2_neg : std_logic;

  begin
    input_strict_pos := sd_nr_pos_in and not sd_nr_neg_in;
    input_strict_neg := sd_nr_neg_in and not sd_nr_pos_in;

    -- default: copy input to output
    pos_tmp(WORDLENGTH-2 downto 0) := input_strict_pos(WORDLENGTH-2 downto 0);
    neg_tmp(WORDLENGTH-2 downto 0) := input_strict_neg(WORDLENGTH-2 downto 0);

    -- extract digits
    MSD_pos   := input_strict_pos(WORDLENGTH+1);
    MSD_neg    := input_strict_neg(WORDLENGTH+1);
    MSD1_pos   := input_strict_pos(WORDLENGTH);
    MSD1_neg   := input_strict_neg(WORDLENGTH);
    MSD2_pos   := input_strict_pos(WORDLENGTH-1);
    MSD2_neg   := input_strict_neg(WORDLENGTH-1);

    -- check MSD cases
    if (MSD_pos='0' and MSD_neg='1') then  -- MINUSONE
      if (MSD1_pos='1' and MSD1_neg='0') then -- ONE
        MSD_pos  := '0'; MSD_neg  := '0'; -- ZERO
        MSD1_pos := '0'; MSD1_neg := '1'; -- MINUSONE
      elsif (MSD1_pos='0' and MSD1_neg='0' and MSD2_pos='1' and MSD2_neg='0') then
        MSD_pos  := '0'; MSD_neg  := '0'; -- ZERO
        MSD1_pos := '0'; MSD1_neg := '1'; -- MINUSONE
        MSD2_pos := '0'; MSD2_neg := '1'; -- MINUSONE
      end if;

    elsif (MSD_pos='1' and MSD_neg='0') then  -- ONE
      if (MSD1_pos='0' and MSD1_neg='1') then -- MINUSONE
        MSD_pos  := '0'; MSD_neg  := '0'; -- ZERO
        MSD1_pos := '1'; MSD1_neg := '0'; -- ONE
      elsif (MSD1_pos='0' and MSD1_neg='0' and MSD2_pos='0' and MSD2_neg='1') then
        MSD_pos  := '0'; MSD_neg  := '0'; -- ZERO
        MSD1_pos := '1'; MSD1_neg := '0'; -- ONE
        MSD2_pos := '1'; MSD2_neg := '0'; -- ONE
      end if;
    end if;

    -- write back
    pos_tmp(WORDLENGTH+1) := MSD_pos;
    neg_tmp(WORDLENGTH+1) := MSD_neg;
    pos_tmp(WORDLENGTH)   := MSD1_pos;
    neg_tmp(WORDLENGTH)   := MSD1_neg;
    pos_tmp(WORDLENGTH-1) := MSD2_pos;
    neg_tmp(WORDLENGTH-1) := MSD2_neg;

    -- drive outputs
    sd_nr_pos_out <= pos_tmp;
    sd_nr_neg_out <= neg_tmp;
  end process;
end architecture;

-- SRT Divider

library ieee;
use ieee.std_logic_1164.all;
use work.types.all;
use ieee.numeric_std.all;

entity divider is
  port (
    a_pos,     a_neg     : in std_logic_vector(33 downto 0);
    b_pos,     b_neg     : in std_logic_vector(33 downto 0);
    q_pos,     q_neg     : in std_logic_vector(33 downto 0);
    a_pos_out, a_neg_out : out std_logic_vector(33 downto 0);
    b_pos_out, b_neg_out : out std_logic_vector(33 downto 0);
    q_pos_out, q_neg_out : out std_logic_vector(33 downto 0);
    counter_in           : in std_logic_vector(5 downto 0);
    counter_out          : out std_logic_vector(5 downto 0)
  );
end entity divider;

architecture behavioral of divider is
  signal a_pos_shifted_old, a_neg_shifted_old : std_logic_vector(33 downto 0);
  signal a_pos_after_adder, a_neg_after_adder : std_logic_vector(34 downto 0);
  signal a_pos_ext,         a_neg_ext         : std_logic_vector(33 downto 0);
  signal b_pos_ext,         b_neg_ext         : std_logic_vector(33 downto 0);
  signal m_pos,             m_neg             : std_logic_vector(33 downto 0);
  signal q_pos_tmp,         q_neg_tmp         : std_logic;
begin
  -- Move to ex_stg3
  --a_pos_shifted(32) <= "00" & a_pos;
  --a_neg_shifted(32) <= "00" & a_neg;
  --b_pos_ext <= "00" & b_pos;
  --b_neg_ext <= "00" & b_neg;

  q_pos_tmp <= a_pos(33) when ((a_pos(33) or a_neg(33)) = '1') else
              a_pos(32) when ((a_pos(32) or a_neg(32)) = '1') else
              a_pos(31) when (((a_pos(31) and not a_neg(30)) or (a_neg(31) and not a_pos(30))) = '1') else
              '0';
  q_neg_tmp <= a_neg(33) when ((a_pos(33) or a_neg(33)) = '1') else
              a_neg(32) when ((a_pos(32) or a_neg(32)) = '1') else
              a_neg(31) when (((a_pos(31) and not a_neg(30)) or (a_neg(31) and not a_pos(30))) = '1') else
              '0';

  m_pos <= b_neg when q_pos_tmp = '1' else
              b_pos when q_neg_tmp = '1' else
              (others => '0');
  m_neg <= b_neg when q_neg_tmp = '1' else
              b_pos when q_pos_tmp = '1' else
              (others => '0');

  adder: entity work.ternary_adder
    generic map (
      N => 34
    )

    port map (
      a_pos => a_pos,
      a_neg => a_neg,
      b_pos => m_pos,
      b_neg => m_neg,
      cin_pos => '0',
      cin_neg => '0',
      s_pos => a_pos_after_adder,
      s_neg => a_neg_after_adder
    );

  normalize: entity work.normalize
    port map (
      sd_nr_pos_in => a_pos_after_adder(33 downto 0),
      sd_nr_neg_in => a_neg_after_adder(33 downto 0),
      sd_nr_pos_out => a_pos_ext,
      sd_nr_neg_out => a_neg_ext
    );

  a_pos_shifted_old <= a_pos_ext(32 downto 0) & '0';
  a_neg_shifted_old <= a_neg_ext(32 downto 0) & '0';

  normalize_after_shift: entity work.normalize
    port map (
      sd_nr_pos_in => a_pos_shifted_old,
      sd_nr_neg_in => a_neg_shifted_old,
      sd_nr_pos_out => a_pos_out,
      sd_nr_neg_out => a_neg_out
    );

  b_pos_out <= b_pos;
  b_neg_out <= b_neg;
  q_pos_out <= q_pos(32 downto 0) & q_pos_tmp;
  q_neg_out <= q_neg(32 downto 0) & q_neg_tmp;

  counter_out <= std_logic_vector(unsigned(counter_in) + to_unsigned(1, 6));
end architecture behavioral;
