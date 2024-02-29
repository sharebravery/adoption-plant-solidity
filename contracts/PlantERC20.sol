// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlantERC20 is ERC20Burnable, Ownable {
    uint256 private constant SUPPLY_LIMIT = 1000000000 * 10 ** 18; // 设定供应限制为 1,000,000,000

    constructor() ERC20("TREE", "TREE") Ownable(msg.sender) {
        _mint(_msgSender(), 0);
    }

    function mint(address account, uint256 amount) public onlyOwner() {
        require(totalSupply() + amount <= SUPPLY_LIMIT, "Exceeds supply limit");
        _mint(account, amount);
    }
}
