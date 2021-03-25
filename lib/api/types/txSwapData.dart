import 'package:polkawallet_ui/utils/format.dart';

class TxSwapData extends _TxSwapData {
  static TxSwapData fromJson(Map<String, dynamic> json) {
    TxSwapData data = TxSwapData();
    data.hash = json['hash'];
    final tokenPair = [
      json['params'][0][0],
      json['params'][0][List.of(json['params'][0]).length - 1]
    ];
    final isExactInput = json['mode'] == 0;

    data.tokenPay = tokenPair[0];
    data.tokenReceive = tokenPair[1];
    data.amountPay = Fmt.priceCeilBigInt(
        Fmt.balanceInt(json['params'][isExactInput ? 1 : 2]),
        tokenPair[0]['decimal'],
        lengthMax: 4);
    data.amountReceive = Fmt.priceFloorBigInt(
        Fmt.balanceInt(json['params'][isExactInput ? 2 : 1]),
        tokenPair[1]['decimal'],
        lengthMax: 4);
    data.time = DateTime.fromMillisecondsSinceEpoch(json['time']);
    return data;
  }
}

abstract class _TxSwapData {
  String hash;
  Map tokenPay;
  Map tokenReceive;
  String amountPay;
  String amountReceive;
  DateTime time;
}
