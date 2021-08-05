import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/earn/earnPage.dart';
import 'package:polkawallet_plugin_acala/pages/gov/democracyPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/homaPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanPage.dart';
import 'package:polkawallet_plugin_acala/pages/nft/nftPage.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/entryPageCard.dart';

class AcalaEntry extends StatefulWidget {
  AcalaEntry(this.plugin, this.keyring);

  final PluginAcala plugin;
  final Keyring keyring;

  @override
  _AcalaEntryState createState() => _AcalaEntryState();
}

class _AcalaEntryState extends State<AcalaEntry> {
  bool _faucetSubmitting = false;

  Future<void> _getTokensFromFaucet() async {
    setState(() {
      _faucetSubmitting = true;
    });
    final res = await widget.plugin.api.assets
        .fetchFaucet(widget.keyring.current.address);
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    String dialogContent = dic['faucet.ok'];
    if (res == null || res != "success") {
      dialogContent = res ?? dic['faucet.error'];
    }

    Timer(Duration(seconds: 3), () {
      if (!mounted) return;

      setState(() {
        _faucetSubmitting = false;
      });

      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Container(),
            content: Text(dialogContent),
            actions: <Widget>[
              CupertinoButton(
                child: Text(I18n.of(context)
                    .getDic(i18n_full_dic_acala, 'common')['ok']),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  final _liveModuleRoutes = {
    'loan': LoanPage.route,
    'swap': SwapPage.route,
    'earn': EarnPage.route,
    'homa': HomaPage.route,
    'nft': NFTPage.route,
    'gov': NFTPage.route,
  };

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'common');
    final dicGov = I18n.of(context).getDic(i18n_full_dic_acala, 'gov');
    final isKar = widget.plugin.basic.name == plugin_name_karura;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    dic[isKar ? 'karura' : 'acala'],
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).cardColor,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: Observer(
                builder: (_) {
                  if (widget.plugin.sdk.api?.connectedNode == null) {
                    return Container(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.width / 2),
                      child: Column(
                        children: [
                          CupertinoActivityIndicator(),
                          Text(dic['node.connecting']),
                        ],
                      ),
                    );
                  }
                  final modulesConfig = widget.plugin.store.setting.liveModules;
                  final List liveModules =
                      modulesConfig.keys.toList().sublist(1);

                  liveModules?.retainWhere((e) => modulesConfig[e]['visible']);
                  return ListView(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: <Widget>[
                      Container(
                        height: 68,
                        margin: EdgeInsets.only(bottom: 16),
                        child: SvgPicture.asset(
                            'packages/polkawallet_plugin_acala/assets/images/${isKar ? 'logo_kar_empty' : 'logo1'}.svg',
                            color: Colors.white70),
                      ),
                      ...liveModules.map((e) {
                        final dicIndex = isKar ? '${e}KSM' : e;
                        final enabled = !isKar || modulesConfig[e]['enabled'];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            child: EntryPageCard(
                              dic['$dicIndex.title'],
                              enabled ? dic['$dicIndex.brief'] : dic['coming'],
                              SvgPicture.asset(
                                module_icons_uri[widget.plugin.basic.name][e],
                                height: 88,
                              ),
                              color: Colors.transparent,
                            ),
                            onTap: () => Navigator.of(context).pushNamed(
                                _liveModuleRoutes[e],
                                arguments: enabled),
                          ),
                        );
                      }).toList(),
                      isKar
                          ? Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                child: EntryPageCard(
                                  dicGov['democracy'],
                                  dicGov['democracy.brief'],
                                  SvgPicture.asset(
                                    'packages/polkawallet_plugin_acala/assets/images/democracy.svg',
                                    height: 88,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  color: Colors.transparent,
                                ),
                                onTap: () => Navigator.of(context)
                                    .pushNamed(DemocracyPage.route),
                              ),
                            )
                          : Container(),
                      widget.plugin.basic.isTestNet
                          ? Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Theme.of(context).primaryColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(40))),
                                  ),
                                  child: Row(
                                    children: [
                                      _faucetSubmitting
                                          ? CupertinoActivityIndicator()
                                          : SvgPicture.asset(
                                              'packages/polkawallet_plugin_acala/assets/images/faucet.svg',
                                              height: 18,
                                              color:
                                                  Theme.of(context).cardColor,
                                            ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Text(
                                          'Faucet',
                                          style: TextStyle(
                                            color: Theme.of(context).cardColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onPressed: _faucetSubmitting
                                      ? null
                                      : _getTokensFromFaucet,
                                ),
                              ],
                            )
                          : Container(),
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
