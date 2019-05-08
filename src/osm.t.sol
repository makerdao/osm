pragma solidity >=0.5.2;

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
        feed = new DSValue();                                   //create new feed
        feed.poke(bytes32(uint(100 ether)));                    //set feed to 100
        osm = new OSM(address(feed));                           //create new osm linked to feed
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);//get hevm instance
        hevm.warp(uint(osm.hop()));                             //warp 1 hop
        osm.poke();                                             //set new next osm value
    }

    function testChangeValue() public {
        assertEq(osm.src(), address(feed));                     //verify osm source is feed
        DSValue feed2 = new DSValue();                          //create new feed
        osm.change(address(feed2));                             //change osm source to new feed
        assertEq(osm.src(), address(feed2));                    //verify osm source is new feed
    }

    function testSetHop() public {
        assertEq(uint(osm.hop()), 3600);                        //verify interval is 1 hour
        osm.step(uint16(7200));                                 //change interval to 2 hours
        assertEq(uint(osm.hop()), 7200);                        //verify interval is 2 hours
    }

    function testFailSetHopZero() public {
        osm.step(uint16(0));                                    //attempt to change interval to 0
    }

    function testVoid() public {
        assertTrue(osm.stopped() == 0);                         //verify osm is active
        osm.kiss(address(this));                                //whitelist caller
        hevm.warp(uint(osm.hop() * 2));                         //warp 2 hops
        osm.poke();                                             //set new curent and next osm value
        (bytes32 val, bool has) = osm.peek();                   //pull current osm value
        assertEq(uint(val), 100 ether);                         //verify osm value is 100
        assertTrue(has);                                        //verify osm value is valid
        (val, has) = osm.peep();                                //pull next osm value
        assertEq(uint(val), 100 ether);                         //verify next osm value is 100
        assertTrue(has);                                        //verify next osm value is valid
        osm.void();                                             //void all osm values
        assertTrue(osm.stopped() == 1);                         //verify osm is inactive
        (val, has) = osm.peek();                                //pull current osm value
        assertEq(uint(val), 0);                                 //verify current osm value is 0
        assertTrue(!has);                                       //verify current osm value is invalid
        (val, has) = osm.peep();                                //pull next osm value
        assertEq(uint(val), 0);                                 //verify next osm value is 0
        assertTrue(!has);                                       //verify next osm value is invalid
    }

    function testPoke() public {
        feed.poke(bytes32(uint(101 ether)));                    //set new feed value
        hevm.warp(uint(osm.hop() * 2));                         //warp 2 hops
        osm.poke();                                             //set new current and next osm value
        osm.kiss(address(this));                                //whitelist caller
        (bytes32 val, bool has) = osm.peek();                   //pull current osm value
        assertEq(uint(val), 100 ether);                         //verify current osm value is 100
        assertTrue(has);                                        //verify current osm value is valid
        (val, has) = osm.peep();                                //pull next osm value
        assertEq(uint(val), 101 ether);                         //verify next osm value is 101
        assertTrue(has);                                        //verify next osm value is valid
        hevm.warp(uint(osm.hop() * 3));                         //warp 3 hops
        osm.poke();                                             //set new current and next osm value
        (val, has) = osm.peek();                                //pull current osm value
        assertEq(uint(val), 101 ether);                         //verify current osm value is 101
        assertTrue(has);                                        //verify current osm value is valid
    }

    function testFailPoke() public {
        feed.poke(bytes32(uint(101 ether)));                    //set new current and next osm value
        hevm.warp(uint(osm.hop() * 2 - 1));                     //warp 2 hops - 1 second
        osm.poke();                                             //attempt to set new current and next osm value
    }

    function testFailWhitelistPeep() public view {
        osm.peep();                                             //attempt to pull next osm value
    }

    function testWhitelistPeep() public {
        osm.kiss(address(this));                                //whitelist caller
        (bytes32 val, bool has) = osm.peep();                   //pull next osm value
        assertEq(uint(val), 100 ether);                         //verify next osm value is 100
        assertTrue(has);                                        //verify next osm value is valid
    }

    function testFailWhitelistPeek() public view {
        osm.peek();                                             //attempt to pull current osm value
    }

    function testWhitelistPeek() public {
        osm.kiss(address(this));                                //whitelist caller
        osm.peek();                                             //pull current osm value

    }

    function testKiss() public {
        assertTrue(!osm.bud(address(this)));                    //verify caller is not whitelisted
        osm.kiss(address(this));                                //whitelist caller
        assertTrue(osm.bud(address(this)));                     //verify caller is whitelisted
    }

    function testDiss() public {
        osm.kiss(address(this));                                //whitelist caller
        assertTrue(osm.bud(address(this)));                     //verify caller is whitelisted
        osm.diss(address(this));                                //remove caller from whitelist
        assertTrue(!osm.bud(address(this)));                    //verify caller is not whitelisted
    }
}
