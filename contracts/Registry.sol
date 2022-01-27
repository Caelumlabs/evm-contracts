// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";
import { Base64 } from './libraries/Base64.sol';

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract CaelumRegistry is
    Context,
    Ownable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    string private _baseTokenURI;

    struct Hash {
      uint256 validFrom;
      uint256 validTo;
    }

    struct Organization {
      uint256 level;
      mapping(bytes => Hash) certificates;
    }

    mapping (uint256 => Organization) private dids;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Mint a new Organization NFT.
     */
    function mint() public virtual {
      uint256 nfts = balanceOf(msg.sender);
      require((nfts == 0), "Organisation already exists");
      uint256 tokenId = _tokenIdTracker.current();
      _mint(msg.sender, tokenId);
      _tokenIdTracker.increment();
      Organization storage org = dids[tokenId];
      org.level = 0;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     */
    function pause() onlyOwner public virtual {
        _pause();
    }

    /**
     * Metadata for the NFT.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
      string memory json = Base64.encode(
        bytes(
          string(
            abi.encodePacked(
              '{"name": "DID #', tokenId.toString(), '",',
              '"level": ', dids[tokenId].level.toString(), 
              '}'
            )
          )
        )
      );

      string memory finalTokenUri = string(
        abi.encodePacked('data:application/json;base64,', json)
      );
      return finalTokenUri;
    }

    /**
     * Update Level
     */
    function setLevel(uint256 tokenId, uint256 level) onlyOwner public virtual {
      require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
      dids[tokenId].level = level;
    }

    function addCertificate(uint256 tokenId, bytes memory hash) public virtual {
      require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
      require(ownerOf(tokenId) == msg.sender, 'Only owner can add certificates');
      dids[tokenId].certificates[hash] = Hash(block.timestamp, 0);
    }

    function verifyCertificate(uint256 tokenId, bytes memory hash) public view returns (uint256 validFrom, uint256 validTo) {
      require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
      // require(_exists(dids[tokenId].certificates[hash]), 'Hash does not exist');
      return (dids[tokenId].certificates[hash].validFrom,dids[tokenId].certificates[hash].validTo);
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     */
    function unpause() onlyOwner public virtual {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
