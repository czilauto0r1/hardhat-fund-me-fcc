//SPDX-License-Identifier: MIT
// Pragma
pragma solidity ^0.8.4;
//Get funds from users
// Withdraw funds
// set a minimum funding value in usd

// contract cost 819,290 gas
// Imports
import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";
// Error Codes
error FundMe__NotOwner();

// Interfaces, Libraries, Contracts

/** @title A contract for crowd funding
 *   @author Tomek Bodek
 *   @notice This contract is to demo a sample funding contract
 *   @dev This implements price fees as our library
 */
contract FundMe {
    // Type declarations
    using PriceConverter for uint256;
    // State variables!
    uint256 public constant MINIMUM_USD = 50 * 1e18; // uint256 constant CANT GO TO STORAGE
    // memory  variables, constant variables, mutual variables not going to storage
    address private immutable i_owner;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;
    // Could we make this constant?

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; // <- rest of code
        // require(msg.sender == i_owner, "Sender is not owner"); // <- do this first
        // <- rest of code
    }

    // Functions order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeedAddress) {
        // () taking data from priceFeed
        i_owner = msg.sender; // przypisuje OWNER to address who deploy that contract
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    /**
     *   @notice This function funds this contract
     *   @dev This implements price feeds as our library
     */

    function fund() public payable {
        //We want to be able to set minimum funding value
        // 1. How do we send eth to this contract
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didnt send enough"
        ); // 1e18 == 1 * 10 ** 18 == 1000000000000000000 = 1 eth
        // if you need to require something with revert use require
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Sender is not owner");
        // for loop
        // [1, 2, 3, 4]
        //  0, 1, 2, 3  <- indexes
        // for(/* starting index, ending index, step amount */ )
        // 0, 10, 2 <- from 0 to 10 by 2 so: 0,2,4,6,8,10
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset array
        s_funders = new address[](0);
        //actually withdraw the funds
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
        // transfer method
        // msg.sender == address
        // payable(msg.sender) = payable
        // payable msg.sender.transfer(address(this).balance);
        // send method
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call method <- RECOMMENDED METHOD
        // (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        // require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mappings cant be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()
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
