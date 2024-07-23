
import { ethers } from 'hardhat'
import NonfungiblePositionManagerABI from '../abis/NonfungiblePositionManager.json'
import UniswapV3Factory from '../abis/UniswapV3Factory.json'

async function main() {
    const [deployer] = await ethers.getSigners()

    console.log('My404 - WETH pool is initializing on Uniswap V3...')
    const token0 = '0x9c8a4762AB11A6Fa13313dDDEe8c879b1298F6a5' // MY404 Token Address on Sepolia
    const token1 = '0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14' // WETH Token Address on Sepolia
    const fee = 10000n // 1% fee
    const sqrtPriceX96 = 792281625000000000000000000n // 1/10000 price ratio

    // Token and pool parameters are defined:
    // - token0 and token1 represent the pair of tokens for the pool, with your ERC-404 token and WETH.
    // - fee denotes the pool's fee tier, affecting trading fees and potential liquidity provider earnings.
    // - sqrtPriceX96 is an encoded value representing the initial price of the pool, set based on the desired price ratio.
    const contractAddress = {
        uniswapV3NonfungiblePositionManager:
            '0x1238536071E1c677A632429e3655c799b22cDA52',
        uniswapV3Factory: '0x0227628f3F023bb0B980b67D528571c95c6DaC1c',
    }

    // Contract instances for interacting with Uniswap V3's NonfungiblePositionManager and Factory.
    const nonfungiblePositionManagerContract = new ethers.Contract(
        contractAddress.uniswapV3NonfungiblePositionManager,
        NonfungiblePositionManagerABI,
        deployer
    )

    const uniswapV3FactoryContract = new ethers.Contract(
        contractAddress.uniswapV3Factory,
        UniswapV3Factory,
        deployer
    )

    const my404Contract = await ethers.getContractAt('My404', token0, deployer)

    // Creating the pool on Uniswap V3 by specifying the tokens, fee, and initial price.
    let tx =
        await nonfungiblePositionManagerContract.createAndInitializePoolIfNecessary(
            token0,
            token1,
            fee,
            sqrtPriceX96
        )

    await tx.wait()

    console.log(`Tx hash for initializing a pool on Uniswap V3: ${tx.hash}`)

    // Retrieving the newly created pool's address to interact with it further.
    const pool = await uniswapV3FactoryContract.getPool(token0, token1, fee)

    console.log(`The pool address: ${pool}`)

    // Whitelisting the Uniswap V3 pool address in your ERC-404 token contract.
    // This step is crucial to bypass the token's built-in protections or requirements for minting and burning,
    // which may be triggered during liquidity provision or trading on Uniswap.
    console.log('Uniswap V3 Pool address is being whitelisted...')
    tx = await my404Contract.setWhitelist(pool, true)
    tx.wait()
    console.log(`Tx hash for whitelisting Uniswap V3 pool: ${tx.hash}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
    console.error(error)
    process.exitCode = 1
})