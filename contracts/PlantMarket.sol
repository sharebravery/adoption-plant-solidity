// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./PlantERC20.sol";

contract PlantMarket is Ownable, ReentrancyGuard {
    using Address for address payable;

    PlantERC20 private _tokenContract; // 代币合约实例

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
        PlantType plantType; // 植物种类
        uint256 minEth; // 最小领养价格（单位：以太）
        uint256 maxEth; // 最大领养价格（单位：以太）
        uint8 startTime; // 开始时间 hour
        uint8 endTime; // 结束时间 hour
        uint256 adoptedTimestamp; // 领养时间 时间戳
        uint8 profitDays; // 收益天数
        uint16 profitRate; // 收益率（单位：百分比）
        address owner; // 拥有者地址
        bool isAdopted; // 是否被领养
        bool isSplit; // 用于标记植物是否已经分裂
    }

    struct PlantDTO {
        uint256 minEth; // 最小领养价格（单位：以太）
        uint256 maxEth; // 最大领养价格（单位：以太）
        uint8 startTime; // 领养时间 hour
        uint8 endTime; // 结束时间 hour
        PlantType plantType; // 植物种类
        uint8 profitDays; // 收益天数
        uint16 profitRate; // 收益率（单位：百分比）
    }

    // 植物实例
    mapping(uint256 => Plant) public plants;

    // 用户领养记录
    struct UserAdoptionRecord {
        uint256[] plantIds;
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
    );

    event PlantCreated(
        uint256 indexed plantId,
        address indexed seller,
        uint256 price
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

    constructor(address tokenContractAddress) Ownable(msg.sender) {
        _tokenContract = PlantERC20(tokenContractAddress); // 初始化代币合约实例
    }

    // 官方创建植物到市场
    function createPlant(PlantDTO memory plantDTO) external {
    // function createPlant(PlantDTO memory plantDTO) external onlyOwner {
        _createPlant(plantDTO, owner());
    }

    function _createPlant(PlantDTO memory plantDTO, address _owner) private {
        require(plantIdCounter < type(uint256).max, "Plant ID overflow");

        // 创建植物实例
        Plant memory newPlant = Plant({
            plantId: plantIdCounter,
            minEth: plantDTO.minEth,
            maxEth: plantDTO.maxEth,
            startTime: plantDTO.startTime,
            endTime: plantDTO.endTime,
            adoptedTimestamp: 0,
            plantType: plantDTO.plantType,
            owner: _owner, // 植物所有权归市场合约
            isAdopted: false,
            isSplit: false,
            profitDays: plantDTO.profitDays, // 收益天数
            profitRate: plantDTO.profitRate
        });

        // 存储植物实例
        plants[plantIdCounter] = newPlant;

        // 更新植物 ID 计数器
        plantIdCounter++;

        // 触发事件
        emit PlantCreated(plantIdCounter, address(this), plantDTO.minEth);
    }

      /**
       * 领养植物
       * @param _plantId 植物id
       */
        function adoptPlant(uint256 _plantId) external payable nonReentrant {
            Plant storage plant = plants[_plantId];

            // 发放代币奖励
            _mintReward(msg.sender);

            // 检查领养价格范围和领养时间
            require(!plant.isAdopted, "Plant is already adopted");
            require(!plant.isSplit, "Plant is already split");
            require(
                msg.value >= plant.minEth && msg.value <= plant.maxEth,
                "Invalid adoption price"
            );
            require(_isAdoptionTimeValid(plant), "Not adoption time");


            // // 转移支付金额给植物所有者
            // payable(plant.owner).sendValue(msg.value);
            (bool success, ) = payable(plant.owner).call{value: msg.value}("");
            require(success, "Transfer failed");    

            // 将植物所有者更改为领养者
            plant.owner = msg.sender;

            // 更新植物信息
            plant.isAdopted = true;

            plant.adoptedTimestamp = block.timestamp;

            // 更新用户领养记录
            userAdoptionRecords[msg.sender].plantIds.push(_plantId);
            userAdoptionRecords[msg.sender].adoptionCount[plant.plantType]++;

            // 触发事件
            emit PlantAdopted(
                _plantId,
                msg.sender,
                plant.plantType,
                block.timestamp
            );

        }

    // 检查领养时间是否有效
    function _isAdoptionTimeValid(Plant memory _plant)
        internal
        view
        returns (bool)
    {
        uint256 currentHour = ((block.timestamp + 8 hours) / 3600) % 24;
        uint256 startTime = _plant.startTime;
        uint256 endTime = _plant.endTime;

        return currentHour >= startTime && currentHour < endTime;
    }

     // 发放代币奖励
    function _mintReward(address recipient) private {
        // 每次领养植物发放的代币数量，你可以根据实际情况调整
        uint256 amount = 1000 * 10 ** 18; // 假设发放 1000 个代币

        // 确认代币余额充足
        if (_tokenContract.balanceOf(address(this)) >= amount) {
            // 调用代币合约的 mint 函数进行代币增发
            _tokenContract.mint(recipient, amount);
        }
    }

    /**
     * 用户自行挂单
     * @param plantId 植物ID
     */
   function list(uint256 plantId) public {
    require(plantId < plantIdCounter, "Invalid plant ID");

    Plant storage plant = plants[plantId];

    require(msg.sender == plant.owner, "Not owner");
    require(plant.isAdopted, "Plant is not adopted");
    require(!(block.timestamp >= 
        plant.adoptedTimestamp + 2 * 60),"Not reaching the contract term");
         // plant.adoptedTimestamp + plant.profitDays * 1 hours
 
        // 结算 更新每种新树的属性，如领养价格范围和收益率等
        plant.minEth =
            plant.minEth +
            (plant.minEth * plant.profitRate) / 100;

        if (plant.minEth > 0.75 ether) {
            _splitPlant(plant);
            plant.isSplit = true; // 确认分裂完毕
        } else {
            _settlePlant(plant);
            plant.isAdopted = false; // 生长完毕重新投入市场
        }

      emit PlantListed(plantId, msg.sender, plant.minEth);
}


    function _splitPlant(Plant storage _plant) private {
        // 分裂逻辑
        // 创建6种新树并更新其属性

        PlantDTO[] memory newPlants = new PlantDTO[](6);

        newPlants[0] = PlantDTO({
            minEth: 0.005 ether,
            maxEth: 0.015 ether,
            startTime: 14,
            endTime: 15,
            plantType: PlantType.Ordinary,
            profitDays: 7, // 收益天数
            profitRate: 2100
        });

        newPlants[1] = PlantDTO({
            minEth: 0.0151 ether,
            maxEth: 0.045 ether,
            startTime: 15,
            endTime: 16,
            plantType: PlantType.SmallTree,
            profitDays: 3, // 收益天数
            profitRate: 900
        });

        newPlants[2] = PlantDTO({
            minEth: 0.0451 ether,
            maxEth: 0.125 ether,
            startTime: 16,
            endTime: 17,
            plantType: PlantType.MediumTree,
            profitDays: 5, // 收益天数
            profitRate: 1250
        });

        newPlants[3] = PlantDTO({
            minEth: 0.1251 ether,
            maxEth: 0.3 ether,
            startTime: 17,
            endTime: 18,
            plantType: PlantType.HighTree,
            profitDays: 12, // 收益天数
            profitRate: 2100
        });

        newPlants[4] = PlantDTO({
            minEth: 0.3001 ether,
            maxEth: 0.75 ether,
            startTime: 18,
            endTime: 19,
            plantType: PlantType.KingTree,
            profitDays: 20, // 收益天数
            profitRate: 4000
        });

        newPlants[5] = PlantDTO({
            minEth: _plant.minEth -
                newPlants[0].minEth -
                newPlants[1].minEth -
                newPlants[2].minEth -
                newPlants[3].minEth -
                newPlants[4].minEth,
            maxEth: 0.3 ether,
            startTime: 17,
            endTime: 18,
            plantType: PlantType.HighTree,
            profitDays: 7,
            profitRate: 2100
        });

        for (uint256 i = 0; i < newPlants.length; i++) {
            plantIdCounter++;
            _createPlant(newPlants[i], _plant.owner);
        }
    }

    function _settlePlant(Plant storage _plant) private {
        // 结算逻辑
        // 根据不同的阈值生长升级植物类型
        if (_plant.minEth > 0.3001 ether && _plant.minEth <= 0.75 ether) {
            _plant.plantType = PlantType.KingTree;
        } else if (_plant.minEth > 0.1251 ether && _plant.minEth <= 0.3 ether) {
            _plant.plantType = PlantType.HighTree;
        } else if (
            _plant.minEth > 0.0451 ether && _plant.minEth <= 0.125 ether
        ) {
            _plant.plantType = PlantType.MediumTree;
        } else if (
            _plant.minEth > 0.0151 ether && _plant.minEth <= 0.045 ether
        ) {
            _plant.plantType = PlantType.SmallTree;
        } else if (
            _plant.minEth >= 0.005 ether && _plant.minEth <= 0.015 ether
        ) {
            _plant.plantType = PlantType.Ordinary;
        }
    }

    /**
     * 查询用户曾经领养过的植物ID
     * @param _user 用户
     */
    function getUserAdoptionPlantIds(address _user)
        public
        view
        returns (uint256[] memory)
    {
        return userAdoptionRecords[_user].plantIds;
    }

    /**
     * 查询用户曾经领养某类植物次数
     * @param _user 用户
     * @param _plantType 植物类型
     */
    function getUserAdoptionRecord(address _user, PlantType _plantType)
        public
        view
        returns (uint256)
    {
        require(
            _plantType >= PlantType.Ordinary &&
                _plantType <= PlantType.KingTree,
            "Invalid plant type"
        );
        return userAdoptionRecords[_user].adoptionCount[_plantType];
    }

    /**
     * 查询用户当前已领养的植物
     * @param _user 用户地址
     * @param includeSplit 是否查询已分裂的植物
     */
    function getUserAdoptedPlants(address _user, bool includeSplit)
        external
        view
        returns (Plant[] memory)
    {
        uint256 userAdoptedCount = 0;

        // 计算用户领养的植物数量
        for (uint256 i = 0; i < plantIdCounter; i++) {
            Plant storage plant = plants[i];
            if (plant.owner == _user && plant.isAdopted && (includeSplit || plant.isSplit)) {
                userAdoptedCount++;
            }
        }

        // 创建用户已领养植物信息列表
        Plant[] memory userAdoptedPlants = new Plant[](userAdoptedCount);
        uint256 index = 0;
        for (uint256 j = 0; j < plantIdCounter; j++) {
            Plant storage plant = plants[j];
            if (plant.owner == _user && plant.isAdopted && (includeSplit || plant.isSplit)) {
                userAdoptedPlants[index] = plant;
                index++;
            }
        }

        return userAdoptedPlants;
    }

    /**
     * 根据Id查询植物信息
     * @param _plantId 植物ID
     */
    function getPlantInfoById(uint256 _plantId)
        public
        view
        returns (Plant memory)
    {
        return plants[_plantId];
    }

    // 获取市场上所有未被领养的植物的更多信息列表
    function getMarketListings() external view returns (Plant[] memory) {
        Plant[] memory marketListings = new Plant[](plantIdCounter);

        uint256 count = 0;
        for (uint256 i = 0; i < plantIdCounter; i++) {
            Plant storage plant = plants[i];
            if (!plant.isAdopted) {
                marketListings[count] = plant;
                count++;
            }
        }

        // Trim array to remove empty slots
        Plant[] memory trimmedListings = new Plant[](count);
        for (uint256 j = 0; j < count; j++) {
            trimmedListings[j] = marketListings[j];
        }

        return trimmedListings;
    }
}
