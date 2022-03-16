const BONUZ = artifacts.require("BONUZ")
const Vesting = artifacts.require("Vesting")
const fs = require("fs");
const fastCsv = require("fast-csv");

/*
 *      NODEJS
 */
const path = require('path')

const verbose = true

const getImportsDirectoryPath = () => {
    let currentPath = __dirname
    if (verbose)
        console.log('Current directory:', currentPath)

    currentPath = path.join(currentPath, '../')
    if (verbose)
        console.log('Root directory:', currentPath)

    currentPath = path.join(currentPath, 'imports')
    if (verbose)
        console.log('Imports directory:', currentPath)

    return currentPath
}

module.exports = function (deployer) {
    if(verbose)
    {
        const importDirectoryPath = getImportsDirectoryPath()
        const options = {
            objectMode: true,
            delimiter: ",",
            quote: null,
            renameHeaders: false,
        };
        
        // Read CSV

        const vestingScheduleSeedRoundCommunity = [];
        const vestingScheduleSeedRoundStrategic = [];
        const vestingSchedulePrivateRoundStrategic = []
        const vestingSchedulePublicRound = []
        const vestingScheduleFomoRound = []
        const vestingScheduleLiquidity = []
        const vestingScheduleMarketing = []

        const PERCENTAGE_FACTOR = 100

        const segmentNames = [];
        const data = [];

        const readableStream = fs.createReadStream(importDirectoryPath + "/vesting_schedule.csv");
        fastCsv
        .parseStream(readableStream, options)
        .on("error", (error) => {
            console.log(error);
        })
        .on("data", (row) => {
            data.push(row);
        })
        .on("end", (rowCount) => {
            //console.log(rowCount);

            data.forEach(element => {
                if(element[0] == "Segment")
                {
                    element.forEach(cell => {
                        if(cell != "Segment") segmentNames.push(cell);
                    });
                    console.log("Segment: ", segmentNames);
                }
                else if(element[0] == "Seed Round - Community")
                {
                    element.forEach(cell => {
                        if(cell != "Seed Round - Community") vestingScheduleSeedRoundCommunity.push(isNaN(parseInt(cell)) ? 0 : parseFloat(cell) * PERCENTAGE_FACTOR);
                    });
                    console.log("Seed Round - Community", vestingScheduleSeedRoundCommunity);
                }
                else if(element[0] == "Seed Round - Strategic")
                {
                    element.forEach(cell => {
                        if(cell != "Seed Round - Strategic") vestingScheduleSeedRoundStrategic.push(isNaN(parseInt(cell)) ? 0 : parseFloat(cell) * PERCENTAGE_FACTOR);
                    });
                    console.log("Seed Round - Strategic", vestingScheduleSeedRoundStrategic);
                }
                else if(element[0] == "Private Round - Strategic")
                {
                    element.forEach(cell => {
                        if(cell != "Private Round - Strategic") vestingSchedulePrivateRoundStrategic.push(isNaN(parseInt(cell)) ? 0 : parseFloat(cell) * PERCENTAGE_FACTOR);
                    });
                    console.log("Private Round - Strategic", vestingSchedulePrivateRoundStrategic);
                }
                else if(element[0] == "Public Round ")
                {
                    element.forEach(cell => {
                        if(cell != "Public Round ") vestingSchedulePublicRound.push(isNaN(parseInt(cell)) ? 0 : parseFloat(cell) * PERCENTAGE_FACTOR);
                    });
                    console.log("Public Round ", vestingSchedulePublicRound);
                }
                else if(element[0] == "FOMO Round - Unlocked")
                {
                    element.forEach(cell => {
                        if(cell != "FOMO Round - Unlocked") vestingScheduleFomoRound.push(isNaN(parseInt(cell)) ? 0 : parseFloat(cell) * PERCENTAGE_FACTOR);
                    });
                    console.log("FOMO Round - Unlocked", vestingScheduleFomoRound);
                }
                else if(element[0] == "Liquidity")
                {
                    element.forEach(cell => {
                        if(cell != "Liquidity") vestingScheduleLiquidity.push(isNaN(parseInt(cell)) ? 0 : parseFloat(cell) * PERCENTAGE_FACTOR);
                    });
                    console.log("Liquidity", vestingScheduleLiquidity);
                }
            });
        });

        const signers = []
        const tge = Date.parse('2022-04-01T00:00:00Z');
        console.log("tge: ", tge / 1000);
        const vestingPeriod = 48

        deployer.then(async () => {

            let bonuzTokenContract = await deployer.deploy(BONUZ, 1000000000)

            let firstAccount,
            secondAccount,
            thirdAccount,
            fourthAccount;

            // await web3.eth.accounts.wallet.create(4) // create 4 accounts
            let accounts = await web3.eth.getAccounts()
            console.log(accounts)
            firstAccount = accounts[0]
            secondAccount = accounts[1]
            thirdAccount = accounts[2]
            fourthAccount = accounts[3]

            signers.push(firstAccount, secondAccount, thirdAccount)

            const vestingAddresses = [];
            const vestingAmounts = [];
            const vestingSchedules = [];

            // for(var i=0; i<10; i++){
                vestingAddresses.push([firstAccount, secondAccount]);
                vestingAmounts.push(Array(2).fill(10));
                vestingSchedules.push(vestingScheduleFomoRound);
            // }
            let vestingContract = await deployer.deploy(
                Vesting,
                bonuzTokenContract.address,
                signers,
                firstAccount,
                tge / 1000,
                vestingPeriod,
                //segmentsCount
                1,
                //segmentNames
                segmentNames,
                // Vesting Schedule
                vestingSchedules,
                // Addresses
                vestingAddresses,
                // Amounts
                vestingAmounts
            )
            console.log("vestingContract deployed to: ", vestingContract.address)
        })
    }
};
