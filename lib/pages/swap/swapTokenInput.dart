import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_plugin_acala/pages/currencySelectPage.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';

class SwapTokenInput extends StatelessWidget {
  SwapTokenInput({
    this.title,
    this.inputCtrl,
    this.focusNode,
    this.balance,
    this.tokenOptions,
    this.tokenIconsMap,
    this.onInputChange,
    this.onTokenChange,
    this.onSetMax,
  });
  final String title;
  final TextEditingController inputCtrl;
  final FocusNode focusNode;
  final TokenBalanceData balance;
  final List<String> tokenOptions;
  final Map<String, Widget> tokenIconsMap;
  final Function(String) onInputChange;
  final Function(String) onTokenChange;
  final Function(BigInt) onSetMax;

  Future<void> _selectCurrencyPay(BuildContext context) async {
    var selected = await Navigator.of(context)
        .pushNamed(CurrencySelectPage.route, arguments: tokenOptions);
    if (selected != null) {
      onTokenChange(selected as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    final dicAssets = I18n.of(context).getDic(i18n_full_dic_acala, 'common');

    final tokenView = PluginFmt.tokenView(balance.symbol);
    final max = Fmt.balanceInt(balance.amount);

    final inputStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.bold);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: Theme.of(context).disabledColor, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title ?? ''),
                Text(
                  '${dicAssets['balance']}: ${Fmt.token(max, balance.decimals)} $tokenView',
                  style: TextStyle(
                      color: Theme.of(context).unselectedWidgetColor,
                      fontSize: 14),
                )
              ],
            ),
          ),
          Row(children: [
            Expanded(
              child: TextFormField(
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: '0.0',
                  hintStyle: inputStyle,
                  errorStyle: TextStyle(height: 0.3),
                  suffix: onSetMax == null
                      ? null
                      : GestureDetector(
                          child: Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: TextTag(dic['dex.max']),
                          ),
                          onTap: () => onSetMax(max),
                        ),
                  contentPadding: EdgeInsets.all(0),
                  border: InputBorder.none,
                ),
                style: inputStyle,
                inputFormatters: [UI.decimalInputFormatter(balance.decimals)],
                controller: inputCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: onInputChange,
              ),
            ),
            GestureDetector(
              child: CurrencyWithIcon(
                tokenView,
                TokenIcon(balance.symbol, tokenIconsMap, small: true),
                textStyle: Theme.of(context).textTheme.headline4,
                trailing: Icon(Icons.keyboard_arrow_down),
              ),
              onTap: () => _selectCurrencyPay(context),
            )
          ])
        ],
      ),
    );
  }
}
