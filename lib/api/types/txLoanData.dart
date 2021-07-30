import 'dart:math';

import 'package:polkawallet_ui/utils/format.dart';

class TxLoanData extends _TxLoanData {
  static const String actionTypeDeposit = 'deposit';
  static const String actionTypeWithdraw = 'withdraw';
  static const String actionTypeBorrow = 'borrow';
  static const String actionTypePayback = 'payback';
  static const String actionTypeCreate = 'create';
  static TxLoanData fromJson(Map json, String stableCoinSymbol,
      int stableCoinDecimals, int tokenDecimals) {
    TxLoanData data = TxLoanData();
    data.block = json['extrinsic']['block']['number'];
    data.hash = json['extrinsic']['id'];

    data.token = json['token']['id'];

    data.collateral = Fmt.balanceInt(json['collateral'].toString());
    data.debit = Fmt.balanceInt(json['debit'].toString()) *
        Fmt.balanceInt(json['exchangeRate'].toString()) ~/
        BigInt.from(pow(10, 18));
    data.amountCollateral =
        Fmt.priceFloorBigInt(BigInt.zero - data.collateral, tokenDecimals);
    data.amountDebit = Fmt.priceCeilBigInt(data.debit, stableCoinDecimals);
    if (data.collateral == BigInt.zero) {
      data.actionType =
          data.debit > BigInt.zero ? actionTypeBorrow : actionTypePayback;
    } else if (data.debit == BigInt.zero) {
      data.actionType = data.collateral > BigInt.zero
          ? actionTypeDeposit
          : actionTypeWithdraw;
    } else if (data.debit < BigInt.zero) {
      data.actionType = actionTypePayback;
    } else {
      data.actionType = actionTypeCreate;
    }

    data.time = (json['extrinsic']['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = json['extrinsic']['isSuccess'];
    return data;
  }
}

abstract class _TxLoanData {
  String block;
  String hash;

  String token;
  String actionType;
  BigInt collateral;
  BigInt debit;
  String amountCollateral;
  String amountDebit;

  String time;
  bool isSuccess = true;
}
