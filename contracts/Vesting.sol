// TODO:
// - set explicit solidity version
// - check if one contract per segment

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Vesting is Context {
    IERC20 private _token;

    address[] private _signers;
    address private _multiSig;

    /*
     *      VESTING
     */
    uint256 private immutable _tge;
    uint8 private immutable _vestingPeriod;
    string[] private _segmentNames;
    uint256 private immutable _segmentsCount;
    // mapping(address => VestingDetails)[] private _vestingMappings;
    mapping(uint256 => mapping(address => VestingDetails)) private _vestingMappings;
    uint16[48][] private _vestingSchedules;

    /*
     *      CONSTANTS
     */
    // 28 days
    uint256 constant ONE_MONTH = 2419200;
    // For calculating two digits after the comma, e.g. 3.75% = 375
    uint256 constant PERCENTAGE_FACTOR = 100;

    /*
     *      EVENTS - DEPLOYMENT
     */
    event AddressDeployed(
        uint256 indexed _segment,
        address indexed _address,
        uint256 amount
    );

    /*
     *      EVENTS - ICE
     */
    event AddressFrozen(address indexed _address);
    event AddressUnfrozen(address indexed _address);

    /*
     *      EVENTS - RELEASE
     */
    event TokenReleased(address indexed _address, uint256 _amount);

    struct VestingDetails {
        uint256 total;
        uint256 released;
        bool isFrozen;
        bool exists;
    }

    /*
     *      REQUIRE FUNCTIONS
     */

    // Changes only allowed by the Multi Sig Wallet
    function requireAuthorization() internal view {
        require(_msgSender() == _multiSig, "Permission denied.");
    }

    // Signers (core team) cannot be frozen
    function requireNotSigner(address _address) internal view {
        require(!isSigner(_address), "Can not freeze address.");
    }

    function requireAddressExistsInAnySegment(address _address) internal view {
        require(
            addressExistsInAnySegment(_address),
            "Address does not exist in any segment."
        );
    }

    function isSigner(address _address) internal view returns (bool) {
        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            if (_address == signer) {
                return true;
            }
        }
        return false;
    }

    function freezeAddress(address _address) public {
        requireAuthorization();
        requireAddressExistsInAnySegment(_address);
        requireNotSigner(_address);

        for (uint256 i = 0; i < _segmentsCount; i++)
            setIsFrozen(_vestingMappings[i], _address, true);

        emit AddressFrozen(_address);
    }

    function unFreezeAddress(address _address) public {
        requireAuthorization();
        requireAddressExistsInAnySegment(_address);
        requireNotSigner(_address);

        for (uint256 i = 0; i < _segmentsCount; i++)
            setIsFrozen(_vestingMappings[i], _address, false);

        emit AddressUnfrozen(_address);
    }

    function setIsFrozen(
        mapping(address => VestingDetails) storage map,
        address _address,
        bool isFrozen
    ) internal {
        if (map[_address].exists) map[_address].isFrozen = isFrozen;
    }

    function getClaimableAmount(
        VestingDetails storage details,
        uint16[48] storage vestingSchedule
    ) internal view returns (uint256) {
        uint256 unlocked = 0;

        // // We checked if TGE started already before entering the function.
        // // So, the vesting started as payout happens on the first of each month.
        uint256 monthsSinceTge = (block.timestamp - _tge) / ONE_MONTH + 1;

        uint16 percentageSinceTge = 0;
        for (uint256 i = 0; i < monthsSinceTge; i++) {
            uint16 percentage = vestingSchedule[i];
            percentageSinceTge = percentageSinceTge + percentage;
        }
        unlocked =
            (details.total * percentageSinceTge) /
            100 /
            PERCENTAGE_FACTOR;

        uint256 claimable = 0;
        if (unlocked > details.released) {
            claimable = unlocked - details.released;
        }

        // Defensive strategy to not payout more than
        // originally defined for the target address.
        if (unlocked + claimable > details.total) {
            claimable = details.total;
        }

        return claimable;
    }

    function getTotalTokenAmountOfAllSegments(address _address)
        internal
        view
        returns (uint256)
    {
        uint256 total = 0;
        for (uint256 index = 0; index < _segmentsCount; index++)
            if (_vestingMappings[index][_address].exists)
                total += _vestingMappings[index][_address].total;
        return total;
    }

    function getReleasedTokenAmountOfAllSegments(address _address)
        internal
        view
        returns (uint256)
    {
        uint256 released = 0;
        for (uint256 index = 0; index < _segmentsCount; index++) {
            mapping(address => VestingDetails)
                storage vesting = _vestingMappings[index];

            if (vesting[_address].exists)
                released += vesting[_address].released;
        }
        return released;
    }

    function releaseAll(
        mapping(address => VestingDetails) storage vesting,
        address _address
    ) internal {
        vesting[_address].released = vesting[_address].total;
    }

    function releaseAllInAllSegments(address _address) internal {
        for (uint256 i = 0; i < _segmentsCount; i++)
            releaseAll(_vestingMappings[i], _address);
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function release() public virtual {
        require(
            block.timestamp > _tge,
            "TGE must happen before any claiming is possible."
        );
        requireAddressExistsInAnySegment(_msgSender());

        uint256 releaseAmount = 0;
        if (block.timestamp > _tge + _vestingPeriod * ONE_MONTH) {
            uint256 totalTokenAmount = getTotalTokenAmountOfAllSegments(
                _msgSender()
            );
            uint256 releasedTokenAmount = getReleasedTokenAmountOfAllSegments(
                _msgSender()
            );
            releaseAmount = totalTokenAmount - releasedTokenAmount;
            releaseAllInAllSegments(_msgSender());
        } else {
            releaseAmount = getClaimableAmountAndRelease(_msgSender());
        }

        emit TokenReleased(_msgSender(), releaseAmount);

        SafeERC20.safeTransferFrom(
            _token,
            address(this),
            _msgSender(),
            releaseAmount
        );
    }

    function getClaimableAmountAndRelease(address _address)
        internal
        returns (uint256)
    {
        uint256 totalClaimableAmount = 0;
        for (uint256 index = 0; index < _segmentsCount; index++) {
            VestingDetails storage vestingDetails = _vestingMappings[index][
                _address
            ];
            uint256 claimableAmount = getClaimableAmount(
                vestingDetails,
                _vestingSchedules[index]
            );
            _vestingMappings[index][_address].released += claimableAmount;
            totalClaimableAmount += claimableAmount;
        }
        return totalClaimableAmount;
    }

    function addressExistsInAnySegment(address _address)
        internal
        view
        returns (bool)
    {
        for (uint256 index = 0; index < _segmentsCount; index++)
            if (_vestingMappings[index][_address].exists) return true;
        return false;
    }

    function getAllSegmentNames() public view returns (string[] memory) {
        return _segmentNames;
    }

    function getSegmentName(uint256 index) public view returns (string memory) {
        require(index < _segmentNames.length);

        return _segmentNames[index];
    }

    function getTimeStamp() public view returns (uint256) {
        uint256 nowStamp = block.timestamp;
        return nowStamp;
    }

    function getTGE() public view returns (uint256) {
        return _tge;
    }

    constructor(
        // BONUZ token contract address
        address tokenContractAddress,
        // Signers for Multi Sig
        address[] memory signers,
        address multiSig,
        // Token Generation Event
        uint256 tge,
        // Vesting Configuration
        uint8 vestingPeriod,
        uint256 segmentsCount,
        string[] memory segmentNames,
        uint16[48][] memory vestingSchedules,
        address[][] memory vestingAddresses,
        uint256[][] memory vestingAmounts
    ) {
        // Would love to use isContract implementation.
        // Unfortunately, it is not possible to detect whether an address
        // is a contract when called within a constructor.
        // https://ethereum.stackexchange.com/a/15642
        require(
            tokenContractAddress != address(0),
            "Provide a valid contract address."
        );
        require(signers.length == 3, "Signers amount must be exactly three.");
        require(multiSig != address(0), "Provide valid multi sig address.");
        require(
            tge >= block.timestamp,
            "TGE must be same date or later than the deployment date."
        );

        // Check if amount of lists for vesting schedules,
        // vesting addresses and vesting amounts each
        // equal to the given amount of segments.
        //
        // Those checks is not used (commented out) as
        // during smart contract deployment these kind
        // of checks automatically happend.
        require(vestingSchedules.length == segmentsCount);
        require(vestingAddresses.length == segmentsCount);
        require(vestingAmounts.length == segmentsCount);

        // Check if total percentage is exactly 100.
        for (uint256 i = 0; i < segmentsCount; i++) {
            uint256 total = 0;
            for (uint256 j = 0; j < vestingPeriod; j++) {
                // Additionally, it can be checked if
                // amount of vesting schedule values is equal
                // to the given vesting period in months.
                //
                // That check is not used (commented out) as
                // during smart contract deployment these kind
                // of checks automatically happend.
                require(vestingSchedules[i].length == vestingPeriod);

                total += vestingSchedules[i][j];
            }
            require(total == 100);
        }

        _token = IERC20(tokenContractAddress);
        _signers = signers;
        _multiSig = multiSig;
        _tge = tge;
        _vestingPeriod = vestingPeriod;
        _segmentsCount = segmentsCount;

        // Save segment names
        for (uint256 index = 0; index < segmentNames.length; index++) {
            _segmentNames.push(segmentNames[index]);
        }

        deployAllSegmentAddresses(
            segmentsCount,
            vestingSchedules,
            vestingAddresses,
            vestingAmounts
        );
    }

    function deployAllSegmentAddresses(
        uint256 segmentsCount,
        uint16[48][] memory vestingSchedules,
        address[][] memory vestingAddresses,
        uint256[][] memory vestingAmounts
    ) internal {
        for (uint256 index = 0; index < segmentsCount; index++) {
                _vestingSchedules.push(vestingSchedules[index]);

            // Save addresses with corresponding vesting details to contract.
            for (uint8 i = 0; i < vestingAddresses[index].length; i++) {
                address _address = vestingAddresses[index][i];
                uint256 _amount = vestingAmounts[index][i];
                VestingDetails memory vestingDetails = VestingDetails(
                    _amount,
                    10,
                    false,
                    true
                );

                _vestingMappings[index][_address] = vestingDetails;

                emit AddressDeployed(index, _address, _amount);
            }
        }
    }
}
