// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    // MATIC/USD
    return uint256((1000000000000000000 ** 2) / (answer * 10000000000));
  }

  // 1000000000
  // call it get fiatConversionRate, since it assumes something about decimals
  // It wouldn't work for every aggregator
  function getConversionRate(uint256 cryptoAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 cryptoPrice = getPrice(priceFeed);
    uint256 usdInCryptoAmount = (cryptoPrice * cryptoAmount) / 1000000000000000000;
    // the actual ETH/USD conversation rate, after adjusting the extra 0s.
    return usdInCryptoAmount;
  }
}