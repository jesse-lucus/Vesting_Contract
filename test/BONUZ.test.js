const BONUZ = artifacts.require('BONUZ')

const verbose = true

const one_billion = Math.pow(10, 9)

contract('BONUZ', (accounts) => {

    before(async () => {

        bonuzTokenContract = await BONUZ.deployed()

        if (verbose)
            // Line break in last argument for better readability in console output.
            console.log('bonuz contract address:', bonuzTokenContract.address, "\n")

    })

    it("contract total supply", async () => {

        let totalSupply = await bonuzTokenContract.totalSupply()
        totalSupply = web3.utils.fromWei(totalSupply)

        if (verbose)
            console.log('bonuz contract total supply:', totalSupply)

        assert.equal(one_billion, totalSupply, 'Total supply must be 1 BLN tokens.')
    })

    it("balance of contract creator", async () => {

        let balance = await bonuzTokenContract.balanceOf(accounts[0])
        balance = web3.utils.fromWei(balance)

        if (verbose)
            console.log('balance of contract creator:', balance)

        assert.equal(one_billion, balance, 'Balance must be 1 BLN tokens for contract creator.')
    })
})