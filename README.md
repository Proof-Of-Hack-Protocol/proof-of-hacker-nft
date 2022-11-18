## Goerli contract deploy
https://goerli.etherscan.io/address/0x2461a9810231ba7b72bc33dc5330ce0ead054d2a

# Proof Of Hacker NFT will be deployed on Polygon
> This is not a final version, and will not be deploy until its ready.

All challenges are on Goerli, but main NFT badge collection (Proof Of Hacker) will be available on polygon, mainly because is affoardable, fast and has nice OpenSea integration.

Current demo NFT collection; https://testnets.opensea.io/collection/unidentified-contract-zuocbsfrgr

# Chainlink integration

To let users claim a badge on polygon mainnet we have create a chainlink oracle integration to check that a `player` has break a `challenge` and if so the oracle will mint the NFT.

Please see;
https://github.com/Proof-Of-Hack-Protocol/proof-of-hacker-nft/blob/main/src/ChainlinkOracleMinter.sol
