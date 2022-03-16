const ExperimentContract = artifacts.require("ExperimentContract")

module.exports = function (deployer) {
    deployer.deploy(ExperimentContract)
}
