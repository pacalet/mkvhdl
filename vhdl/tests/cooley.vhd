-- Copyright © Telecom Paris
-- Copyright © Renaud Pacalet (renaud.pacalet@telecom-paris.fr)
-- 
-- This file must be used under the terms of the CeCILL. This source
-- file is licensed as described in the file COPYING, which you should
-- have received as part of this distribution. The terms are also
-- available at:
-- https://cecill.info/licences/Licence_CeCILL_V2.1-en.html
--

library ieee;
use ieee.numeric_bit_unsigned.all;

entity cooley is
  port(
        clock: in  bit;
        up:    in  bit;
        down:  in  bit;
        di:    in  bit_vector(8 downto 0);
        co:    out bit;
        bo:    out bit;
        po:    out bit;
        do:    out bit_vector(8 downto 0)
      );
end entity cooley;

architecture rtl of cooley is
begin
  process(clock)
    variable ndo: bit_vector(9 downto 0);
  begin
    if rising_edge(clock) then
      ndo := '0' & do;
      co   <= '0';
      bo   <= '0';
      if up = '0' and down = '0' then
        ndo := '0' & di;
      elsif up = '1' and down = '0' then
        ndo := ndo + 3;
        co   <= ndo(9);
      elsif up = '0' and down = '1' then
        ndo := ndo - 5;
        bo   <= ndo(9);
      end if;
      po <= xnor ndo(8 downto 0);
      do <= ndo(8 downto 0);
    end if;
  end process;
end architecture rtl;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab textwidth=0:
