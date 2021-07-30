import 'package:polkawallet_plugin_acala/api/acalaApi.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/service/walletApi.dart';
import 'package:polkawallet_plugin_acala/store/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class ServiceAssets {
  ServiceAssets(this.plugin, this.keyring)
      : api = plugin.api,
        store = plugin.store;

  final PluginAcala plugin;
  final Keyring keyring;
  final AcalaApi api;
  final PluginStore store;

  Future<void> queryMarketPrices(List<String> tokens) async {
    final all = tokens.toList();
    all.removeWhere((e) => e == karura_stable_coin || e == acala_stable_coin);
    if (all.length == 0) return;

    final List res =
        await Future.wait(all.map((e) => WalletApi.getTokenPrice(e)).toList());
    final Map<String, double> prices = {
      karura_stable_coin: 1.0,
      acala_stable_coin: 1.0,
    };
    res.forEach((e) {
      if (e != null && e['price'] != null) {
        prices[e['token']] = double.parse(e['price']);
      }
    });
    store.assets.setMarketPrices(prices);
  }
}
