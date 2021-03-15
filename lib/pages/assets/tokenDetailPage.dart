import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/api/types/transferData.dart';
import 'package:polkawallet_plugin_acala/pages/assets/transferPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/borderedTitle.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TokenDetailPage extends StatelessWidget {
  TokenDetailPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  final colorIn = Color(0xFF62CFE4);
  final colorOut = Color(0xFF3394FF);

  static final String route = '/assets/token/detail';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');

    final TokenBalanceData token = ModalRoute.of(context).settings.arguments;

    final primaryColor = Theme.of(context).primaryColor;
    final titleColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(token.name),
        centerTitle: true,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final balance = Fmt.balanceInt(
                plugin.store.assets.tokenBalanceMap[token.symbol]?.amount ??
                    '0');

            final txs = plugin.store.assets.txs.reversed.toList();
            txs.retainWhere((i) => i.token.toUpperCase() == token.symbol);
            return Column(
              children: <Widget>[
                Stack(
                  alignment: AlignmentDirectional.bottomCenter,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      alignment: Alignment.center,
                      color: primaryColor,
                      padding: EdgeInsets.only(bottom: 24),
                      margin: EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 40),
                        child: Text(
                          Fmt.token(balance, token.decimals, length: 8),
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: titleColor,
                        borderRadius:
                            const BorderRadius.all(const Radius.circular(16)),
                      ),
                      child: Row(
                        children: <Widget>[
                          BorderedTitle(
                            title: dic['loan.txs'],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    color: titleColor,
                    child: ListView.builder(
                      itemCount: txs.length + 1,
                      itemBuilder: (_, i) {
                        if (i == txs.length) {
                          return ListTail(
                              isEmpty: txs.length == 0, isLoading: false);
                        }
                        return TransferListItem(
                          data: txs[i],
                          token: token.symbol,
                          isOut: true,
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  color: titleColor,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.fromLTRB(16, 8, 8, 8),
                          child: RoundedButton(
                            icon: Icon(Icons.qr_code,
                                color: titleColor, size: 24),
                            text: dic['receive'],
                            color: colorIn,
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, AccountQrCodePage.route);
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.fromLTRB(8, 8, 16, 8),
                          child: RoundedButton(
                            icon: SizedBox(
                              height: 20,
                              child:
                                  Image.asset('assets/images/assets_send.png'),
                            ),
                            text: dic['transfer'],
                            color: colorOut,
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                TransferPage.route,
                                arguments: token.symbol,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TransferListItem extends StatelessWidget {
  TransferListItem({
    this.data,
    this.token,
    this.isOut,
    this.crossChain,
  });

  final TransferData data;
  final String token;
  final String crossChain;
  final bool isOut;

  final colorIn = Color(0xFF62CFE4);
  final colorOut = Color(0xFF3394FF);

  @override
  Widget build(BuildContext context) {
    final address = isOut ? data.to : data.from;
    final title =
        Fmt.address(address) ?? data.extrinsicIndex ?? Fmt.address(data.hash);
    final colorFailed = Theme.of(context).unselectedWidgetColor;
    final amount = Fmt.priceFloor(double.parse(data.amount), lengthFixed: 4);
    return ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          data.success
              ? isOut
                  ? SvgPicture.asset('assets/images/assets_up.svg', width: 32)
                  : SvgPicture.asset('assets/images/assets_down.svg', width: 32)
              : SvgPicture.asset('assets/images/tx_failed.svg', width: 32)
        ],
      ),
      title: Text('$title${crossChain != null ? ' ($crossChain)' : ''}'),
      subtitle: Text(Fmt.dateTime(
          DateTime.fromMillisecondsSinceEpoch(data.blockTimestamp * 1000))),
      trailing: Container(
        width: 110,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${isOut ? '-' : '+'} $amount',
                style: TextStyle(
                    color: data.success
                        ? isOut
                            ? colorOut
                            : colorIn
                        : colorFailed,
                    fontSize: 16),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
