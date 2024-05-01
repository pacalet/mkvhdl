-- Copyright © Telecom Paris
-- Copyright © Renaud Pacalet (renaud.pacalet@telecom-paris.fr)
--
-- This file must be used under the terms of the CeCILL. This source
-- file is licensed as described in the file COPYING, which you should
-- have received as part of this distribution. The terms are also
-- available at:
-- https://cecill.info/licences/Licence_CeCILL_V2.1-en.html

-- simple helper package for simulations of AXI4 lite interfaces

library ieee;
use ieee.std_logic_1164.all;

use work.axi_pkg.all;

package axi_sim_pkg is

    -- awaddr, awstrb and wdata must be assigned before calling axi_write.
    -- axi_write asserts bready high at the same time as awvalid and wvalid. if
    -- it is not the intended behaviour do not use axi_write. axi_write plays
    -- the role of the AXI4 lite master. it submits the write request and waits
    -- until it has been acknowledged and responded by the slave. the bresp
    -- response status is ignored. if it must be checked the axi_resp_check
    -- procedure can be instantiated as a concurrent statement.
    procedure axi_write(
        signal clk:     in  std_ulogic;
        signal awvalid: out std_ulogic;
        signal awready: in  std_ulogic;
        signal wvalid:  out std_ulogic;
        signal wready:  in  std_ulogic;
        signal bvalid:  in  std_ulogic;
        signal bready:  out std_ulogic
    );

    -- araddr must be assigned before calling axi_read. axi_read asserts rready
    -- high at the same time as arvalid. if it is not the intended behaviour do
    -- not use axi_read. axi_read plays the role of the AXI4 lite master. it
    -- submits the read request and waits until it has been acknowledged and
    -- responded by the slave. res contains the read data. the rresp response
    -- status is ignored. if it must be checked the axi_resp_check procedure
    -- can be instantiated as a concurrent statement.
    procedure axi_read(
        signal clk:     in  std_ulogic;
        signal arvalid: out std_ulogic;
        signal arready: in  std_ulogic;
        signal rvalid:  in  std_ulogic;
        signal rready:  out std_ulogic;
        signal rdata:   in  std_ulogic_vector(31 downto 0);
        res:            out std_ulogic_vector(31 downto 0)
    );

    -- axi_resp_check is intended to be instantiated as a concurrent statement.
    -- on rising edges of clk where valid=1 it checks resp and, if it is not
    -- axi_resp_okay, raise an assertion with severity level sev and message.
    procedure axi_resp_check(
        signal clk:   in  std_ulogic;
        signal valid: in  std_ulogic;
        signal resp:  in  std_ulogic_vector(1 downto 0);
        sev:          in  severity_level := failure;
        message:      in  string := "response not OK"
    );

end package axi_sim_pkg;

package body axi_sim_pkg is

    procedure axi_write(
        signal clk:     in  std_ulogic;
        signal awvalid: out std_ulogic;
        signal awready: in  std_ulogic;
        signal wvalid:  out std_ulogic;
        signal wready:  in  std_ulogic;
        signal bvalid:  in  std_ulogic;
        signal bready:  out std_ulogic
    ) is
        variable aw, w, b: boolean;
    begin
        awvalid <= '1';
        wvalid  <= '1';
        bready  <= '1';
        aw      := false;
        w       := false;
        b       := false;
        while not (aw and w and b) loop
            wait until rising_edge(clk);
            if awready = '1' then 
                awvalid <= '0';
                aw      := true;
            end if;
            if wready = '1' then 
                wvalid <= '0';
                w      := true;
            end if;
            if bvalid = '1' then 
                bready <= '0';
                b      := true;
            end if;
        end loop;
    end procedure axi_write;

    procedure axi_read(
        signal clk:     in  std_ulogic;
        signal arvalid: out std_ulogic;
        signal arready: in  std_ulogic;
        signal rvalid:  in  std_ulogic;
        signal rready:  out std_ulogic;
        signal rdata:   in  std_ulogic_vector(31 downto 0);
        res:            out std_ulogic_vector(31 downto 0)
    ) is
        variable ar, r: boolean;
    begin
        arvalid <= '1';
        rready  <= '1';
        ar      := false;
        r       := false;
        while not (ar and r) loop
            wait until rising_edge(clk);
            if arready = '1' then 
                arvalid <= '0';
                ar      := true;
            end if;
            if rvalid = '1' then 
                rready <= '0';
                r      := true;
                res    := rdata;
            end if;
        end loop;
    end procedure axi_read;

    procedure axi_resp_check(
        signal clk:   in  std_ulogic;
        signal valid: in  std_ulogic;
        signal resp:  in  std_ulogic_vector(1 downto 0);
        sev:          in  severity_level := failure;
        message:      in  string := "response not OK"
    ) is
    begin
        if rising_edge(clk) and valid = '1' then
            assert resp = axi_resp_okay report message severity sev;
        end if;
    end procedure axi_resp_check;

end package body axi_sim_pkg;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab textwidth=0:
