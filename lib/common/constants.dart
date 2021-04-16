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

const acala_price_decimals = 18;
const acala_stable_coin = 'AUSD';
const acala_stable_coin_view = 'aUSD';
const acala_token_ren_btc = 'RENBTC';
const acala_token_ren_btc_view = 'renBTC';
const acala_token_polka_btc = 'POLKABTC';
const acala_token_polka_btc_view = 'polkaBTC';
