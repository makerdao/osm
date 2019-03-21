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

pragma solidity >=0.5.2;

import "ds-stop/stop.sol";

interface ValueLike {
    function peek() external returns (bytes32,bool);
    function read() external returns (bytes32);
}

contract OSM is DSStop {

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) public auth { wards[guy] = 1; }
    function deny(address guy) public auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    address public src;
    uint16 constant ONE_HOUR = uint16(3600);
    uint16 public hop = ONE_HOUR;
    uint64 public zzz;

    struct Feed {
        uint128 val;
        bool    has;
    }

    Feed cur;
    Feed nxt;

    // Whitelisted contracts, set by an auth
    mapping (address => bool) public bud;

    modifier toll { require(bud[msg.sender], "contract-is-not-whitelisted"); _; }

    event LogValue(bytes32 val);
    
    constructor (address src_) public {
        wards[msg.sender] = 1;
        src = src_;
    }
    
    function change(address src_) external auth {
        src = src_;
    }

    function era() internal view returns (uint) {
        return block.timestamp;
    }

    function prev(uint ts) internal view returns (uint64) {
        return uint64(ts - (ts % hop));
    }

    function step(uint16 ts) external auth {
        require(ts > 0, "ts-is-zero");
        hop = ts;
    }

    function void() external auth {
        cur = nxt = Feed(0, false);
        stopped = true;
    }

    function pass() public view returns (bool ok) {
        return era() >= zzz + hop;
    }

    function poke() external stoppable {
        require(pass(), "not-passed");
        (bytes32 wut, bool ok) = ValueLike(src).peek();
        if (ok) {
            cur = nxt;
            nxt = Feed(uint128(uint(wut)), ok);
            zzz = prev(era());
            emit LogValue(bytes32(uint(cur.val)));
        }
    }

    function peek() external view toll returns (bytes32,bool) {
        return (bytes32(uint(cur.val)), cur.has);
    }

    function peep() external view toll returns (bytes32,bool) {
        return (bytes32(uint(nxt.val)), nxt.has);
    }

    function read() external view toll returns (bytes32) {
        require(cur.has, "no-current-value");
        return (bytes32(uint(cur.val)));
    }

    function kiss(address a) external auth {
        require (a != address(0), "no-contract-0");
        bud[a] = true;
    }

    function diss(address a) external auth {
        bud[a] = false;
    }
}