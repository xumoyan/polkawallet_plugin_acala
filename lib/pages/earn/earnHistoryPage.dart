import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/api/types/txLiquidityData.dart';
import 'package:polkawallet_plugin_acala/common/constants.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/utils/format.dart';

class EarnHistoryPage extends StatelessWidget {
  EarnHistoryPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/earn/txs';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['loan.txs']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final symbols = plugin.networkState.tokenSymbol;
            final decimals = plugin.networkState.tokenDecimals;

            final String poolId = ModalRoute.of(context).settings.arguments;
            final pair = poolId.toUpperCase().split('-');
            final pairView = pair.map((e) => PluginFmt.tokenView(e)).toList();

            final token = pair.firstWhere((e) => e != acala_stable_coin);
            final stableCoinDecimals =
                decimals[symbols.indexOf(acala_stable_coin)];
            final tokenDecimals = decimals[symbols.indexOf(token)];
            final shareDecimals = stableCoinDecimals >= tokenDecimals
                ? stableCoinDecimals
                : tokenDecimals;
            final decimalsLeft = pair[0] == acala_stable_coin
                ? stableCoinDecimals
                : tokenDecimals;
            final decimalsRight = pair[0] == acala_stable_coin
                ? tokenDecimals
                : stableCoinDecimals;

            final list = plugin.store.earn.txs.reversed.toList();
            list.retainWhere((i) => i.currencyId == poolId);

            return ListView.builder(
              itemCount: list.length + 1,
              itemBuilder: (BuildContext context, int i) {
                if (i == list.length) {
                  return ListTail(isEmpty: list.length == 0, isLoading: false);
                }

                TxDexLiquidityData detail = list[i];
                String amount = '';
                bool isReceive = true;
                switch (detail.action) {
                  case TxDexLiquidityData.actionDeposit:
                    amount =
                        '${Fmt.priceCeilBigInt(detail.amountLeft, decimalsLeft)} ${pairView[0]}\n+ ${Fmt.priceCeilBigInt(detail.amountRight, decimalsRight)} ${pairView[1]}';
                    isReceive = false;
                    break;
                  case TxDexLiquidityData.actionWithdraw:
                    amount =
                        '${Fmt.priceFloorBigInt(detail.amountShare, shareDecimals, lengthFixed: 0)} ${PluginFmt.tokenView(poolId)}';
                    break;
                  case TxDexLiquidityData.actionRewardIncentive:
                    amount =
                        '${Fmt.priceCeilBigInt(detail.amountLeft, decimals[symbols.indexOf('ACA')])} ACA';
                    break;
                  case TxDexLiquidityData.actionRewardSaving:
                    amount =
                        '${Fmt.priceCeilBigInt(detail.amountRight, stableCoinDecimals)} $acala_stable_coin_view';
                    break;
                  case TxDexLiquidityData.actionStake:
                    amount =
                        '${Fmt.priceCeilBigInt(detail.amountShare, shareDecimals)} ${PluginFmt.tokenView(poolId)}';
                    isReceive = false;
                    break;
                  case TxDexLiquidityData.actionUnStake:
                    amount =
                        '${Fmt.priceCeilBigInt(detail.amountShare, shareDecimals)} ${PluginFmt.tokenView(poolId)}';
                    break;
                }
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(width: 0.5, color: Colors.black12)),
                  ),
                  child: ListTile(
                    title: Text(detail.action),
                    subtitle: Text(Fmt.dateTime(detail.time)),
                    leading: SvgPicture.asset(
                        'assets/images/assets_${isReceive ? 'down' : 'up'}.svg',
                        width: 32),
                    trailing: Text(
                      amount,
                      style: Theme.of(context).textTheme.headline4,
                      textAlign: TextAlign.end,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
