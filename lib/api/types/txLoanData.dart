import 'dart:math';

import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_plugin_acala/common/constants.dart';

class TxLoanData extends _TxLoanData {
  static const String actionTypeDeposit = 'deposit';
  static const String actionTypeWithdraw = 'withdraw';
  static const String actionTypeBorrow = 'borrow';
  static const String actionTypePayback = 'payback';
  static const String actionTypeCreate = 'create';
  static TxLoanData fromJson(
      Map json, List<String> symbols, List<int> decimals) {
    TxLoanData data = TxLoanData();
    data.block = json['extrinsic']['block']['number'];
    data.hash = json['extrinsic']['id'];

    data.token = json['token']['id'];

    final stableCoinDecimals = decimals[symbols.indexOf(acala_stable_coin)];
    final tokenDecimals = decimals[symbols.indexOf(data.token)];
    final collateralInt = Fmt.balanceInt(json['collateral'].toString());
    final debitInt = Fmt.balanceInt(json['debit'].toString()) * Fmt.balanceInt(json['exchangeRate'].toString()) ~/ BigInt.from(pow(10, 18));
    data.amountCollateral = Fmt.priceFloorBigInt(BigInt.zero - collateralInt, tokenDecimals);
    data.amountDebit = Fmt.priceCeilBigInt(debitInt, stableCoinDecimals);
    if (collateralInt == BigInt.zero) {
      data.actionType =
          debitInt > BigInt.zero ? actionTypeBorrow : actionTypePayback;
    } else if (debitInt == BigInt.zero) {
      data.actionType =
          collateralInt > BigInt.zero ? actionTypeDeposit : actionTypeWithdraw;
    } else if (debitInt < BigInt.zero) {
      data.actionType = actionTypePayback;
    } else {
      data.actionType = actionTypeCreate;
    }

    data.time = (json['extrinsic']['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = json['isSuccess'];
    return data;
  }
}

abstract class _TxLoanData {
  String block;
  String hash;

  String token;
  String actionType;
  String amountCollateral;
  String amountDebit;

  String time;
  bool isSuccess = true;
}
