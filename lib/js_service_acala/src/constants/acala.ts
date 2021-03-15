function AcalaToken(token: string, name: string, decimals: number) {
  return {
    token,
    name,
    decimals,
  };
}

export const tokensForAcala = [
  AcalaToken("AUSD", "Acala Dollar", 12),
  AcalaToken("DOT", "Polkadot", 10),
  AcalaToken("LDOT", "Liquid DOT", 10),
  AcalaToken("XBTC", "ChainX BTC", 8),
  AcalaToken("RENBTC", "Ren Protocol BTC", 8),
  AcalaToken("POLKABTC", "PolkaBTC", 8),
  AcalaToken("PLM", "Plasm", 18),
  AcalaToken("PHA", "Phala", 18),
  AcalaToken("HDT", "HydraDX", 12),
];

export const tokensForKarura = [
  AcalaToken("KUSD", "Karura Dollar", 12),
  AcalaToken("KSM", "Kusama", 10),
  AcalaToken("LKSM", "Liquid KSM", 10),
  //   AcalaToken("XBTC", "ChainX BTC", 8),
  //   AcalaToken("RENBTC", "Ren Protocol BTC", 8),
  //   AcalaToken("POLKABTC", "PolkaBTC", 8),
  AcalaToken("SDN", "Shiden", 12),
];
