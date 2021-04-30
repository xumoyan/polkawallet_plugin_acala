import 'dart:convert';
import 'package:polkawallet_ui/utils/format.dart';

class TxSwapData extends _TxSwapData {
  static TxSwapData fromJson(
      Map json, List<String> symbols, List<int> decimals) {
    final args = jsonDecode(json['args']);

    final data = TxSwapData();
    data.block = json['extrinsic']['block']['number'];
    data.hash = json['extrinsic']['id'];
    final tokenPair = [args[0][0], args[0][List.of(args[0]).length - 1]];
    final isExactInput = json['mode'] == 0;

    data.tokenPay = tokenPair[0];
    data.tokenReceive = tokenPair[1];
    data.amountPay = Fmt.priceCeilBigInt(
        Fmt.balanceInt(args[isExactInput ? 2 : 1].toString()),
        decimals[symbols.indexOf(data.tokenPay['token'])],
        lengthMax: 4);
    data.amountReceive = Fmt.priceFloorBigInt(
        Fmt.balanceInt(args[isExactInput ? 1 : 2].toString()),
        decimals[symbols.indexOf(data.tokenReceive['token'])],
        lengthMax: 4);
    data.time = (json['extrinsic']['timestamp'] as String).replaceAll(' ', '');
    data.isSuccess = json['isSuccess'];
    return data;
  }
}

abstract class _TxSwapData {
  String block;
  String hash;
  Map tokenPay;
  Map tokenReceive;
  String amountPay;
  String amountReceive;
  String time;
  bool isSuccess = true;
}
