const int SECONDS_OF_DAY = 24 * 60 * 60; // seconds of one day
const int SECONDS_OF_YEAR = 365 * 24 * 60 * 60; // seconds of one year

const node_list = [
  {
    'name': 'Acala Mandala (Hosted by Acala Network)',
    'ss58': 42,
    'endpoint': 'wss://mandala6.laminar.codes',
  },
  {
    'name': 'Mandala TC6 Node 1 (Hosted by OnFinality)',
    'ss58': 42,
    'endpoint': 'wss://node-6775973502614921216.rz.onfinality.io/ws',
  },
];

const acala_plugin_cache_key = 'plugin_acala';

const acala_genesis_hash =
    '0x5fad1818cb637f0737771f27db0c28e7f669305ea71d84299291370d6723809c';
const acala_price_decimals = 18;
const acala_stable_coin = 'AUSD';
const acala_stable_coin_view = 'aUSD';
const acala_token_ren_btc = 'RENBTC';
const acala_token_ren_btc_view = 'renBTC';
const acala_token_polka_btc = 'POLKABTC';
const acala_token_polka_btc_view = 'polkaBTC';

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
