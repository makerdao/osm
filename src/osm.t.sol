pragma solidity >=0.4.24;

import "ds-test/test.sol";
import {DSValue} from "ds-value/value.sol";
import {OSM} from "./osm.sol";

contract Hevm {
    function warp(uint256) public;
}

contract OSMTest is DSTest {
    Hevm hevm;

    DSValue feed;
    OSM osm;

    function setUp() public {
        feed = new DSValue();
        feed.poke(bytes32(uint(100 ether)));

        osm = new OSM(address(feed));

        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(0);
    }

    function testChangeValue() public {
        assertEq(osm.src(), address(feed));
        DSValue feed2 = new DSValue();
        osm.change(address(feed2));
        assertEq(osm.src(), address(feed2));
    }

    function testSetHop() public {
        assertEq(uint(osm.hop()), 3600);
        osm.step(uint16(7200));
        assertEq(uint(osm.hop()), 7200);
    }

    function testFailSetHopZero() public {
        osm.step(uint16(0));
    }

    function testVoid() public {
        assertTrue(!osm.stopped());
        (bytes32 val, bool has) = osm.peek();
        assertEq(uint(val), 100 ether);
        assertTrue(has);
        (val, has) = osm.peep();
        assertEq(uint(val), 100 ether);
        assertTrue(has);
        osm.void();
        assertTrue(osm.stopped());
        (val, has) = osm.peek();
        assertEq(uint(val), 0);
        assertTrue(!has);
        (val, has) = osm.peep();
        assertEq(uint(val), 0);
        assertTrue(!has);
    }

    function testPoke() public {
        feed.poke(bytes32(uint(101 ether)));
        hevm.warp(3600);
        osm.poke();
        (bytes32 val,) = osm.peek();
        assertEq(uint(val), 100 ether);
        (val,) = osm.peep();
        assertEq(uint(val), 101 ether);
        hevm.warp(7200);
        osm.poke();
        (val,) = osm.peek();
        assertEq(uint(val), 101 ether);
    }

    function testFailPoke() public {
        feed.poke(bytes32(uint(101 ether)));
        hevm.warp(3599);
        osm.poke();
    }
}
