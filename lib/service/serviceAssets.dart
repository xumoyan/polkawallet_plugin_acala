import 'package:polkawallet_plugin_acala/api/acalaApi.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/service/walletApi.dart';
import 'package:polkawallet_plugin_acala/store/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
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

    // todo: remove this after homaToken enabled
    final relayChainToken = relay_chain_token_symbol[plugin.basic.name];
    final homaToken = 'L$relayChainToken';
    if (store.assets.marketPrices[homaToken] == null &&
        prices[homaToken] == null) {
      if (store.assets.marketPrices[relayChainToken] != null ||
          prices[relayChainToken] != null) {
        prices[homaToken] = store.assets.marketPrices[relayChainToken] ??
            prices[relayChainToken];
      }
    }

    store.assets.setMarketPrices(prices);
  }

  Future<void> updateTokenBalances(String tokenId) async {
    String currencyId = '{Token: "$tokenId"}';
    if (tokenId.contains('-')) {
      final pair = tokenId.split('-');
      currencyId = '{DEXShare: [{Token: "${pair[0]}"}, {Token: "${pair[1]}"}]}';
    }
    final res = await plugin.sdk.webView.evalJavascript(
        'api.query.tokens.accounts("${keyring.current.address}", $currencyId)');

    final balances =
        Map<String, TokenBalanceData>.from(store.assets.tokenBalanceMap);
    final data = TokenBalanceData(
        id: balances[tokenId].id,
        name: balances[tokenId].name,
        symbol: balances[tokenId].symbol,
        decimals: balances[tokenId].decimals,
        amount: res['free'].toString(),
        locked: res['frozen'].toString(),
        reserved: res['reserved'].toString(),
        detailPageRoute: balances[tokenId].detailPageRoute,
        price: balances[tokenId].price);
    balances[tokenId] = data;

    store.assets
        .setTokenBalanceMap(balances.values.toList(), keyring.current.pubKey);
    plugin.balances.setTokens([data]);
  }
}
