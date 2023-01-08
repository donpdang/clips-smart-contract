// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../src/ERC1155ClaimTip.sol";
import {Utils} from "./utils/Utils.sol";
import {ERC1155Creator} from "@manifoldxyz/creator-core-solidity/contracts/ERC1155Creator.sol";

contract ERC1155ClaimTipTest is Test {
    Utils internal utils;
    address payable[] internal users;
    ERC1155ClaimTip public lazyClaim;
    address internal minter;
    address internal owner;
    ERC1155Creator public creator;

    function setUp() public {
        utils = new Utils();
        users = utils.createUsers(2);
        owner = users[0];
        vm.label(owner, "Owner");
        minter = users[1];
        vm.label(minter, "Minter");
        vm.startPrank(owner);
        console.log("the address", address(creator));
        lazyClaim = new ERC1155ClaimTip(0x00000000000076A84feF008CDAbe6409d2FE638B);
        creator = new ERC1155Creator("test","TEST");

        creator.registerExtension(address(lazyClaim), "");
        vm.stopPrank();
    }

    function testTipping() public {
        console.log(
           "Should let user pay extra"
       );
       vm.startPrank(owner);
       IERC1155ClaimTip.ClaimParameters memory claimParameters = IERC1155ClaimTip.ClaimParameters( {
          merkleRoot: bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
          location: "arweaveHash2",
          totalMax: 0,
          walletMax: 0,
          startDate: 0,
          endDate: 0,
          storageProtocol: IERC1155ClaimTip.StorageProtocol.ARWEAVE,
          cost: 1e18,
          paymentReceiver: payable(owner)
        });
        // initialize claim
        lazyClaim.initializeClaim(address(creator), 2,claimParameters);
        vm.stopPrank();
    }
}
