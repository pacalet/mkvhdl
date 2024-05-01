-- Copyright © Telecom Paris
-- Copyright © Renaud Pacalet (renaud.pacalet@telecom-paris.fr)
-- 
-- This file must be used under the terms of the CeCILL. This source
-- file is licensed as described in the file COPYING, which you should
-- have received as part of this distribution. The terms are also
-- available at:
-- https://cecill.info/licences/Licence_CeCILL_V2.1-en.html

-- simulation environment for axi_memory

use std.textio.all;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.axi_pkg.all;
use work.utils_pkg.all;

entity axi_memory_sim is
end entity axi_memory_sim;

architecture sim of axi_memory_sim is

    constant na: positive := 20;
    constant nb: positive := 3;
    constant fin: string := "axi_memory_in.txt";
    constant fout: string := "axi_memory_out.txt";

    signal aclk:           std_ulogic;
    signal aresetn:        std_ulogic;
    signal dump:           std_ulogic;
    signal s0_axi_araddr:  std_ulogic_vector(na - 1 downto 0);
    signal s0_axi_arvalid: std_ulogic;
    signal s0_axi_arready: std_ulogic;
    signal s0_axi_awaddr:  std_ulogic_vector(na - 1 downto 0);
    signal s0_axi_awvalid: std_ulogic;
    signal s0_axi_awready: std_ulogic;
    signal s0_axi_wdata:   std_ulogic_vector(2**(nb + 3) - 1 downto 0);
    signal s0_axi_wstrb:   std_ulogic_vector(2**nb - 1 downto 0);
    signal s0_axi_wvalid:  std_ulogic;
    signal s0_axi_wready:  std_ulogic;
    signal s0_axi_rdata:   std_ulogic_vector(2**(nb + 3) - 1 downto 0);
    signal s0_axi_rresp:   std_ulogic_vector(1 downto 0);
    signal s0_axi_rvalid:  std_ulogic;
    signal s0_axi_rready:  std_ulogic;
    signal s0_axi_bresp:   std_ulogic_vector(1 downto 0);
    signal s0_axi_bvalid:  std_ulogic;
    signal s0_axi_bready:  std_ulogic;

begin

    u0: entity work.axi_memory(rtl)
    generic map(
        na   => na,
        nb   => nb,
        fin  => fin,
        fout => fout
    )
    port map(
        aclk           => aclk,
        aresetn        => aresetn,
        dump           => dump,
        s0_axi_araddr  => s0_axi_araddr,
        s0_axi_arvalid => s0_axi_arvalid,
        s0_axi_arready => s0_axi_arready,
        s0_axi_awaddr  => s0_axi_awaddr,
        s0_axi_awvalid => s0_axi_awvalid,
        s0_axi_awready => s0_axi_awready,
        s0_axi_wdata   => s0_axi_wdata,
        s0_axi_wstrb   => s0_axi_wstrb,
        s0_axi_wvalid  => s0_axi_wvalid,
        s0_axi_wready  => s0_axi_wready,
        s0_axi_rdata   => s0_axi_rdata,
        s0_axi_rresp   => s0_axi_rresp,
        s0_axi_rvalid  => s0_axi_rvalid,
        s0_axi_rready  => s0_axi_rready,
        s0_axi_bresp   => s0_axi_bresp,
        s0_axi_bvalid  => s0_axi_bvalid,
        s0_axi_bready  => s0_axi_bready
    );

    process
    begin
        aclk <= '0';
        wait for 1 ns;
        aclk <= '1';
        wait for 1 ns;
    end process;

    s0_axi_rready <= '1';
    s0_axi_bready <= '1';

    process
        file f: text;
        variable l: line;
    begin
        file_open(f, fin, write_mode);
        for i in 0 to 2**(na - nb) - 1 loop
            hwrite(l, to_stdulogicvector(i, 2**(nb + 3)));
            writeline(f, l);
        end loop;
        file_close(f);
        aresetn        <= '0';
        dump           <= '0';
        s0_axi_araddr  <= (others => '0');
        s0_axi_arvalid <= '0';
        s0_axi_awaddr  <= (others => '0');
        s0_axi_awvalid <= '0';
        s0_axi_wdata   <= (others => '0');
        s0_axi_wstrb   <= (others => '0');
        s0_axi_wvalid  <= '0';
        wait until rising_edge(aclk);
        aresetn <= '1';
        for i in 0 to 2**(na - nb) - 1 loop
            s0_axi_araddr  <= to_stdulogicvector(i * 2**nb, na);
            s0_axi_arvalid <= '1';
            wait until rising_edge(aclk) and s0_axi_arready = '1';
            s0_axi_arvalid <= '0';
            if s0_axi_rvalid = '0' then
                wait until rising_edge(aclk) and s0_axi_rvalid = '1';
            end if;
            check_ref(s0_axi_rresp, axi_resp_okay, "s0_axi_rresp");
            check_ref(s0_axi_rdata, to_stdulogicvector(i, 2**(nb + 3)), "s0_axi_rdata");
        end loop;
        s0_axi_wstrb <= (others => '1');
        for i in 0 to 2**(na - nb) - 1 loop
            s0_axi_awaddr  <= to_stdulogicvector(i * 2**nb, na);
            s0_axi_wdata   <= to_stdulogicvector(2**(na - nb) - 1 - i, 2**(nb + 3));
            s0_axi_awvalid <= '1';
            s0_axi_wvalid  <= '1';
            loop
                wait until rising_edge(aclk);
                if s0_axi_awready = '1' then
                    s0_axi_awvalid <= '0';
                end if;
                if s0_axi_wready = '1' then
                    s0_axi_wvalid <= '0';
                end if;
                exit when (s0_axi_awvalid = '0' or s0_axi_awready = '1') and (s0_axi_wvalid = '0' or s0_axi_wready = '1');
            end loop;
        end loop;
        dump <= '1';
        wait until rising_edge(aclk);
        pass;
    end process;

end architecture sim;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab textwidth=0:
