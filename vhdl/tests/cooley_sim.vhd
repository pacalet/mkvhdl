-- Copyright © Telecom Paris
-- Copyright © Renaud Pacalet (renaud.pacalet@telecom-paris.fr)
-- 
-- This file must be used under the terms of the CeCILL. This source
-- file is licensed as described in the file COPYING, which you should
-- have received as part of this distribution. The terms are also
-- available at:
-- https://cecill.info/licences/Licence_CeCILL_V2.1-en.html
--

-- Our simulation environment is a black box with no inputs and no outputs.
entity cooley_sim is
  generic(n: positive := 10000); -- number of test clock cycles
end entity cooley_sim;

-- The std.textio declares types, functions and procedures for text
-- input/output. We use it to print error messages.
use std.textio.all;
-- The std.env package declares the finish procedure that we use to gracefully
-- end the simulation when all stimuli have been exercised.
use std.env.all;

library common;
-- The random generator package that we use to generate the input stimuli.
use common.rnd_pkg.all;

architecture sim of cooley_sim is

    -- Internal signals used to connect the Design Under Test (DUT) to the its
    -- environment. As there are no name conflicts between port names at one
    -- hierarchy level and signal names at another level, we can use the same
    -- names as the input-output ports of the DUT. This is not mandatory, we
    -- can also use other names, like, for example, clk instead of clock.
    signal clk:    bit;
    signal up:     bit;
    signal down:   bit;
    signal di:     bit_vector(8 downto 0);
    signal co:     bit;
    signal bo:     bit;
    signal po:     bit;
    signal do:     bit_vector(8 downto 0);

begin

    -- Instance of the DUT entity-architecture pair. This is an entity
    -- instantiation. It is different from the component instantiation that we
    -- do not use in this course. The instance name is u0, the library in which
    -- the entity cooley, architecture rtl will be searched for is work, that
    -- is, the same library as the one in which we will compile this simulation
    -- environment. Note that `cooley(rtl)` must be compiled first. The mappings:
    --   port => signal 
    -- are named mappings. They are more verbose than the ordered mappings
    -- where only the signal names are given:
    --   port map(clk, up, down...)
    -- but they are also more readable when signal names and port names are
    -- different and they allow the order of mappings to be different from the
    -- order of ports declaration in the cooley entity.
    u0: entity work.cooley(rtl)
    port map(
        clock   => clk,
        up      => up,
        down    => down,
        di      => di,
        co      => co,
        bo      => bo,
        po      => po,
        do      => do
    );

    -- The clock generator
    process
    begin
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
    end process;

    -- The input stimuli generator
    process
        variable r: rnd_generator;
    begin
        r.init(1, 1);
        -- Initialize the counter to zero
        up   <= '0';
        down <= '0';
        di   <= (others => '0');
        wait until rising_edge(clk);
        for i in 1 to n loop
            (up, down, di) <= r.get_bit_vector(11);
            wait until rising_edge(clk);
        end loop;
        report "End of simulation";
        finish;
    end process;

    -- An example of output verifier process to check the correctness of the
    -- parity output. We could add some more if we had a reference model of the
    -- expected behavior.
    process
        -- The line type is declared in std.textio. It is a pointer to a
        -- character string. It is used by the write and writeline functions
        -- to, respectively, assemble a character string and print it.
        variable l: line;
    begin
        -- Wait rising edge of clock for initialization
        wait until rising_edge(clk);
        loop -- Infinite loop
            -- Wait for next value change of po or do
            wait on po, do;
            -- Check po output against expected value
            if po /= xnor do then
                -- Assemble error message. Note that due to VHDL intricacies
                -- character string literals must be qualified when passed to
                -- the write procedure.
                write(l, string'("DO="));
                write(l, do);
                write(l, string'(", PO="));
                write(l, po);
                -- Assertions are fired when the condition is false. The report
                -- message is printed (l.all is the string l points to) and the
                -- simulation stops if the severity level is error, failure or
                -- fatal (this is configurable in the simulator's options).
                assert false report l.all severity failure;
            end if;
        end loop;
    end process;

end architecture sim;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab textwidth=0:
