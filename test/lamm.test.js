const LeverageAMM = artifacts.require('LeverageAMM');
const ERC20PresetMinterPauser = artifacts.require(
  '@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser'
);
const { BigNumber, ethers } = require("ethers");

contract('LeverageAMM test', async (accounts) => {
  let lamm;
  let tokenETH;
  let tokenUSD;

  let rt;
  let ru;

  let decimalsETH;
  let decimalsUSD;

  const maxLeverage = 10;

  let depositAmount;

  it('check deployed', async () => {
    lamm = await LeverageAMM.deployed();

    assert.notEqual(lamm.address, undefined, 'AMM is not deployed');
  });

  it('initialize', async () => {
    tokenETH = await ERC20PresetMinterPauser.new("sETH", "ETH"); 
    tokenUSD = await ERC20PresetMinterPauser.new("sUSD", "USD");
    
    assert.notEqual(tokenETH.address, undefined, 'tokenETH is not created');
    assert.notEqual(tokenUSD.address, undefined, 'tokenUSD is not created');

    decimalsETH = parseInt((await tokenETH.decimals()).toString());
    decimalsUSD = parseInt((await tokenUSD.decimals()).toString());
    rt = ethers.utils.parseUnits("1000", decimalsETH);
    ru = ethers.utils.parseUnits("10000", decimalsUSD);
    
    await tokenETH.mint(accounts[0], rt);
    await tokenUSD.mint(accounts[0], ru);

    await tokenETH.approve.sendTransaction(lamm.address, rt, {
      from: accounts[0]
    });
    await tokenUSD.approve.sendTransaction(lamm.address, ru, {
      from: accounts[0]
    });
    
    lamm.initialize(tokenETH.address, tokenUSD.address, rt, ru, maxLeverage);
  });

  it('deposit', async () => {
    depositAmount = ethers.utils.parseUnits("50", decimalsUSD);
    await tokenUSD.mint(accounts[1], depositAmount);

    await tokenUSD.approve.sendTransaction(lamm.address, depositAmount, {
      from: accounts[1]
    });

    await lamm.deposit.sendTransaction(tokenUSD.address, depositAmount, {
      from: accounts[1]
    });

    // check margin amount
    const margin = await lamm.margin(accounts[1], tokenUSD.address);
    assert.equal(margin.toString(), depositAmount.toString(), "Deposit amount isn't correct");
  });

  it('calcAmount & openPosition', async () => {
    const leverage = 8;
    const margin = await lamm.margin(accounts[1], tokenUSD.address);
    const amountOut = await lamm.calcAmount(tokenETH.address, leverage, margin);

    const balanceETHBefore = await lamm.positionAmount(accounts[1], tokenETH.address);

    await lamm.openPosition.sendTransaction(tokenETH.address, leverage, {
      from: accounts[1]
    });

    const balanceETHAfter = await lamm.positionAmount(accounts[1], tokenETH.address);

    assert.equal(amountOut, balanceETHAfter - balanceETHBefore, "amountOut value is not correct");
  });

  it('remainAmount', async () => {
    const { remainValue, positionValue } = await lamm.remainAmount(accounts[1], tokenUSD.address);

    const remainValueExpected = ethers.utils.parseUnits("100", decimalsUSD);
    const positionValueExpected = ethers.utils.parseUnits("400", decimalsUSD);

    assert.equal(remainValue.toString(), remainValueExpected.toString(), "remainValue is not correct");
    assert.equal(positionValue.toString(), positionValueExpected.toString(), "positionValue is not correct");
  });

  it('withdarw', async() => {
    const marginBefore = await lamm.margin(accounts[1], tokenUSD.address);
    const withdrawAmount = ethers.utils.parseUnits("5", decimalsUSD);

    await lamm.withdraw.sendTransaction(tokenUSD.address, withdrawAmount, {
      from: accounts[1]
    });

    const marginAfter = await lamm.margin(accounts[1], tokenUSD.address);

    assert.equal((marginBefore - marginAfter).toString(), withdrawAmount.toString(), "withdrawn amount is not correct");
  });
});
