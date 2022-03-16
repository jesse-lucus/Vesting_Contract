const ExperimentContract = artifacts.require("ExperimentContract")

const verbose = true

contract("ExperimentContract", (accounts) => {

    before(async () => {

        experimentContract = await ExperimentContract.deployed()

        if (verbose)
            // Line break in last argument for better readability in console output.
            console.log('experiment contract address:', experimentContract.address, "\n")

    })

    it('mapping persistent changes after passing by ref', async () => {
        await experimentContract.changeStatus()

        const isEnabled = await experimentContract.readStatus()
        assert.equal(isEnabled, isEnabled)
    })

})