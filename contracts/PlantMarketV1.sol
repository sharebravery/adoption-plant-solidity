// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./AuthorizedERC20.sol";

contract PlantMarketV1 is Ownable, ReentrancyGuard {
    using Address for address payable;

    AuthorizedERC20 private _tokenContract;

    enum PlantType {
        Seed,
        Seedling,
        VegetativeVariation,
        Vegetative,
        Flowering,
        Fruiting
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

    mapping(PlantType => uint256[]) private typeHavePlantIdsInMarket; // 用来标识市场是否有某类型的植物 不作他用

    mapping(uint256 => Plant) public plants;
    mapping(address => uint256[]) private userAdoptionPlantIds;
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
    error PlantAdoptedError();
    error NotReachingContractTerm();
    error InvalidPlantType();
    error InsufficientTokens();
    error OnlyScheduleAdoptionOncePerDay();

    // error MarketNoHavedThePlant();

    constructor(address tokenContractAddress) Ownable(msg.sender) {
        _tokenContract = AuthorizedERC20(tokenContractAddress);

        priceRanges[PlantType.Seed] = AdoptionPriceRange(
            0.005 ether,
            0.015 ether,
            14,
            15,
            7,
            2100,
            1000
        );
        priceRanges[PlantType.Seedling] = AdoptionPriceRange(
            0.0151 ether,
            0.045 ether,
            15,
            16,
            3,
            900,
            3000
        );
        priceRanges[PlantType.VegetativeVariation] = AdoptionPriceRange(
            0.0451 ether,
            0.125 ether,
            20,
            21,
            1,
            500,
            5000
        );
        priceRanges[PlantType.Vegetative] = AdoptionPriceRange(
            0.0451 ether,
            0.125 ether,
            16,
            17,
            5,
            1250,
            5000
        );
        priceRanges[PlantType.Flowering] = AdoptionPriceRange(
            0.1251 ether,
            0.3 ether,
            18,
            17,
            18,
            2100,
            10000
        );
        priceRanges[PlantType.Fruiting] = AdoptionPriceRange(
            0.3001 ether,
            0.75 ether,
            18,
            19,
            20,
            4000,
            20000
        );
    }

    /**
     * 预约
     * @param plantType PlantType
     */
    function scheduleAdoption(PlantType plantType) external {
        uint256 amount = typeHavePlantIdsInMarket[plantType].length == 0
            ? 1000
            : priceRanges[plantType].rewardAmounts;

        if (_tokenContract.mintableBalance() >= amount * 10 ** 18) {
            _tokenContract.mint(msg.sender, amount * 10 ** 18);
        }
    }

    function createPlant(
        PlantDTO memory newPlantDTO,
        address _owner
    ) public onlyOwner {
        AdoptionPriceRange memory rangeData = priceRanges[
            newPlantDTO.plantType
        ];
        Plant memory newPlant = Plant({
            plantId: plantIdCounter,
            valueEth: rangeData.minEth,
            adoptedTimestamp: 0,
            plantType: newPlantDTO.plantType,
            owner: _owner,
            isAdopted: false,
            isSplit: false
        });
        plants[plantIdCounter] = newPlant;
        typeHavePlantIdsInMarket[newPlantDTO.plantType].push(plantIdCounter);
        plantIdCounter++;

        emit PlantCreated(plantIdCounter, address(this), rangeData.minEth);
    }

    function adoptPlant(uint256 _plantId) external payable nonReentrant {
        Plant storage plant = plants[_plantId];

        // Ensure the plant is not already adopted or split
        if (plant.isAdopted) {
            revert PlantAlreadyAdopted();
        }
        if (plant.isSplit) {
            revert PlantAlreadySplit();
        }

        // Ensure the adoption price is within the valid range
        if (
            msg.value < priceRanges[plant.plantType].minEth ||
            msg.value > priceRanges[plant.plantType].maxEth
        ) {
            revert InvalidAdoptionPrice();
        }

        // Check if it's the right time for adoption
        if (!_isAdoptionTimeValid(plant.plantType)) {
            revert NotAdoptionTime();
        }

        // Calculate the amount of tokens to burn based on the adoption price
        uint256 tokenAmountToBurn = (
            priceRanges[plant.plantType].rewardAmounts
        ) * 10 ** 18;

        // Ensure the user has enough tokens to adopt
        if (_tokenContract.balanceOf(msg.sender) < tokenAmountToBurn) {
            revert InsufficientTokens();
        }

        // Burn the required tokens from the user's balance
        _tokenContract.burnFrom(msg.sender, tokenAmountToBurn);

        // Transfer the adoption payment to the plant owner
        (bool success, ) = payable(plant.owner).call{value: msg.value}("");
        if (!success) {
            revert TransferFailed();
        }

        // Update plant adoption status and user records
        plant.owner = msg.sender;
        plant.isAdopted = true;
        typeHavePlantIdsInMarket[plant.plantType].pop();
        plant.adoptedTimestamp = block.timestamp;

        userAdoptionPlantIds[msg.sender].push(_plantId);

        // Emit event
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
            block.timestamp <
            plant.adoptedTimestamp +
                uint256(priceRanges[plant.plantType].profitDays)
        ) {
            revert NotReachingContractTerm();
            // plant.adoptedTimestamp + plant.profitDays * 1 hours
        }

        plant.valueEth =
            plant.valueEth +
            (plant.valueEth * priceRanges[plant.plantType].profitRate) /
            10000;

        if (plant.valueEth > 0.75 ether) {
            _splitPlant(plant);
            plant.isSplit = true;
        } else {
            _settlePlant(plant);
            plant.isAdopted = false;
            typeHavePlantIdsInMarket[plant.plantType].push(plant.plantId);
        }
        emit PlantListed(plantId, msg.sender, plant.valueEth);
    }

    function _splitPlant(Plant storage _plant) private {
        PlantType[] memory types = new PlantType[](6);
        types[0] = PlantType.Seed;
        types[1] = PlantType.Seedling;
        types[2] = PlantType.VegetativeVariation;
        types[3] = PlantType.Vegetative;
        types[4] = PlantType.Flowering;
        types[5] = PlantType.Fruiting;

        uint256 totalEthFromPreviousPlants = 0;

        // 计算之前所有植物分裂出去的总和
        for (uint256 i = 0; i < types.length; i++) {
            totalEthFromPreviousPlants += priceRanges[types[i]].minEth;

            PlantDTO memory newPlant = PlantDTO({
                plantType: types[i],
                minEth: priceRanges[types[i]].minEth,
                maxEth: priceRanges[types[i]].maxEth
            });

            createPlant(newPlant, _plant.owner);
        }

        PlantDTO memory vPlant1 = PlantDTO({
            plantType: PlantType.VegetativeVariation,
            minEth: priceRanges[PlantType.Flowering].minEth,
            maxEth: priceRanges[PlantType.Flowering].maxEth
        });

        PlantDTO memory vPlant2 = PlantDTO({
            plantType: PlantType.VegetativeVariation,
            minEth: priceRanges[PlantType.Flowering].minEth,
            maxEth: priceRanges[PlantType.Flowering].maxEth
        });

        // 剩余的 ETH 是当前植物的 minEth 减去之前所有植物分裂出去的总和
        uint256 remainingEth = _plant.valueEth -
            totalEthFromPreviousPlants -
            priceRanges[PlantType.VegetativeVariation].minEth *
            2;

        createPlant(vPlant1, _plant.owner);
        createPlant(vPlant2, _plant.owner);

        PlantDTO memory lastPlant = PlantDTO({
            plantType: PlantType.Flowering,
            minEth: remainingEth,
            maxEth: priceRanges[PlantType.Flowering].maxEth
        });

        createPlant(lastPlant, _plant.owner);
        _settlePlant(plants[plantIdCounter - 1]);
        plants[plantIdCounter - 1].valueEth = remainingEth;
    }

    function _settlePlant(Plant storage _plant) private {
        if (_plant.valueEth > 0.3001 ether && _plant.valueEth <= 0.75 ether) {
            _plant.plantType = PlantType.Fruiting;
        } else if (
            _plant.valueEth > 0.1251 ether && _plant.valueEth <= 0.3 ether
        ) {
            _plant.plantType = PlantType.Flowering;
        } else if (
            _plant.valueEth > 0.0451 ether && _plant.valueEth <= 0.125 ether
        ) {
            if (_plant.plantType != PlantType.VegetativeVariation) {
                _plant.plantType = PlantType.Vegetative;
            }
        } else if (
            _plant.valueEth > 0.0151 ether && _plant.valueEth <= 0.045 ether
        ) {
            _plant.plantType = PlantType.Seedling;
        } else if (
            _plant.valueEth >= 0.005 ether && _plant.valueEth <= 0.015 ether
        ) {
            _plant.plantType = PlantType.Seed;
        }
    }

    function getLastPlantId() external view returns (uint256) {
        return plantIdCounter;
    }

    function getPlantInfoById(
        uint256 _plantId
    )
        public
        view
        returns (
            uint256 plantId,
            PlantType plantType,
            uint256 valueEth,
            uint256 adoptedTimestamp,
            address owner,
            bool isAdopted,
            bool isSplit
        )
    {
        require(_plantId < plantIdCounter, "Invalid plant ID");

        Plant memory plant = plants[_plantId];
        return (
            plant.plantId,
            plant.plantType,
            plant.valueEth,
            plant.adoptedTimestamp,
            plant.owner,
            plant.isAdopted,
            plant.isSplit
        );
    }

    /**
     * 获取用户曾经拥有的植物ID
     * @param _user 拥有者
     */
    function getUserAdoptionRecordPlantIds(
        address _user
    ) public view returns (uint256[] memory) {
        return userAdoptionPlantIds[_user];
    }

    /**
     * 获取用户当前领养的植物
     * @param _user owner
     * @param includeSplit 是否分裂
     */
    function getUserAdoptedCurrentPlants(
        address _user,
        bool includeSplit
    ) external view returns (Plant[] memory) {
        uint256 userAdoptedCount = 0;
        for (uint256 i = 0; i < plantIdCounter; i++) {
            Plant storage plant = plants[i];
            if (
                plant.owner == _user &&
                plant.isAdopted &&
                (includeSplit ? plant.isSplit : !plant.isSplit) // 根据 includeSplit 参数筛选已分裂或未分裂的数据
            ) {
                userAdoptedCount++;
            }
        }
        Plant[] memory userAdoptedPlants = new Plant[](userAdoptedCount);
        uint256 index = 0;
        for (uint256 j = 0; j < plantIdCounter; j++) {
            Plant storage plant = plants[j];
            if (
                plant.owner == _user &&
                plant.isAdopted &&
                (includeSplit ? plant.isSplit : !plant.isSplit) // 根据 includeSplit 参数筛选已分裂或未分裂的数据
            ) {
                userAdoptedPlants[index] = plant;
                index++;
            }
        }
        return userAdoptedPlants;
    }

    function getMarketListings() external view returns (Plant[] memory) {
        uint256 marketCount = 0;
        for (uint256 i = 0; i < plantIdCounter; i++) {
            Plant storage plant = plants[i];
            if (!plant.isAdopted) {
                marketCount++;
            }
        }
        Plant[] memory marketListings = new Plant[](marketCount);
        uint256 index = 0;
        for (uint256 j = 0; j < plantIdCounter; j++) {
            Plant storage plant = plants[j];
            if (!plant.isAdopted) {
                marketListings[index] = plant;
                index++;
            }
        }
        return marketListings;
    }
}
