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
-- Software FIFO
--

package fifo_pkg is

    generic(type T);

    type fifo_t is protected
        procedure free;
        procedure push(val: in T);
        impure function current return T;
        procedure pop;
        impure function empty return boolean;
        impure function count return natural;
    end protected fifo_t;

end package fifo_pkg;

package body fifo_pkg is

    type fifo_t is protected body

        type entry;
        type entry_pointer is access entry;
        type entry is record
            val: T;
            prv: entry_pointer;
            nxt: entry_pointer;
        end record entry;
    
        variable head, tail: entry_pointer;
        variable cnt: natural := 0;
    
        procedure free is
            variable tmp: entry_pointer;
        begin
            while cnt /= 0 loop
                tmp := tail;
                tail := tail.prv;
                deallocate(tmp);
                cnt := cnt - 1;
            end loop;
        end procedure free;
    
        procedure push(val: in T) is
            variable tmp: entry_pointer;
        begin
            tmp := new entry'(val => val, prv => null, nxt => head);
            if cnt = 0 then
                tail := tmp;
            else
                head.prv := tmp;
            end if;
            head := tmp;
            cnt := cnt + 1;
        end procedure push;
    
        impure function current return T is
            variable val: T;
        begin
            return tail.val;
        end function current;
    
        procedure pop is
            variable tmp: entry_pointer;
        begin
            assert not empty report "Cannot pop empty FIFO" severity failure;
            tmp := tail;
            tail := tmp.prv;
            deallocate(tmp);
            cnt := cnt - 1;
        end procedure pop;
    
        impure function empty return boolean is
        begin
            return cnt = 0;
        end function empty;
    
        impure function count return natural is
        begin
            return cnt;
        end function count;

    end protected body fifo_t;

end package body fifo_pkg;

-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab textwidth=0:
