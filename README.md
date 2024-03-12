# Solidity API

## AuthorizedERC20

### UnauthorizedAccess

```solidity
error UnauthorizedAccess()
```

### ExceedsSupplyLimit

```solidity
error ExceedsSupplyLimit()
```

### OneTimeAuthorizationDone

```solidity
error OneTimeAuthorizationDone()
```

### constructor

```solidity
constructor(string name_, string symbol_) public
```

### mint

```solidity
function mint(address account, uint256 amount) external
```

仅允许授权的地址调用 mint 函数

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | account |
| amount | uint256 | amount |

### authorizeOnce

```solidity
function authorizeOnce(address minter) external
```

一次性授权地址调用 mint 函数

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minter | address | minter |

### mintableBalance

```solidity
function mintableBalance() external view returns (uint256)
```

查询还可以 mint 的余额

## PlantMarketV1

### BLAST

```solidity
contract IBlast BLAST
```

### PlantType

```solidity
enum PlantType {
  Seed,
  Seedling,
  VegetativeVariation,
  Vegetative,
  Flowering,
  Fruiting
}
```

### Plant

```solidity
struct Plant {
  uint256 plantId;
  enum PlantMarketV1.PlantType plantType;
  uint256 valueEth;
  uint256 adoptedTimestamp;
  address owner;
  bool isAdopted;
  bool isSplit;
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
  enum PlantMarketV1.PlantType plantType;
  uint256 minEth;
  uint256 maxEth;
}
```

### plants

```solidity
mapping(uint256 => struct PlantMarketV1.Plant) plants
```

### priceRanges

```solidity
mapping(enum PlantMarketV1.PlantType => struct PlantMarketV1.AdoptionPriceRange) priceRanges
```

### PlantAdopted

```solidity
event PlantAdopted(uint256 plantId, address owner, enum PlantMarketV1.PlantType plantType, uint256 adoptionTime)
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

### PlantAdoptedError

```solidity
error PlantAdoptedError()
```

### NotReachingContractTerm

```solidity
error NotReachingContractTerm()
```

### InvalidPlantType

```solidity
error InvalidPlantType()
```

### InsufficientTokens

```solidity
error InsufficientTokens()
```

### OnlyScheduleAdoptionOncePerDay

```solidity
error OnlyScheduleAdoptionOncePerDay()
```

### NoBalance

```solidity
error NoBalance()
```

### constructor

```solidity
constructor(address tokenContractAddress, address _pointsOperator) public
```

### scheduleAdoption

```solidity
function scheduleAdoption(enum PlantMarketV1.PlantType plantType) external
```

预约

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| plantType | enum PlantMarketV1.PlantType | PlantType |

### createPlant

```solidity
function createPlant(struct PlantMarketV1.PlantDTO newPlantDTO, address _owner) public
```

### adoptPlant

```solidity
function adoptPlant(uint256 _plantId) external payable
```

### _isAdoptionTimeValid

```solidity
function _isAdoptionTimeValid(enum PlantMarketV1.PlantType plantType) internal view returns (bool)
```

### list

```solidity
function list(uint256 plantId) public
```

### getLastPlantId

```solidity
function getLastPlantId() external view returns (uint256)
```

### getPlantInfoById

```solidity
function getPlantInfoById(uint256 _plantId) public view returns (uint256 plantId, enum PlantMarketV1.PlantType plantType, uint256 valueEth, uint256 adoptedTimestamp, address owner, bool isAdopted, bool isSplit)
```

### getUserAdoptionRecordPlantIds

```solidity
function getUserAdoptionRecordPlantIds(address _user) public view returns (uint256[])
```

获取用户曾经拥有的植物ID

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _user | address | 拥有者 |

### getUserAdoptedCurrentPlants

```solidity
function getUserAdoptedCurrentPlants(address _user, bool includeSplit) external view returns (struct PlantMarketV1.Plant[])
```

获取用户当前领养的植物

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _user | address | owner |
| includeSplit | bool | 是否分裂 |

### getMarketListings

```solidity
function getMarketListings() external view returns (struct PlantMarketV1.Plant[])
```

### claimMyContractsGas

```solidity
function claimMyContractsGas() external
```

### receive

```solidity
receive() external payable
```

### withdraw

```solidity
function withdraw() external
```

## IBlast

### configureClaimableGas

```solidity
function configureClaimableGas() external
```

### claimAllGas

```solidity
function claimAllGas(address contractAddress, address recipient) external returns (uint256)
```

## IBlastPoints

### configurePointsOperator

```solidity
function configurePointsOperator(address operator) external
```

