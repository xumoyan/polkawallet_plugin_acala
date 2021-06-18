library polkawallet_plugin_acala;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_acala/api/acalaApi.dart';
import 'package:polkawallet_plugin_acala/api/acalaService.dart';
import 'package:polkawallet_plugin_acala/common/constants.dart';
import 'package:polkawallet_plugin_acala/pages/acalaEntry.dart';
import 'package:polkawallet_plugin_acala/pages/assets/tokenDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/assets/transferDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/assets/transferPage.dart';
import 'package:polkawallet_plugin_acala/pages/currencySelectPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/LPStakePage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/addLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/earnDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/earnHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/earnPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/liquidityDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/withdrawLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/homaHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/homaPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/mintPage.dart';
import 'package:polkawallet_plugin_acala/pages/homa/redeemPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanAdjustPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanCreatePage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanTxDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/nft/nftPage.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/swap/swapPage.dart';
import 'package:polkawallet_plugin_acala/service/graphql.dart';
import 'package:polkawallet_plugin_acala/service/index.dart';
import 'package:polkawallet_plugin_acala/store/cache/storeCache.dart';
import 'package:polkawallet_plugin_acala/store/index.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';

class PluginAcala extends PolkawalletPlugin {
  PluginAcala({String name = plugin_name_acala})
      : basic = PluginBasicData(
          name: name,
          genesisHash: plugin_genesis_hash[name],
          ss58: name == plugin_name_karura
              ? ss58_prefix_karura
              : ss58_prefix_acala,
          primaryColor: name == plugin_name_karura ? Colors.red : Colors.indigo,
          gradientColor: name == plugin_name_karura
              ? Color.fromARGB(255, 255, 76, 59)
              : Color(0xFF4B68F9),
          backgroundImage: AssetImage(
              'packages/polkawallet_plugin_acala/assets/images/${name == plugin_name_karura ? 'bg_kar' : 'bg'}.png'),
          icon: name == plugin_name_karura
              ? Image.asset(
                  'packages/polkawallet_plugin_acala/assets/images/tokens/KAR.png')
              : SvgPicture.asset(
                  'packages/polkawallet_plugin_acala/assets/images/logo.svg'),
          iconDisabled: name == plugin_name_karura
              ? Image.asset(
                  'packages/polkawallet_plugin_acala/assets/images/logo_kar_gray.png')
              : SvgPicture.asset(
                  'packages/polkawallet_plugin_acala/assets/images/logo.svg',
                  color: Color(0xFF9E9E9E),
                  width: 24,
                ),
          isTestNet: name != plugin_name_karura,
          jsCodeVersion: 20701,
        );

  @override
  final PluginBasicData basic;

  @override
  List<NetworkParams> get nodeList {
    return node_list[basic.name].map((e) => NetworkParams.fromJson(e)).toList();
  }

  Map<String, Widget> _getTokenIcons() {
    final Map<String, Widget> all = {};
    acala_token_ids[basic.name].forEach((token) {
      all[token] = Image.asset(
          'packages/polkawallet_plugin_acala/assets/images/tokens/$token.png');
    });
    acala_lp_token_ids[basic.name].forEach((token) {
      all[token] = TokenIcon(token, all);
    });
    return all;
  }

  @override
  Map<String, Widget> get tokenIcons => _getTokenIcons();

  @override
  List<HomeNavItem> getNavItems(BuildContext context, Keyring keyring) {
    return [
      basic.name == plugin_name_karura
          ? HomeNavItem(
              text: 'Karura',
              icon: SvgPicture.asset(
                  'packages/polkawallet_plugin_acala/assets/images/logo_kar_empty.svg',
                  color: Theme.of(context).disabledColor),
              iconActive: Image.asset(
                  'packages/polkawallet_plugin_acala/assets/images/tokens/KAR.png'),
              content: AcalaEntry(this, keyring),
            )
          : HomeNavItem(
              text: 'Acala',
              icon: SvgPicture.asset(
                'packages/polkawallet_plugin_acala/assets/images/logo.svg',
                color: Theme.of(context).disabledColor,
              ),
              iconActive: SvgPicture.asset(
                  'packages/polkawallet_plugin_acala/assets/images/logo.svg'),
              content: AcalaEntry(this, keyring),
            )
    ];
  }

  @override
  Map<String, WidgetBuilder> getRoutes(Keyring keyring) {
    return {
      TxConfirmPage.route: (_) =>
          TxConfirmPage(this, keyring, _service.getPassword),
      CurrencySelectPage.route: (_) => CurrencySelectPage(this),
      AccountQrCodePage.route: (_) => AccountQrCodePage(this, keyring),

      TokenDetailPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => TokenDetailPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri'],
            subscriptionUri: GraphQLConfig['wsUri'],
          ),
      TransferPage.route: (_) => TransferPage(this, keyring),
      TransferDetailPage.route: (_) => TransferDetailPage(this, keyring),

      // loan pages
      LoanPage.route: (_) => LoanPage(this, keyring),
      LoanDetailPage.route: (_) => LoanDetailPage(this, keyring),
      LoanTxDetailPage.route: (_) => LoanTxDetailPage(this, keyring),
      LoanCreatePage.route: (_) => LoanCreatePage(this, keyring),
      LoanAdjustPage.route: (_) => LoanAdjustPage(this, keyring),
      LoanHistoryPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => LoanHistoryPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri'],
            subscriptionUri: GraphQLConfig['wsUri'],
          ),
      // swap pages
      SwapPage.route: (_) => SwapPage(this, keyring),
      SwapHistoryPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => SwapHistoryPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri'],
            subscriptionUri: GraphQLConfig['wsUri'],
          ),
      SwapDetailPage.route: (_) => SwapDetailPage(this, keyring),
      // earn pages
      EarnPage.route: (_) => EarnPage(this, keyring),
      EarnHistoryPage.route: (_) => ClientProvider(
            child: Builder(
              builder: (_) => EarnHistoryPage(this, keyring),
            ),
            uri: GraphQLConfig['httpUri'],
            subscriptionUri: GraphQLConfig['wsUri'],
          ),
      EarnLiquidityDetailPage.route: (_) =>
          EarnLiquidityDetailPage(this, keyring),
      EarnIncentiveDetailPage.route: (_) =>
          EarnIncentiveDetailPage(this, keyring),
      LPStakePage.route: (_) => LPStakePage(this, keyring),
      AddLiquidityPage.route: (_) => AddLiquidityPage(this, keyring),
      WithdrawLiquidityPage.route: (_) => WithdrawLiquidityPage(this, keyring),
      // homa pages
      HomaPage.route: (_) => HomaPage(this, keyring),
      MintPage.route: (_) => MintPage(this, keyring),
      HomaRedeemPage.route: (_) => HomaRedeemPage(this, keyring),
      HomaHistoryPage.route: (_) => HomaHistoryPage(this, keyring),
      // NFT pages
      NFTPage.route: (_) => NFTPage(this, keyring),
    };
  }

  @override
  Future<String> loadJSCode() => rootBundle.loadString(
      'packages/polkawallet_plugin_acala/lib/js_service_acala${basic.name == plugin_name_karura ? '' : '_tc6'}/dist/main.js');

  AcalaApi _api;
  AcalaApi get api => _api;

  StoreCache _cache;
  PluginStore _store;
  PluginService _service;
  PluginStore get store => _store;
  PluginService get service => _service;

  Future<void> _subscribeTokenBalances(KeyPairData acc) async {
    final enabled = basic.name != plugin_name_karura ||
        _store.setting.liveModules['assets']['enabled'];

    _api.assets.subscribeTokenBalances(basic.name, acc.address, (data) {
      _store.assets.setTokenBalanceMap(data, acc.pubKey);

      _updateTokenBalances(data);
    }, transferEnabled: enabled);

    if (basic.name == plugin_name_acala) {
      final airdrops = await _api.assets.queryAirdropTokens(acc.address);
      balances
          .setExtraTokens([ExtraTokenData(title: 'Airdrop', tokens: airdrops)]);
    }

    final nft = await _api.assets.queryNFTs(acc.address);
    if (nft != null) {
      _store.assets.setNFTs(nft);
    }
  }

  void _updateTokenBalances(List<TokenBalanceData> data) {
    data.removeWhere((e) => e.symbol.contains('-') && e.amount == '0');
    balances.setTokens(data);
  }

  void _loadCacheData(KeyPairData acc) {
    balances.setExtraTokens([]);
    _store.assets.setNFTs([]);

    try {
      loadBalances(acc);

      _store.assets.loadCache(acc.pubKey);
      _updateTokenBalances(_store.assets.tokenBalanceMap.values.toList());

      _store.loan.loadCache(acc.pubKey);
      _store.earn.loadCache(acc.pubKey);
      _store.homa.loadCache(acc.pubKey);
      print('acala plugin cache data loaded');
    } catch (err) {
      print(err);
      print('load acala cache data failed');
    }
  }

  @override
  Future<void> onWillStart(Keyring keyring) async {
    _api = AcalaApi(AcalaService(this));

    await GetStorage.init(plugin_cache_key[basic.name]);

    _cache = basic.name == plugin_name_karura ? StoreCacheKar() : StoreCache();
    _store = PluginStore(_cache);
    _loadCacheData(keyring.current);

    _service = PluginService(this, keyring);

    _service.fetchLiveModules();
  }

  @override
  Future<void> onStarted(Keyring keyring) async {
    _service.connected = true;

    if (keyring.current.address != null) {
      _subscribeTokenBalances(keyring.current);
    }
  }

  @override
  Future<void> onAccountChanged(KeyPairData acc) async {
    _loadCacheData(acc);

    if (_service.connected) {
      _api.assets.unsubscribeTokenBalances(basic.name, acc.address);
      _subscribeTokenBalances(acc);
    }
  }
}
