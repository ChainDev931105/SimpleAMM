const AMM = artifacts.require("AMM");
const LeverageAMM = artifacts.require("LeverageAMM");

module.exports = function (deployer) {
  deployer.deploy(AMM);
  deployer.deploy(LeverageAMM);
};
