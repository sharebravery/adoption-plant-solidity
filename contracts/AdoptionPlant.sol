// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PlantAdoption is Ownable, ReentrancyGuard {
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

    // 植物类型 => 预约用户列表
    mapping(PlantType => address[]) public reservedUsers;

    // 用户预约抢购记录
    mapping(PlantType => mapping(address => bool)) public userReservations;

    // 植物 ID 计数器
    uint256 private plantIdCounter;

    // 事件
    event PlantAdopted(
        uint256 indexed plantId,
        address indexed owner,
        PlantType plantType,
        uint256 adoptionTime,
        uint256 endTime
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

    // 领养植物
    function adoptPlant(PlantType _plantType) external payable nonReentrant {
        // 检查领养价格范围和领养时间
        require(
            msg.value >= priceRanges[_plantType].minEth &&
                msg.value <= priceRanges[_plantType].maxEth,
            "Invalid adoption price"
        );
        require(_isAdoptionTimeValid(_plantType), "Not adoption time");

        // 如果用户已预约抢购，则直接把树分配给预约的用户
        address reservedUser = _getReservedUser(_plantType);
        if (reservedUser != address(0)) {
            _assignPlantToUser(reservedUser, _plantType);
            return;
        }

        // 创建植物实例
        Plant memory newPlant = Plant({
            adoptionTime: block.timestamp,
            endTime: block.timestamp +
                priceRanges[_plantType].profitDays *
                1 days,
            plantType: _plantType,
            owner: msg.sender,
            isAdopted: true
        });

        // 存储植物实例
        plants[plantIdCounter] = newPlant;

        // 更新植物 ID 计数器
        plantIdCounter++;

        // 触发事件
        emit PlantAdopted(
            plantIdCounter,
            msg.sender,
            _plantType,
            newPlant.adoptionTime,
            newPlant.endTime
        );
    }

    // 用户预约抢购树
    function reservePlant(PlantType _plantType) external {
        require(!_isAdoptionTimeValid(_plantType), "It's adoption time");
        require(
            !userReservations[_plantType][msg.sender],
            "You have already reserved this plant type"
        );

        // 添加用户到预约列表
        reservedUsers[_plantType].push(msg.sender);
        userReservations[_plantType][msg.sender] = true;
    }

    // 获取已预约抢购的用户
    function _getReservedUser(
        PlantType _plantType
    ) internal view returns (address) {
        // 获取该植物类型的预约用户列表
        address[] storage reservedUsers = reservedUsers[_plantType];
        uint256 numberOfUsers = reservedUsers.length;

        if (numberOfUsers > 0) {
            // 生成一个随机数，确定选择哪个预约用户
            uint256 randomNumber = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        blockhash(block.number - 1)
                    )
                )
            );
            uint256 index = randomNumber % numberOfUsers;

            // 返回选中的预约用户地址
            return reservedUsers[index];
        } else {
            // 没有预约用户，返回地址(0)
            return address(0);
        }
    }

    // 将植物分配给用户
    function _assignPlantToUser(address _user, PlantType _plantType) internal {
        // 创建植物实例
        Plant memory newPlant = Plant({
            adoptionTime: block.timestamp,
            endTime: block.timestamp +
                priceRanges[_plantType].profitDays *
                1 days,
            plantType: _plantType,
            owner: _user,
            isAdopted: true
        });

        // 存储植物实例
        plants[plantIdCounter] = newPlant;

        // 更新植物 ID 计数器
        plantIdCounter++;

        // 触发事件
        emit PlantAdopted(
            plantIdCounter,
            _user,
            _plantType,
            newPlant.adoptionTime,
            newPlant.endTime
        );
    }

    // 检查领养时间是否有效
    function _isAdoptionTimeValid(
        PlantType _plantType
    ) internal view returns (bool) {
        uint256 currentHour = (block.timestamp / 3600) % 24;
        uint256 startTime = priceRanges[_plantType].startTime;
        uint256 endTime = priceRanges[_plantType].endTime;

        return currentHour >= startTime && currentHour < endTime;
    }

    // 取回合约中的 ETH
    function withdrawEth() external onlyOwner {
        payable(owner()).sendValue(address(this).balance);
    }
}
