pragma solidity >=0.4.24;

import "../SkullCore.sol";
import "./LocationManagement.sol";
import "./StringUtils.sol";
contract SkullFighting{
    /// We need 2 skulls ready to fight
    /// One skull has many location to pin;
    SkullCore public skullCore = SkullCore(0x6D4921f70EF7fA8836B39039f24CC9EfA46694F7);
    PO8Token public po8 = PO8Token(0xE538Bf5735EF0c30a6A303D2fF6A61E083CD4c12);

    LocationManagement public locationMgmt = LocationManagement(0xaE5c82b1656F8B417301039D8e0f4F6132D0B2E8);
    /// Skull's rank shows the time a Skully can attack in each day.
    uint32[13] internal attackTimes = [3, 25, 15, 10, 8, 7, 6, 5, 4, 4, 4, 3, 3];

    /// Struct of Location

    struct Location{
        uint64 latitude;
        uint64 longitude;
    }

    /// Begin time of game: Fri, 18 Jan 2019 00:00:00 GMT
    uint256 public constant beginTime = 1547769600000;

    uint256 public autoAttackFee = 2 finney;

    /// Nearest day the skull have attack action
    mapping (uint256 => uint256) nearestDateAttack;
    // show the total times skull attacks on the current day. Must be < total attack times per day of this skull.
    mapping (uint256 => uint) internal currentAttackTimes;

    // total success attack
    mapping (uint256 => uint64) internal totalSuccessAttacks;

    // Current location belong to skull
    mapping (uint256 => Location[]) locationsOfSkull;
    // Show the Id of Skull, that is the boss of this location
    mapping (uint256 => uint256) locationIdToSkullId;

    event Battle(address owner, uint256 attackId, uint256 defenceId, bool win);
    event SetLocationToNewSkull(uint256 _skullId, uint64 _lat, uint64 _long, uint256 _oldOwnerId);
    event DeleteLocationFromSkull(uint256 _skullId, uint64 _lat, uint64 _long);
    event BeginTimeOfSkull(uint256 _skullId, uint256 _time);
    event ResetAttackTimes(uint256 _skullId, uint256 _time);

    /// Get location information of Skull by index
    function getLocationInfoFromSkull(uint256 _skullId, uint _index) public view returns (uint64 lat, uint64 long) {
        Location storage location = locationsOfSkull[_skullId][_index];
        return (location.latitude, location.longitude);
    }

    /// Get all location of each Skull
    function getTotalLocationOfSkull(uint256 _skullId) public view returns (uint) {
        return locationsOfSkull[_skullId].length;
    }

    /// Get Skull ID by Location ID
    function getLocationInfo(uint256 _locationId) public view returns(uint256 skullId, uint64 lat, uint long) {
        uint64 latitude;
        uint64 longitude;
        (latitude, longitude) = locationMgmt.getLocationInfo(_locationId);
        return (locationIdToSkullId[_locationId], latitude, longitude) ;
    }

    /// Set exist location to new skull
    function setLocationToSkull(uint256 _skullId, uint64 _lat, uint64 _long, uint256 _defenceLocationId) internal{
        locationsOfSkull[_skullId].push(Location({latitude: _lat, longitude: _long}));
        locationIdToSkullId[_defenceLocationId] = _skullId; //set location to new skully
        emit SetLocationToNewSkull(_skullId, _lat, _long, _defenceLocationId);
    }

    /// Delete exist location in old skull
    function deleteLocationFromSkull(uint256 _skullId, uint256 _defenceLocationId) internal{
        uint arrayLength = getTotalLocationOfSkull(_skullId);
        Location memory defenceLocation;
        (defenceLocation.latitude, defenceLocation.longitude) = locationMgmt.getLocationInfo(_defenceLocationId);
        uint i; //find index of defenceLocationId
        for(i = 0; i <= arrayLength; i++)
        {
            if(locationsOfSkull[_skullId][i].latitude == defenceLocation.latitude && locationsOfSkull[_skullId][i].longitude == defenceLocation.longitude)
                break; // already found
        }
        locationsOfSkull[_skullId][i] = locationsOfSkull[_skullId][arrayLength-1];
        delete locationsOfSkull[_skullId][arrayLength-1];
        locationsOfSkull[_skullId].length--;

        emit DeleteLocationFromSkull(_skullId, defenceLocation.latitude, defenceLocation.longitude);
    }

    /// Game play, Fighting battle of two skulls
    function skullFightWith(uint256 attackId, uint256 _defenceLocationId) internal returns (bool) {
        require(skullCore.ownerOf(attackId) == msg.sender, "Sender must be the skull's owner!");              

        uint256 defenceSkullId = locationIdToSkullId[_defenceLocationId]; // Skull ID of enemy
        require(defenceSkullId != attackId, "Skull have to attack on another skull!");

        require(_defenceLocationId < locationMgmt.getTotalLocations(), "The ID location must less than total locations of Map"); // The ID location must less than total locations of Map 

        uint256 attackPower; // Attack power of user's skull
        uint256 defencePower; // Defence power of the enemy
        Location memory defenceLocation; // Location attacking
        (defenceLocation.latitude, defenceLocation.longitude) = locationMgmt.getLocationInfo(_defenceLocationId);
        /// get attack power of Skully;
        (,attackPower,,,) = skullCore.getSkull(attackId);

        /// attack to the new location
        if(locationIdToSkullId[_defenceLocationId] == 0)
        {
            setLocationToSkull(attackId, defenceLocation.latitude, defenceLocation.longitude, _defenceLocationId);
            emit Battle(msg.sender, attackId, defenceSkullId, true);
            return true;
        }     
        /// attack to the location with the enemy
        else
        {
            (,,defencePower,,) = skullCore.getSkull(locationIdToSkullId[_defenceLocationId]);

            if(attackPower > defencePower)
            {
                setLocationToSkull(attackId, defenceLocation.latitude, defenceLocation.longitude, _defenceLocationId);
                deleteLocationFromSkull(defenceSkullId, _defenceLocationId);
                emit Battle(msg.sender, attackId, defenceSkullId, true);
                return true;
            }
            emit Battle(msg.sender, attackId, defenceSkullId, false);
            return false;
        }
    }

    function fight(uint256 attackId, uint256 defenceLocationId) public payable returns(bool) {
        require(po8.balanceOf(msg.sender) >= 20000000000000000000);// Balance of attacker must greater than 20 PO8.
        //po8.approve(address(this), 20000000000000000000);// users do it themself!
        require(po8.allowance(msg.sender, address(this)) >= 20000000000000000000); // Attacker must be approve at least 20 PO8 before attack (Only one time).

        // attack times of skull between 0 - maximum base-on skull's rank
        require(canAttack(attackId));

        uint256 tempLocationId = locationIdToSkullId[defenceLocationId]; // save a temp ID of defence location
        if(skullFightWith(attackId, defenceLocationId)) {
            if(tempLocationId != 0)
                po8.transfer(msg.sender, 30000000000000000000); // if attack success, attacker win this location and 30 PO8;
            currentAttackTimes[attackId] ++; // attack times on one day
            totalSuccessAttacks[attackId] ++; // total success attacks of skull
        }
        else {
            po8.transferFrom(msg.sender, address(this), 20000000000000000000); // if attack fail, attacker lose 20 PO8;
            currentAttackTimes[attackId] ++;
        }
        return true;
    }

    // condition of skull can attack with time between 0 - maximum attack times per day.
    function canAttack(uint256 skullId) internal returns(bool) { 
        // set begin time of new skull
        if(nearestDateAttack[skullId] == 0)
        {
            setBeginTimeOfSkull(skullId);
        }

        // if current day is a new day, user reset their attack times by themself 
        uint256 subTime = now * 1000 - nearestDateAttack[skullId];
        if(subTime > 86400000) {
            resetAttackTimes(skullId, subTime);
        }
        
        // check current attack times on this day.
        if (currentAttackTimes[skullId] >= 0 && currentAttackTimes[skullId] < getMaximumAttackTimesPerDay(skullId)) {
            return true;
        }
        return false;
    }

    // get maximum attack times of skull base-on its rank 
    function getMaximumAttackTimesPerDay(uint256 skullId) public view returns (uint) {
        uint skullRank;
        (,,,skullRank,) = skullCore.getSkull(skullId);
        uint attackTime = attackTimes[skullRank];
        return attackTime;
    }

    // return attack times of skull on current day
    function getCurrentAttackTimes(uint256 skullId) public view returns (uint) {
        return currentAttackTimes[skullId];
    }

    // set the begin time of skull equal to Fri, 18 Jan 2019 00:00:00 GMT
    function setBeginTimeOfSkull(uint256 skullId) internal {
        nearestDateAttack[skullId] = beginTime;
        emit BeginTimeOfSkull(skullId, beginTime);
    }

    // reset attack times on the new day base-on nowtime and nearest time attack
    function resetAttackTimes(uint256 skullId, uint256 _subTime) internal {
        currentAttackTimes[skullId] = 0; // reset attack times to 0
        nearestDateAttack[skullId] = (uint256(_subTime)/86400000)*86400000 + nearestDateAttack[skullId]; // round the day, before plus day.
        emit ResetAttackTimes(skullId, nearestDateAttack[skullId]);
    }

    // get total success attack times of skull
    function getTotalSuccsessAttacks(uint256 skullId) public view returns (uint64) {
        return totalSuccessAttacks[skullId];
    }
}