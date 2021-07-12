import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/swapOutputData.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapTokenInput.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class SwapPage extends StatefulWidget {
  SwapPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/dex';

  @override
  _SwapPageState createState() => _SwapPageState();
}

class _SwapPageState extends State<SwapPage> {
  final TextEditingController _amountPayCtrl = new TextEditingController();
  final TextEditingController _amountReceiveCtrl = new TextEditingController();
  final TextEditingController _amountSlippageCtrl = new TextEditingController();

  final _payFocusNode = FocusNode();
  final _receiveFocusNode = FocusNode();
  final _slippageFocusNode = FocusNode();

  String _error;
  double _slippage = 0.005;
  bool _slippageSettingVisable = false;
  String _slippageError;
  List<String> _allSwapTokens = [];
  List<String> _swapPair = [];
  int _swapMode = 0; // 0 for 'EXACT_INPUT' and 1 for 'EXACT_OUTPUT'
  double _swapRatio = 0;
  SwapOutputData _swapOutput = SwapOutputData();

  TxFeeEstimateResult _fee;
  BigInt _maxInput;

  // use a _timer to update page data consistently
  Timer _timer;
  // use another _timer to control swap amount query
  Timer _delayTimer;

  Future<void> _getTxFee({bool reload = false}) async {
    final sender = TxSenderData(
        widget.keyring.current.address, widget.keyring.current.pubKey);
    final txInfo = TxInfoData('balances', 'transfer', sender);
    final fee = await widget.plugin.sdk.api.tx
        .estimateFees(txInfo, [widget.keyring.current.address, '10000000000']);
    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
  }

  Future<void> _switchPair() async {
    final pay = _amountPayCtrl.text;
    setState(() {
      _swapPair = [_swapPair[1], _swapPair[0]];
      _amountPayCtrl.text = _amountReceiveCtrl.text;
      _amountReceiveCtrl.text = pay;
      _swapMode = _swapMode == 0 ? 1 : 0;
    });
    if (_payFocusNode.hasFocus) {
      _payFocusNode.unfocus();
      _receiveFocusNode.requestFocus();
    } else if (_receiveFocusNode.hasFocus) {
      _receiveFocusNode.unfocus();
      _payFocusNode.requestFocus();
    }
    await _updateSwapAmount();
  }

  Future<List<String>> _getSwapTokens() async {
    final dexPairs = await widget.plugin.api.swap.getTokenPairs();
    final List<String> tokens = widget.plugin.basic.name == plugin_name_karura
        ? ['KAR', karura_stable_coin]
        : ['ACA', acala_stable_coin];
    dexPairs.forEach((e) {
      e.tokens.forEach((token) {
        if (tokens.indexOf(token['token']) < 0) {
          tokens.add(token['token']);
        }
      });
    });
    setState(() {
      _allSwapTokens = tokens;
    });
    print(tokens);
    return tokens;
  }

  bool _onCheckBalance() {
    if (_maxInput != null) {
      setState(() {
        _error = null;
      });
      return true;
    }

    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'common');
    final v = _amountPayCtrl.text.trim();
    TokenBalanceData balance;
    if (_swapPair.length > 0) {
      if (_swapPair[0] == widget.plugin.networkState.tokenSymbol[0]) {
        balance = TokenBalanceData(
            symbol: _swapPair[0],
            decimals: widget.plugin.networkState.tokenDecimals[0],
            amount:
                (widget.plugin.balances.native?.freeBalance ?? 0).toString());
      } else if (_allSwapTokens.length > 0) {
        balance = widget
            .plugin.store.assets.tokenBalanceMap[_swapPair[0].toUpperCase()];
      }
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
    setState(() {
      _error = error;
    });
    return error == null;
  }

  void _onSupplyAmountChange(String v) {
    String supply = v.trim();
    setState(() {
      _swapMode = 0;
      _maxInput = null;
    });

    _onInputChange(supply);
  }

  void _onTargetAmountChange(String v) {
    String target = v.trim();
    setState(() {
      _swapMode = 1;
      _maxInput = null;
    });

    _onInputChange(target);
  }

  void _onInputChange(String input) {
    if (_delayTimer != null) {
      _delayTimer.cancel();
    }
    _delayTimer = Timer(Duration(milliseconds: 500), () {
      if (_swapMode == 0) {
        _calcSwapAmount(input, null);
      } else {
        _calcSwapAmount(null, input);
      }
    });
  }

  Future<void> _updateSwapAmount({bool init = false}) async {
    if (_swapMode == 0) {
      await _calcSwapAmount(_amountPayCtrl.text.trim(), null, init: init);
    } else {
      await _calcSwapAmount(null, _amountReceiveCtrl.text.trim(), init: init);
    }
  }

  void _setUpdateTimer() {
    _updateSwapAmount(init: true);

    _timer = Timer(Duration(seconds: 10), () {
      _updateSwapAmount();
    });
  }

  Future<void> _calcSwapAmount(
    String supply,
    String target, {
    bool init = false,
  }) async {
    if (supply == null) {
      final output = await widget.plugin.api.swap.queryTokenSwapAmount(
        supply,
        target.isEmpty ? '1' : target,
        _swapPair,
        _slippage.toString(),
      );
      setState(() {
        if (!init) {
          if (target.isNotEmpty) {
            _amountPayCtrl.text = output.amount.toString();
          } else {
            _amountPayCtrl.text = '';
          }
        }
        _swapRatio = target.isEmpty
            ? output.amount
            : double.parse(target) / output.amount;
        _swapOutput = output;
      });
      if (!init) {
        _onCheckBalance();
      }
    } else if (target == null) {
      final output = await widget.plugin.api.swap.queryTokenSwapAmount(
        supply.isEmpty ? '1' : supply,
        target,
        _swapPair,
        _slippage.toString(),
      );
      setState(() {
        if (!init) {
          if (supply.isNotEmpty) {
            _amountReceiveCtrl.text = output.amount.toString();
          } else {
            _amountReceiveCtrl.text = '';
          }
        }
        _swapRatio = supply.isEmpty
            ? output.amount
            : output.amount / double.parse(supply);
        _swapOutput = output;
      });
      if (!init) {
        _onCheckBalance();
      }
    }
  }

  void _onSetSlippage() {
    setState(() {
      _slippageSettingVisable = !_slippageSettingVisable;
    });
  }

  void _onSlippageChange(String v) {
    final Map dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    try {
      double value = double.parse(v.trim());
      if (value >= 50 || value < 0.1) {
        setState(() {
          _slippageError = dic['dex.slippage.error'];
        });
      } else {
        setState(() {
          _slippageError = null;
        });
        _updateSlippage(value / 100, custom: true);
      }
    } catch (err) {
      setState(() {
        _slippageError = dic['dex.slippage.error'];
      });
    }
  }

  Future<void> _updateSlippage(double input, {bool custom = false}) async {
    if (!custom) {
      _slippageFocusNode.unfocus();
      setState(() {
        _amountSlippageCtrl.text = '';
        _slippageError = null;
      });
    }
    setState(() {
      _slippage = input;
    });
    if (_swapMode == 0) {
      await _calcSwapAmount(_amountPayCtrl.text.trim(), null);
    } else {
      await _calcSwapAmount(null, _amountReceiveCtrl.text.trim());
    }
  }

  void _onSetMax(BigInt max, int decimals) {
    final amount = Fmt.bigIntToDouble(max, decimals).toStringAsFixed(6);
    setState(() {
      _swapMode = 0;
      _amountPayCtrl.text = amount;
      _maxInput = max;
    });
    _onInputChange(amount);
  }

  Future<void> _onSubmit(List<int> pairDecimals, double minMax) async {
    if (_onCheckBalance()) {
      final pay = _amountPayCtrl.text.trim();
      final receive = _amountReceiveCtrl.text.trim();

      BigInt input = Fmt.tokenInt(
          _swapMode == 0 ? pay : receive, pairDecimals[_swapMode == 0 ? 0 : 1]);
      if (_maxInput != null) {
        input = _maxInput;
        // keep tx fee for ACA swap
        if (_swapMode == 0 &&
            (_swapPair[0] == widget.plugin.networkState.tokenSymbol[0])) {
          input -= BigInt.two * Fmt.balanceInt(_fee.partialFee.toString());
        }
      }

      final params = [
        _swapOutput.path
            .map((e) => ({'Token': e['name'], 'decimal': e['decimal']}))
            .toList(),
        input.toString(),
        Fmt.tokenInt(minMax.toString(), pairDecimals[_swapMode == 0 ? 1 : 0])
            .toString(),
      ];
      Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'dex',
            call:
                _swapMode == 0 ? 'swapWithExactSupply' : 'swapWithExactTarget',
            txTitle: I18n.of(context)
                .getDic(i18n_full_dic_acala, 'acala')['dex.title'],
            txDisplay: {
              "currencyPay": _swapPair[0],
              "amountPay": pay,
              "currencyReceive": _swapPair[1],
              "amountReceive": receive,
            },
            params: params,
          ));
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _getTxFee();

      final currencyIds = await _getSwapTokens();
      if (currencyIds.length > 0) {
        setState(() {
          _swapPair = widget.plugin.basic.name == plugin_name_karura
              ? ['KAR', karura_stable_coin]
              : ['ACA', acala_stable_coin];
        });
        _setUpdateTimer();
      }
    });
  }

  @override
  void dispose() {
    _amountPayCtrl.dispose();
    _amountReceiveCtrl.dispose();

    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }

    super.dispose();
  }

  @override
  Widget build(_) {
    final isKar = widget.plugin.basic.name == plugin_name_karura;
    final bool enabled = !isKar || ModalRoute.of(context).settings.arguments;
    // final bool enabled = true;
    return Observer(
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
        final symbols = widget.plugin.networkState.tokenSymbol;
        final decimals = widget.plugin.networkState.tokenDecimals;

        final pairDecimals = [8, 8];
        final currencyOptions = _allSwapTokens.toList();
        if (_swapPair.length > 0) {
          pairDecimals
              .replaceRange(0, 1, [decimals[symbols.indexOf(_swapPair[0])]]);
          pairDecimals
              .replaceRange(1, 2, [decimals[symbols.indexOf(_swapPair[1])]]);

          currencyOptions
              .retainWhere((i) => i != _swapPair[0] && i != _swapPair[1]);
        }

        TokenBalanceData payBalance;
        TokenBalanceData receiveBalance;
        if (_swapPair.length > 0) {
          if (_swapPair[0] == symbols[0]) {
            payBalance = TokenBalanceData(
                symbol: _swapPair[0],
                decimals: widget.plugin.networkState.tokenDecimals[0],
                amount: (widget.plugin.balances.native?.freeBalance ?? 0)
                    .toString());
            receiveBalance = widget.plugin.store.assets
                .tokenBalanceMap[_swapPair[1].toUpperCase()];
          } else if (_swapPair[1] == symbols[0]) {
            receiveBalance = TokenBalanceData(
                symbol: _swapPair[1],
                decimals: widget.plugin.networkState.tokenDecimals[0],
                amount: (widget.plugin.balances.native?.freeBalance ?? 0)
                    .toString());
            payBalance = widget.plugin.store.assets
                .tokenBalanceMap[_swapPair[0].toUpperCase()];
          } else if (currencyOptions.length > 0) {
            payBalance = widget.plugin.store.assets
                .tokenBalanceMap[_swapPair[0].toUpperCase()];
            receiveBalance = widget.plugin.store.assets
                .tokenBalanceMap[_swapPair[1].toUpperCase()];
          }
        }

        double minMax = 0;
        if (_swapOutput.output != null) {
          minMax = _swapMode == 0
              ? _swapOutput.amount * (1 - _slippage)
              : _swapOutput.amount * (1 + _slippage);
        }

        final showExchangeRate = _amountPayCtrl.text.isNotEmpty &&
            _amountReceiveCtrl.text.isNotEmpty;

        final primary = Theme.of(context).primaryColor;
        final grey = Theme.of(context).unselectedWidgetColor;
        final labelStyle = TextStyle(color: grey, fontSize: 13);

        return Scaffold(
          appBar: AppBar(
            title: Text(dic['dex.title']),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.history, color: Theme.of(context).cardColor),
                onPressed: enabled
                    ? () =>
                        Navigator.of(context).pushNamed(SwapHistoryPage.route)
                    : null,
              )
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(8, 16, 8, 16),
              children: <Widget>[
                RoundedCard(
                  padding: EdgeInsets.all(16),
                  child: _swapPair.length == 2
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SwapTokenInput(
                              title: dic['dex.pay'],
                              inputCtrl: _amountPayCtrl,
                              focusNode: _payFocusNode,
                              balance: payBalance,
                              tokenOptions: currencyOptions,
                              tokenIconsMap: widget.plugin.tokenIcons,
                              onInputChange: _onSupplyAmountChange,
                              onTokenChange: (String token) {
                                if (token != null) {
                                  setState(() {
                                    _swapPair = [token, _swapPair[1]];
                                  });
                                  _updateSwapAmount();
                                }
                              },
                              onSetMax: (v) => _onSetMax(v, pairDecimals[0]),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 16, top: 2),
                              child: _error == null
                                  ? null
                                  : Row(children: [
                                      Text(
                                        _error,
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.red),
                                      )
                                    ]),
                            ),
                            GestureDetector(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(8, 10, 8, 0),
                                child: Icon(
                                  Icons.arrow_downward,
                                  color: Theme.of(context).primaryColor,
                                  size: 18,
                                ),
                              ),
                              onTap: () => _switchPair(),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 12),
                              child: SwapTokenInput(
                                title: dic['dex.receive'],
                                inputCtrl: _amountReceiveCtrl,
                                focusNode: _receiveFocusNode,
                                balance: receiveBalance,
                                tokenOptions: currencyOptions,
                                tokenIconsMap: widget.plugin.tokenIcons,
                                onInputChange: _onTargetAmountChange,
                                onTokenChange: (String token) {
                                  if (token != null) {
                                    setState(() {
                                      _swapPair = [_swapPair[0], token];
                                    });
                                    _updateSwapAmount();
                                  }
                                },
                              ),
                            ),
                            showExchangeRate
                                ? Container(
                                    margin: EdgeInsets.only(
                                        left: 16, top: 12, right: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(dic['dex.rate'],
                                            style: labelStyle),
                                        Text(
                                            '1 ${PluginFmt.tokenView(_swapPair[0])} = ${_swapRatio.toStringAsFixed(6)} ${PluginFmt.tokenView(_swapPair[1])}'),
                                      ],
                                    ),
                                  )
                                : Container(),
                            Container(
                              margin:
                                  EdgeInsets.only(left: 16, top: 12, right: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                      child: Text(dic['dex.slippage'],
                                          style: labelStyle)),
                                  GestureDetector(
                                      child: Row(
                                        children: [
                                          Text(
                                            Fmt.ratio(_slippage),
                                            style: TextStyle(color: primary),
                                          ),
                                          Icon(Icons.settings_outlined,
                                              color: primary, size: 16)
                                        ],
                                      ),
                                      onTap: _onSetSlippage),
                                  // GestureDetector(
                                  //     child: ,
                                  //     onTap: _onSetSlippage)
                                ],
                              ),
                            ),
                            _slippageSettingVisable
                                ? Container(
                                    margin: EdgeInsets.only(
                                        left: 8, right: 8, top: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        OutlinedButtonSmall(
                                          content: '0.1 %',
                                          active: _slippage == 0.001,
                                          onPressed: () =>
                                              _updateSlippage(0.001),
                                        ),
                                        OutlinedButtonSmall(
                                          content: '0.5 %',
                                          active: _slippage == 0.005,
                                          onPressed: () =>
                                              _updateSlippage(0.005),
                                        ),
                                        OutlinedButtonSmall(
                                          content: '1 %',
                                          active: _slippage == 0.01,
                                          onPressed: () =>
                                              _updateSlippage(0.01),
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: <Widget>[
                                              CupertinoTextField(
                                                padding: EdgeInsets.fromLTRB(
                                                    12, 4, 12, 2),
                                                placeholder: I18n.of(context)
                                                    .getDic(i18n_full_dic_acala,
                                                        'common')['custom'],
                                                placeholderStyle: TextStyle(
                                                    fontSize: 12,
                                                    height: 1.5,
                                                    color: grey),
                                                inputFormatters: [
                                                  UI.decimalInputFormatter(6)
                                                ],
                                                keyboardType: TextInputType
                                                    .numberWithOptions(
                                                        decimal: true),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(24)),
                                                  border: Border.all(
                                                      color: _slippageFocusNode
                                                              .hasFocus
                                                          ? primary
                                                          : grey),
                                                ),
                                                controller: _amountSlippageCtrl,
                                                focusNode: _slippageFocusNode,
                                                onChanged: _onSlippageChange,
                                                suffix: Container(
                                                  padding:
                                                      EdgeInsets.only(right: 8),
                                                  child: Text(
                                                    '%',
                                                    style: TextStyle(
                                                        color:
                                                            _slippageFocusNode
                                                                    .hasFocus
                                                                ? primary
                                                                : grey),
                                                  ),
                                                ),
                                              ),
                                              _slippageError != null
                                                  ? Text(
                                                      _slippageError,
                                                      style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 10),
                                                    )
                                                  : Container()
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                : Container(),
                          ],
                        )
                      : CupertinoActivityIndicator(),
                ),
                showExchangeRate && _amountPayCtrl.text.isNotEmpty
                    ? RoundedCard(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                        dic[_swapMode == 0
                                            ? 'dex.min'
                                            : 'dex.max'],
                                        style: labelStyle),
                                  ),
                                  Text(
                                      '${minMax.toStringAsFixed(6)} ${_swapMode == 0 ? _swapOutput.output : _swapOutput.input}'),
                                ],
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(dic['dex.impact'],
                                        style: labelStyle),
                                  ),
                                  Text(
                                      '<${Fmt.ratio(_swapOutput.priceImpact)}'),
                                ],
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child:
                                        Text(dic['dex.fee'], style: labelStyle),
                                  ),
                                  Text(
                                      '${_swapOutput.fee} ${PluginFmt.tokenView(_swapPair[0])}'),
                                ],
                              ),
                            ),
                            (_swapOutput.path?.length ?? 0) > 2
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(dic['dex.route'],
                                            style: labelStyle),
                                      ),
                                      Text(_swapOutput.path
                                          .map((i) =>
                                              PluginFmt.tokenView(i['symbol']))
                                          .toList()
                                          .join(' > ')),
                                    ],
                                  )
                                : Container()
                          ],
                        ),
                      )
                    : Container(),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: RoundedButton(
                    text: dic['dex.title'],
                    onPressed: !enabled || _swapRatio == 0
                        ? null
                        : () => _onSubmit(pairDecimals, minMax),
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
