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
        uint256 plantId;
        // uint256 startTime; // 领养时间
        // uint256 endTime; // 结束时间
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

    // 用户领养记录
    struct UserAdoptionRecord {
        mapping(PlantType => uint256) adoptionCount; // 记录用户领养每种植物的次数
    }

    // 用户地址到领养记录的映射
    mapping(address => UserAdoptionRecord) private userAdoptionRecords;

    // 植物 ID 计数器
    uint256 private plantIdCounter;

    event PlantAdopted(
        uint256 indexed plantId,
        address indexed owner,
        PlantType plantType,
        uint256 adoptionTime
        // uint256 endTime
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

    // 植物在市场上的列表信息
    struct MarketPlantInfo {
        uint256 plantId;
        PlantType plantType;
    }

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

        // 获取领养时间范围
        // uint256 startTime = priceRanges[_plantType].startTime;
        // uint256 endTime = priceRanges[_plantType].endTime;

        // uint256 adoptionTime = getAdoptionTime(startTime);

        // uint256 endTime = adoptionTime + priceRanges[_plantType].profitDays * 1 days;

        // 创建植物实例
        Plant memory newPlant = Plant({
            plantId: plantIdCounter,
            // startTime: adoptionTime,
            // endTime: endTime,
            plantType: _plantType,
            owner: address(this), // 植物所有权归市场合约
            isAdopted: false
        });

        // 存储植物实例
        plants[plantIdCounter] = newPlant;

        // 更新植物 ID 计数器
        plantIdCounter++;

        // 触发事件
        emit PlantListed(plantIdCounter, address(this), 0);
    }

    // 获取领养时间
    // function getAdoptionTime(uint256 startTime)
    //     internal
    //     view
    //     returns (uint256)
    // {
    //     uint256 currentTimestamp = block.timestamp;
    //     uint256 currentHour = (currentTimestamp / 3600) % 24;
    //     uint256 secondsUntilNextHour = ((
    //         currentHour < startTime ? startTime : startTime + 24
    //     ) - currentHour) * 3600;
    //     return currentTimestamp + secondsUntilNextHour;
    // }

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

        // 更新植物信息
        plant.owner = msg.sender;
        plant.isAdopted = true;

        // 更新用户领养记录
        userAdoptionRecords[msg.sender].adoptionCount[plant.plantType]++;

        // 触发事件
        emit PlantAdopted(
            _plantId,
            msg.sender,
            plant.plantType,
            block.timestamp
            // plant.endTime
        );

        // 转移支付金额给植物所有者（之前是市场合约）
        payable(owner()).sendValue(msg.value);
    }

    // 查询用户领养记录
    function getUserAdoptionRecord(address _user, PlantType _plantType)
        external
        view
        returns (uint256)
    {
        return userAdoptionRecords[_user].adoptionCount[_plantType];
    }

    // // 查询植物是否挂卖及价格
    // function getPlantListing(uint256 _plantId)
    //     external
    //     view
    //     returns (bool listed, uint256 price)
    // {
    //     Plant storage plant = plants[_plantId];
    //     return (!plant.isAdopted, 0);
    // }

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

    function getPlantInfoById(uint256 _plantId) public view returns(Plant memory) {
        return plants[_plantId];
    }

    // 获取市场上所有未被领养的植物的更多信息列表
    function getMarketListings()
        external
        view
        returns (MarketPlantInfo[] memory)
    {
        MarketPlantInfo[] memory marketListings = new MarketPlantInfo[](
            plantIdCounter
        );

        uint256 count = 0;
        for (uint256 i = 0; i < plantIdCounter; i++) {
            Plant storage plant = plants[i];
            if (!plant.isAdopted) {
                marketListings[count] = MarketPlantInfo({
                    plantId: i,
                    plantType: plant.plantType
                });
                count++;
            }
        }

        // Trim array to remove empty slots
        MarketPlantInfo[] memory trimmedListings = new MarketPlantInfo[](count);
        for (uint256 j = 0; j < count; j++) {
            trimmedListings[j] = marketListings[j];
        }

        return trimmedListings;
    }
}
