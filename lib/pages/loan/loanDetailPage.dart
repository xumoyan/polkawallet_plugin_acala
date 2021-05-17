import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/common/constants.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanCard.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanChart.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';

class LoanDetailPage extends StatefulWidget {
  LoanDetailPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/loan/detail';

  @override
  _LoanDetailPageState createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    return Observer(
      builder: (_) {
        final token = ModalRoute.of(context).settings.arguments;
        final loan = widget.plugin.store.loan.loans[token];

        final symbols = widget.plugin.networkState.tokenSymbol;
        final decimals = widget.plugin.networkState.tokenDecimals;
        final stableCoinDecimals = decimals[symbols.indexOf(acala_stable_coin)];
        final collateralDecimals = decimals[symbols.indexOf(token)];

        final dataChartDebit = [
          Fmt.bigIntToDouble(loan.debitInUSD, stableCoinDecimals),
          Fmt.bigIntToDouble(
              loan.maxToBorrow - loan.debitInUSD > BigInt.zero
                  ? loan.maxToBorrow - loan.debitInUSD
                  : BigInt.zero,
              stableCoinDecimals),
        ];
        final price = widget.plugin.store.assets.prices[token];
        final dataChartPrice = [
          Fmt.bigIntToDouble(loan.liquidationPrice, stableCoinDecimals),
          Fmt.bigIntToDouble(
              price - loan.liquidationPrice > BigInt.zero
                  ? price - loan.liquidationPrice
                  : BigInt.zero,
              stableCoinDecimals),
          Fmt.bigIntToDouble(
              price ~/ (BigInt.one + BigInt.two), stableCoinDecimals),
        ];
        final requiredCollateralRatio =
            double.parse(Fmt.token(loan.type.requiredCollateralRatio, 18));
        final colorType = loan.collateralRatio > requiredCollateralRatio
            ? loan.collateralRatio > requiredCollateralRatio + 0.2
                ? 0
                : 1
            : loan.collateralRatio > 1
                ? 2
                : 0;

        final aUSDBalance = Fmt.balanceInt(widget
            .plugin.store.assets.tokenBalanceMap[acala_stable_coin].amount);
        final tokenBalance = Fmt.balanceInt(
            widget.plugin.store.assets.tokenBalanceMap[token].amount);

        final titleStyle = TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).unselectedWidgetColor,
          letterSpacing: -0.8,
        );
        final subtitleStyle = TextStyle(fontSize: 12);

        return Scaffold(
          backgroundColor: Theme.of(context).cardColor,
          appBar: AppBar(
              title: Text(PluginFmt.tokenView(token)), centerTitle: true),
          body: SafeArea(
            child: AccountCardLayout(widget.keyring.current, Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: Row(children: [
                            Expanded(
                                child: RoundedCard(
                                    padding:
                                    EdgeInsets.only(top: 8, bottom: 16),
                                    child: Column(
                                      children: [
                                        LoanDonutChart(
                                          dataChartDebit,
                                          title: Fmt.priceFloorBigInt(
                                              loan.debits, stableCoinDecimals),
                                          subtitle: dic['loan.borrowed'],
                                          colorType: colorType,
                                        ),
                                        Text(
                                            Fmt.priceFloorBigInt(
                                                loan.maxToBorrow,
                                                stableCoinDecimals),
                                            style: titleStyle),
                                        Text('${dic['borrow.limit']}(aUSD)',
                                            style: subtitleStyle)
                                      ],
                                    ))),
                            Container(width: 16),
                            Expanded(
                                child: RoundedCard(
                                    padding:
                                    EdgeInsets.only(top: 8, bottom: 16),
                                    child: Column(
                                      children: [
                                        LoanDonutChart(
                                          dataChartPrice,
                                          title: Fmt.priceFloorBigInt(
                                              loan.liquidationPrice, 18),
                                          subtitle: dic['liquid.price'],
                                          colorType: colorType,
                                        ),
                                        Text(Fmt.priceFloorBigInt(price, 18),
                                            style: titleStyle),
                                        Text('${dic['collateral.price']}(\$)',
                                            style: subtitleStyle)
                                      ],
                                    ))),
                          ])),
                      LoanCollateralCard(
                          loan,
                          Fmt.priceFloorBigInt(
                              tokenBalance, collateralDecimals),
                          stableCoinDecimals,
                          collateralDecimals,
                          widget.plugin.tokenIcons),
                      LoanDebtCard(
                          loan,
                          Fmt.priceFloorBigInt(aUSDBalance, stableCoinDecimals),
                          stableCoinDecimals,
                          collateralDecimals,
                          widget.plugin.tokenIcons),
                    ],
                  ),
                ),
              ],
            ),),
          ),
        );
      },
    );
  }
}
