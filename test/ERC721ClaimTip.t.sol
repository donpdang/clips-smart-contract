// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC721ClaimTip.sol";
import {Utils} from "./utils/Utils.sol";
import {ERC721Creator} from "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";



contract ERC721ClaimTipTest is Test {
    Utils internal utils;
    address payable[] internal users;
    ERC721ClaimTip public lazyClaim;
    address internal owner;
    address internal creator;
    address internal minter;
    ERC721Creator public creatorContract;
    uint256 private constant DEV_FEE = 0.00069 ether;

    function setUp() public {
        utils = new Utils();
        users = utils.createUsers(3);
        owner = 0xCD56df7B4705A99eBEBE2216e350638a1582bEC4;
        vm.label(owner, "Owner");
        creator = users[1];
        vm.label(creator, "Creator");
        minter = users[2];
        vm.label(minter, "Minter");

        // dev deploy the clip extension contract
        vm.startPrank(owner);
        lazyClaim = new ERC721ClaimTip(0x00000000000076A84feF008CDAbe6409d2FE638B);
        vm.stopPrank();

        // creator deploying the creator contract
        vm.startPrank(creator);
        creatorContract = new ERC721Creator("test","TEST");
        creatorContract.registerExtension(address(lazyClaim), "");
        vm.stopPrank();
    }

    function testTippingMint() public {
       vm.startPrank(creator);
       IERC721ClaimTip.ClaimParameters memory claimParameters = IERC721ClaimTip.ClaimParameters( {
          merkleRoot: bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
          location: "arweaveHash2",
          totalMax: 0,
          walletMax: 0,
          startDate: 0,
          endDate: 0,
          storageProtocol: IERC721ClaimTip.StorageProtocol.ARWEAVE,
          cost: 1e17,
          paymentReceiver: payable(creator),
          identical: true
        });
        // initialize claim
        lazyClaim.initializeClaim(address(creatorContract), 1,claimParameters);
        vm.stopPrank();

        bytes32[] memory merkleProof = new bytes32[](1);
        uint beforeBalanceCreator = creator.balance;
        uint beforeBalanceContract = address(lazyClaim).balance;
        vm.startPrank(minter);
        // no tip
        lazyClaim.mint{value: 1e17 + DEV_FEE}(address(creatorContract), 1, 0, merkleProof, address(minter));
        // transfer full amount to the creator wallet
        uint afterBalanceCreator = creator.balance;
        uint afterBalanceContract = address(lazyClaim).balance;

        assertEq(1e17, afterBalanceCreator - beforeBalanceCreator);
        // transfer DEV_FEE to the dev wallet
        assertEq(DEV_FEE, afterBalanceContract - beforeBalanceContract);

        beforeBalanceCreator = creator.balance;
        beforeBalanceContract = address(lazyClaim).balance;
        // with tip
        lazyClaim.mint{value: 2e17}(address(creatorContract), 1, 0, merkleProof, address(minter));
        afterBalanceCreator = creator.balance;
        afterBalanceContract = address(lazyClaim).balance;
        assertEq(2e17 - DEV_FEE, afterBalanceCreator - beforeBalanceCreator);
        assertEq(DEV_FEE, afterBalanceContract - beforeBalanceContract);
        vm.stopPrank();
    }

    function testTippingMintBatch() public {
       vm.startPrank(creator);
       IERC721ClaimTip.ClaimParameters memory claimParameters = IERC721ClaimTip.ClaimParameters( {
          merkleRoot: bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
          location: "arweaveHash2",
          totalMax: 0,
          walletMax: 0,
          startDate: 0,
          endDate: 0,
          storageProtocol: IERC721ClaimTip.StorageProtocol.ARWEAVE,
          cost: 1e17,
          paymentReceiver: payable(creator),
          identical: true
        });
        // initialize claim
        lazyClaim.initializeClaim(address(creatorContract), 1,claimParameters);
        vm.stopPrank();

        uint beforeBalanceCreator = creator.balance;
        uint beforeBalanceContract = address(lazyClaim).balance;
        vm.startPrank(minter);
        // able to pay the right price
        uint32[] memory randomArray = new uint32[](1);
        bytes32[][] memory anotherRandomArray = new bytes32[][](1);
        // no tip
        lazyClaim.mintBatch{value: 2e17 + DEV_FEE * 2}(address(creatorContract), 1, 2, randomArray, anotherRandomArray, address(minter));
        // transfer full amount to the creator wallet
        uint afterBalanceCreator = creator.balance;
        uint afterBalanceContract = address(lazyClaim).balance;
        assertEq( 2e17, afterBalanceCreator - beforeBalanceCreator);
         // transfer DEV_FEE to the dev wallet
        assertEq(DEV_FEE * 2, afterBalanceContract - beforeBalanceContract);
        beforeBalanceCreator = creator.balance;
        beforeBalanceContract = address(lazyClaim).balance;
        // with tip
        lazyClaim.mintBatch{value: 3e17}(address(creatorContract), 1, 2, randomArray, anotherRandomArray, address(minter));
        afterBalanceCreator = creator.balance;
        afterBalanceContract = address(lazyClaim).balance;
        assertEq(3e17 - DEV_FEE * 2, afterBalanceCreator - beforeBalanceCreator);
        assertEq(DEV_FEE * 2, afterBalanceContract - beforeBalanceContract);
        vm.stopPrank();
    }


    function testNotEnoughEthMintBatch() public {
        vm.startPrank(creator);
       IERC721ClaimTip.ClaimParameters memory claimParameters = IERC721ClaimTip.ClaimParameters( {
          merkleRoot: bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
          location: "arweaveHash2",
          totalMax: 0,
          walletMax: 0,
          startDate: 0,
          endDate: 0,
          storageProtocol: IERC721ClaimTip.StorageProtocol.ARWEAVE,
          cost: 1e17,
          paymentReceiver: payable(creator),
          identical: true
        });
        // initialize claim
        lazyClaim.initializeClaim(address(creatorContract), 1,claimParameters);
        vm.stopPrank();
        vm.startPrank(minter);
        // able to pay the right price
        uint32[] memory randomArray = new uint32[](1);
        bytes32[][] memory anotherRandomArray = new bytes32[][](1);
        vm.expectRevert('Must pay more.');
        lazyClaim.mintBatch{value: 2e17}(address(creatorContract), 1, 2, randomArray, anotherRandomArray, address(minter));
        vm.stopPrank();
    }

        function testNotEnoughEthMint() public {
        vm.startPrank(creator);
       IERC721ClaimTip.ClaimParameters memory claimParameters = IERC721ClaimTip.ClaimParameters( {
          merkleRoot: bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
          location: "arweaveHash2",
          totalMax: 0,
          walletMax: 0,
          startDate: 0,
          endDate: 0,
          storageProtocol: IERC721ClaimTip.StorageProtocol.ARWEAVE,
          cost: 1e17,
          paymentReceiver: payable(creator),
          identical: true
        });
        // initialize claim
        lazyClaim.initializeClaim(address(creatorContract), 1,claimParameters);
        vm.stopPrank();

        bytes32[] memory merkleProof = new bytes32[](1);
        vm.startPrank(minter);
        vm.expectRevert('Must pay more.');
        // able to pay the right price
        lazyClaim.mint{value: 1e17}(address(creatorContract), 1, 0, merkleProof, address(minter));
        vm.stopPrank();
    }

    function testWithdraw() public {
        // test if the owner of the extension will receive the fund
        vm.startPrank(creator);
       IERC721ClaimTip.ClaimParameters memory claimParameters = IERC721ClaimTip.ClaimParameters( {
          merkleRoot: bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
          location: "arweaveHash2",
          totalMax: 0,
          walletMax: 0,
          startDate: 0,
          endDate: 0,
          storageProtocol: IERC721ClaimTip.StorageProtocol.ARWEAVE,
          cost: 1e17,
          paymentReceiver: payable(creator),
          identical: true
        });
        // initialize claim
        lazyClaim.initializeClaim(address(creatorContract), 1,claimParameters);
        vm.stopPrank();

        bytes32[] memory merkleProof = new bytes32[](1);

        vm.startPrank(minter);
        uint beforeBalanceCreator = creator.balance;
        uint beforeBalanceContract = address(lazyClaim).balance;
        // able to pay more
        lazyClaim.mint{value: 2e17}(address(creatorContract), 1, 0, merkleProof, address(minter));
        uint afterBalanceCreator = creator.balance;
        uint afterBalanceContract = address(lazyClaim).balance;
        // transfer full price + 98% of tip amount to the creator wallet
        assertEq(2e17 - DEV_FEE, afterBalanceCreator - beforeBalanceCreator);
        assertEq(DEV_FEE, afterBalanceContract - beforeBalanceContract);
        vm.stopPrank();

        vm.startPrank(owner);      
        lazyClaim.withdraw();
        assertEq(DEV_FEE, owner.balance);
        vm.stopPrank();

        // mintBatch
        vm.startPrank(minter);
        uint32[] memory randomArray = new uint32[](1);
        bytes32[][] memory anotherRandomArray = new bytes32[][](1);
        lazyClaim.mintBatch{value: 2e17 + DEV_FEE*2}(address(creatorContract), 1, 2, randomArray, anotherRandomArray, address(minter));
        vm.stopPrank();
        
        uint ownerBeforeBalance = owner.balance;
        vm.startPrank(owner);      
        lazyClaim.withdraw();
        assertEq(DEV_FEE*2, owner.balance - ownerBeforeBalance);
        vm.stopPrank();
    }

    function testCannotWithdrawIfNotOwner() public {
        vm.expectRevert('Wallet is not an administrator for contract');
        vm.startPrank(creator);
        lazyClaim.withdraw();
        vm.stopPrank();
        
        vm.expectRevert('Wallet is not an administrator for contract');
        vm.startPrank(minter);
        lazyClaim.withdraw();
        vm.stopPrank();
    }


}
