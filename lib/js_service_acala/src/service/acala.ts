import { StakingPool } from "@acala-network/sdk-homa";
import { FixedPointNumber, TokenPair, TokenBalance, Token, DexShare } from "@acala-network/sdk-core";
import { SwapPromise } from "@acala-network/sdk-swap";
import { ApiPromise } from "@polkadot/api";
import { tokensForAcala, tokensForKarura } from "../constants/acala";

let swapper: SwapPromise;
/**
 * calc token swap amount
 */
async function calcTokenSwapAmount(api: ApiPromise, input: number, output: number, swapPair: string[], slippage: number) {
  if (!swapper) {
    swapper = new SwapPromise(api);
  }

  const inputToken = Token.fromCurrencyId(api.createType("CurrencyId" as any, { token: swapPair[0] }));
  const outputToken = Token.fromCurrencyId(api.createType("CurrencyId" as any, { token: swapPair[1] }));
  const i = new TokenBalance(inputToken, new FixedPointNumber(input || 0, inputToken.decimal));
  const o = new TokenBalance(outputToken, new FixedPointNumber(output || 0, outputToken.decimal));

  const mode = output === null ? "EXACT_INPUT" : "EXACT_OUTPUT";

  return new Promise((resolve, reject) => {
    swapper.swap(i, o, mode, (res: any) => {
      console.log(res);
      resolve({
        amount: output === null ? res.output.balance.toNumber(6) : res.input.balance.toNumber(6),
        path: res.path,
        input: res.input.token.toString(),
        output: res.output.token.toString(),
      });
    });
  });
}

async function queryLPTokens(api: ApiPromise, address: string) {
  const allTokens = (api.consts.dex.enabledTradingPairs as any).map((item: any) =>
    api.createType("CurrencyId" as any, {
      DEXShare: [item[0].asToken.toString(), item[1].asToken.toString()],
    })
  );

  const res = await api.queryMulti(allTokens.map((e) => [api.query.tokens.accounts, [address, e]]));
  return (res as any)
    .map((e: any, i: number) => ({ free: e.free.toString(), currencyId: allTokens[i].asDexShare }))
    .filter((e: any) => e.free > 0);
}

/**
 * getAllTokenPairs
 */
async function getTokenPairs(api: ApiPromise) {
  const tokenPairs = await api.query.dex.tradingPairStatuses.entries();
  return tokenPairs
    .filter((item) => (item[1] as any).isEnabled)
    .map(
      ([
        {
          args: [item],
        },
      ]) => {
        const pair = DexShare.fromCurrencyId(
          api.createType("CurrencyId" as any, { DEXShare: [(item[0] as any).asToken.toString(), (item[1] as any).asToken.toString()] })
        );
        return {
          decimals: pair.decimal,
          tokens: [{ token: pair.token1.symbol }, { token: pair.token2.symbol }],
        };
      }
    );
}

async function getAllTokenSymbols(chain: string) {
  return chain.match("karura") ? tokensForKarura : tokensForAcala;
}

/**
 * fetchDexPoolInfo
 * @param {String} poolId
 * @param {String} address
 */
async function fetchDexPoolInfo(api: ApiPromise, pool: any, address: string) {
  const res = (await Promise.all([
    api.query.dex.liquidityPool(pool.DEXShare.map((e: any) => ({ Token: e }))),
    api.query.rewards.pools({ DexIncentive: pool }),
    api.query.rewards.pools({ DexSaving: pool }),
    api.query.rewards.shareAndWithdrawnReward({ DexIncentive: pool }, address),
    api.query.rewards.shareAndWithdrawnReward({ DexSaving: pool }, address),
    api.query.tokens.totalIssuance(pool),
  ])) as any;
  let proportion = new FixedPointNumber(0);
  if (res[1] && res[3]) {
    proportion = FPNum(res[3][0]).div(FPNum(res[1].totalShares));
  }
  return {
    token: pool.DEXShare.join("-"),
    pool: res[0],
    sharesTotal: res[1].totalShares,
    shares: res[3][0],
    proportion: proportion.toNumber() || 0,
    reward: {
      incentive: FPNum(res[1].totalRewards)
        .times(proportion)
        .minus(FPNum(res[3][1]))
        .toString(),
      saving: FPNum(res[2].totalRewards)
        .times(proportion)
        .minus(FPNum(res[4][1]))
        .toString(),
    },
    issuance: res[5],
  };
}

function FPNum(input: any) {
  return FixedPointNumber.fromInner(input.toString());
}

async function _calacFreeList(api: ApiPromise, start: number, duration: number) {
  const list = [];
  for (let i = start; i < start + duration; i++) {
    const result = await api.query.stakingPool.unbonding(i);
    const free = FixedPointNumber.fromInner(result[0]).minus(FixedPointNumber.fromInner(result[1]));
    list.push({
      era: i,
      free: free.toNumber(),
    });
  }
  return list.filter((item) => item.free);
}

let homaStakingPool;

async function fetchHomaStakingPool(api: ApiPromise) {
  const [stakingPool, { mockRewardRate }] = (await Promise.all([
    (api.derive as any).homa.stakingPool(),
    api.query.polkadotBridge.subAccounts(1),
  ])) as any;

  const poolInfo = new StakingPool({
    params: {
      baseFeeRate: FPNum(stakingPool.params.baseFeeRate),
      targetMaxFreeUnbondedRatio: FPNum(stakingPool.params.targetMaxFreeUnbondedRatio),
      targetMinFreeUnbondedRatio: FPNum(stakingPool.params.targetMinFreeUnbondedRatio),
      targetUnbondingToFreeRatio: FPNum(stakingPool.params.targetUnbondingToFreeRatio),
    },
    defaultExchangeRate: FPNum(stakingPool.defaultExchangeRate),
    liquidTotalIssuance: FPNum(stakingPool.liquidIssuance),
    currentEra: stakingPool.currentEra.toNumber(),
    bondingDuration: stakingPool.bondingDuration.toNumber(),
    ledger: {
      toUnbondNextEra: stakingPool.ledger.toUnbondNextEra.map((e: any) => FPNum(e)),
      bonded: FPNum(stakingPool.ledger.bonded),
      unbondingToFree: FPNum(stakingPool.ledger.unbondingToFree),
      freePool: FPNum(stakingPool.ledger.freePool),
    },
  });
  homaStakingPool = poolInfo;

  const freeList = await _calacFreeList(api, stakingPool.currentEra.toNumber() + 1, stakingPool.bondingDuration.toNumber());
  const eraLength = api.consts.polkadotBridge.eraLength as any;
  const expectedBlockTime = api.consts.babe.expectedBlockTime;
  const unbondingDuration = expectedBlockTime.toNumber() * eraLength.toNumber() * stakingPool.bondingDuration.toNumber();
  return {
    // ...stakingPoolHelper,
    rewardRate: mockRewardRate.toString(),
    freeList,
    unbondingDuration,
    liquidTokenIssuance: stakingPool.liquidIssuance.toString(),
    defaultExchangeRate: FPNum(stakingPool.defaultExchangeRate).toNumber(),
    bondingDuration: stakingPool.bondingDuration.toNumber(),
    currentEra: stakingPool.currentEra.toNumber(),
    communalBonded: poolInfo.ledger.bondedBelongToLiquidHolders.toNumber(),
    communalTotal: poolInfo.ledger.total.toNumber(),
    communalFreeRatio: poolInfo.ledger.freePoolRatio.toNumber(),
    unbondingToFreeRatio: poolInfo.ledger.unbondingToFreeRatio.toNumber(),
    communalBondedRatio: poolInfo.ledger.bondedBelongToLiquidHolders.div(poolInfo.ledger.total).toNumber(),
    liquidExchangeRate: poolInfo.liquidExchangeRate().toNumber(),
  };
}

async function fetchHomaUserInfo(api: ApiPromise, address: string) {
  const stakingPool = await (api.derive as any).homa.stakingPool();
  const start = stakingPool.currentEra.toNumber() + 1;
  const duration = stakingPool.bondingDuration.toNumber();
  const nextEraUnbund = (await api.query.stakingPool.nextEraUnbonds(address)) as any;
  const claims = [
    {
      era: start,
      claimed: nextEraUnbund,
    },
  ];
  for (let i = start + 1; i < start + duration + 2; i++) {
    const claimed = (await api.query.stakingPool.claimedUnbond(address, i)) as any;
    if (claimed.gtn(0)) {
      claims[claims.length] = {
        era: i,
        claimed,
      };
    }
  }
  const unbonded = await (api.rpc as any).stakingPool.getAvailableUnbonded(address);
  return {
    unbonded: unbonded.amount || 0,
    claims,
  };
}

async function queryHomaRedeemAmount(api: ApiPromise, amount: number, redeemType: number, targetEra: number) {
  if (redeemType == 0) {
    const res = await homaStakingPool.getStakingAmountInRedeemByFreeUnbonded(new FixedPointNumber(amount));
    return {
      demand: res.demand.toNumber(),
      fee: res.fee.toNumber(),
      received: res.received.toNumber(),
    };
  } else if (redeemType == 1) {
    const unbonding = await api.query.stakingPool.unbonding(targetEra);
    const res = await homaStakingPool.getStakingAmountInClaimUnbonding(new FixedPointNumber(amount), targetEra, {
      unbonding: FixedPointNumber.fromInner(unbonding[0].toString()),
      claimedUnbonding: FixedPointNumber.fromInner(unbonding[1].toString()),
      initialClaimedUnbonding: FixedPointNumber.fromInner(unbonding[2].toString()),
    });
    return {
      atEra: res.atEra,
      demand: res.demand.toNumber(),
      fee: res.fee.toNumber(),
      received: res.received.toNumber(),
    };
  } else if (redeemType == 2) {
    const res = await homaStakingPool.getStakingAmountInRedeemByUnbond(new FixedPointNumber(amount));
    return {
      atEra: res.atEra,
      amount: res.amount.toNumber(),
    };
  }
}

async function queryNFTs(api: ApiPromise, address: string) {
  const tokens = await api.query.ormlNft.tokensByOwner.entries(address);
  const nfts = tokens.map((item) => {
    return {
      classes: item[0].args[1][0].toString(),
      tokenId: item[0].args[1][1].toString(),
    };
  });
  const res = await api.queryMulti(
    nfts.map((nft: { classes: string; tokenId: string }) => {
      return [api.query.ormlNft.tokens, [nft.classes, nft.tokenId]];
    })
  );
  return res
    .map((item: any) => item.unwrap())
    .map((item) => {
      try {
        return JSON.parse(item.metadata.toUtf8());
      } catch (e) {
        return null;
      }
    })
    .filter((i) => !!i);
}

export default {
  calcTokenSwapAmount,
  queryLPTokens,
  getTokenPairs,
  getAllTokenSymbols,
  fetchDexPoolInfo,
  fetchHomaStakingPool,
  fetchHomaUserInfo,
  queryHomaRedeemAmount,
  queryNFTs,
};
