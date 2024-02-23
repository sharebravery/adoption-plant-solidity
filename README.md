# Solidity API

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
mapping(enum PlantMarket.PlantType => struct PlantMarket.AdoptionPriceRange) priceRanges
```

### plants

```solidity
mapping(uint256 => struct PlantMarket.Plant) plants
```

### UserAdoptionRecord

```solidity
struct UserAdoptionRecord {
  mapping(enum PlantMarket.PlantType => uint256) adoptionCount;
}
```

### PlantAdopted

```solidity
event PlantAdopted(uint256 plantId, address owner, enum PlantMarket.PlantType plantType, uint256 adoptionTime)
```

### PlantListed

```solidity
event PlantListed(uint256 plantId, address seller, uint256 price)
```

### PlantSold

```solidity
event PlantSold(uint256 plantId, address buyer, address seller, uint256 price)
```

### MarketPlantInfo

```solidity
struct MarketPlantInfo {
  uint256 plantId;
  enum PlantMarket.PlantType plantType;
}
```

### constructor

```solidity
constructor() public
```

### createPlant

```solidity
function createPlant(enum PlantMarket.PlantType _plantType) external
```

### adoptPlant

```solidity
function adoptPlant(uint256 _plantId) external payable
```

### getUserAdoptionRecord

```solidity
function getUserAdoptionRecord(address _user, enum PlantMarket.PlantType _plantType) external view returns (uint256)
```

### _isAdoptionTimeValid

```solidity
function _isAdoptionTimeValid(enum PlantMarket.PlantType _plantType) internal view returns (bool)
```

### getPlantInfoById

```solidity
function getPlantInfoById(uint256 _plantId) public view returns (struct PlantMarket.Plant)
```

### getMarketListings

```solidity
function getMarketListings() external view returns (struct PlantMarket.MarketPlantInfo[])
```

