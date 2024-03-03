# Solidity API

## PlantERC20

### UnauthorizedAccess

```solidity
error UnauthorizedAccess()
```

### ExceedsSupplyLimit

```solidity
error ExceedsSupplyLimit()
```

### constructor

```solidity
constructor() public
```

### mintFromMarket

```solidity
function mintFromMarket(address account, uint256 amount) external
```

### setPlantMarketContract

```solidity
function setPlantMarketContract(address plantMarketContract) external
```

### mintableBalance

```solidity
function mintableBalance() external view returns (uint256)
```

## PlantMarket

### PlantType

```solidity
enum PlantType {
  Ordinary,
  SmallTree,
  MediumTree,
  HighTree,
  KingTree
}
```

### Plant

```solidity
struct Plant {
  uint256 plantId;
  enum PlantMarket.PlantType plantType;
  uint256 valueEth;
  uint256 adoptedTimestamp;
  address owner;
  bool isAdopted;
  bool isSplit;
}
```

### UserAdoptionRecord

```solidity
struct UserAdoptionRecord {
  uint256[] plantIds;
  mapping(enum PlantMarket.PlantType => uint256) adoptionCount;
}
```

### AdoptionPriceRange

```solidity
struct AdoptionPriceRange {
  uint256 minEth;
  uint256 maxEth;
  uint8 startTime;
  uint8 endTime;
  uint8 profitDays;
  uint16 profitRate;
  uint256 rewardAmounts;
}
```

### PlantDTO

```solidity
struct PlantDTO {
  enum PlantMarket.PlantType plantType;
  uint256 minEth;
  uint256 maxEth;
}
```

### plants

```solidity
mapping(uint256 => struct PlantMarket.Plant) plants
```

### priceRanges

```solidity
mapping(enum PlantMarket.PlantType => struct PlantMarket.AdoptionPriceRange) priceRanges
```

### PlantAdopted

```solidity
event PlantAdopted(uint256 plantId, address owner, enum PlantMarket.PlantType plantType, uint256 adoptionTime)
```

### PlantCreated

```solidity
event PlantCreated(uint256 plantId, address seller, uint256 price)
```

### PlantListed

```solidity
event PlantListed(uint256 plantId, address seller, uint256 price)
```

### PlantSold

```solidity
event PlantSold(uint256 plantId, address buyer, address seller, uint256 price)
```

### PlantIDOverflow

```solidity
error PlantIDOverflow()
```

### TransferFailed

```solidity
error TransferFailed()
```

### PlantAlreadyAdopted

```solidity
error PlantAlreadyAdopted()
```

### PlantAlreadySplit

```solidity
error PlantAlreadySplit()
```

### InvalidAdoptionPrice

```solidity
error InvalidAdoptionPrice()
```

### NotAdoptionTime

```solidity
error NotAdoptionTime()
```

### InvalidPlantID

```solidity
error InvalidPlantID()
```

### NotOwner

```solidity
error NotOwner()
```

### PlantNotAdopted

```solidity
error PlantNotAdopted()
```

### NotReachingContractTerm

```solidity
error NotReachingContractTerm()
```

### InvalidPlantType

```solidity
error InvalidPlantType()
```

### constructor

```solidity
constructor(address tokenContractAddress) public
```

### createPlant

```solidity
function createPlant(struct PlantMarket.PlantDTO newPlantDTO, address _owner) public
```

### adoptPlant

```solidity
function adoptPlant(uint256 _plantId) external payable
```

### _isAdoptionTimeValid

```solidity
function _isAdoptionTimeValid(enum PlantMarket.PlantType plantType) internal view returns (bool)
```

### list

```solidity
function list(uint256 plantId) public
```

### getUserAdoptionPlantIds

```solidity
function getUserAdoptionPlantIds(address _user) public view returns (uint256[])
```

### getUserAdoptionRecord

```solidity
function getUserAdoptionRecord(address _user, enum PlantMarket.PlantType _plantType) public view returns (uint256)
```

### getUserAdoptedPlants

```solidity
function getUserAdoptedPlants(address _user, bool includeSplit) external view returns (struct PlantMarket.Plant[])
```

### getPlantInfoById

```solidity
function getPlantInfoById(uint256 _plantId) public view returns (struct PlantMarket.Plant)
```

### getMarketListings

```solidity
function getMarketListings() external view returns (struct PlantMarket.Plant[])
```

## PlantAdoption

### PlantType

```solidity
enum PlantType {
  Ordinary,
  SmallTree,
  MediumTree,
  HighTree,
  KingTree
}
```

### Plant

```solidity
struct Plant {
  uint256 adoptionTime;
  uint256 endTime;
  enum PlantAdoption.PlantType plantType;
  address owner;
  bool isAdopted;
}
```

### AdoptionPriceRange

```solidity
struct AdoptionPriceRange {
  uint256 minEth;
  uint256 maxEth;
  uint256 startTime;
  uint256 endTime;
  uint256 profitDays;
  uint256 profitRate;
}
```

### priceRanges

```solidity
mapping(enum PlantAdoption.PlantType => struct PlantAdoption.AdoptionPriceRange) priceRanges
```

### plants

```solidity
mapping(uint256 => struct PlantAdoption.Plant) plants
```

### reservedUsers

```solidity
mapping(enum PlantAdoption.PlantType => address[]) reservedUsers
```

### userReservations

```solidity
mapping(enum PlantAdoption.PlantType => mapping(address => bool)) userReservations
```

### PlantAdopted

```solidity
event PlantAdopted(uint256 plantId, address owner, enum PlantAdoption.PlantType plantType, uint256 adoptionTime, uint256 endTime)
```

### constructor

```solidity
constructor() public
```

### transferPlantOwnership

```solidity
function transferPlantOwnership(uint256 _plantId, address _newOwner) external
```

### adoptPlant

```solidity
function adoptPlant(enum PlantAdoption.PlantType _plantType) external payable
```

### _transferPlantOwnership

```solidity
function _transferPlantOwnership(uint256 _plantId, address _newOwner) internal
```

### reservePlant

```solidity
function reservePlant(enum PlantAdoption.PlantType _plantType) external
```

### _getReservedUser

```solidity
function _getReservedUser(enum PlantAdoption.PlantType _plantType) internal view returns (address)
```

### _assignPlantToUser

```solidity
function _assignPlantToUser(address _user, enum PlantAdoption.PlantType _plantType) internal
```

### _isAdoptionTimeValid

```solidity
function _isAdoptionTimeValid(enum PlantAdoption.PlantType _plantType) internal view returns (bool)
```

### withdrawEth

```solidity
function withdrawEth() external
```

