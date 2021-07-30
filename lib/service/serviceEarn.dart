import 'dart:math';

import 'package:polkawallet_plugin_acala/api/acalaApi.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/store/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_ui/utils/format.dart';

class ServiceEarn {
  ServiceEarn(this.plugin, this.keyring)
      : api = plugin.api,
        store = plugin.store;

  final PluginAcala plugin;
  final Keyring keyring;
  final AcalaApi api;
  final PluginStore store;

  Map<String, double> _calcIncentives(
      Map rewards, List<DexPoolData> pools, int epochOfYear) {
    final res = Map<String, double>();
    rewards.forEach((k, v) {
      final amount =
          Fmt.balanceDouble(v.toString(), plugin.networkState.tokenDecimals[0]);
      final pool = pools
          .firstWhere((e) => e.tokens.map((t) => t['token']).join('-') == k);
      final poolInfo = store.earn.dexPoolInfoMap[k];

      /// poolValue = LPAmountOfPool / LPIssuance * token0Issuance * token0Price * 2;
      final stakingPoolValue = poolInfo.sharesTotal /
          poolInfo.issuance *
          Fmt.bigIntToDouble(poolInfo.amountLeft, pool.pairDecimals[0]) *
          store.assets.marketPrices[pool.tokens[0]['token'].toString()] *
          2;

      /// rewardsRate = rewardsAmount * rewardsTokenPrice / poolValue;
      final rate = amount *
          store.assets.marketPrices[plugin.networkState.tokenSymbol[0]] /
          stakingPoolValue;
      if (amount > 0) {
        res[k] = pow(1 + rate, epochOfYear) - 1;
      } else {
        res[k] = 0;
      }
    });
    return res;
  }

  Map<String, double> _calcSavingRates(Map savingRates, int epochOfYear) {
    final stableCoin = plugin.basic.name == plugin_name_karura
        ? karura_stable_coin
        : acala_stable_coin;
    final res = Map<String, double>();
    savingRates.forEach((k, v) {
      final rate = Fmt.balanceDouble(
          v.toString(),
          plugin.networkState.tokenDecimals[
              plugin.networkState.tokenSymbol.indexOf(stableCoin)]);
      if (rate > 0) {
        res[k] = pow(1 + rate, epochOfYear) - 1;
      } else {
        res[k] = 0;
      }
    });
    return res;
  }

  Map<String, double> _calcDeductionRates(Map deductionRates) {
    final res = Map<String, double>();
    deductionRates.forEach((k, v) {
      res[k] = Fmt.balanceDouble(v.toString(), acala_price_decimals);
    });
    return res;
  }

  Future<List<DexPoolData>> getDexPools() async {
    final pools = await api.swap.getTokenPairs();
    store.earn.setDexPools(pools);
    return pools;
  }

  Future<List<DexPoolData>> getBootstraps() async {
    final pools = await api.swap.getBootstraps();
    store.earn.setBootstraps(pools);
    return pools;
  }

  Future<void> queryDexPoolRewards(DexPoolData pool) async {
    final rewards = await api.swap.queryDexLiquidityPoolRewards([pool]);

    final blockTime = plugin.networkConst['babe'] == null
        ? BLOCK_TIME_DEFAULT
        : int.parse(plugin.networkConst['babe']['expectedBlockTime']);
    final epoch =
        int.parse(plugin.networkConst['incentives']['accumulatePeriod']);
    final epochOfYear = SECONDS_OF_YEAR * 1000 ~/ blockTime ~/ epoch;

    final res = Map<String, Map<String, double>>();
    res['incentives'] =
        _calcIncentives(rewards['incentives'], [pool], epochOfYear);
    res['savingRates'] = _calcSavingRates(rewards['savingRates'], epochOfYear);
    res['deductionRates'] = _calcDeductionRates(rewards['deductionRates']);
    store.earn.setDexPoolRewards(res);
  }

  Future<void> queryDexPoolInfo(String poolId) async {
    final info =
        await api.swap.queryDexPoolInfo(poolId, keyring.current.address);
    store.earn.setDexPoolInfo(info);
  }

  double getSwapFee() {
    return plugin.networkConst['dex']['getExchangeFee'][0] /
        plugin.networkConst['dex']['getExchangeFee'][1];
  }
}
