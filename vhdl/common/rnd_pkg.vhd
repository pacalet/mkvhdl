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
-- Random numbers generator
--
-- Example of use:
--
-- library common;
-- use common.rnd_pkg.all;
-- ...
-- process
--   variable rg: rnd_generator;
--   variable rndbool: boolean;
--   variable rndint: integer range -9 to 17;
-- begin
--   rg.init(2,3);
--   ...
--   rndbool := rg.get_boolean;
--   rndint  := rg.get_integer(-9,17);
--   s       <= rg.get_std_ulogic_vector(32);
--   ...

library ieee;
use ieee.std_logic_1164.all;

-- A package is split in two parts: declaration and body, a bit like circuits
-- descriptions are split in entity and architecture. The package declaration
-- is the part that is visible from the outside and it defines the public
-- interface (subprograms' prototypes, types, constants...)
package rnd_pkg is

    -- Protected types are what ressemble most the classes of OO languages in
    -- VHDL. A impure function is a function that has side effects.
    type rnd_generator is protected
        -- Set random seeds (default seeds are (1,1))
        procedure init(s1, s2: positive);
        -- Return a random boolean
        impure function get_boolean return boolean;
        -- Return a random integer greater or equal min and less or equal max
        impure function get_integer(min, max: integer) return integer;
        -- Return a random real in the ]0.0, 1.0[ range
        impure function get_real return real;
        -- Return a random bit
        impure function get_bit return bit;
        -- Return a random bit_vector of length size
        impure function get_bit_vector(size: positive) return bit_vector;
        -- Return a random std_ulogic ('0' or '1' only)
        impure function get_std_ulogic return std_ulogic;
        -- Return a random std_ulogic_vector ('0' or '1' only) of length size
        impure function get_std_ulogic_vector(size: positive) return std_ulogic_vector;
    end protected rnd_generator;
end package rnd_pkg;

-- The random generator uses the uniform procedure of the ieee.math_real
-- package.
library ieee;
use ieee.math_real.all;

-- The package body defines the private internals of the package (subprograms'
-- bodies, constant values...)
package body rnd_pkg is

    type rnd_generator is protected body
        -- Private members
        variable seed1: positive := 1;
        variable seed2: positive := 1;
        variable rnd:   real;

        -- Private procedure
        procedure throw is
        begin
            uniform(seed1, seed2, rnd);
        end procedure throw;

        -- Bodies of public subprograms
        procedure init(s1, s2: positive) is
        begin
            seed1 := s1;
            seed2 := s2;
        end procedure init;

        impure function get_boolean return boolean is
        begin
            throw;
            return rnd < 0.5;
        end function get_boolean;

        impure function get_integer(min, max: integer) return integer is
            variable tmp: integer;
        begin
            throw;
            tmp := min + integer(real(max - min + 1) * rnd - 0.5);
            if tmp < min then
                tmp := min;
            elsif tmp > max then
                tmp := max;
            end if;
            return tmp;
        end function get_integer;

        impure function get_real return real is
        begin
            throw;
            return rnd;
        end function get_real;

        impure function get_bit return bit is
        variable res: bit;
        begin
            res := '0' when get_boolean else '1';
            return res;
        end function get_bit;

        impure function get_std_ulogic return std_ulogic is
        variable res: std_ulogic;
        begin
            res := '0' when get_boolean else '1';
            return res;
        end function get_std_ulogic;

        -- When two types are very similar they are said "compatible" and
        -- conversion functions are implicitely declared. The names of the
        -- conversion functions are the same as the names of the destination
        -- type (e.g. std_ulogic_vector).
        impure function get_std_ulogic_vector(size: positive) return std_ulogic_vector is
            variable res: std_ulogic_vector(1 to size);
        begin
            if size = 1 then
                res(1) := get_std_ulogic;
            else
                res := get_std_ulogic & get_std_ulogic_vector(size - 1);
            end if;
            return res;
        end function get_std_ulogic_vector;

        -- The std_ulogic_vector and bit_vector types are not compatible but
        -- the ieee.std_logic_1164 declares the to_bitvector function.
        impure function get_bit_vector(size: positive) return bit_vector is
        begin
            return to_bitvector(get_std_ulogic_vector(size));
        end function get_bit_vector;
    end protected body rnd_generator;

end package body rnd_pkg;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab textwidth=0:
