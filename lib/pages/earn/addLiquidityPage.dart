import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/common/constants.dart';
import 'package:polkawallet_plugin_acala/api/types/txLiquidityData.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class AddLiquidityPage extends StatefulWidget {
  AddLiquidityPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/earn/deposit';
  static const String actionDeposit = 'deposit';

  @override
  _AddLiquidityPageState createState() => _AddLiquidityPageState();
}

class _AddLiquidityPageState extends State<AddLiquidityPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountLeftCtrl = new TextEditingController();
  final TextEditingController _amountRightCtrl = new TextEditingController();

  Timer _timer;
  double _price = 0;
  bool _withStake = false;

  Future<void> _refreshData() async {
    final String poolId = ModalRoute.of(context).settings.arguments;
    await widget.plugin.service.earn.queryDexPoolInfo(poolId);

    final output = await widget.plugin.api.swap.queryTokenSwapAmount(
      '1',
      null,
      poolId.toUpperCase().split('-'),
      '0.005',
    );
    if (mounted) {
      setState(() {
        _price = output.amount;
      });
      _timer = Timer(Duration(seconds: 10), () {
        if (mounted) {
          _refreshData();
        }
      });
    }
  }

  Future<void> _onSupplyAmountChange(String v) async {
    String supply = v.trim();
    try {
      if (supply.isEmpty || double.parse(supply) == 0) {
        return;
      }
    } catch (err) {
      return;
    }
    setState(() {
      _amountRightCtrl.text =
          (double.parse(supply) * _price).toStringAsFixed(6);
    });
    _formKey.currentState.validate();
  }

  Future<void> _onTargetAmountChange(String v) async {
    String target = v.trim();
    try {
      if (target.isEmpty || double.parse(target) == 0) {
        return;
      }
    } catch (err) {
      return;
    }
    setState(() {
      _amountLeftCtrl.text = (double.parse(target) / _price).toStringAsFixed(6);
    });
    _formKey.currentState.validate();
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState.validate()) {
      final symbols = widget.plugin.networkState.tokenSymbol;
      final decimals = widget.plugin.networkState.tokenDecimals;

      final String poolId = ModalRoute.of(context).settings.arguments;
      final pair = poolId.toUpperCase().split('-');

      final token = pair.firstWhere((e) => e != 'AUSD');
      final stableCoinDecimals = decimals[symbols.indexOf('AUSD')];
      final tokenDecimals = decimals[symbols.indexOf(token)];

      final decimalsLeft =
          pair[0] == acala_stable_coin ? stableCoinDecimals : tokenDecimals;
      final decimalsRight =
          pair[0] == acala_stable_coin ? tokenDecimals : stableCoinDecimals;

      final amountLeft = _amountLeftCtrl.text.trim();
      final amountRight = _amountRightCtrl.text.trim();

      final params = [
        {'Token': pair[0]},
        {'Token': pair[1]},
        Fmt.tokenInt(amountLeft, decimalsLeft).toString(),
        Fmt.tokenInt(amountRight, decimalsRight).toString(),
        _withStake,
      ];
      final res = (await Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'dex',
            call: 'addLiquidity',
            txTitle: I18n.of(context)
                .getDic(i18n_full_dic_acala, 'acala')['earn.deposit'],
            txDisplay: {
              "poolId": poolId,
              "amount": [amountLeft, amountRight],
              "withStake": _withStake,
            },
            params: params,
          ))) as Map;
      if (res != null) {
        res['action'] = TxDexLiquidityData.actionDeposit;
        res['params'] = [poolId, params[2], params[3]];
        res['time'] = DateTime.now().millisecondsSinceEpoch;

        widget.plugin.store.earn
            .addDexLiquidityTx(res, widget.keyring.current.pubKey);
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

    _amountLeftCtrl.dispose();
    _amountRightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
        final dicAssets =
            I18n.of(context).getDic(i18n_full_dic_acala, 'common');
        final symbols = widget.plugin.networkState.tokenSymbol;
        final decimals = widget.plugin.networkState.tokenDecimals;

        final String poolId = ModalRoute.of(context).settings.arguments;
        final tokenPair = poolId.toUpperCase().split('-');

        final token = tokenPair.firstWhere((e) => e != acala_stable_coin);
        final stableCoinDecimals = decimals[symbols.indexOf(acala_stable_coin)];
        final tokenDecimals = decimals[symbols.indexOf(token)];
        final decimalsLeft = tokenPair[0] == acala_stable_coin
            ? stableCoinDecimals
            : tokenDecimals;
        final decimalsRight = tokenPair[0] == acala_stable_coin
            ? tokenDecimals
            : stableCoinDecimals;

        final double inputWidth = MediaQuery.of(context).size.width / 3;

        double userShare = 0;
        double userShareNew = 0;

        double amountToken = 0;
        double amountStableCoin = 0;
        double amountTokenUser = 0;
        BigInt balanceLeftUser = tokenPair[0] == 'ACA'
            ? Fmt.balanceInt(
                widget.plugin.balances.native.freeBalance.toString())
            : Fmt.balanceInt(widget.plugin.store.assets
                    .tokenBalanceMap[tokenPair[0].toUpperCase()]?.amount ??
                '0');
        BigInt balanceRightUser = Fmt.balanceInt(widget.plugin.store.assets
                .tokenBalanceMap[tokenPair[1].toUpperCase()]?.amount ??
            '0');

        final poolInfo = widget.plugin.store.earn.dexPoolInfoMap[poolId];
        if (poolInfo != null) {
          userShare = poolInfo.proportion;

          amountToken = Fmt.bigIntToDouble(poolInfo.amountToken, tokenDecimals);
          amountStableCoin =
              Fmt.bigIntToDouble(poolInfo.amountStableCoin, stableCoinDecimals);
          amountTokenUser = amountToken * userShare;

          String input = _amountLeftCtrl.text.trim();
          try {
            final double amountInput =
                double.parse(input.isEmpty ? '0' : input);
            userShareNew =
                (amountInput + amountTokenUser) / (amountInput + amountToken);
          } catch (_) {
            // parse double failed
          }
        }

        final colorGray = Theme.of(context).unselectedWidgetColor;

        return Scaffold(
          appBar: AppBar(title: Text(dic['earn.deposit']), centerTitle: true),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: <Widget>[
                RoundedCard(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            width: inputWidth,
                            child: CurrencyWithIcon(
                              tokenPair[0],
                              TokenIcon(tokenPair[0], widget.plugin.tokenIcons),
                              textStyle: Theme.of(context).textTheme.headline4,
                            ),
                          ),
                          Expanded(
                            child: Icon(
                              Icons.add,
                            ),
                          ),
                          Container(
                            width: inputWidth,
                            child: CurrencyWithIcon(
                              tokenPair[1],
                              TokenIcon(tokenPair[1], widget.plugin.tokenIcons),
                              textStyle: Theme.of(context).textTheme.headline4,
                            ),
                          ),
                        ],
                      ),
                      Form(
                        key: _formKey,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: inputWidth,
                              child: TextFormField(
                                decoration: InputDecoration(
                                  hintText: dicAssets['amount'],
                                  labelText: dicAssets['amount'],
                                  suffix: GestureDetector(
                                    child: Icon(
                                      CupertinoIcons.clear_thick_circled,
                                      color: Theme.of(context).disabledColor,
                                      size: 18,
                                    ),
                                    onTap: () {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback(
                                              (_) => _amountLeftCtrl.clear());
                                    },
                                  ),
                                ),
                                inputFormatters: [
                                  UI.decimalInputFormatter(decimalsLeft)
                                ],
                                controller: _amountLeftCtrl,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                validator: (v) {
                                  try {
                                    if (v.trim().isEmpty ||
                                        double.parse(v.trim()) == 0) {
                                      return dicAssets['amount.error'];
                                    }
                                  } catch (err) {
                                    return dicAssets['amount.error'];
                                  }
                                  if (Fmt.tokenInt(v.trim(), decimalsLeft) >
                                      balanceLeftUser) {
                                    return dicAssets['amount.low'];
                                  }
                                  return null;
                                },
                                onChanged: (v) => _onSupplyAmountChange(v),
                              ),
                            ),
                            Container(
                              width: inputWidth,
                              child: TextFormField(
                                decoration: InputDecoration(
                                  hintText: dicAssets['amount'],
                                  labelText: dicAssets['amount'],
                                  suffix: GestureDetector(
                                    child: Icon(
                                      CupertinoIcons.clear_thick_circled,
                                      color: Theme.of(context).disabledColor,
                                      size: 18,
                                    ),
                                    onTap: () {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback(
                                              (_) => _amountRightCtrl.clear());
                                    },
                                  ),
                                ),
                                inputFormatters: [
                                  UI.decimalInputFormatter(decimalsRight)
                                ],
                                controller: _amountRightCtrl,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                validator: (v) {
                                  try {
                                    if (v.trim().isEmpty ||
                                        double.parse(v.trim()) == 0) {
                                      return dicAssets['amount.error'];
                                    }
                                  } catch (err) {
                                    return dicAssets['amount.error'];
                                  }
                                  if (Fmt.tokenInt(v.trim(), decimalsRight) >
                                      balanceRightUser) {
                                    return dicAssets['amount.low'];
                                  }
                                  return null;
                                },
                                onChanged: (v) => _onTargetAmountChange(v),
                              ),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Container(
                              width: inputWidth,
                              child: Text(
                                '${dicAssets['balance']}: ${Fmt.priceFloorBigInt(
                                  balanceLeftUser,
                                  decimalsLeft,
                                  lengthFixed: 4,
                                )}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorGray,
                                ),
                              ),
                            ),
                            Container(
                              width: inputWidth,
                              child: Text(
                                '${dicAssets['balance']}: ${Fmt.priceFloorBigInt(
                                  balanceRightUser,
                                  decimalsRight,
                                  lengthFixed: 4,
                                )}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorGray,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              dic['dex.rate'],
                              style: TextStyle(
                                color: colorGray,
                              ),
                            ),
                          ),
                          Text(
                              '1 ${tokenPair[0]} = ${Fmt.doubleFormat(_price, length: 6)} ${tokenPair[1]}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              dic['earn.pool'],
                              style: TextStyle(color: colorGray),
                            ),
                          ),
                          Text(
                            '${Fmt.doubleFormat(amountToken)} ${tokenPair[0]}\n+ ${Fmt.doubleFormat(amountStableCoin)} ${tokenPair[1]}',
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
                              style: TextStyle(color: colorGray),
                            ),
                          ),
                          Text(Fmt.ratio(userShareNew)),
                        ],
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TapTooltip(
                        message: dic['earn.withStake.txt'],
                        child: Icon(Icons.info, color: colorGray, size: 16),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(dic['earn.withStake']),
                      ),
                      CupertinoSwitch(
                        value: _withStake,
                        onChanged: (res) {
                          setState(() {
                            _withStake = res;
                          });
                        },
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: RoundedButton(
                    text: dic['earn.deposit'],
                    onPressed: _onSubmit,
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
