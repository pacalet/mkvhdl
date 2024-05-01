-- Copyright © Telecom Paris
-- Copyright © Renaud Pacalet (renaud.pacalet@telecom-paris.fr)
--
-- This file must be used under the terms of the CeCILL. This source
-- file is licensed as described in the file COPYING, which you should
-- have received as part of this distribution. The terms are also
-- available at:
-- https://cecill.info/licences/Licence_CeCILL_V2.1-en.html

-- common declarations for the AXI protocol

library ieee;
use ieee.std_logic_1164.all;

package axi_pkg is

    constant axi_resp_okay:   std_ulogic_vector(1 downto 0) := "00";
    constant axi_resp_exokay: std_ulogic_vector(1 downto 0) := "01";
    constant axi_resp_slverr: std_ulogic_vector(1 downto 0) := "10";
    constant axi_resp_decerr: std_ulogic_vector(1 downto 0) := "11";

end package axi_pkg;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab textwidth=0:
