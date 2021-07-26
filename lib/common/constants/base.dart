const int SECONDS_OF_DAY = 24 * 60 * 60; // seconds of one day
const int SECONDS_OF_YEAR = 365 * 24 * 60 * 60; // seconds of one year
const BLOCK_TIME_DEFAULT = 12000;

const plugin_name_acala = 'acala-tc6';
const plugin_name_karura = 'karura';
const ss58_prefix_acala = 42;
const ss58_prefix_karura = 8;

const GraphQLConfig = {
  plugin_name_acala: {'httpUri': 'https://api.polkawallet.io/acala-subql'},
  plugin_name_karura: {'httpUri': 'https://api.polkawallet.io/karura-subql'},
};
