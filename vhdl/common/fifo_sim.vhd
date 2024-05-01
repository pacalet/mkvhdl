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
-- FIFO simulation environment
--

use std.env.all;

library ieee;
use ieee.std_logic_1164.all;

library common;
use common.rnd_pkg.all;
use common.utils_pkg.all;

entity fifo_sim is
    generic(
        w: positive := 8; -- bit width
        d: positive := 4  -- depth
    );
end entity fifo_sim;

architecture sim of fifo_sim is

    package fifo_pkg is new common.fifo_pkg generic map(T => std_ulogic_vector(w - 1 downto 0));
    use fifo_pkg.all;

    signal aclk:      std_ulogic;
    signal aresetn:   std_ulogic;

    signal write:     std_ulogic;
    signal wdata:     std_ulogic_vector(w - 1 downto 0);
    signal read:      std_ulogic;
    signal rdata:     std_ulogic_vector(w - 1 downto 0);
    signal empty:     std_ulogic;
    signal full:      std_ulogic;

    signal rdata_ref: std_ulogic_vector(w - 1 downto 0);
    signal empty_ref: std_ulogic;
    signal full_ref:  std_ulogic;
    signal check:     boolean := false;

begin

    -- FIFO
    u0: entity work.fifo(rtl)
    generic map(
        w => w,
        d => d
    )
    port map( 
        aclk    => aclk,
        aresetn => aresetn,
        write   => write,
        wdata   => wdata,
        read    => read,
        rdata   => rdata,
        empty   => empty,
        full    => full
    );

    process(aclk)
        variable f: fifo_t;
        variable ve, vf: boolean;
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                empty_ref <= '1';
                full_ref  <= '0';
                rdata_ref <= (others => '0');
                check     <= true;
            else
                ve := f.count = 0;
                vf := f.count = d;
                if read = '1' and (not ve) then
                    f.pop;
                end if;
                if write = '1' and (not vf) then
                    f.push(wdata);
                end if;
                empty_ref <= '1' when f.count = 0 else '0';
                full_ref  <= '1' when f.count = d else '0';
                rdata_ref <= f.current when f.count /= 0 else (others => 'U');
            end if;
        end if;
    end process;

    postponed process(check, rdata, rdata_ref, empty_ref)
    begin
        if check and empty_ref = '0' then
            check_ref(rdata, rdata_ref, "rdata");
        end if;
    end process;

    postponed process(check, full, full_ref)
    begin
        if check then
            check_ref(full, full_ref, "full");
        end if;
    end process;

    postponed process(check, empty, empty_ref)
    begin
        if check then
            check_ref(empty, empty_ref, "empty");
        end if;
    end process;

    process
    begin
        aclk <= '0';
        wait for 1 ns;
        aclk <= '1';
        wait for 1 ns;
    end process;

    process
        variable r: rnd_generator;
        variable v: std_ulogic_vector(w - 1 downto 0);
    begin
        aresetn <= '0';
        write   <= '0';
        wdata   <= (others => '0');
        read    <= '0';
        for i in 1 to 10 loop
            wait until rising_edge(aclk);
        end loop;
        aresetn <= '1';
        for i in 1 to 100000 loop
            if full = '0' and r.get_boolean then
                v     := r.get_std_ulogic_vector(w);
                write <= '1';
                wdata <= v;
            else
                write <= '0';
            end if;
            if empty = '0' and r.get_boolean then
                read <= '1';
            else
                read <= '0';
            end if;
            wait until rising_edge(aclk);
        end loop;
        pass;
    end process;

end architecture sim;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab textwidth=0: 
