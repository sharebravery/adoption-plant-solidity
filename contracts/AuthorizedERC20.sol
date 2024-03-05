// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AuthorizedERC20 is ERC20Burnable, Ownable {
    uint256 private constant SUPPLY_LIMIT = 1000000000 * 10 ** 18;

    mapping(address => bool) private _authorizedMinters;
    bool private _isOneTimeAuthorizationDone;

    // 错误：未经授权的访问
    error UnauthorizedAccess();
    // 错误：超出供应限制
    error ExceedsSupplyLimit();
    // 错误：已经进行过一次性授权
    error OneTimeAuthorizationDone();

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {}

    /**
     * 仅允许授权的地址调用 mint 函数
     * @param account account
     * @param amount amount
     */
    function mint(address account, uint256 amount) external {
        if (!_authorizedMinters[msg.sender]) revert UnauthorizedAccess();
        if (totalSupply() + amount > SUPPLY_LIMIT) revert ExceedsSupplyLimit();

        _mint(account, amount);
    }

    /**
     * 一次性授权地址调用 mint 函数
     * @param minter minter
     */
    function authorizeOnce(address minter) external onlyOwner {
        if (_isOneTimeAuthorizationDone) revert OneTimeAuthorizationDone();
        _authorizedMinters[minter] = true;
        _isOneTimeAuthorizationDone = true;
    }

    /**
     * 查询还可以 mint 的余额
     */
    function mintableBalance() external view returns (uint256) {
        return SUPPLY_LIMIT - totalSupply();
    }

    /**
     * 查询地址的授权状态
     * @param minter minter
     */
    function isMinterAuthorized(address minter) external view returns (bool) {
        return _authorizedMinters[minter];
    }
}
