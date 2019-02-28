pragma solidity >=0.4.24;
contract MapOwner{
    address public manager; // address of admin
    address public CEO;
    address public CTO;
    address public SFC; // address of Skull Fighting contract
    event TransferOwnership(address indexed _oldManager, address indexed _newManager);
    event SetNewSFC(address _oldSFC, address _newSFC);

    modifier onlyManager() {
        require(msg.sender == manager
        || msg.sender == SFC
        || msg.sender == CEO
        || msg.sender == CTO);
        _;
    }

    constructor() public {
        manager = msg.sender;
        CEO = msg.sender;
        CTO = msg.sender;
    }

    // transfer ownership of contract to new address
    function transferOwnership(address _newManager) external onlyManager returns (bool) {
        require(_newManager != address(0x0));
        manager = _newManager;
        emit TransferOwnership(msg.sender, _newManager);
        return true;
    }

    function setCEO(address _newCEO) external onlyManager returns (bool) {
        require(_newCEO != address(0x0));
        CEO = _newCEO;
        emit TransferOwnership(msg.sender, _newCEO);
        return true;
    }

    function setCTO(address _newCTO) external onlyManager returns (bool) {
        require(_newCTO != address(0x0));
        CTO = _newCTO;
        emit TransferOwnership(msg.sender, _newCTO);
        return true;
    }

    // Set new SF address
    function setNewSF(address _newSFC) external onlyManager returns (bool) {
        require(_newSFC != address(0x0));
        emit SetNewSFC(SFC, _newSFC);
        SFC = _newSFC;
        return true;
    }
}

contract LocationManagement is MapOwner{
    // struct of one location, include: latitude and longitude
    struct Location{
        uint64 latitude;
        uint64 longitude;
    }

    Location[] locations; // all locations already have verified

    // Current location belong to skull
    mapping (uint256 => Location[]) locationsOfSkull;
    // Show the Id of Skull, which is the boss of this location
    mapping (uint256 => uint256) locationIdToSkullId;

    event SetNewLocation(address indexed _manager, uint256 _newLocationId, uint64 _lat, uint64 _long);
    event UpdateLocationInfo(uint256 _locationId, uint64 _newLat, uint64 _newLong);
    event DeleteLocation(uint256 _locationId, uint64 _lat, uint64 _long);

    event UserPinNewLocation(address indexed _manager, uint256 _newLocationId, uint64 _lat, uint64 _long);
    event SetLocationToNewSkull(uint256 _skullId, uint64 _lat, uint64 _long, uint256 _oldOwnerId);
    event DeleteLocationFromSkull(uint256 _skullId, uint64 _lat, uint64 _long);

    /// Only Contract's Manager can set new location.
    /// By default, when set new location, owner of this location is Skull[0]
    function setNewLocation(uint64 _lat, uint64 _long) public onlyManager returns (uint256) {
        locations.push(Location({latitude: _lat, longitude: _long}));
        uint256 _newId = locations.length - 1; /// Id of new location
        if(msg.sender != SFC)
            emit SetNewLocation(msg.sender, _newId, _lat, _long);
        else{
            emit UserPinNewLocation(msg.sender, _newId, _lat, _long);
        }
        return _newId;
    }

    /// Only Contract's Manager can set many new locations.
    function setNewLocations(uint64[] _arrLat, uint64[] _arrLong) public onlyManager {
        require(_arrLat.length == _arrLong.length);
        uint256 length = _arrLat.length;
        for(uint i = 0; i < length; i++)
        {
            locations.push(Location({latitude: _arrLat[i], longitude: _arrLong[i]}));
            uint256 _newLocationId = locations.length - 1; /// Id of new location
            emit SetNewLocation(msg.sender, _newLocationId, _arrLat[i], _arrLong[i]);
        }
    }

    // Update location info
    function updateLocationInfo(uint256 _locationId, uint64 _newLat, uint64 _newLong) public onlyManager {
        locations[_locationId].latitude = _newLat;
        locations[_locationId].longitude = _newLong;
        emit UpdateLocationInfo(_locationId, _newLat, _newLong);
    }

    // Manager can delete illegal location
    // We need to check this location have belong to what skull
    // if no, we just delete it
    // if yes, we need to delete mapping locationsOfSkull on this skull first, and then delete on array locations[]
    // When done..
    // We set mapping location of skull (last) to new position of location
    function deleteLocation(uint256 _locationId) public onlyManager {
        require(_locationId < locations.length);
        uint256 arrLength = locations.length; // length of array locations[]
        uint64 lat = locations[_locationId].latitude;
        uint64 long = locations[_locationId].longitude;
        // check:
        if(_locationId != arrLength-1) // position in mid array
        {
            if(locationIdToSkullId[_locationId] == 0)
            {
                locations[_locationId] = locations[arrLength-1];
            }
            else {
                deleteLocationFromSkull(locationIdToSkullId[_locationId], _locationId);
                locations[_locationId] = locations[arrLength-1];
            }

            // set mapping location of skull (last) to new position of location
            if(locationIdToSkullId[arrLength-1] != 0)
            {
                locationIdToSkullId[_locationId] = locationIdToSkullId[arrLength-1];
            }
        }
        else { // position on right and
            if(locationIdToSkullId[_locationId] != 0)
            {
                deleteLocationFromSkull(locationIdToSkullId[_locationId], _locationId);
            }
        }
        delete locations[arrLength-1]; // delete the last location
        locations.length--; // sud length by 1
        emit DeleteLocation(_locationId, lat, long);
    }

    // Delete many locations
    function deleteLocations(uint64[] _lat, uint64[] _long) public onlyManager {
        require(_lat.length == _long.length);
        for(uint i = 0; i < _lat.length; i++)
        {
            for(uint j = 0; j < locations.length; j++)
            {
                if (_lat[i] == locations[j].latitude && _long[i] == locations[j].longitude)
                {
                    deleteLocation(j);
                }
            }
        }
    }

    // Get location info by id from array locations[]
    function getLocationInfoById(uint256 _locationId) internal view returns (uint64 lat, uint64 long) {
        require(_locationId < locations.length);
        Location storage location = locations[_locationId];
        return (location.latitude, location.longitude);
    }

    // Get location info by id from array locations[]
    function getLocationIdByLatLong(uint64 _lat, uint64 _long) public view returns (uint256 _id) {
       for(uint i = 0; i < locations.length; i++)
       {
           if(_lat == locations[i].latitude && _long == locations[i].longitude){
               return i;
           }
       }
       return locations.length;
    }

    // Total locations are verified
    function getTotalLocations() public view returns (uint256) {
        return locations.length;
    }

    ///----------------------------------------------------------///

    /// Get location information of Skull by index
    function getLocationInfoFromSkull(uint256 _skullId, uint _index) public view returns (uint256 locationId, uint64 lat, uint64 long) {
        Location storage location = locationsOfSkull[_skullId][_index];
        locationId = getLocationIdByLatLong(location.latitude, location.longitude);
        return (locationId, location.latitude, location.longitude);
    }

    /// Get all location of each Skull
    function getTotalLocationOfSkull(uint256 _skullId) public view returns (uint) {
        return locationsOfSkull[_skullId].length;
    }

    /// Get Skull ID by Location ID
    function getLocationInfo(uint256 _locationId) public view returns(uint256 skullId, uint64 lat, uint64 long) {
        uint64 latitude;
        uint64 longitude;
        (latitude, longitude) = getLocationInfoById(_locationId);
        return (locationIdToSkullId[_locationId], latitude, longitude) ;
    }

    /// Set exist location to new skull
    function setLocationToSkull(uint256 _skullId, uint64 _lat, uint64 _long, uint256 _defenceLocationId) public onlyManager{
        locationsOfSkull[_skullId].push(Location({latitude: _lat, longitude: _long}));
        locationIdToSkullId[_defenceLocationId] = _skullId; //set location to new skully
        emit SetLocationToNewSkull(_skullId, _lat, _long, _defenceLocationId);
    }

    /// Delete exist location in old skull
    function deleteLocationFromSkull(uint256 _skullId, uint256 _defenceLocationId) public onlyManager{
        uint arrayLength = getTotalLocationOfSkull(_skullId);
        Location memory defenceLocation;
        (defenceLocation.latitude, defenceLocation.longitude) = getLocationInfoById(_defenceLocationId);
        uint i; //find index of defenceLocationId in array of skull
        for(i = 0; i < arrayLength; i++)
        {
            if(locationsOfSkull[_skullId][i].latitude == defenceLocation.latitude && locationsOfSkull[_skullId][i].longitude == defenceLocation.longitude)
                break; // already found
        }
        locationsOfSkull[_skullId][i] = locationsOfSkull[_skullId][arrayLength-1];
        delete locationsOfSkull[_skullId][arrayLength-1];
        locationsOfSkull[_skullId].length--;
        locationIdToSkullId[_defenceLocationId] = 0; // set skull of this location to 0

        emit DeleteLocationFromSkull(_skullId, defenceLocation.latitude, defenceLocation.longitude);
    }
}
