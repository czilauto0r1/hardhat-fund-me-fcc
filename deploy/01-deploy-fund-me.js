// imports

// function deployFunc(hre) {
//     console.log("Hi!")
// hre.getNamedAccounts()
// hre.deployments
// }

// module.exports.default = deployFunc          // export that function as a defult deploy function

// module.exports = async (hre) => {
// const {getNamedAccounts, deployments } = hre

const { getNamedAccounts, deployments, network } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config") // export module
// const helperConfig = require("../helper-hardhat-config")
// const networkConfig = helperConfig.networkConfig             with these 2 lines we make same like line above
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    //if chainId is X use address Y
    // if chainId is Y use addres A
    //const ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    let ethUsdPriceFeedAddress
    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }

    // if contract doesnt exist we deploy a minimial version
    // for our local testing

    // what happens when we want to change chains?
    // when going for localhost or hardhat network we want to use a mock
    const arg = [ethUsdPriceFeedAddress]
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: arg, // put price feed address
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(fundMe.address, arg)
    }
    log("------------------------------")
}
module.exports.tags = ["all", "fundme"]
