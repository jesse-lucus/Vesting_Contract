const {duration} = require('truffle-test-helpers') 
const Vesting = artifacts.require('Vesting')
const { timetravel } = require('./helpers/timeTravel')
const {
    expectRevert,
  } = require("@openzeppelin/test-helpers");

contract('Vesting', (accounts) => {
    before(async () => {
    })
    it("When try to release before TGE", async () => {
        let vestingContract = await Vesting.deployed()

        const now_timestamp = await vestingContract.getTimeStamp()
        const now_date = new Date(now_timestamp * 1000);
        console.log("Time NOW", now_date)
        let tge_timestamp = await vestingContract.getTGE()
        const tge_date = new Date(tge_timestamp * 1000)
        console.log("TGE", tge_date)
        
        await expectRevert(
            vestingContract.release(),
            "TGE must happen before any claiming is possible."
          );
        // expectRevert(await vestingContract.release())
        console.log("Fail to Release")
    })
    it("Can be released", async () => {
        let vestingContract = await Vesting.deployed()
        //Increase EVM BlockTimeStamp One Year
        const Duration = duration.years(1)
        timetravel(Duration)
        
        const now_timestamp = await vestingContract.getTimeStamp()
        const now_date = new Date(now_timestamp * 1000);
        console.log("Time NOW", now_date)
        let tge_timestamp = await vestingContract.getTGE()
        const tge_date = new Date(tge_timestamp * 1000)
        console.log("TGE", tge_date)

        await vestingContract.release()
        console.log("Successfully Released")
    })
    
})