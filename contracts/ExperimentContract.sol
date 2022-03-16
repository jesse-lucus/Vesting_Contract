// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Status {
    bool isEnabled;
}

contract ExperimentContract {
    mapping(address => Status) private _addressStatusMap;

    address _address = 0xD17CD8b3a4852F0a883f1Beb7a0b9C493b70f7B9;

    constructor() {
        _addressStatusMap[_address] = Status(false);
    }

    function changeStatus() public {
        changeStatusRef(_addressStatusMap);
    }

    function changeStatusRef(
        mapping(address => Status) storage addressStatusMap
    ) private {
        addressStatusMap[_address].isEnabled = true;
    }

    function readStatus() public view returns (bool) {
        return _addressStatusMap[_address].isEnabled;
    }
}
