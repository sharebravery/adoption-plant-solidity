// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlantERC20 is ERC20Burnable, Ownable {
    uint256 private constant SUPPLY_LIMIT = 1000000000 * 10 ** 18;

    constructor() ERC20("TREE", "TREE") Ownable(msg.sender) {
        _mint(_msgSender(), 0);
    }

    // 只允许 PlantMarket 合约调用 mint 函数
    function mintFromMarket(address account, uint256 amount) external {
        require(msg.sender == address(_plantMarketContract), "Unauthorized");
        require(totalSupply() + amount <= SUPPLY_LIMIT, "Exceeds supply limit");
        _mint(account, amount);
    }

    // 设置 PlantMarket 合约地址
    function setPlantMarketContract(address plantMarketContract) external onlyOwner {
        _plantMarketContract = plantMarketContract;
    }

    address private _plantMarketContract;
}
