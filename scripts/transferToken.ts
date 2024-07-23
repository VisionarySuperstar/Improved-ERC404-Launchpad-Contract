// import { ethers } from 'hardhat'

// async function main() {
//     const toAddress = '0x9319Ec01DcB2086dc828C9A23Fa32DFb2FE10143'
//     const contractAddress = '0x98542457A54621Ceb07757aBc936FEe115E319f8'

//     console.log('Sending My404 token...')
//     const my404 = await ethers.getContractAt('My404', contractAddress)

//     const tx = await my404.transfer(toAddress, ethers.parseEther('20'))
//     tx.wait()
//     console.log(`Tx hash for sending My404 token: ${tx.hash}`)
// }

// // We recommend this pattern to be able to use async/await everywhere
// // and properly handle errors.
// main().catch(error => {
//     console.error(error)
//     process.exitCode = 1
// })