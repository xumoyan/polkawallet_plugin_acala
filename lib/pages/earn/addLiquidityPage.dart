import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/common/constants.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapTokenInput.dart';
import 'package:polkawallet_plugin_acala/api/types/txLiquidityData.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

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

  TxFeeEstimateResult _fee;
  BigInt _maxInputLeft;
  BigInt _maxInputRight;
  String _errorLeft;
  String _errorRight;

  Future<void> _refreshData() async {
    final symbols = widget.plugin.networkState.tokenSymbol;
    final decimals = widget.plugin.networkState.tokenDecimals;

    final String poolId = ModalRoute.of(context).settings.arguments;
    final tokenPair = poolId.toUpperCase().split('-');

    final token = tokenPair.firstWhere((e) => e != acala_stable_coin);
    final stableCoinDecimals = decimals[symbols.indexOf(acala_stable_coin)];
    final tokenDecimals = decimals[symbols.indexOf(token)];
    final decimalsLeft =
        tokenPair[0] == acala_stable_coin ? stableCoinDecimals : tokenDecimals;
    final decimalsRight =
        tokenPair[0] == acala_stable_coin ? tokenDecimals : stableCoinDecimals;

    await widget.plugin.service.earn.queryDexPoolInfo(poolId);

    final poolInfo = widget.plugin.store.earn.dexPoolInfoMap[poolId];
    if (mounted) {
      setState(() {
        _price = Fmt.bigIntToDouble(poolInfo.amountRight, decimalsRight) /
            Fmt.bigIntToDouble(poolInfo.amountLeft, decimalsLeft);
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
    _onValidate();
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
    _onValidate();
  }

  String _onValidateInput(int index) {
    if (index == 0 && _maxInputLeft != null) return null;
    if (index == 1 && _maxInputRight != null) return null;

    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'common');
    final String poolId = ModalRoute.of(context).settings.arguments;
    final tokenPair = poolId.toUpperCase().split('-');
    final v =
        index == 0 ? _amountLeftCtrl.text.trim() : _amountRightCtrl.text.trim();
    TokenBalanceData balance;
    if (index == 0 && tokenPair[0] == 'ACA') {
      balance = TokenBalanceData(
          symbol: tokenPair[0],
          decimals: widget.plugin.networkState.tokenDecimals[0],
          amount: (widget.plugin.balances.native?.freeBalance ?? 0).toString());
    } else {
      balance = widget
          .plugin.store.assets.tokenBalanceMap[tokenPair[index].toUpperCase()];
    }

    String error;
    try {
      if (v.isEmpty || double.parse(v) == 0) {
        error = dic['amount.error'];
      }
    } catch (err) {
      error = dic['amount.error'];
    }
    if (error == null) {
      if (double.parse(v) >
          Fmt.bigIntToDouble(
              Fmt.balanceInt(balance?.amount ?? '0'), balance.decimals)) {
        error = dic['amount.low'];
      }
    }
    return error;
  }

  bool _onValidate() {
    final errorLeft = _onValidateInput(0);
    print(errorLeft);
    if (errorLeft != null) {
      setState(() {
        _errorLeft = errorLeft;
        _errorRight = null;
      });
      return false;
    }
    final errorRight = _onValidateInput(1);
    if (errorRight != null) {
      setState(() {
        _errorLeft = null;
        _errorRight = errorRight;
      });
      return false;
    }
    setState(() {
      _errorLeft = null;
      _errorRight = null;
    });
    return true;
  }

  void _onSetLeftMax(BigInt max, int decimals) {
    final amount = Fmt.bigIntToDouble(max, decimals).toStringAsFixed(6);
    setState(() {
      _amountLeftCtrl.text = amount;
      _maxInputLeft = max;
      _maxInputRight = null;
    });
    _onSupplyAmountChange(amount);
  }

  void _onSetRightMax(BigInt max, int decimals) {
    final amount = Fmt.bigIntToDouble(max, decimals).toStringAsFixed(6);
    setState(() {
      _amountRightCtrl.text = amount;
      _maxInputLeft = null;
      _maxInputRight = max;
    });
    _onTargetAmountChange(amount);
  }

  Future<void> _onSubmit() async {
    if (_onValidate()) {
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
        final symbols = widget.plugin.networkState.tokenSymbol;
        final decimals = widget.plugin.networkState.tokenDecimals;

        final String poolId = ModalRoute.of(context).settings.arguments;
        final tokenPair = poolId.toUpperCase().split('-');
        final tokenPairView = [
          PluginFmt.tokenView(tokenPair[0]),
          PluginFmt.tokenView(tokenPair[1])
        ];

        final token = tokenPair.firstWhere((e) => e != acala_stable_coin);
        final stableCoinDecimals = decimals[symbols.indexOf(acala_stable_coin)];
        final tokenDecimals = decimals[symbols.indexOf(token)];
        final decimalsLeft = tokenPair[0] == acala_stable_coin
            ? stableCoinDecimals
            : tokenDecimals;
        final decimalsRight = tokenPair[0] == acala_stable_coin
            ? tokenDecimals
            : stableCoinDecimals;

        double userShare = 0;
        double userShareNew = 0;

        double amountLeft = 0;
        double amountRight = 0;
        double amountLeftUser = 0;

        TokenBalanceData balanceLeftUser;
        TokenBalanceData balanceRightUser;
        if (tokenPair[0] == 'ACA') {
          balanceLeftUser = TokenBalanceData(
              symbol: tokenPair[0],
              decimals: widget.plugin.networkState.tokenDecimals[0],
              amount:
                  (widget.plugin.balances.native?.freeBalance ?? 0).toString());
          balanceRightUser =
              widget.plugin.store.assets.tokenBalanceMap[tokenPair[1]];
        } else if (tokenPair[1] == 'ACA') {
          balanceRightUser = TokenBalanceData(
              symbol: tokenPair[1],
              decimals: widget.plugin.networkState.tokenDecimals[0],
              amount: (widget.plugin.balances.native?.freeBalance ?? 0));
          balanceLeftUser =
              widget.plugin.store.assets.tokenBalanceMap[tokenPair[0]];
        } else {
          balanceLeftUser =
              widget.plugin.store.assets.tokenBalanceMap[tokenPair[0]];
          balanceRightUser =
              widget.plugin.store.assets.tokenBalanceMap[tokenPair[1]];
        }

        final poolInfo = widget.plugin.store.earn.dexPoolInfoMap[poolId];
        if (poolInfo != null) {
          userShare = poolInfo.proportion;

          amountLeft = Fmt.bigIntToDouble(poolInfo.amountLeft, decimalsLeft);
          amountRight = Fmt.bigIntToDouble(poolInfo.amountRight, decimalsRight);
          amountLeftUser = amountLeft * userShare;

          String input = _amountLeftCtrl.text.trim();
          try {
            final double amountInput =
                double.parse(input.isEmpty ? '0' : input);
            userShareNew =
                (amountInput + amountLeftUser) / (amountInput + amountLeft);
          } catch (_) {
            // parse double failed
          }
        }

        final colorGray = Theme.of(context).unselectedWidgetColor;

        return Scaffold(
          appBar: AppBar(title: Text(dic['earn.deposit']), centerTitle: true),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(8, 16, 8, 32),
              children: <Widget>[
                RoundedCard(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SwapTokenInput(
                        title: 'token 1',
                        inputCtrl: _amountLeftCtrl,
                        balance: balanceLeftUser,
                        tokenIconsMap: widget.plugin.tokenIcons,
                        onInputChange: _onSupplyAmountChange,
                        onSetMax: (v) =>
                            _onSetLeftMax(v, balanceLeftUser.decimals),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 16, top: 2),
                        child: _errorLeft == null
                            ? null
                            : Row(children: [
                                Text(
                                  _errorLeft,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.red),
                                )
                              ]),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: Theme.of(context).primaryColor,
                          )
                        ],
                      ),
                      SwapTokenInput(
                        title: 'token 2',
                        inputCtrl: _amountRightCtrl,
                        balance: balanceRightUser,
                        tokenIconsMap: widget.plugin.tokenIcons,
                        onInputChange: _onTargetAmountChange,
                        onSetMax: (v) =>
                            _onSetRightMax(v, balanceRightUser.decimals),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 16, top: 2),
                        child: _errorRight == null
                            ? null
                            : Row(children: [
                                Text(
                                  _errorRight,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.red),
                                )
                              ]),
                      ),
                      Divider(height: 24),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                  '1 ${tokenPairView[0]} = ${Fmt.doubleFormat(_price, length: 6)} ${tokenPairView[1]}'),
                              Text(
                                  '1 ${tokenPairView[1]} = ${Fmt.doubleFormat(1 / _price, length: 6)} ${tokenPairView[0]}')
                            ],
                          ),
                        ],
                      ),
                      Divider(),
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
                            '${Fmt.doubleFormat(amountLeft)} ${tokenPairView[0]}\n+ ${Fmt.doubleFormat(amountRight)} ${tokenPairView[1]}',
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
