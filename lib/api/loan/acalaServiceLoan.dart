import 'dart:async';

import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';

class AcalaServiceLoan {
  AcalaServiceLoan(this.plugin);

  final PluginAcala plugin;

  Future<List> queryAccountLoans(String address) async {
    return await plugin.sdk.webView
        .evalJavascript('api.derive.loan.allLoans("$address")');
  }

  Future<List> queryLoanTypes() async {
    return await plugin.sdk.webView
        .evalJavascript('api.derive.loan.allLoanTypes()');
  }
}
