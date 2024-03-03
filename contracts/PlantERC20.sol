// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlantERC20 is ERC20Burnable, Ownable {
    uint256 private constant SUPPLY_LIMIT = 1000000000 * 10 ** 18;

    address private _plantMarketContract;

    // 错误：未经授权的访问
    error UnauthorizedAccess();
    // 错误：超出供应限制
    error ExceedsSupplyLimit();

    constructor() ERC20("TREE", "TREE") Ownable(msg.sender) {}

    // 只允许 PlantMarket 合约调用 mint 函数
    function mintFromMarket(address account, uint256 amount) external {
        if (msg.sender != address(_plantMarketContract))
            revert UnauthorizedAccess();
        if (totalSupply() + amount > SUPPLY_LIMIT) revert ExceedsSupplyLimit();

        _mint(account, amount);
    }

    // 设置 PlantMarket 合约地址
    function setPlantMarketContract(
        address plantMarketContract
    ) external onlyOwner {
        _plantMarketContract = plantMarketContract;
    }

    // 查询还可以 mint 的余额
    function mintableBalance() external view returns (uint256) {
        return SUPPLY_LIMIT - totalSupply();
    }
}
