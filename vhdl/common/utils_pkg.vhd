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
-- Utility package
--
-- Defines utility procedures for simulation.

library ieee;
use ieee.std_logic_1164.all;

package utils_pkg is

    -- return true if b is '0' or '1', else false
    function is_01(b: std_ulogic) return boolean;
    -- return true if all bits of b are '0' or '1', else false
    function is_01(b: std_ulogic_vector) return boolean;
    -- check that v equals '0' or '1'; if not prints an error message and finish the simulation. s is the name of the faulty variable or signal, used in the error message. If not empty pre (post) is printed before (after) the error message.
    procedure check_unknowns(v: in std_ulogic; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns);
    -- check that all elements of v equal '0' or '1'; if not prints an error message and finish the simulation.
    -- s is the name of the faulty variable or signal, used in the error message.
    -- If not empty pre (post) is printed before (after) the error message.
    -- Vector values printed in binary if h false, else in hexadecimal
    procedure check_unknowns(v: in std_ulogic_vector; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns; h: in boolean := false);
    -- print string to standard output
    procedure print(s: in string := "");
    -- return now if t < 0, else t
    impure function now_or_what(t: time) return time;
    -- check that c is true r; if not prints an error message and finish the simulation. If not empty pre (post) is printed before (after) the error message.
    procedure check_ref(c: in boolean; pre: in string := ""; post: in string := ""; t: in time := -1 ns);
    -- all check-ref procedures check that v equals r; if not prints an error message and finish the simulation.
    -- s is the name of the faulty variable or signal, used in the error message.
    -- If not empty pre (post) is printed before (after) the error message.
    -- Vector values printed in binary if h false, else in hexadecimal
    procedure check_ref(v, r: in integer; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns);
    procedure check_ref(v, r: in bit; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns);
    procedure check_ref(v, r: in bit_vector; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns; h: in boolean := false);
    procedure check_ref(v, r: in std_ulogic; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns);
    procedure check_ref(v, r: in std_ulogic_vector; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns; h: in boolean := false);
    procedure check_ref(v, r: in time; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns);
    -- print a sucess message and finish the simulation.
    procedure pass;

    -- the log2 function returns the log base 2 of its parameter. the rounding
    -- is toward zero (log2(2) = log2(3) = 1)
    -- precision RTL when the parameter is a static constant.
    function log2(v: positive) return natural;
    function log2_down(v: positive) return natural;
    function log2_up(v: positive) return natural;

    -- shared natural numbers
    type shared_natural is protected
        -- Set value
        procedure set(v: natural);
        -- Return value
        impure function get return natural;
        -- Add value
        procedure add(v: integer);
    end protected shared_natural;

end package utils_pkg;

use std.textio.all;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;

package body utils_pkg is

    function is_01(b: std_ulogic) return boolean is
    begin
        return (b = '0') or (b = '1');
    end function is_01;

    function is_01(b: std_ulogic_vector) return boolean is
    begin
        for i in b'range loop
            if not is_01(b(i)) then
                return false;
            end if;
        end loop;
        return true;
    end function is_01;

    impure function now_or_what(t: time) return time is
    begin
        if t < 0 ns then
            return now;
        else
            return t;
        end if;
    end function now_or_what;

    procedure check_unknowns(v: in std_ulogic; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns) is
    begin
        if not is_01(v) then
            if pre'length > 0 then
                print(pre);
            end if;
            print("NON REGRESSION TEST FAILED - " & to_string(now_or_what(t)));
            print("  INVALID " & s & " VALUE: " & to_string(v));
            if post'length > 0 then
                print(post);
            end if;
            finish;
        end if;
    end procedure check_unknowns;

    procedure check_unknowns(v: in std_ulogic_vector; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns; h: in boolean := false) is
    begin
        if not is_01(v) then
            if pre'length > 0 then
                print(pre);
            end if;
            print("NON REGRESSION TEST FAILED - " & to_string(now_or_what(t)));
            if h then
                print("  INVALID " & s & " VALUE: " & to_hstring(v));
            else
                print("  INVALID " & s & " VALUE: " & to_string(v));
            end if;
            if post'length > 0 then
                print(post);
            end if;
            finish;
        end if;
    end procedure check_unknowns;

    procedure print(s: in string := "") is
        variable l: line;
    begin
        write(l, s);
        writeline(output, l);
    end procedure print;

    procedure check_ref(c: in boolean; pre: in string := ""; post: in string := ""; t: in time := -1 ns) is
    begin
        if not c then
            if pre'length > 0 then
                print(pre);
            end if;
            print("NON REGRESSION TEST FAILED - " & to_string(now_or_what(t)));
            if post'length > 0 then
                print(post);
            end if;
            finish;
        end if;
    end procedure check_ref;

    procedure check_ref(v, r: in integer; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns) is
    begin
        if v /= r then
            if pre'length > 0 then
                print(pre);
            end if;
            print("NON REGRESSION TEST FAILED - " & to_string(now_or_what(t)));
            print("  EXPECTED " & s & "=" & to_string(r));
            print("       GOT " & s & "=" & to_string(v));
            if post'length > 0 then
                print(post);
            end if;
            finish;
        end if;
    end procedure check_ref;

    procedure check_ref(v, r: in bit; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns) is
    begin
        if v /= r then
            if pre'length > 0 then
                print(pre);
            end if;
            print("NON REGRESSION TEST FAILED - " & to_string(now_or_what(t)));
            print("  EXPECTED " & s & "=" & to_string(r));
            print("       GOT " & s & "=" & to_string(v));
            if post'length > 0 then
                print(post);
            end if;
            finish;
        end if;
    end procedure check_ref;

    procedure check_ref(v, r: in bit_vector; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns; h: in boolean := false) is
        constant lv: bit_vector(v'length - 1 downto 0) := v;
        constant lr: bit_vector(r'length - 1 downto 0) := r;
    begin
        for i in v'length - 1 downto 0 loop
            if lv(i) /= lr(i) then
                if pre'length > 0 then
                    print(pre);
                end if;
                print("NON REGRESSION TEST FAILED - " & to_string(now_or_what(t)));
                if h then
                    print("  EXPECTED " & s & "=" & to_hstring(r));
                    print("       GOT " & s & "=" & to_hstring(v));
                else
                    print("  EXPECTED " & s & "=" & to_string(r));
                    print("       GOT " & s & "=" & to_string(v));
                end if;
                if post'length > 0 then
                    print(post);
                end if;
                finish;
            end if;
        end loop;
    end procedure check_ref;

    procedure check_ref(v, r: in std_ulogic; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns) is
    begin
        if r /= '-' and v /= r then
            if pre'length > 0 then
                print(pre);
            end if;
            print("NON REGRESSION TEST FAILED - " & to_string(now_or_what(t)));
            print("  EXPECTED " & s & "=" & to_string(r));
            print("       GOT " & s & "=" & to_string(v));
            if post'length > 0 then
                print(post);
            end if;
            finish;
        end if;
    end procedure check_ref;

    procedure check_ref(v, r: in std_ulogic_vector; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns; h: in boolean := false) is
        variable l: line;
        constant lv: std_ulogic_vector(v'length - 1 downto 0) := v;
        constant lr: std_ulogic_vector(r'length - 1 downto 0) := r;
    begin
        for i in v'length - 1 downto 0 loop
            if lr(i) /= '-' and lv(i) /= lr(i) then
                if pre'length > 0 then
                    print(pre);
                end if;
                print("NON REGRESSION TEST FAILED - " & to_string(now_or_what(t)));
                if h then
                    print("  EXPECTED " & s & "=" & to_hstring(r));
                    print("       GOT " & s & "=" & to_hstring(v));
                else
                    print("  EXPECTED " & s & "=" & to_string(r));
                    print("       GOT " & s & "=" & to_string(v));
                end if;
                if post'length > 0 then
                    print(post);
                end if;
                finish;
            end if;
        end loop;
    end procedure check_ref;

    procedure check_ref(v, r: in time; s: in string; pre: in string := ""; post: in string := ""; t: in time := -1 ns) is
    begin
        if v /= r then
            if pre'length > 0 then
                print(pre);
            end if;
            print("NON REGRESSION TEST FAILED - " & to_string(now_or_what(t)));
            print("  EXPECTED " & s & "=" & to_string(r));
            print("       GOT " & s & "=" & to_string(v));
            if post'length > 0 then
                print(post);
            end if;
            finish;
        end if;
    end procedure check_ref;

    procedure pass is
        variable l: line;
    begin
        print("NON REGRESSION TEST PASSED - " & to_string(now));
        finish;
    end procedure pass;

    function log2(v: positive) return natural is
        variable res: natural;
    begin
        if v = 1 then
            res := 0;
        else
            res := 1 + log2(v / 2);
        end if;
        return res;
    end function log2;

    function log2_down(v: positive) return natural is
    begin
        return log2(v);
    end function log2_down;

    function log2_up(v: positive) return natural is
        variable res: natural;
    begin
        if v = 1 then
            res := 0;
        else
            res := 1 + log2_up((v + 1) / 2);
        end if;
        return res;
    end function log2_up;

    type shared_natural is protected body
        variable val: natural := 0;
        procedure set(v: natural) is
        begin
            val := v;
        end procedure set;
        impure function get return natural is
        begin
            return val;
        end function get;
        procedure add(v: integer) is
        begin
            val := val + v;
        end procedure add;
    end protected body shared_natural;

end package body utils_pkg;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab textwidth=0:
