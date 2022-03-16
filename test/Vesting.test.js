const Vesting = artifacts.require('Vesting')

contract('Vesting', (accounts) => {
    before(async () => {
    })
    it("Release Token", async () => {
        // let vestingContract = await Vesting.deployed()
        const contract_address = '0xbE618DD76dE596df6b3129F4081d76666B413b9C'
        let vestingContract = await Vesting.at(contract_address);

        console.log(await vestingContract.getAllSegmentNames())
        let blockTime = await vestingContract.getTimeStamp()
        console.log("Block TimeStamp", parseInt(blockTime))
        let tge = await vestingContract.getTGE()
        console.log("TGE", parseInt(tge))
        await vestingContract.release()
        console.log("Successfully Released")
    })
})