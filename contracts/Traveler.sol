// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Traveler is
    ERC1155,
    Ownable,
    Pausable,
    ERC1155Supply,
    PaymentSplitter
{
    uint256 public publicPrice = 0.02 ether;
    uint256 public allowListPrice = 0.01 ether;
    uint256 public maxSupply = 20;
    uint256 public maxPerWallet = 3;
    bool public publicMintOpen = false;
    bool public allowListMintOpen = true;
    mapping(address => bool) public allowList;
    mapping(address => uint256) public purchasesPerWallet;

    constructor(
        address[] memory _payees,
        uint256[] memory _shares
    )
        ERC1155("ipfs://Qmaa6TuP2s9pSKczHF4rwWhTKUdygrrDs8RmYYqCjP3Hye/")
        PaymentSplitter(_payees, _shares)
    {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function uri(
        uint256 _id
    ) public view virtual override returns (string memory) {
        require(exists(_id), "URI: non-existent token");
        return
            string(
                abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json")
            );
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function publicMint(uint256 id, uint256 amount) public payable {
        require(publicMintOpen, "Public mint is closed!");
        require(
            msg.value == publicPrice * amount,
            "Not enough amount of money!"
        );
        internalMint(id, amount);
    }

    function allowListMint(uint256 id, uint256 amount) public payable {
        require(allowListMintOpen, "Allow list mint is closed!");
        require(allowList[msg.sender], "You are not on allowlist");
        require(
            msg.value == allowListPrice * amount,
            "Not enough amount of money!"
        );
        internalMint(id, amount);
    }

    function internalMint(uint256 id, uint256 amount) internal {
        require(
            purchasesPerWallet[msg.sender] + amount <= maxPerWallet,
            "Wallet limit reached"
        );
        require(id < 2, "Looks like you are trying to mint wrong NFT!");
        require(totalSupply(id) + amount <= maxSupply, "We sold out!");
        _mint(msg.sender, id, amount, "");
        purchasesPerWallet[msg.sender] += amount;
    }

    // This method is not required if Payment Splitter has been integrated.
    // function withdraw(address _addr) external onlyOwner {
    //     uint256 balance = address(this).balance;
    //     payable(_addr).transfer(balance);
    // }

    function editMintWindows(
        bool _publicMintOpen,
        bool _allowListMintOpen
    ) external onlyOwner {
        publicMintOpen = _publicMintOpen;
        allowListMintOpen = _allowListMintOpen;
    }

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = true;
        }
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
