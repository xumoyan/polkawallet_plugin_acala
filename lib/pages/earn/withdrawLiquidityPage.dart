import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class WithdrawLiquidityPage extends StatefulWidget {
  WithdrawLiquidityPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/earn/withdraw';

  @override
  _WithdrawLiquidityPageState createState() => _WithdrawLiquidityPageState();
}

class _WithdrawLiquidityPageState extends State<WithdrawLiquidityPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = new TextEditingController();

  Timer _timer;

  bool _fromPool = false;

  Future<void> _refreshData() async {
    final String poolId = ModalRoute.of(context).settings.arguments;
    await widget.plugin.service.earn.queryDexPoolInfo(poolId);
    if (mounted) {
      _timer = Timer(Duration(seconds: 10), () {
        if (mounted) {
          _refreshData();
        }
      });
    }
  }

  void _onAmountSelect(BigInt v, int decimals) {
    setState(() {
      _amountCtrl.text = Fmt.bigIntToDouble(v, decimals).toStringAsFixed(4);
    });
    _formKey.currentState.validate();
  }

  String _validateInput(String value, int shareDecimals) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'common');

    final v = value.trim();
    if (v.isEmpty || double.parse(v.trim()) == 0) {
      return dic['amount.error'];
    }

    final symbols = widget.plugin.networkState.tokenSymbol;
    final String poolId = ModalRoute.of(context).settings.arguments;
    final pair = poolId.toUpperCase().split('-');
    final poolInfo = widget.plugin.store.earn.dexPoolInfoMap[poolId];

    final shareInput = Fmt.tokenInt(v, shareDecimals);
    final shareBalance = _fromPool
        ? poolInfo.shares
        : Fmt.balanceInt(widget
            .plugin.store.assets.tokenBalanceMap[poolId.toUpperCase()].amount);
    if (shareInput > shareBalance) {
      return dic['amount.low'];
    }

    final balancePair = PluginFmt.getBalancePair(widget.plugin, pair);
    if (pair[0] != symbols[0] &&
        Fmt.balanceInt(balancePair[0].amount) == BigInt.zero) {
      final min = Fmt.balanceDouble(
          existential_deposit[pair[0]], balancePair[0].decimals);
      if (Fmt.bigIntToDouble(shareInput, shareDecimals) / 2 < min) {
        return '${dic['amount.min']} ${Fmt.priceCeil(min * 2, lengthMax: 6)}';
      }
    }
    if (pair[1] != symbols[0] &&
        Fmt.balanceInt(balancePair[1].amount) == BigInt.zero) {
      final min = Fmt.balanceDouble(
          existential_deposit[pair[1]], balancePair[1].decimals);
      final exchangeRate = poolInfo.amountLeft / poolInfo.amountRight;
      if (Fmt.bigIntToDouble(shareInput, shareDecimals) / 2 / exchangeRate <
          min) {
        return '${dic['amount.min']} ${Fmt.priceCeil(min * 2 * exchangeRate, lengthMax: 6)}';
      }
    }
    return null;
  }

  Future<void> _onSubmit(int shareDecimals) async {
    if (_formKey.currentState.validate()) {
      final String poolId = ModalRoute.of(context).settings.arguments;
      final pair = poolId.toUpperCase().split('-');
      final amount = _amountCtrl.text.trim();

      // todo: fix this after new acala online
      final isTC6 = widget.plugin.basic.name == plugin_name_acala;
      final params = isTC6
          ? [
              {'Token': pair[0]},
              {'Token': pair[1]},
              Fmt.tokenInt(amount, shareDecimals).toString(),
              _fromPool,
            ]
          : [
              {'Token': pair[0]},
              {'Token': pair[1]},
              Fmt.tokenInt(amount, shareDecimals).toString(),
              '0',
              '0',
              _fromPool,
            ];
      final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'dex',
            call: 'removeLiquidity',
            txTitle: I18n.of(context)
                .getDic(i18n_full_dic_acala, 'acala')['earn.withdraw'],
            txDisplay: {
              "poolId": poolId,
              "amount": amount,
              "fromPool": _fromPool,
            },
            params: params,
          ))) as Map;
      if (res != null) {
        Navigator.of(context).pop(res);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }

    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
        final dicAssets =
            I18n.of(context).getDic(i18n_full_dic_acala, 'common');

        final String poolId = ModalRoute.of(context).settings.arguments;
        final pair = poolId.toUpperCase().split('-');
        final pairView = pair.map((e) => PluginFmt.tokenView(e)).toList();

        final balancePair = PluginFmt.getBalancePair(widget.plugin, pair);
        final shareDecimals = balancePair[0].decimals > balancePair[1].decimals
            ? balancePair[0].decimals
            : balancePair[1].decimals;

        final shareInput = double.parse(_amountCtrl.text.trim());
        final shareInputInt = Fmt.tokenInt(_amountCtrl.text, shareDecimals);
        double shareTotal = 0;
        BigInt shareInt = BigInt.zero;
        BigInt shareInt10 = BigInt.zero;
        BigInt shareInt25 = BigInt.zero;
        BigInt shareInt50 = BigInt.zero;
        double share = 0;
        double shareRatioNew = 0;

        double poolLeft = 0;
        double poolRight = 0;
        double exchangeRate = 1;
        double amountLeft = 0;
        double amountRight = 0;

        final poolInfo = widget.plugin.store.earn.dexPoolInfoMap[poolId];
        if (poolInfo != null) {
          exchangeRate = poolInfo.amountLeft / poolInfo.amountRight;

          if (_fromPool) {
            shareInt = poolInfo.shares;
            shareTotal =
                Fmt.bigIntToDouble(poolInfo.sharesTotal, shareDecimals);

            poolLeft = Fmt.bigIntToDouble(
                poolInfo.amountLeft * poolInfo.sharesTotal ~/ poolInfo.issuance,
                balancePair[0].decimals);
            poolRight = Fmt.bigIntToDouble(
                poolInfo.amountRight *
                    poolInfo.sharesTotal ~/
                    poolInfo.issuance,
                balancePair[1].decimals);
          } else {
            shareInt = Fmt.balanceInt(widget.plugin.store.assets
                .tokenBalanceMap[poolId.toUpperCase()].amount);
            shareTotal = Fmt.bigIntToDouble(poolInfo.issuance, shareDecimals);

            poolLeft = Fmt.bigIntToDouble(
                poolInfo.amountLeft, balancePair[0].decimals);
            poolRight = Fmt.bigIntToDouble(
                poolInfo.amountRight, balancePair[1].decimals);
          }
          shareInt10 = BigInt.from(shareInt / BigInt.from(10));
          shareInt25 = BigInt.from(shareInt / BigInt.from(4));
          shareInt50 = BigInt.from(shareInt / BigInt.from(2));

          share = Fmt.bigIntToDouble(shareInt, shareDecimals);

          amountLeft = poolLeft * shareInput / shareTotal;
          amountRight = poolRight * shareInput / shareTotal;

          shareRatioNew = shareTotal - shareInput == 0.0
              ? 0.0
              : (share - shareInput) / (shareTotal - shareInput);
        }

        return Scaffold(
          appBar: AppBar(title: Text(dic['earn.withdraw']), centerTitle: true),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: <Widget>[
                (poolInfo?.shares ?? BigInt.zero) > BigInt.zero
                    ? Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TapTooltip(
                              message: dic['earn.fromPool.txt'],
                              child: Icon(Icons.info,
                                  color:
                                      Theme.of(context).unselectedWidgetColor,
                                  size: 16),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(dic['earn.fromPool']),
                            ),
                            CupertinoSwitch(
                              value: _fromPool,
                              onChanged: (res) {
                                setState(() {
                                  _fromPool = res;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    : Container(),
                RoundedCard(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: dicAssets['amount'],
                            labelText:
                                '${dicAssets['amount']} (${dic['earn.available']}: ${Fmt.priceFloorBigInt(shareInt, shareDecimals, lengthMax: 4)} Shares)',
                            suffix: GestureDetector(
                              child: Icon(
                                CupertinoIcons.clear_thick_circled,
                                color: Theme.of(context).disabledColor,
                                size: 18,
                              ),
                              onTap: () {
                                WidgetsBinding.instance.addPostFrameCallback(
                                    (_) => _amountCtrl.clear());
                              },
                            ),
                          ),
                          inputFormatters: [
                            UI.decimalInputFormatter(shareDecimals)
                          ],
                          controller: _amountCtrl,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => _validateInput(v, shareDecimals),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            OutlinedButtonSmall(
                              content: '10%',
                              active: shareInputInt == shareInt10,
                              onPressed: () =>
                                  _onAmountSelect(shareInt10, shareDecimals),
                            ),
                            OutlinedButtonSmall(
                              content: '25%',
                              active: shareInputInt == shareInt25,
                              onPressed: () =>
                                  _onAmountSelect(shareInt25, shareDecimals),
                            ),
                            OutlinedButtonSmall(
                              content: '50%',
                              active: shareInputInt == shareInt50,
                              onPressed: () =>
                                  _onAmountSelect(shareInt50, shareDecimals),
                            ),
                            OutlinedButtonSmall(
                              margin: EdgeInsets.only(right: 0),
                              content: '100%',
                              active: shareInputInt == shareInt,
                              onPressed: () =>
                                  _onAmountSelect(shareInt, shareDecimals),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '= ${Fmt.doubleFormat(amountLeft)} ${pairView[0]} + ${Fmt.doubleFormat(amountRight)} ${pairView[1]}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).unselectedWidgetColor,
                                wordSpacing: -4,
                              ),
                            )
                          ],
                        ),
                      ),
                      Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              dic['dex.rate'],
                              style: TextStyle(
                                color: Theme.of(context).unselectedWidgetColor,
                              ),
                            ),
                          ),
                          Column(children: [
                            Text(
                                '1 ${pairView[0]} = ${Fmt.doubleFormat(1 / exchangeRate)} ${pairView[1]}'),
                            Text(
                                '1 ${pairView[1]} = ${Fmt.doubleFormat(exchangeRate)} ${pairView[0]}'),
                          ])
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              dic['earn${_fromPool ? '.stake' : ''}.pool'],
                              style: TextStyle(
                                color: Theme.of(context).unselectedWidgetColor,
                              ),
                            ),
                          ),
                          Text(
                            '${Fmt.doubleFormat(poolLeft)} ${pairView[0]}\n+ ${Fmt.doubleFormat(poolRight)} ${pairView[1]}',
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              dic['earn.share'],
                              style: TextStyle(
                                color: Theme.of(context).unselectedWidgetColor,
                              ),
                            ),
                          ),
                          Text(Fmt.ratio(shareRatioNew)),
                        ],
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: RoundedButton(
                    text: dic['earn.withdraw'],
                    onPressed: () => _onSubmit(shareDecimals),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
