import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/txDetail.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/api/types/txSwapData.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';

class SwapDetailPage extends StatelessWidget {
  SwapDetailPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static final String route = '/acala/swap/tx';

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context).getDic(i18n_full_dic_acala, 'acala');

    final TxSwapData tx = ModalRoute.of(context).settings.arguments;

    final amountStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

    String networkName = plugin.basic.name;
    if (plugin.basic.isTestNet) {
      networkName = '${networkName.split('-')[0]}-testnet';
    }
    return TxDetail(
      success: tx.isSuccess,
      action: dic['dex.title'],
      blockNum: tx.block,
      hash: tx.hash,
      blockTime: Fmt.dateTime(DateTime.parse(tx.time)),
      networkName: networkName,
      infoItems: <TxDetailInfoItem>[
        TxDetailInfoItem(
          label: dic['dex.pay'],
          content: Text('${tx.amountPay} ${PluginFmt.tokenView(tx.tokenPay['token'])}',
              style: amountStyle),
        ),
        TxDetailInfoItem(
          label: dic['dex.receive'],
          content: Text('${tx.amountReceive} ${PluginFmt.tokenView(tx.tokenReceive['token'])}',
              style: amountStyle),
        )
      ],
    );
  }
}
