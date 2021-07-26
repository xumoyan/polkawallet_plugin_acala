import 'dart:convert';

import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxDexIncentiveData extends _TxDexIncentiveData {
  // static const String actionRewardIncentive = 'dexIncentive';
  // static const String actionRewardSaving = 'dexSaving';
  static const String actionStake = 'depositDexShare';
  static const String actionUnStake = 'withdrawDexShare';
  static TxDexIncentiveData fromJson(Map<String, dynamic> json,
      String stableCoinSymbol, List<String> symbols, List<int> decimals) {
    final data = TxDexIncentiveData();
    data.block = json['extrinsic']['block']['number'];
    data.hash = json['extrinsic']['id'];
    data.action = json['extrinsic']['method'];

    switch (data.action) {
      // case actionRewardIncentive: // incentive reward is ACA
      // case actionRewardSaving: // saving reward is aUSD
      //   break;
      case actionStake:
      case actionUnStake:
        final pair = (jsonDecode(json['data'][1]['value'])['dexShare'] as List)
            .map((e) => e['token'])
            .toList();
        final poolId = pair.join('-');
        final shareTokenView = PluginFmt.tokenView(poolId);
        data.amountShare =
            '${Fmt.balance(json['data'][2]['value'], decimals[symbols.indexOf(pair[0])])} $shareTokenView';
        break;
    }
    data.time = json['extrinsic']['timestamp'] as String;
    data.isSuccess = json['extrinsic']['isSuccess'];
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
