// graphql query
const transferQuery = r'''
  query ($account: String, $token: String) {
    transfers(filter: {
      tokenId: { equalTo: $token },
      or: [
        { fromId: { equalTo: $account } },
        { toId: { equalTo: $account } }
      ]
    }, first: 10, orderBy: TIMESTAMP_DESC) {
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
const loanQuery = r'''
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
const swapQuery = r'''
  query ($account: String) {
    dexActions(filter: {accountId: {equalTo: $account}},
      orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        data
        extrinsic {
          id
          method
          block {number}
          timestamp
          isSuccess
        }
      }
    }
  }
''';
const dexStakeQuery = r'''
  query ($account: String) {
    incentiveActions(filter: {accountId: {equalTo: $account}},
      orderBy: TIMESTAMP_DESC, first: 20) {
      nodes {
        id
        data
        extrinsic {
          id
          method
          block {number}
          timestamp
          isSuccess
        }
      }
    }
  }
''';
const earnQuery = r'''
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
const homaQuery = r'''
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
