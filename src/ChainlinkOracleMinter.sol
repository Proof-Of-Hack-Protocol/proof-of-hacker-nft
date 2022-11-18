// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "chainlink-brownie-contracts/contracts/src/v0.8/ChainlinkClient.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/ConfirmedOwner.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

interface NftCollection {
  function chainlinkMint(address player, address challenge) external;
}

contract APIConsumer is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    bytes32 immutable private JOBID;
    uint256 immutable private FEE;
    address immutable public LINK;
    address immutable public NFT;

    struct Job {
      address challenge;
      address player;
    }

    mapping(bytes32 => Job) _pendingJobs;
    mapping(bytes32 => bool) _minted;
    
    /**
     * @notice Initialize the link token and target oracle
     *
     * Goerli Testnet details:
     * Link Token: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Oracle: 0xf3FBB7f3391F62C8fe53f89B41dFC8159EE9653f (Chainlink DevRel)
     * JOBID: ca98366cc7314957b8c012c72f05aeeb
     *
     */
    constructor(address _link, address _oracle, address _nft, bytes32 _jobid) ConfirmedOwner(msg.sender) {
        LINK = _link;
        setChainlinkToken(_link);
        setChainlinkOracle(_oracle);
        NFT = _nft;
        JOBID = _jobid;
        FEE = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    function requestNftBadge(address player, address challenge) public returns (bytes32 requestId) {
        if (ERC20(LINK).balanceOf(address(this)) < FEE) {
          ERC20(LINK).transferFrom(msg.sender, address(this), FEE);
        }
        Chainlink.Request memory req = buildChainlinkRequest(
            JOBID,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        req.add(
            "get",
            string(abi.encodePacked(
              "https://www.ctfprotocol.com/mint?player=",
              Strings.toHexString(player),
              "&challenge=",
              Strings.toHexString(challenge)
            ))
        );

        /// @dev if user cant mint the api response will be rejected
        req.add("path", "keccak");

        requestId = sendChainlinkRequest(req, FEE);
        
        _pendingJobs[requestId] = Job({ challenge: challenge, player: player});
        
    }

    event MintNft(address player, address challenge);
    /**
     * Receive the response
     */
    function fulfill(
        bytes32 _requestId,
        bytes32 _responseOk
    ) public recordChainlinkFulfillment(_requestId) {
        require(_responseOk != bytes32(0), "value cant be null");
        Job memory j = _pendingJobs[_requestId];
        require(j.player != address(0), "inexistent job");
        bytes32 _hash = keccak256(abi.encodePacked(j.player, j.challenge));
        require(_minted[_hash] == false, "badge already minted");
        _minted[_hash] = true;
        
        /// @dev lets mint the NFT to the player
        NftCollection(NFT).chainlinkMint(j.player, j.challenge);

        emit MintNft(j.player, j.challenge);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}