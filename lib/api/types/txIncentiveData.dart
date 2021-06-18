import 'dart:convert';

import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxDexIncentiveData extends _TxDexIncentiveData {
  static const String actionRewardIncentive = 'dexIncentive';
  static const String actionRewardSaving = 'dexSaving';
  static const String actionStake = 'depositDexShare';
  static const String actionUnStake = 'withdrawDexShare';
  static TxDexIncentiveData fromJson(Map<String, dynamic> json,
      String stableCoinSymbol, List<String> symbols, List<int> decimals) {
    final args = jsonDecode(json['args']);

    final data = TxDexIncentiveData();
    data.block = json['extrinsic']['block']['number'];
    data.hash = json['extrinsic']['id'];

    if (json['method'] == 'claimRewards') {
      data.action = Map.of(args[0]).keys.toList()[0];
    } else {
      data.action = json['method'];
    }
    final stableCoinDecimals = decimals[symbols.indexOf(stableCoinSymbol)];

    switch (data.action) {
      case actionRewardIncentive: // incentive reward is ACA
      case actionRewardSaving: // saving reward is aUSD
        break;
      case actionStake:
      case actionUnStake:
        final pair = args[0]['dexShare'];
        final poolId = pair.join('-');
        final shareTokenView = PluginFmt.tokenView(poolId);

        final token = pair.firstWhere((e) => e != stableCoinSymbol);
        final tokenDecimals = decimals[symbols.indexOf(token)];
        final shareDecimals = stableCoinDecimals >= tokenDecimals
            ? stableCoinDecimals
            : tokenDecimals;
        data.amountShare =
            '${Fmt.balance(args[1].toString(), shareDecimals)} $shareTokenView';
        break;
    }
    data.time = json['extrinsic']['timestamp'] as String;
    data.isSuccess = json['isSuccess'];
    return data;
  }
}

abstract class _TxDexIncentiveData {
  String block;
  String hash;
  String action;
  String amountShare;
  String time;
  bool isSuccess = true;
}
