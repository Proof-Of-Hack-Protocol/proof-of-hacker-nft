// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/ProofOfHacker.sol";

contract ProofOfHackerTest is Test {
    ProofOfHacker public proofOfHacker;

    address admin;

    address minter;
    uint256 minterKey;

    address challenge;
    address player;

    function setUp() public {
        (minter, minterKey) = makeAddrAndKey("minter");
        admin = makeAddr("admin");

        challenge = makeAddr("challenge");
        player = makeAddr("player");

        vm.prank(admin);
        proofOfHacker = new ProofOfHacker(minter);
    }

    function testMint() public {
        assertTrue(proofOfHacker.minters(minter));

        string memory url = "url";
        bytes32 hash = keccak256(abi.encodePacked(address(proofOfHacker), challenge, player, url));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(minterKey, message);
        bytes memory signature = abi.encodePacked(r, s, v);

        /**
         * // JS sample
         *     const signer = new ethers.Wallet(KEY-minterKey);
         *
         *     const hashed = ethers.utils.solidityKeccak256(
         *         ['address', 'address', 'address', 'string'],
         *         [
         *         contractAddress,
         *         challenge,
         *         player,
         *         nftUrl
         *         ]);
         *
         *     const signature = await wallet.signMessage(ethers.utils.arrayify(hashed))
         */

        proofOfHacker.mint(player, challenge, url, signature);
        vm.expectRevert(ProofOfHacker.errCantMintMoreThanOnce.selector);
        proofOfHacker.mint(player, challenge, url, signature);

        vm.expectRevert(ProofOfHacker.errWrongSignature.selector);
        proofOfHacker.mint(address(this), challenge, url, signature);
        vm.expectRevert(ProofOfHacker.errWrongSignature.selector);
        proofOfHacker.mint(address(this), challenge, "otra-url", signature);

        assertEq(proofOfHacker.uri(uint256(uint160(challenge))), url);
    }

    function testOwnerFunctions() public {
        vm.expectRevert("UNAUTHORIZED");
        proofOfHacker.setContractURI("contracturl");
        vm.prank(admin);
        proofOfHacker.setContractURI("contracturl");

        assertEq(proofOfHacker.contractURI(), "contracturl");

        address[] memory arr = new address[](1);
        arr[0] = admin;
        vm.expectRevert("UNAUTHORIZED");
        proofOfHacker.massMint(arr, arr);
        assertEq(proofOfHacker.balanceOf(admin, uint256(uint160(admin))), 0);

        vm.prank(admin);
        proofOfHacker.massMint(arr, arr);
        assertEq(proofOfHacker.balanceOf(admin, uint256(uint160(admin))), 1);

        vm.prank(admin);
        proofOfHacker.massMint(arr, admin);
        // it wont mint again
        assertEq(proofOfHacker.balanceOf(admin, uint256(uint160(admin))), 1);

        vm.prank(admin);
        proofOfHacker.massMint(arr, minter);
        // it wont mint again
        assertEq(proofOfHacker.balanceOf(admin, uint256(uint160(minter))), 1);
    }

    function testSoulBound() public {
        uint256 tokenId = uint256(uint160(challenge));

        uint256[] memory arrIds = new uint256[](1);
        arrIds[0] = tokenId;
        uint256[] memory arrAmnts = new uint256[](1);
        arrAmnts[0] = 1;

        vm.expectRevert(SoulBound1155.errIsASoulBoundToken.selector);
        proofOfHacker.safeBatchTransferFrom(admin, minter, arrIds, arrAmnts, "");

        vm.expectRevert(SoulBound1155.errIsASoulBoundToken.selector);
        proofOfHacker.safeTransferFrom(admin, minter, tokenId, 1, "");

        vm.expectRevert(SoulBound1155.errIsASoulBoundToken.selector);
        proofOfHacker.setApprovalForAll(minter, true);
    }
}
