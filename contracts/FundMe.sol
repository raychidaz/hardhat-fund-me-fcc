// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

//SPDX-License-Identifier: MIT
// 1. pragma
pragma solidity ^0.8.8;

// 2. imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// 3. custom errors
error FundMe__NotOwner();

// 4. Interfaces, Libraries, Contracts

/**@title A sample Funding Contract
 * @author Raymond Chidavaenzi
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // 4. Type declarations

    using PriceConverter for uint256;

    // 5. State variables
    // constant & immutable are for variables that can only be declared and uppdated once
    // will help save gas
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1* 10 ** 18
    address[] private s_funders;
    address private immutable i_owner;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    // 6. modifiers
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not the ownwer");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //  What happens if somebody sends this contract ETH without calling the fund. function
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // want to be able to send a minimum fund anount in USD
    // 1. How do we send ETH to this contract
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough money"
        ); // 1e18 == 1 * 10 ** 18 = 1 000000 000000 000000
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    /* call -- in combination with re-entrancy guard is the 
 recommended method to use after December 2019.
 Guard against re-entrancy by making all state changes before (check effects)
 calling other contracts using re-entrancy guard modifier */

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            // code
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);
        // acctually withdraw the funds
        //call - (forward all gas or set gas, returns bool)
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mappings cant be in memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callSuccess);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
