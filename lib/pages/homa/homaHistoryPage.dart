import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/api/types/txHomaData.dart';
import 'package:polkawallet_plugin_acala/common/constants.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/utils/format.dart';

class HomaHistoryPage extends StatelessWidget {
  HomaHistoryPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/homa/txs';

  @override
  Widget build(BuildContext context) {
    final symbol = relay_chain_token_symbol[plugin.basic.name];
    final list = plugin.store.homa.txs.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
            I18n.of(context).getDic(i18n_full_dic_acala, 'acala')['loan.txs']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: list.length + 1,
          itemBuilder: (BuildContext context, int i) {
            if (i == list.length) {
              return ListTail(isEmpty: list.length == 0, isLoading: false);
            }

            final detail = list[i];

            String amountPay = detail.amountPay ?? '0';
            String amountReceive = detail.amountReceive ?? '0';
            if (detail.action == TxHomaData.actionRedeem) {
              amountPay += ' L$symbol';
              amountReceive += ' $symbol';
            } else {
              amountPay += ' $symbol';
              amountReceive += ' L$symbol';
            }
            return Container(
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(width: 0.5, color: Colors.black12)),
              ),
              child: ListTile(
                title: Text('${list[i].action} $amountReceive'),
                subtitle: Text(Fmt.dateTime(list[i].time)),
                leading:
                    SvgPicture.asset('assets/images/assets_up.svg', width: 32),
                trailing: Text(
                  amountPay,
                  style: Theme.of(context).textTheme.headline4,
                  textAlign: TextAlign.end,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
