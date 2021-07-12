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
