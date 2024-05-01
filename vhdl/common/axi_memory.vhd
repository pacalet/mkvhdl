-- Copyright © Telecom Paris
-- Copyright © Renaud Pacalet (renaud.pacalet@telecom-paris.fr)
-- 
-- This file must be used under the terms of the CeCILL. This source
-- file is licensed as described in the file COPYING, which you should
-- have received as part of this distribution. The terms are also
-- available at:
-- https://cecill.info/licences/Licence_CeCILL_V2.1-en.html

-- AXI4 lite memory for simulation, 2**nb bytes words, 2^(na-nb) - 1 words
-- (2**na bytes). na is the bit width of the address buses (maximum 20 = 1MB).
-- During simultaneous read and write at the same address read is performed
-- first, that is, the read word is the old one. This is achieved by performing
-- the actual write operations on falling edges of the clock.
--
-- The input file is a text file with one word per line in hexadecimal form (8
-- or 16 digits), little endian. It's content is used to initialize the memory
-- on the first rising edge of the clock where aresetn = '0'. The first word
-- corresponds to address 0. Extra lines are ignored. Addresses corresponding
-- to missing lines are initialized with (others => 'U'). Example: if for na=4
-- and nb=2 the input file is:
--   01234567
--   76543210
--   89ABCDEF
-- the content of the memory is:
--   Address Byte
--   0x0     0x67
--   0x1     0x45
--   0x2     0x23
--   0x3     0x01
--   0x4     0x10
--   0x5     0x32
--   0x6     0x54
--   0x7     0x76
--   0x8     0xEF
--   0x9     0xCD
--   0xA     0xAB
--   0xB     0x89
--   0xC     U..U
--   0xD     U..U
--   0xE     U..U
--   0xF     U..U
--
-- The content of the memory is dumped to the output file each time the dump
-- input is high on a rising edge of the clock. The format and organization are
-- the same as for the input file.

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

library common;
use common.axi_pkg.all;

entity axi_memory is
    generic(
        na:   positive range 2 to 20; -- bit width of address buses
        nb:   positive range 2 to 3;  -- 2**2 = 4 or 2**3 = 8 bytes words
        fin:  string;                 -- name of input file
        fout: string                  -- name of output file
    );
    port(
        aclk:           in  std_ulogic;
        aresetn:        in  std_ulogic;
        dump:           in  std_ulogic;
        s0_axi_araddr:  in  std_ulogic_vector(na - 1 downto 0);
        s0_axi_arvalid: in  std_ulogic;
        s0_axi_arready: out std_ulogic;
        s0_axi_awaddr:  in  std_ulogic_vector(na - 1 downto 0);
        s0_axi_awvalid: in  std_ulogic;
        s0_axi_awready: out std_ulogic;
        s0_axi_wdata:   in  std_ulogic_vector(2**(nb + 3) - 1 downto 0);
        s0_axi_wstrb:   in  std_ulogic_vector(2**nb - 1 downto 0);
        s0_axi_wvalid:  in  std_ulogic;
        s0_axi_wready:  out std_ulogic;
        s0_axi_rdata:   out std_ulogic_vector(2**(nb + 3) - 1 downto 0);
        s0_axi_rresp:   out std_ulogic_vector(1 downto 0);
        s0_axi_rvalid:  out std_ulogic;
        s0_axi_rready:  in  std_ulogic;
        s0_axi_bresp:   out std_ulogic_vector(1 downto 0);
        s0_axi_bvalid:  out std_ulogic;
        s0_axi_bready:  in  std_ulogic
    );
end entity axi_memory;

architecture rtl of axi_memory is

    type state_t is (idle, responding);
    subtype word_t is std_ulogic_vector(2**(nb + 3) - 1 downto 0);

    type ram_t is protected
        procedure init(name: string);
        procedure dumpmem(name: string);
        impure function read(a: std_ulogic_vector) return word_t;
        procedure write(a: std_ulogic_vector; d: std_ulogic_vector; w: std_ulogic_vector);
    end protected ram_t;

    type ram_t is protected body

        type mem_t is array(natural range 0 to 2**na - 1) of word_t;
        variable mem: mem_t := (others => (others => 'U'));

        procedure init(name: string) is
            file f: text;
            variable l: line;
        begin
            file_open(f, name, read_mode);
            for a in 0 to 2**(na - nb) - 1 loop
                exit when endfile(f);
                readline(f, l);
                hread(l, mem(a));
            end loop;
            file_close(f);
        end procedure init;

        procedure dumpmem(name: string) is
            file f: text;
            variable l: line;
        begin
            file_open(f, name, write_mode);
            for a in 0 to 2**(na - nb) - 1 loop
                hwrite(l, mem(a));
                writeline(f, l);
            end loop;
            file_close(f);
        end procedure dumpmem;

        impure function read(a: std_ulogic_vector) return word_t is
            alias addr: std_ulogic_vector(na - 1 downto 0) is a;
        begin
            return mem(to_integer(addr(na - 1 downto nb)));
        end function read;

        procedure write(a: std_ulogic_vector; d: std_ulogic_vector; w: std_ulogic_vector) is
            alias addr: std_ulogic_vector(na - 1 downto 0) is a;
            alias data: std_ulogic_vector(2**(nb + 3) - 1 downto 0) is d;
            alias strb: std_ulogic_vector(2**nb - 1 downto 0) is w;
        begin
            for i in 0 to 2**nb - 1 loop
                if strb(i) = '1' then
                    mem(to_integer(addr(na - 1 downto nb)))(8 * i + 7 downto 8 * i) := data(8 * i + 7 downto 8 * i);
                end if;
            end loop;
        end procedure write;

    end protected body ram_t;

    shared variable ram: ram_t;

begin

    s0_axi_rresp   <= axi_resp_okay;

    process(aclk)
        variable state: state_t;
        variable init_done: boolean := false;
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                if not init_done then
                    ram.init(fin);
                    init_done := true;
                end if;
                state := idle;
                s0_axi_arready <= '1';
                s0_axi_rdata   <= (others => '0');
                s0_axi_rvalid  <= '0';
            else
                case state is
                    when idle =>
                        if s0_axi_arvalid = '1' then
                            s0_axi_arready <= '0';
                            s0_axi_rvalid  <= '1';
                            s0_axi_rdata   <= ram.read(s0_axi_araddr);
                            state          := responding;
                        end if;
                    when responding =>
                        if s0_axi_rready = '1' then
                            s0_axi_arready <= '1';
                            s0_axi_rvalid  <= '0';
                            state          := idle;
                        end if;
                end case;
            end if;
        end if;
    end process;

    s0_axi_bresp   <= axi_resp_okay;

    process
        variable state: state_t;
    begin
        wait until rising_edge(aclk);
        if aresetn = '0' then
            state := idle;
            s0_axi_awready <= '0';
            s0_axi_wready  <= '0';
            s0_axi_bvalid  <= '0';
        else
            if dump = '1' then
                ram.dumpmem(fout);
            end if;
            case state is
                when idle =>
                    if s0_axi_awvalid = '1' and s0_axi_wvalid = '1' then
                        s0_axi_awready <= '1';
                        s0_axi_wready  <= '1';
                        s0_axi_bvalid  <= '1';
                        state          := responding;
                        if to_integer(s0_axi_wstrb) /= 0 then
                            wait until falling_edge(aclk);
                            ram.write(s0_axi_awaddr, s0_axi_wdata, s0_axi_wstrb);
                        end if;
                    end if;
                when responding =>
                    s0_axi_awready <= '0';
                    s0_axi_wready  <= '0';
                    if s0_axi_bready = '1' then
                        s0_axi_bvalid <= '0';
                        state         := idle;
                    end if;
            end case;
        end if;
    end process;

end architecture rtl;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab textwidth=0:
