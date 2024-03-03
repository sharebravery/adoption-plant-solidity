// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./PlantERC20.sol";

contract PlantMarket is Ownable, ReentrancyGuard {
    using Address for address payable;

    PlantERC20 private _tokenContract;

    enum PlantType {
        Ordinary,
        SmallTree,
        MediumTree,
        HighTree,
        KingTree
    }

    struct Plant {
        uint256 plantId;
        PlantType plantType;
        uint256 valueEth;
        uint256 adoptedTimestamp;
        address owner;
        bool isAdopted;
        bool isSplit;
    }

    struct UserAdoptionRecord {
        uint256[] plantIds;
        mapping(PlantType => uint256) adoptionCount;
    }

    struct AdoptionPriceRange {
        uint256 minEth;
        uint256 maxEth;
        uint8 startTime;
        uint8 endTime;
        uint8 profitDays;
        uint16 profitRate;
        uint256 rewardAmounts;
    }

    struct PlantDTO {
        PlantType plantType;
        uint256 minEth;
        uint256 maxEth;
    }

    mapping(uint256 => Plant) public plants;
    mapping(address => UserAdoptionRecord) private userAdoptionRecords;
    uint256 private plantIdCounter;

    mapping(PlantType => AdoptionPriceRange) public priceRanges;

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

    error PlantIDOverflow();
    error TransferFailed();
    error PlantAlreadyAdopted();
    error PlantAlreadySplit();
    error InvalidAdoptionPrice();
    error NotAdoptionTime();
    error InvalidPlantID();
    error NotOwner();
    error PlantNotAdopted();
    error NotReachingContractTerm();
    error InvalidPlantType();

    constructor(address tokenContractAddress) Ownable(msg.sender) {
        _tokenContract = PlantERC20(tokenContractAddress);

        priceRanges[PlantType.Ordinary] = AdoptionPriceRange(
            0.005 ether,
            0.015 ether,
            7,
            23,
            7,
            21,
            1000
        );
        priceRanges[PlantType.SmallTree] = AdoptionPriceRange(
            0.0151 ether,
            0.045 ether,
            7,
            23,
            3,
            9,
            3000
        );
        priceRanges[PlantType.MediumTree] = AdoptionPriceRange(
            0.0451 ether,
            0.125 ether,
            7,
            23,
            5,
            13,
            5000
        );
        priceRanges[PlantType.HighTree] = AdoptionPriceRange(
            0.1251 ether,
            0.3 ether,
            7,
            23,
            12,
            21,
            10000
        );
        priceRanges[PlantType.KingTree] = AdoptionPriceRange(
            0.3001 ether,
            0.75 ether,
            7,
            23,
            20,
            40,
            20000
        );
    }

    function createPlant(PlantDTO memory newPlantDTO, address _owner) public {
        if (plantIdCounter >= type(uint256).max) {
            revert PlantIDOverflow();
        }
        AdoptionPriceRange memory rangeData = priceRanges[
            newPlantDTO.plantType
        ];
        Plant memory newPlant = Plant({
            plantId: plantIdCounter,
            valueEth: rangeData.minEth,
            // minEth: rangeData.minEth,
            // maxEth: rangeData.maxEth,
            // startTime: rangeData.startTime,
            // endTime: rangeData.endTime,
            adoptedTimestamp: 0,
            plantType: newPlantDTO.plantType,
            owner: _owner,
            isAdopted: false,
            isSplit: false
            // profitDays: rangeData.profitDays,
            // profitRate: rangeData.profitRate
        });
        plants[plantIdCounter] = newPlant;
        plantIdCounter++;

        emit PlantCreated(plantIdCounter, address(this), rangeData.minEth);
    }

    function adoptPlant(uint256 _plantId) external payable nonReentrant {
        Plant storage plant = plants[_plantId];

        _mintReward(plant.plantType, msg.sender);

        if (plant.isAdopted) {
            revert PlantAlreadyAdopted();
        }
        if (plant.isSplit) {
            revert PlantAlreadySplit();
        }
        if (
            msg.value < priceRanges[plant.plantType].minEth ||
            msg.value > priceRanges[plant.plantType].maxEth
        ) {
            revert InvalidAdoptionPrice();
        }
        if (!_isAdoptionTimeValid(plant.plantType)) {
            revert NotAdoptionTime();
        }

        (bool success, ) = payable(plant.owner).call{value: msg.value}("");
        if (!success) {
            revert TransferFailed();
        }

        plant.owner = msg.sender;
        plant.isAdopted = true;
        plant.adoptedTimestamp = block.timestamp;
        userAdoptionRecords[msg.sender].plantIds.push(_plantId);
        userAdoptionRecords[msg.sender].adoptionCount[plant.plantType]++;
        emit PlantAdopted(
            _plantId,
            msg.sender,
            plant.plantType,
            block.timestamp
        );
    }

    function _isAdoptionTimeValid(
        PlantType plantType
    ) internal view returns (bool) {
        uint256 currentHour = ((block.timestamp + 8 hours) / 3600) % 24;

        return
            currentHour >= priceRanges[plantType].startTime &&
            currentHour < priceRanges[plantType].endTime;
    }

    function _mintReward(PlantType plantType, address recipient) private {
        if (
            _tokenContract.mintableBalance() >=
            priceRanges[plantType].rewardAmounts * 10 ** 18
        ) {
            _tokenContract.mintFromMarket(
                recipient,
                priceRanges[plantType].rewardAmounts * 10 ** 18
            );
        }
    }

    function list(uint256 plantId) public {
        if (plantId > plantIdCounter) {
            revert InvalidPlantID();
        }

        Plant storage plant = plants[plantId];

        if (msg.sender != plant.owner) {
            revert NotOwner();
        }
        if (!plant.isAdopted) {
            revert PlantNotAdopted();
        }

        if (
            block.timestamp >=
            plant.adoptedTimestamp +
                priceRanges[plant.plantType].profitDays *
                60
        ) {
            revert NotReachingContractTerm();
            // plant.adoptedTimestamp + plant.profitDays * 1 hours
        }

        plant.valueEth =
            plant.valueEth +
            (plant.valueEth * priceRanges[plant.plantType].profitRate) /
            100;
        if (plant.valueEth > 0.75 ether) {
            _splitPlant(plant);
            plant.isSplit = true;
        } else {
            _settlePlant(plant);
            plant.isAdopted = false;
        }
        emit PlantListed(plantId, msg.sender, plant.valueEth);
    }

    function _splitPlant(Plant storage _plant) private {
        PlantType[] memory types = new PlantType[](5);
        types[0] = PlantType.Ordinary;
        types[1] = PlantType.SmallTree;
        types[2] = PlantType.MediumTree;
        types[3] = PlantType.HighTree;
        types[4] = PlantType.KingTree;

        uint256 totalEthFromPreviousPlants = 0;

        // 计算之前所有植物分裂出去的总和
        for (uint256 i = 0; i < types.length - 1; i++) {
            totalEthFromPreviousPlants += priceRanges[types[i]].minEth;

            // 创建新的植物实例
            PlantDTO memory newPlant = PlantDTO({
                plantType: types[i],
                minEth: priceRanges[types[i]].minEth,
                maxEth: priceRanges[types[i]].maxEth
            });

            createPlant(newPlant, _plant.owner);
        }

        // 剩余的 ETH 是当前植物的 minEth 减去之前所有植物分裂出去的总和
        uint256 remainingEth = _plant.valueEth - totalEthFromPreviousPlants;

        // 创建新的植物实例
        PlantDTO memory lastPlant = PlantDTO({
            plantType: PlantType.HighTree,
            minEth: remainingEth,
            maxEth: 0.3 ether
        });
        createPlant(lastPlant, _plant.owner);
    }

    function _settlePlant(Plant storage _plant) private {
        if (_plant.valueEth > 0.3001 ether && _plant.valueEth <= 0.75 ether) {
            _plant.plantType = PlantType.KingTree;
        } else if (
            _plant.valueEth > 0.1251 ether && _plant.valueEth <= 0.3 ether
        ) {
            _plant.plantType = PlantType.HighTree;
        } else if (
            _plant.valueEth > 0.0451 ether && _plant.valueEth <= 0.125 ether
        ) {
            _plant.plantType = PlantType.MediumTree;
        } else if (
            _plant.valueEth > 0.0151 ether && _plant.valueEth <= 0.045 ether
        ) {
            _plant.plantType = PlantType.SmallTree;
        } else if (
            _plant.valueEth >= 0.005 ether && _plant.valueEth <= 0.015 ether
        ) {
            _plant.plantType = PlantType.Ordinary;
        }
    }

    function getUserAdoptionPlantIds(
        address _user
    ) public view returns (uint256[] memory) {
        return userAdoptionRecords[_user].plantIds;
    }

    function getUserAdoptionRecord(
        address _user,
        PlantType _plantType
    ) public view returns (uint256) {
        if (
            _plantType < PlantType.Ordinary || _plantType > PlantType.KingTree
        ) {
            revert InvalidPlantType();
        }
        return userAdoptionRecords[_user].adoptionCount[_plantType];
    }

    function getUserAdoptedPlants(
        address _user,
        bool includeSplit
    ) external view returns (Plant[] memory) {
        uint256 userAdoptedCount = 0;
        Plant[] memory userAdoptedPlants = new Plant[](plantIdCounter);

        for (uint256 i = 0; i < plantIdCounter; i++) {
            Plant storage plant = plants[i];
            if (
                plant.owner == _user &&
                plant.isAdopted &&
                (includeSplit || plant.isSplit)
            ) {
                userAdoptedPlants[userAdoptedCount] = plant;
                userAdoptedCount++;
            }
        }
        // 返回修剪后的数组
        Plant[] memory trimmedListings = new Plant[](userAdoptedCount);
        for (uint256 j = 0; j < userAdoptedCount; j++) {
            trimmedListings[j] = userAdoptedPlants[j];
        }
        return trimmedListings;
    }

    function getPlantInfoById(
        uint256 _plantId
    ) public view returns (Plant memory) {
        return plants[_plantId];
    }

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
        Plant[] memory trimmedListings = new Plant[](count);
        for (uint256 j = 0; j < count; j++) {
            trimmedListings[j] = marketListings[j];
        }
        return trimmedListings;
    }
}
