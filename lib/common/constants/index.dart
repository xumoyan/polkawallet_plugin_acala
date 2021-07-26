import 'package:polkawallet_plugin_acala/common/constants/base.dart';

const plugin_cache_key = {
  plugin_name_acala: 'plugin_acala',
  plugin_name_karura: 'plugin_karura',
};

const plugin_genesis_hash = {
  plugin_name_acala:
      '0x5fad1818cb637f0737771f27db0c28e7f669305ea71d84299291370d6723809c',
  plugin_name_karura:
      '0xbaf5aabe40646d11f0ee8abbdc64f4a4b7674925cba08e4a05ff9ebed6e2126b',
};
const acala_price_decimals = 18;
const acala_stable_coin = 'AUSD';
const acala_stable_coin_view = 'aUSD';
const karura_stable_coin = 'KUSD';
const karura_stable_coin_view = 'kUSD';
const acala_token_ren_btc = 'RENBTC';
const acala_token_ren_btc_view = 'renBTC';
const acala_token_polka_btc = 'POLKABTC';
const acala_token_polka_btc_view = 'polkaBTC';

const relay_chain_name = {
  plugin_name_acala: 'polkadot',
  plugin_name_karura: 'kusama',
};
const network_ss58_format = {
  plugin_name_acala: 42, // todo: update this after new acala online
  plugin_name_karura: 8,
  'kusama': 2,
};
const relay_chain_token_symbol = {
  plugin_name_acala: 'DOT',
  plugin_name_karura: 'KSM',
};
const relay_chain_xcm_fees = {
  // todo: polkadot xcm not enabled
  // 'polkadot': {
  //   'fee': '3000000000',
  //   'existentialDeposit': '1000000000',
  // },
  'kusama': {
    'fee': '79999999',
    'existentialDeposit': '33333333',
  },
};
const xcm_dest_weight = '3000000000';

const existential_deposit = {
  'KSM': '100000000',
  'KUSD': '10000000000',
  'LKSM': '500000000',
};

const acala_token_ids = {
  plugin_name_acala: [
    'ACA',
    'AUSD',
    'DOT',
    'LDOT',
    'RENBTC',
    'XBTC',
    'POLKABTC',
    'PLM',
    'PHA'
  ],
  plugin_name_karura: [
    'KAR',
    'KUSD',
    'KSM',
    'LKSM',
    // 'RENBTC',
    // 'XBTC',
    // 'POLKABTC',
  ]
};
const acala_lp_token_ids = {
  plugin_name_acala: [
    'AUSD-DOT',
    'AUSD-LDOT',
    'AUSD-XBTC',
    'AUSD-RENBTC',
    'AUSD-POLKABTC',
    'AUSD-PHA',
    'AUSD-PLM',
    'ACA-AUSD',
  ],
  plugin_name_karura: [
    'KAR-KSM',
    'KUSD-LKSM',
    // 'KUSD-XBTC',
    // 'KUSD-RENBTC',
    // 'KUSD-POLKABTC',
    'KAR-KUSD',
  ]
};

const module_name_assets = 'assets';
const module_name_loan = 'loan';
const module_name_swap = 'swap';
const module_name_earn = 'earn';
const module_name_homa = 'homa';
const module_name_nft = 'nft';
const config_modules = {
  module_name_assets: {
    'visible': true,
    'enabled': false,
  },
  module_name_loan: {
    'visible': true,
    'enabled': false,
  },
  module_name_swap: {
    'visible': true,
    'enabled': false,
  },
  module_name_earn: {
    'visible': true,
    'enabled': false,
  },
  module_name_homa: {
    'visible': true,
    'enabled': false,
  },
  module_name_nft: {
    'visible': true,
    'enabled': true,
  },
};

const image_assets_uri = 'packages/polkawallet_plugin_acala/assets/images';
const module_icons_uri = {
  plugin_name_acala: {
    module_name_loan: '$image_assets_uri/loan.svg',
    module_name_swap: '$image_assets_uri/swap.svg',
    module_name_earn: '$image_assets_uri/earn.svg',
    module_name_homa: '$image_assets_uri/homa.svg',
    module_name_nft: '$image_assets_uri/nft.svg',
  },
  plugin_name_karura: {
    module_name_loan: '$image_assets_uri/loan_kar.svg',
    module_name_swap: '$image_assets_uri/swap_kar.svg',
    module_name_earn: '$image_assets_uri/earn_kar.svg',
    module_name_homa: '$image_assets_uri/homa_kar.svg',
    module_name_nft: '$image_assets_uri/nft_kar.svg',
  }
};
