//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Libraries are similar to contracts, but you can't declare any state variable and you can't send ether.
// A library is embedded into the contract if all library functions are internal.
// Otherwise the library must be deployed and then linked before the contract is deployed.

library PriceConverter {
    // interaction with external contracts needs ABI and contract address
    // 	addy == 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 1e10); // 1**10 == 10000000000
    }

    function getVersion() internal view returns (uint256) {
        address ethUsdFeedAddress = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            ethUsdFeedAddress
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 _ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18; // ALWAYS multiply before you divide
        return ethAmountInUsd;
    }
}
