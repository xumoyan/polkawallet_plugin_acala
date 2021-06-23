const int SECONDS_OF_DAY = 24 * 60 * 60; // seconds of one day
const int SECONDS_OF_YEAR = 365 * 24 * 60 * 60; // seconds of one year
const BLOCK_TIME_DEFAULT = 6000;

const plugin_name_acala = 'acala-tc6';
const plugin_name_karura = 'karura';
const ss58_prefix_acala = 42;
const ss58_prefix_karura = 8;

const node_list = {
  plugin_name_acala: [
    {
      'name': 'Acala Mandala (Hosted by Acala Network)',
      'ss58': ss58_prefix_acala,
      'endpoint': 'wss://mandala6.laminar.codes',
    },
    {
      'name': 'Mandala TC6 Node 1 (Hosted by OnFinality)',
      'ss58': ss58_prefix_acala,
      'endpoint': 'wss://node-6775973502614921216.rz.onfinality.io/ws',
    },
  ],
  plugin_name_karura: [
    {
      'name': 'Acala Karura (Hosted by Acala Network)',
      'ss58': ss58_prefix_karura,
      'endpoint': 'wss://karura-rpc-0.aca-api.network',
    },
    {
      'name': 'Acala Karura (Hosted by OnFinality)',
      'ss58': ss58_prefix_karura,
      'endpoint': 'wss://karura.api.onfinality.io',
    },
    {
      'name': 'Acala Karura (Hosted by Polkawallet)',
      'ss58': ss58_prefix_karura,
      'endpoint': 'wss://karura.polkawallet.io:9944',
    },
  ],
};

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

const relay_chain_token_symbol = {
  plugin_name_acala: 'DOT',
  plugin_name_karura: 'KSM',
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
    'KUSD-KSM',
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

// graphql query
const graphTransferQuery = r'''
  query ($account: String, $token: String) { 
    transfers(filter: {
      tokenId: { equalTo: $token },
      or: [
        { fromId: { equalTo: $account } },
        { toId: { equalTo: $account } }
      ]
    }, first: 20, orderBy: TIMESTAMP_DESC) {
      nodes {
        id
        from {id}
        to {id}
        token {id}
        amount
        isSuccess
        extrinsic {
          id
          block {number}
          timestamp
        }
      }
    }
  }
''';
const graphLoanQuery = r'''
  query ($account: String) {
    loanActions(condition: {accountId: $account }, orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        token {id}
        collateral
        debit
        exchangeRate
        isSuccess
        extrinsic {
          id
          block {number}
          timestamp
        }
      }
    }
  }
''';
const graphSwapQuery = r'''
  query ($account: String) {
    calls(filter: {
      and: [
        {
          or: [
            { method: {equalTo: "swapWithExactSupply"} },
            { method: {equalTo: "swapWithExactTarget"} },
          ]
        },
        { section: {equalTo: "dex"} },
        { signerId: { equalTo: $account } }
      ]
    }, orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        method
        section
        args
        isSuccess
        extrinsic {
          id
          block {number}
          timestamp
        }
      }
    }
  }
''';
const graphDexPoolQuery = r'''
  query ($account: String) {
    calls(filter: {
      and: [
        {
          or: [
            { method: {equalTo: "addLiquidity"} },
            { method: {equalTo: "removeLiquidity"} },
          ]
        },
        { section: {equalTo: "dex"} },
        { signerId: { equalTo: $account } }
      ]
    }, orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        method
        section
        args
        isSuccess
        extrinsic {
          id
          block {number}
          timestamp
        }
      }
    }
  }
''';
const graphDexStakeQuery = r'''
  query ($account: String) {
    calls(filter: {
      and: [
        {
          or: [
            { method: {equalTo: "depositDexShare"} },
            { method: {equalTo: "withdrawDexShare"} }
          ]
        },
        { section: {equalTo: "incentives"} },
        { signerId: {equalTo: $account} }
      ]
    }, orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        method
        section
        args
        isSuccess
        extrinsic {
          id
          block {number}
          timestamp
        }
      }
    }
  }
''';
const graphEarnQuery = r'''
  query ($account: String) {
    calls(filter: {
      and: [
        {
          or: [
            { args: {includes: "dexIncentive"} },
            { args: {includes: "dexSaving"} }
          ]
        },
        { section: {equalTo: "incentives"} },
        { method: {equalTo: "claimRewards"} }
        { signerId: {equalTo: $account} }
      ]
    }, orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        method
        section
        args
        isSuccess
        extrinsic {
          id
          block {number}
          timestamp
        }
      }
    }
  }
''';
const graphHomaQuery = r'''
  query ($account: String) {
    calls(filter: {
      and: [
        {
          or: [
            { method: {equalTo: "mint"} },
            { method: {equalTo: "redeem"} }
          ]
        },
        { section: {equalTo: "homa"} },
        { signerId: { equalTo: $account } }
      ]
    }, orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        method
        section
        args
        isSuccess
        extrinsic {
          id
          block {number}
          timestamp
          events {
            nodes {
              data,
              method
            }
          }
        }
      }
    }
  }
''';
