pragma solidity ^0.4.24;

contract LocationManagement{

    address public manager;
    event TransferOwnership(address indexed _oldManager, address indexed _newManager);
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
    function transferOwnership(address _newManager) external onlyManager returns(bool) {
        manager = _newManager;
        emit TransferOwnership(msg.sender, _newManager);
        return true;
    }

    struct Location{
        uint64 latitude;
        uint64 longitude;
    }

    Location[] locations;

    event SetNewLocation(uint256 _newLocationId, uint64 _lat, uint64 _long);
    event UpdateLocationInfo(uint256 _locationId, uint64 _newLat, uint64 _newLong);

    constructor () public {
        manager = msg.sender;
    }

    /// Only Contract's Manager can set new location.
    function setNewLocation(uint64 _lat, uint64 _long) external onlyManager {
        locations.push(Location({latitude: _lat, longitude: _long}));
        uint256 _newId = locations.length - 1; /// Id of new location
        emit SetNewLocation(_newId, _lat, _long);
    }

    /// Only Contract's Manager can set many new locations.
    function setNewLocations(uint64[] _arrLat, uint64[] _arrLong) external onlyManager {
        require(_arrLat.length == _arrLong.length);
        uint256 length = _arrLat.length;
        for(uint i = 0; i < length; i++)
        {
            locations.push(Location({latitude: _arrLat[i], longitude: _arrLong[i]}));
            uint256 _newLocationId = locations.length - 1; /// Id of new location
            emit SetNewLocation(_newLocationId, _arrLat[i], _arrLong[i]);
        }

    }

    function updateLocationInfo(uint256 _locationId, uint64 _newLat, uint64 _newLong) external onlyManager {
        locations[_locationId].latitude = _newLat;
        locations[_locationId].longitude = _newLong;
        emit UpdateLocationInfo(_locationId, _newLat, _newLong);
    }


    function getLocationInfo(uint256 _locationId) public view returns (uint64 lat, uint64 long) {
        require(_locationId < locations.length);
        Location storage location = locations[_locationId];
        return (location.latitude, location.longitude);
    }

    function getTotalLocations() public view returns (uint256) {
        return locations.length;
    }
}
