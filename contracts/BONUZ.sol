// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BONUZ is ERC20 {
    constructor(uint256 initialSupply) ERC20("bonuz", "BONUZ") {
        _mint(_msgSender(), initialSupply * (10**decimals()));
    }
}
