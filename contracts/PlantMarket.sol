// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./PlantAdoption.sol";

contract PlantMarket is Ownable, ReentrancyGuard {
    using Address for address payable;

    PlantAdoption public plantAdoptionContract;

    event PlantListed(uint256 indexed plantId, address indexed seller, uint256 price);
    event PlantSold(uint256 indexed plantId, address indexed buyer, address indexed seller, uint256 price);

    constructor(address _plantAdoptionContract) {
        plantAdoptionContract = PlantAdoption(_plantAdoptionContract);
    }

    // 挂卖植物
    function listPlantForSale(uint256 _plantId, uint256 _price) external nonReentrant {
        require(plantAdoptionContract.plants(_plantId).isAdopted, "Plant is not adopted");
        require(plantAdoptionContract.plants(_plantId).owner == msg.sender, "You don't own this plant");
        plantsForSale[_plantId] = _price;
        emit PlantListed(_plantId, msg.sender, _price);
    }

    // 取消挂卖植物
    function cancelPlantListing(uint256 _plantId) external nonReentrant {
        require(plantsForSale[_plantId] > 0, "Plant is not listed for sale");
        require(plantAdoptionContract.plants(_plantId).owner == msg.sender, "You don't own this plant");
        delete plantsForSale[_plantId];
    }

    // 领养植物
    function adoptPlantFromMarket(uint256 _plantId) external payable nonReentrant {
        require(plantsForSale[_plantId] > 0, "Plant is not listed for sale");
        uint256 price = plantsForSale[_plantId];
        address payable seller = payable(plantAdoptionContract.plants(_plantId).owner);
        require(msg.value >= price, "Insufficient payment");

        // 转移所有权
        plantAdoptionContract.transferPlantOwnership(_plantId, msg.sender);

        // 转移支付金额给卖家
        seller.sendValue(price);

        // 触发事件
        emit PlantSold(_plantId, msg.sender, seller, price);

        // 删除植物挂卖信息
        delete plantsForSale[_plantId];
    }

    // 查询植物是否挂卖及价格
    function getPlantListing(uint256 _plantId) external view returns (bool listed, uint256 price) {
        return (plantsForSale[_plantId] > 0, plantsForSale[_plantId]);
    }
}
