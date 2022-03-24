# SimpleAMM
It contains two contracts: *AMM* and *LeverageAMM*


## Introduction

### Build
```bash
npm install
truffle build
```

### Test
```bash
truffle test
```

## Notes

- Currently, available on localnet only. Make sure that Ganache is running on port 7545.
- *LeverageAMM.OpenPosition* is processed on storage yet.
- Assumed that *LeverageAMM* provides 2 ERC20 tokens, because providing multiple ERC20 tokens needs much more working to manage multiple sub AMMs.
- Assumed that ETH is also one of ERC20 token in the example.

## Reference

https://perp.notion.site/Pretest-Perpetual-Protocol-Smart-Contract-Engineer-2a02f5333d8746eeb1adfc720b6d9485
