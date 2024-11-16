// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * This contract assumes that the tokenOut is a token that
 * it's pegged with the USD dollar (1 tokenOut = 1 dollar)
*/
contract PythPriceOracle is IPriceOracle, Ownable2Step {
    struct PythPriceFeed {
        bytes32 id;
        uint256 age;
    }

    IPyth public pyth;
    mapping (address tokenIn => mapping(address tokenOut => PythPriceFeed feed)) public tokenPairPriceFeed;
    mapping (address tokenIn => mapping(address tokenOut => uint256 price)) public tokenPairPrice;

    constructor(address owner, address pythContract) Ownable(owner) {
        pyth = IPyth(pythContract);
    }

    function getCurrentPrice(address tokenIn, address tokenOut) external view returns (uint256) {
        int64 price = tokenPairPrice[tokenIn][tokenOut];
        if(price == 0) {
            // TODO: Throw error
            return 0;
        }

        // TODO: We should check when was this updated
        return price;
    }

    // TODO: Check what happens if anyone can update this function
    function updatePrice(
        bytes[] calldata priceUpdate,
        address tokenIn,
        address tokenOut
    ) external payable {
        PythPriceFeed memory feed = tokenPairPriceFeed[tokenIn][tokenOut];
        // Submit a priceUpdate to the Pyth contract to update the on-chain price.
        // Updating the price requires paying the fee returned by getUpdateFee.
        // WARNING: These lines are required to ensure the getPriceNoOlderThan call below succeeds.
        // If you remove them, transactions may fail with "0x19abf40e" error.
        uint fee = pyth.getUpdateFee(priceUpdate);
        pyth.updatePriceFeeds{ value: fee }(priceUpdate);

        // Read the current price from a price feed if it is less than 60 seconds old.
        // Each price feed (e.g., ETH/USD) is identified by a price feed ID.
        // The complete list of feed IDs is available at https://pyth.network/developers/price-feed-ids
        PythStructs.Price memory price = pyth.getPriceNoOlderThan(feed.id, feed.age);
        // TODO: Do we care about the other stuff?
        tokenPairPrice[tokenIn][tokenOut] = _transformPriceTo18Decimals(price.price);
    }

    function withdraw() external onlyOwner {
        // Withdraw the balance of the contract
        // TODO: Emit event
        payable(owner()).transfer(address(this).balance);
    }

    function addFeed(
        address tokenIn,
        address tokenOut,
        PythPriceFeed calldata priceFeed
    ) external onlyOwner {
        // TODO: Emit event
        tokenPairPriceFeed[tokenIn][tokenOut] = PythPriceFeed({
            id: priceFeed.id,
            age: priceFeed.age
        });
    }

    // TODO: Check
    function _transformPriceTo18Decimals(int64 price, int32 expo) private pure returns (uint256) {
        // Convert expo + 18 to uint256 for exponentiation
        uint256 factor = uint256(10)**uint256(int256(expo + 18));

        // Multiply the price by the factor, ensuring the result is in int256
        uint256 priceWith18Decimals = uint256(price) * factor;

        return priceWith18Decimals;
    }

    // Receive ether to pay to the pyth oracle
    receive() external payable {}
}
