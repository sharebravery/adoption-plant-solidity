# Solidity API

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
  uint256 minEth;
  uint256 maxEth;
  uint8 startTime;
  uint8 endTime;
  uint256 adoptedTimestamp;
  uint8 profitDays;
  uint16 profitRate;
  address owner;
  bool isAdopted;
  bool hasSplit;
}
```

### PlantDTO

```solidity
struct PlantDTO {
  uint256 minEth;
  uint256 maxEth;
  uint8 startTime;
  uint8 endTime;
  enum PlantMarket.PlantType plantType;
  uint8 profitDays;
  uint16 profitRate;
}
```

### plants

```solidity
mapping(uint256 => struct PlantMarket.Plant) plants
```

### UserAdoptionRecord

```solidity
struct UserAdoptionRecord {
  uint256[] plantIds;
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
function createPlant(struct PlantMarket.PlantDTO plantDTO) external
```

### adoptPlant

```solidity
function adoptPlant(uint256 _plantId) external payable
```

### _isAdoptionTimeValid

```solidity
function _isAdoptionTimeValid(struct PlantMarket.Plant _plant) internal view returns (bool)
```

### autoSplitAndSettle

```solidity
function autoSplitAndSettle() public
```

达到收益天数自动结算，重新投入市场

### getUserAdoptionPlantIds

```solidity
function getUserAdoptionPlantIds(address _user) public view returns (uint256[])
```

查询用户曾经领养过的植物ID

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _user | address | 用户 |

### getUserAdoptionRecord

```solidity
function getUserAdoptionRecord(address _user, enum PlantMarket.PlantType _plantType) public view returns (uint256)
```

查询用户曾经领养某类植物次数

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _user | address | 用户 |
| _plantType | enum PlantMarket.PlantType | 植物类型 |

### getUserAdoptedPlants

```solidity
function getUserAdoptedPlants(address _user, bool includeSplit) external view returns (struct PlantMarket.Plant[])
```

查询用户当前已领养的植物

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _user | address | 用户地址 |
| includeSplit | bool | 是否查询已分裂的植物 |

### getPlantInfoById

```solidity
function getPlantInfoById(uint256 _plantId) public view returns (struct PlantMarket.Plant)
```

根据Id查询植物信息

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _plantId | uint256 | 植物ID |

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

