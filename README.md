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

### adoptPlant

```solidity
function adoptPlant(enum PlantAdoption.PlantType _plantType) external payable
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

