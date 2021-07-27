import 'package:polkawallet_plugin_acala/api/acalaApi.dart';
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

  Future<String> queryMarketPrice(String token) async {
    final res = await WalletApi.getTokenPrice(token);
    store.assets.setMarketPrices({token: res['price'] as String});
    return res['price'] as String;
  }
}
