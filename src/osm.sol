/// osm.sol - oracle security module

// Copyright (C) 2018  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.4.20;

import "ds-auth/auth.sol";
import "ds-value/value.sol";

// interface DSValue {
//     function peek() external returns (bytes32,bool);
//     function read() external returns (bytes32);
// }

contract OSM is DSAuth {
    DSValue public src;
    
    uint16 constant ONE_HOUR = 3600;

    uint64 public hop = uint64(ONE_HOUR);
    uint64 public zzz;

    struct Feed {
        uint128 val;
        bool    has;
    }

    Feed cur;
    Feed nxt;
    
    function OSM(DSValue src_) public {
        src = src_;
        bytes32 wut; bool ok;
        (wut, ok) = src_.peek();
        if (ok) {
            cur = nxt = Feed(uint128(wut), ok);
            zzz = prev(now);
        }
    }

    function prev(uint ts) internal view returns (uint64) {
        return uint64(ts - (ts % hop));
    }

    function step(uint ts) external auth {
        // TODO: Reenable this
        // require(ts % ONE_HOUR == 0);
        hop = uint64(ts);
    }

    function poke() external {
        require(now >= zzz + hop);
        bytes32 wut; bool ok;
        (wut, ok) = src.peek();
        cur = nxt;
        nxt = Feed(uint128(wut), ok);
        zzz = prev(now);
    }

    function peek() public view returns (bytes32,bool) {
        return (bytes32(cur.val), cur.has);
    }

    function read() public view returns (bytes32) {

        return (bytes32(cur.val));
    }
}
