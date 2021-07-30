import 'dart:async';
import 'dart:convert';

import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';

class AcalaServiceSwap {
  AcalaServiceSwap(this.plugin);

  final PluginAcala plugin;

  Future<Map> queryTokenSwapAmount(
    String supplyAmount,
    String targetAmount,
    List<String> swapPair,
    String slippage,
  ) async {
    final code =
        'acala.calcTokenSwapAmount(api, $supplyAmount, $targetAmount, ${jsonEncode(swapPair)}, $slippage)';
    final output = await plugin.sdk.webView.evalJavascript(code);
    return output;
  }

  Future<List> getTokenPairs() async {
    return await plugin.sdk.webView.evalJavascript('acala.getTokenPairs(api)');
  }

  Future<List> getBootstraps() async {
    return await plugin.sdk.webView.evalJavascript('acala.getBootstraps(api)');
  }

  Future<Map> queryDexLiquidityPoolRewards(List<List> dexPools) async {
    // todo: fix this after new acala online
    final isTC6 = plugin.basic.name == plugin_name_acala;
    final pools = dexPools
        .map((pool) => jsonEncode(isTC6
            ? {'DEXShare': pool.map((e) => e['token']).toList()}
            : {
                'DexIncentive': {'DEXShare': pool}
              }))
        .toList();
    final incentiveQuery = pools
        .map((i) =>
            'api.query.incentives.${isTC6 ? 'dEXIncentiveRewards' : 'incentiveRewardAmount'}($i)')
        .join(',');
    final savingRateQuery = pools
        .map((i) =>
            'api.query.incentives.${isTC6 ? 'dEXSavingRates' : 'dexSavingRewardRate'}($i)')
        .join(',');
    final res = await Future.wait([
      plugin.sdk.webView.evalJavascript('Promise.all([$incentiveQuery])'),
      plugin.sdk.webView.evalJavascript('Promise.all([$savingRateQuery])')
    ]);
    List deductions;
    if (!isTC6) {
      final deductionQuery = pools
          .map((i) => 'api.query.incentives.payoutDeductionRates($i)')
          .join(',');
      deductions = await plugin.sdk.webView
          .evalJavascript('Promise.all([$deductionQuery])');
    }
    final incentives = Map<String, dynamic>();
    final savingRates = Map<String, dynamic>();
    final deductionRates = Map<String, dynamic>();
    final tokenPairs =
        dexPools.map((e) => e.map((i) => i['token']).join('-')).toList();
    tokenPairs.asMap().forEach((k, v) {
      incentives[v] = res[0][k];
      savingRates[v] = res[1][k];
      if (deductions.length > 0) {
        deductionRates[v] = deductions[k];
      }
    });
    return {
      'incentives': incentives,
      'savingRates': savingRates,
      'deductionRates': deductionRates,
    };
  }

  Future<Map> queryDexPoolInfo(String pool, address) async {
    // todo: fix this after new acala online
    final isTC6 = plugin.basic.name == plugin_name_acala;
    final Map info = await plugin.sdk.webView
        .evalJavascript('acala.fetchDexPoolInfo(api, ${jsonEncode({
          'DEXShare': isTC6
              ? pool.split('-').map((e) => e.toUpperCase()).toList()
              : pool
                  .split('-')
                  .map((e) => ({'Token': e.toUpperCase()}))
                  .toList()
        })}, "$address")');
    return info;
  }
}
