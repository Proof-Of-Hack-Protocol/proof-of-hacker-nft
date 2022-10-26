// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/tokens/ERC1155.sol";

abstract contract SoulBound1155 is ERC1155 {
    error errIsASoulBoundToken();

    function setApprovalForAll(address, bool) public virtual override {
        revert errIsASoulBoundToken();
    }

    function safeTransferFrom(address, address, uint256, uint256, bytes calldata) public virtual override {
        revert errIsASoulBoundToken();
    }

    function safeBatchTransferFrom(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        public
        virtual
        override
    {
        revert errIsASoulBoundToken();
    }
}
