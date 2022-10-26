// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SoulBound1155} from "./SoulBound1155.sol";

contract ProofOfHacker is SoulBound1155, Owned {
    string constant public name = "Proof Of Hacker";
    string constant public symbol = "POH";
    string public contractURI;

    mapping(address => bool) public minters;

    mapping(uint256 => string) private _uri;

    error errWrongSignature();
    error errCantMintMoreThanOnce();
    error errArrLengthMismatch();

    error errTokenNotExists(address);

    constructor(address _minter) Owned(msg.sender) {
        minters[_minter] = true;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function setMinter(address _minter, bool canMint) external onlyOwner {
        minters[_minter] = canMint;
    }

    /// @notice Ownet mint function to subsidize minting
    function massMint(address[] calldata _players, address[] calldata _challenges) external onlyOwner {
        if (_players.length != _challenges.length) {
            revert errArrLengthMismatch();
        }
        for (uint256 i; i < _players.length;) {
            uint256 _tokenId = uint256(uint160(_challenges[i]));
            if (balanceOf[_players[i]][_tokenId] == 0) {
                _mint(_players[i], _tokenId, 1, "");
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Ownet mint function to subsidize minting
    function massMint(address[] calldata _players, address _challenge) external onlyOwner {
        uint256 _tokenId = uint256(uint160(_challenge));
        for (uint256 i; i < _players.length;) {
            if (balanceOf[_players[i]][_tokenId] == 0) {
                _mint(_players[i], _tokenId, 1, "");
            }
            unchecked {
                ++i;
            }
        }
    }

    function mint(address _player, address _challenge, string memory _ipfs, bytes calldata _signature) external {
        uint256 _tokenId = uint256(uint160(_challenge));
        if (balanceOf[_player][_tokenId] > 0) {
            revert errCantMintMoreThanOnce();
        }

        bytes32 hash = keccak256(abi.encodePacked(address(this), _challenge, _player, _ipfs));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(message, _signature);
        if (error != ECDSA.RecoverError.NoError || !minters[recovered]) {
            revert errWrongSignature();
        }

        if (keccak256(abi.encodePacked(_uri[_tokenId])) != keccak256(abi.encodePacked(_ipfs))) {
            _uri[_tokenId] = _ipfs;
        }

        _mint(_player, _tokenId, 1, "");
    }

    function uri(uint256 id) public view override returns (string memory url) {
        url = _uri[id];
        if (bytes(url).length == 0) {
            revert errTokenNotExists(address(uint160(id)));
        }
    }
}
