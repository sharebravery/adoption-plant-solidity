// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PlantMarket is Ownable, ReentrancyGuard {
    using Address for address payable;

    // 植物种类
    enum PlantType {
        Ordinary,
        SmallTree,
        MediumTree,
        HighTree,
        KingTree
    }

    // 植物信息
    struct Plant {
        uint256 adoptionTime; // 领养时间
        uint256 endTime; // 结束时间
        PlantType plantType; // 植物种类
        address owner; // 拥有者地址
        bool isAdopted; // 是否被领养
    }

    // 植物领养价格范围
    struct AdoptionPriceRange {
        uint256 minEth; // 最小领养价格（单位：以太）
        uint256 maxEth; // 最大领养价格（单位：以太）
        uint256 startTime; // 开始时间（单位：小时）
        uint256 endTime; // 结束时间（单位：小时）
        uint256 profitDays; // 收益天数
        uint256 profitRate; // 收益率（单位：百分比）
    }

    // 各种植物的领养价格范围
    mapping(PlantType => AdoptionPriceRange) public priceRanges;

    // 植物实例
    mapping(uint256 => Plant) public plants;

    // 预约用户列表
    mapping(PlantType => address[]) public reservedUsers;

    // 预约记录
    mapping(PlantType => mapping(address => bool)) public reservations;

    // 植物 ID 计数器
    uint256 private plantIdCounter;

    event PlantAdopted(
        uint256 indexed plantId,
        address indexed owner,
        PlantType plantType,
        uint256 adoptionTime,
        uint256 endTime
    );

    event PlantListed(
        uint256 indexed plantId,
        address indexed seller,
        uint256 price
    );
    event PlantSold(
        uint256 indexed plantId,
        address indexed buyer,
        address indexed seller,
        uint256 price
    );
    event PlantReserved(
        uint256 indexed plantId,
        address indexed user,
        PlantType plantType
    );
    event ReservationCanceled(
        uint256 indexed plantId,
        address indexed user,
        PlantType plantType
    );

    constructor() Ownable(msg.sender) {
        // 设置各种植物的领养价格范围
        priceRanges[PlantType.Ordinary] = AdoptionPriceRange(
            0.005 ether,
            0.015 ether,
            14,
            15,
            7,
            21
        );
        priceRanges[PlantType.SmallTree] = AdoptionPriceRange(
            0.0151 ether,
            0.045 ether,
            15,
            16,
            3,
            9
        );
        priceRanges[PlantType.MediumTree] = AdoptionPriceRange(
            0.0451 ether,
            0.125 ether,
            16,
            17,
            5,
            13
        );
        priceRanges[PlantType.HighTree] = AdoptionPriceRange(
            0.1251 ether,
            0.3 ether,
            17,
            18,
            12,
            21
        );
        priceRanges[PlantType.KingTree] = AdoptionPriceRange(
            0.3001 ether,
            0.75 ether,
            18,
            19,
            20,
            40
        );
    }

    // 官方创建植物到市场
    function createPlant(PlantType _plantType) external onlyOwner {
        require(plantIdCounter < type(uint256).max, "Plant ID overflow");

        // 创建植物实例
        Plant memory newPlant = Plant({
            adoptionTime: block.timestamp,
            endTime: block.timestamp +
                priceRanges[_plantType].profitDays *
                1 days,
            plantType: _plantType,
            owner: address(this), // 植物所有权归市场合约
            isAdopted: false
        });

        // 存储植物实例
        plants[plantIdCounter] = newPlant;

        // 触发事件
        emit PlantListed(plantIdCounter, address(this), 0);

        // 更新植物 ID 计数器
        plantIdCounter++;
    }

    // 领养植物
    function adoptPlant(uint256 _plantId) external payable nonReentrant {
        Plant storage plant = plants[_plantId];

        // 检查领养价格范围和领养时间
        require(!plant.isAdopted, "Plant is already adopted");
        require(
            msg.value >= priceRanges[plant.plantType].minEth &&
                msg.value <= priceRanges[plant.plantType].maxEth,
            "Invalid adoption price"
        );
        require(_isAdoptionTimeValid(plant.plantType), "Not adoption time");

        plant.owner = msg.sender;
        plant.isAdopted = true;

        // 转移支付金额给植物所有者（之前是市场合约）
        payable(owner()).sendValue(msg.value);

        // 如果有预约用户且当前用户是预约用户，则领养植物并取消预约
        if (reservations[plant.plantType][msg.sender]) {
            // 取消预约
            reservations[plant.plantType][msg.sender] = false;

            emit ReservationCanceled(_plantId, msg.sender, plant.plantType);
        }

        // 触发事件
        emit PlantAdopted(
            _plantId,
            msg.sender,
            plant.plantType,
            block.timestamp,
            plant.endTime
        );
    }

    // 预约植物抢购
    function reservePlant(PlantType _plantType) external nonReentrant {
        require(!_isAdoptionTimeValid(_plantType), "It's adoption time");
        require(
            !reservations[_plantType][msg.sender],
            "You have already reserved this plant type"
        );

        // 添加用户到预约列表
        reservedUsers[_plantType].push(msg.sender);
        reservations[_plantType][msg.sender] = true;

        // 触发事件
        emit PlantReserved(0, msg.sender, _plantType);
    }

    // 查询植物是否挂卖及价格
    function getPlantListing(uint256 _plantId)
        external
        view
        returns (bool listed, uint256 price)
    {
        Plant storage plant = plants[_plantId];
        return (!plant.isAdopted, 0);
    }

    // 检查领养时间是否有效
    function _isAdoptionTimeValid(PlantType _plantType)
        internal
        view
        returns (bool)
    {
        uint256 currentHour = (block.timestamp / 3600) % 24;
        uint256 startTime = priceRanges[_plantType].startTime;
        uint256 endTime = priceRanges[_plantType].endTime;

        return currentHour >= startTime && currentHour < endTime;
    }

}
