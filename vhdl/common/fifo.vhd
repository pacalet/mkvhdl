-- Copyright © Telecom Paris
-- Copyright © Renaud Pacalet (renaud.pacalet@telecom-paris.fr)
-- 
-- This file must be used under the terms of the CeCILL. This source
-- file is licensed as described in the file COPYING, which you should
-- have received as part of this distribution. The terms are also
-- available at:
-- https://cecill.info/licences/Licence_CeCILL_V2.1-en.html
--

--
-- FIFO. Read pointer unmodified if read while empty. Write pointer unmodified
-- and data not written if write while full.
--

library ieee;
use ieee.std_logic_1164.all;

entity fifo is
    generic(
        w: positive := 32; -- bit width
        d: positive := 32  -- depth
    );
    port( 
        aclk:    in  std_ulogic;
        aresetn: in  std_ulogic;
        write:   in  std_ulogic;
        wdata:   in  std_ulogic_vector(w - 1 downto 0);
        read:    in  std_ulogic;
        rdata:   out std_ulogic_vector(w - 1 downto 0);
        empty:   out std_ulogic;
        full:    out std_ulogic
    );
end entity fifo;

architecture rtl of fifo is

    type fifo_memory is array(0 to d - 1) of std_ulogic_vector(w - 1 downto 0);

    signal memory: fifo_memory;
    signal wrptr:  natural range 0 to d - 1; -- write pointer
    signal rdptr:  natural range 0 to d - 1; -- read pointer
    signal wbr:    boolean; -- write-pointer-behind-read-pointer flag

begin

    process(aclk)
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                wrptr <= 0;
                rdptr <= 0;
                wbr   <= false;
            else
                if read = '1' then
                    if empty = '0' then
                        if rdptr = d - 1 then
                            rdptr <= 0;
                            wbr   <= false;
                        else
                            rdptr <= rdptr + 1;
                        end if;
                    end if;
                end if;
                if write = '1' then
                    if full = '0' then
                        memory(wrptr) <= wdata;
                        if wrptr = d - 1 then
                            wrptr <= 0;
                            wbr   <= true;
                        else
                            wrptr <= wrptr + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    full  <= '1' when wrptr = rdptr and wbr else '0';
    empty <= '1' when wrptr = rdptr and (not wbr) else '0';
    rdata <= memory(rdptr);

end architecture rtl;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab textwidth=0: 
