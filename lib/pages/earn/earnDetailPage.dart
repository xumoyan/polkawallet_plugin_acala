import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/txDetail.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/api/types/txIncentiveData.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';

class EarnIncentiveDetailPage extends StatelessWidget {
  EarnIncentiveDetailPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static final String route = '/acala/earn/incentive/tx';

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    final amountStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

    final TxDexIncentiveData tx = ModalRoute.of(context).settings.arguments;

    final List<TxDetailInfoItem> items = [];
    switch (tx.action) {
      case TxDexIncentiveData.actionRewardIncentive:
        items.add(TxDetailInfoItem(
          label: dic['earn.get'],
          content: Text('ACA', style: amountStyle),
        ));
        break;
      case TxDexIncentiveData.actionRewardSaving:
        items.add(TxDetailInfoItem(
          label: dic['earn.get'],
          content: Text('aUSD', style: amountStyle),
        ));
        break;
      case TxDexIncentiveData.actionStake:
        items.add(TxDetailInfoItem(
          label: dic['earn.stake'],
          content: Text(tx.amountShare, style: amountStyle),
        ));
        break;
      case TxDexIncentiveData.actionUnStake:
        items.add(TxDetailInfoItem(
          label: dic['earn.unStake'],
          content: Text(tx.amountShare, style: amountStyle),
        ));
        break;
    }

    String networkName = plugin.basic.name;
    if (plugin.basic.isTestNet) {
      networkName = '${networkName.split('-')[0]}-testnet';
    }
    return TxDetail(
      success: tx.isSuccess,
      action: tx.action,
      blockNum: tx.block,
      hash: tx.hash,
      blockTime: Fmt.dateTime(DateTime.parse(tx.time)),
      networkName: networkName,
      infoItems: items,
    );
  }
}
