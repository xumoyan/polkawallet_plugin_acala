import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/txLiquidityData.dart';
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

  BigInt _shareInput = BigInt.zero;
  double _price = 0;
  bool _fromPool = false;

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

  void _onAmountChange(String v, int decimals) {
    final amountInput = v.trim();
    setState(() {
      _shareInput = Fmt.tokenInt(amountInput, decimals);
    });
    _formKey.currentState.validate();
  }

  void _onAmountSelect(BigInt v, int decimals) {
    setState(() {
      _shareInput = v;
      _amountCtrl.text = Fmt.bigIntToDouble(v, decimals).toStringAsFixed(4);
    });
    _formKey.currentState.validate();
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState.validate()) {
      final String poolId = ModalRoute.of(context).settings.arguments;
      final pair = poolId.toUpperCase().split('-');
      String amount = _amountCtrl.text.trim();

      final params = [
        {'Token': pair[0]},
        {'Token': pair[1]},
        _shareInput.toString(),
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
        res['action'] = TxDexLiquidityData.actionWithdraw;
        res['params'] = [poolId, params[2]];
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
        final symbols = widget.plugin.networkState.tokenSymbol;
        final decimals = widget.plugin.networkState.tokenDecimals;

        final String poolId = ModalRoute.of(context).settings.arguments;
        final pair = poolId.toUpperCase().split('-');
        final pairView = pair.map((e) => PluginFmt.tokenView(e)).toList();

        final token = pair.firstWhere((e) => e != 'AUSD');
        final stableCoinDecimals = decimals[symbols.indexOf('AUSD')];
        final tokenDecimals = decimals[symbols.indexOf(token)];
        final shareDecimals = stableCoinDecimals >= tokenDecimals
            ? stableCoinDecimals
            : tokenDecimals;

        double shareTotal = 0;
        BigInt shareInt = BigInt.zero;
        BigInt shareInt10 = BigInt.zero;
        BigInt shareInt25 = BigInt.zero;
        BigInt shareInt50 = BigInt.zero;
        double share = 0;
        double shareRatioNew = 0;
        double shareInput = Fmt.bigIntToDouble(_shareInput, shareDecimals);

        double poolToken = 0;
        double poolStableCoin = 0;
        double amountToken = 0;
        double amountStableCoin = 0;

        final poolInfo = widget.plugin.store.earn.dexPoolInfoMap[poolId];
        if (poolInfo != null) {
          shareTotal = Fmt.bigIntToDouble(poolInfo.issuance, shareDecimals);
          if (_fromPool) {
            shareInt = poolInfo.shares;
          } else {
            shareInt = Fmt.balanceInt(widget.plugin.store.assets
                .tokenBalanceMap[poolId.toUpperCase()].amount);
          }
          shareInt10 = BigInt.from(shareInt / BigInt.from(10));
          shareInt25 = BigInt.from(shareInt / BigInt.from(4));
          shareInt50 = BigInt.from(shareInt / BigInt.from(2));

          share = Fmt.bigIntToDouble(poolInfo.shares, shareDecimals);

          poolToken = Fmt.bigIntToDouble(poolInfo.amountToken, tokenDecimals);
          poolStableCoin =
              Fmt.bigIntToDouble(poolInfo.amountStableCoin, stableCoinDecimals);

          amountToken = poolToken * shareInput / shareTotal;
          amountStableCoin = poolStableCoin * shareInput / shareTotal;

          shareRatioNew = (share - shareInput) / (shareTotal - shareInput);
        }

        return Scaffold(
          appBar: AppBar(title: Text(dic['earn.withdraw']), centerTitle: true),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TapTooltip(
                        message: dic['earn.fromPool.txt'],
                        child: Icon(Icons.info,
                            color: Theme.of(context).unselectedWidgetColor,
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
                      )
                    ],
                  ),
                ),
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
                          validator: (v) {
                            try {
                              if (v.trim().isEmpty ||
                                  double.parse(v.trim()) == 0) {
                                return dicAssets['amount.error'];
                              }
                            } catch (err) {
                              return dicAssets['amount.error'];
                            }
                            if (_shareInput > shareInt) {
                              return dicAssets['amount.low'];
                            }
                            return null;
                          },
                          onChanged: (v) => _onAmountChange(v, shareDecimals),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            OutlinedButtonSmall(
                              content: '10%',
                              active: _shareInput == shareInt10,
                              onPressed: () => _onAmountSelect(shareInt10, shareDecimals),
                            ),
                            OutlinedButtonSmall(
                              content: '25%',
                              active: _shareInput == shareInt25,
                              onPressed: () => _onAmountSelect(shareInt25, shareDecimals),
                            ),
                            OutlinedButtonSmall(
                              content: '50%',
                              active: _shareInput == shareInt50,
                              onPressed: () => _onAmountSelect(shareInt50, shareDecimals),
                            ),
                            OutlinedButtonSmall(
                              margin: EdgeInsets.only(right: 0),
                              content: '100%',
                              active: _shareInput == shareInt,
                              onPressed: () => _onAmountSelect(shareInt, shareDecimals),
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
                              '= ${Fmt.doubleFormat(amountToken)} ${pairView[0]} + ${Fmt.doubleFormat(amountStableCoin)} ${pairView[1]}',
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
                          Text(
                              '1 ${pairView[0]} = ${Fmt.doubleFormat(_price)} ${pairView[1]}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              dic['earn.pool'],
                              style: TextStyle(
                                color: Theme.of(context).unselectedWidgetColor,
                              ),
                            ),
                          ),
                          Text(
                            '${Fmt.doubleFormat(poolToken)} ${pairView[0]}\n+ ${Fmt.doubleFormat(poolStableCoin)} ${pairView[1]}',
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
