const AMM = artifacts.require('AMM');
const ERC20PresetMinterPauser = artifacts.require(
  '@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser'
);
const { BigNumber, ethers } = require("ethers");

contract('AMM test', async (accounts) => {
  let amm;
  let tokenTWD;
  let tokenUSD;

  let rt;
  let ru;

  let decimalsTWD;
  let decimalsUSD;

  it('check deployed', async () => {
    amm = await AMM.deployed();

    assert.notEqual(amm.address, undefined, 'AMM is not deployed');
  });

  it('initialize', async () => {
    tokenTWD = await ERC20PresetMinterPauser.new("sTWD", "TWD"); 
    tokenUSD = await ERC20PresetMinterPauser.new("sUSD", "USD");
    
    assert.notEqual(tokenTWD.address, undefined, 'tokenTWD is not created');
    assert.notEqual(tokenUSD.address, undefined, 'tokenUSD is not created');

    decimalsTWD = parseInt((await tokenTWD.decimals()).toString());
    decimalsUSD = parseInt((await tokenUSD.decimals()).toString());
    rt = ethers.utils.parseUnits("10000", decimalsTWD);
    ru = ethers.utils.parseUnits("1000", decimalsUSD);
    
    await tokenTWD.mint(accounts[0], rt);
    await tokenUSD.mint(accounts[0], ru);

    await tokenTWD.approve.sendTransaction(amm.address, rt, {
      from: accounts[0]
    });
    await tokenUSD.approve.sendTransaction(amm.address, ru, {
      from: accounts[0]
    });
    
    amm.initialize(tokenTWD.address, tokenUSD.address, rt, ru);
  });

  it('swap', async () => {
    const amountIn = ethers.utils.parseUnits("6000", decimalsTWD);
    const amountOutExpect = ethers.utils.parseUnits("375", decimalsUSD);
    await tokenTWD.mint(accounts[1], amountIn);

    const balanceTWDBefore = await tokenTWD.balanceOf(accounts[1]);
    const balanceUSDBefore = await tokenUSD.balanceOf(accounts[1]);

    await tokenTWD.approve.sendTransaction(amm.address, amountIn, {
      from: accounts[1]
    });

    await amm.swap.sendTransaction(false, amountIn,{
      from: accounts[1]
    });

    // check balance change
    const balanceTWDAfter = await tokenTWD.balanceOf(accounts[1]);
    const balanceUSDAfter = await tokenUSD.balanceOf(accounts[1]);

    assert.equal(balanceTWDBefore - balanceTWDAfter, amountIn, "amountIn is not correct");
    assert.equal(balanceUSDAfter - balanceUSDBefore, amountOutExpect, "amountOut is not correct");

    // check Rt & Ru
    let newRt = await amm.r0();
    let newRu = await amm.r1();

    assert.equal(newRt - rt, amountIn, "newRt is not correct");
    assert.equal(ru - newRu, amountOutExpect, "newRu is not correct");

    rt = newRt;
    ru = newRu;
  });

  it('swap reverse', async () => {
    const amountIn = ethers.utils.parseUnits("375", decimalsTWD);
    const amountOutExpect = ethers.utils.parseUnits("6000", decimalsUSD);
    await tokenUSD.mint(accounts[1], amountIn);

    const balanceTWDBefore = await tokenTWD.balanceOf(accounts[1]);
    const balanceUSDBefore = await tokenUSD.balanceOf(accounts[1]);

    await tokenUSD.approve.sendTransaction(amm.address, amountIn, {
      from: accounts[1]
    });

    await amm.swap.sendTransaction(true, amountIn,{
      from: accounts[1]
    });

    // check balance change
    const balanceTWDAfter = await tokenTWD.balanceOf(accounts[1]);
    const balanceUSDAfter = await tokenUSD.balanceOf(accounts[1]);

    assert.equal(balanceUSDBefore - balanceUSDAfter, amountIn, "amountIn is not correct");
    assert.equal(balanceTWDAfter - balanceTWDBefore, amountOutExpect, "amountOut is not correct");

    // check Rt & Ru
    let newRt = await amm.r0();
    let newRu = await amm.r1();

    assert.equal(newRu - ru, amountIn, "newRu is not correct");
    assert.equal(rt - newRt, amountOutExpect, "newRt is not correct");

    rt = newRt;
    ru = newRu;
  });
});
