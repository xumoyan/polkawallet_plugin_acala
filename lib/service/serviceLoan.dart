import 'package:polkawallet_plugin_acala/api/acalaApi.dart';
import 'package:polkawallet_plugin_acala/api/types/loanType.dart';
import 'package:polkawallet_plugin_acala/api/types/stakingPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/common/constants.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/store/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_ui/utils/format.dart';

class ServiceLoan {
  ServiceLoan(this.plugin, this.keyring)
      : api = plugin.api,
        store = plugin.store;

  final PluginAcala plugin;
  final Keyring keyring;
  final AcalaApi api;
  final PluginStore store;

  void _calcLDOTPrice(Map<String, BigInt> prices, double liquidExchangeRate) {
    // LDOT price may lost precision here
    prices['LDOT'] = Fmt.tokenInt(
        (Fmt.bigIntToDouble(
                    prices['DOT'], plugin.networkState.tokenDecimals[0]) *
                liquidExchangeRate)
            .toString(),
        plugin.networkState.tokenDecimals[0]);
  }

  Future<double> _fetchACAPrice() async {
    final output =
        await api.swap.queryTokenSwapAmount('1', null, ['ACA', 'AUSD'], '0.1');
    return output.amount;
  }

  Map<String, LoanData> _calcLoanData(
    List loans,
    List<LoanType> loanTypes,
    Map<String, BigInt> prices,
  ) {
    final data = Map<String, LoanData>();
    final isKar = plugin.basic.name == plugin_name_karura;
    final stableCoinDecimals = plugin.networkState.tokenDecimals[plugin
        .networkState.tokenSymbol
        .indexOf(isKar ? karura_stable_coin : acala_stable_coin)];
    loans.forEach((i) {
      final String token = i['currency']['token'];
      final tokenDecimals = plugin.networkState
          .tokenDecimals[plugin.networkState.tokenSymbol.indexOf(token)];
      data[token] = LoanData.fromJson(
        Map<String, dynamic>.from(i),
        loanTypes.firstWhere((t) => t.token == token),
        prices[token] ?? BigInt.zero,
        stableCoinDecimals,
        tokenDecimals,
      );
    });
    return data;
  }

  Map<String, double> _calcCollateralIncentiveRate(
      List<CollateralIncentiveData> incentives) {
    final blockTime = plugin.networkConst['babe'] == null
        ? BLOCK_TIME_DEFAULT
        : int.parse(plugin.networkConst['babe']['expectedBlockTime']);
    final epoch =
        int.parse(plugin.networkConst['incentives']['accumulatePeriod']);
    final epochOfYear = SECONDS_OF_YEAR * 1000 / blockTime / epoch;
    final res = Map<String, double>();
    incentives.forEach((e) {
      res[e.token] = Fmt.bigIntToDouble(
              e.incentive, plugin.networkState.tokenDecimals[0]) *
          epochOfYear;
    });
    return res;
  }

  Future<void> queryLoanTypes(String address) async {
    if (address == null) return;

    final res = await Future.wait([
      api.loan.queryLoanTypes(),
      plugin.basic.name == plugin_name_karura
          ? api.loan.queryCollateralIncentives()
          : api.loan.queryCollateralIncentivesTC6(),
    ]);
    store.loan.setLoanTypes(res[0]);
    if (res[1] != null) {
      store.loan.setCollateralIncentives(_calcCollateralIncentiveRate(res[1]));
    }

    queryTotalCDPs();
  }

  Future<void> subscribeAccountLoans(String address) async {
    if (address == null) return;

    store.loan.setLoansLoading(true);

    // 1. subscribe all token prices, callback triggers per 5s.
    api.assets.subscribeTokenPrices((Map<String, BigInt> prices) async {
      // 2. we need homa staking pool info to calculate price of LDOT
      final data = await Future.wait(
          [api.homa.queryHomaStakingPool(), _fetchACAPrice()]);
      final StakingPoolInfoData stakingPoolInfo = data[0];
      store.homa.setStakingPoolInfoData(stakingPoolInfo);

      // 3. set prices
      _calcLDOTPrice(prices, stakingPoolInfo.liquidExchangeRate);
      prices['ACA'] =
          Fmt.tokenInt(data[1].toString(), 18); // decimals of prices are 18.
      store.assets.setPrices(prices);

      // 4. update collateral incentive rewards
      queryCollateralRewards(address);

      // 4. we need loanTypes & prices to get account loans
      final loans = await api.loan.queryAccountLoans(address);
      if (store.loan.loansLoading) {
        store.loan.setLoansLoading(false);
      }
      if (loans != null &&
          loans.length > 0 &&
          store.loan.loanTypes.length > 0 &&
          keyring.current.address == address) {
        store.loan.setAccountLoans(
            _calcLoanData(loans, store.loan.loanTypes, prices));
      }
    });
  }

  Future<void> queryTotalCDPs() async {
    final res = await api.loan
        .queryTotalCDPs(store.loan.loanTypes.map((e) => e.token).toList());
    store.loan.setTotalCDPs(res);
  }

  Future<void> queryCollateralRewards(String address) async {
    final res = await api.loan.queryCollateralRewards(
        store.loan.collateralIncentives.keys.toList(), address);
    store.loan.setCollateralRewards(res);
  }

  void unsubscribeAccountLoans() {
    api.assets.unsubscribeTokenPrices();
    store.loan.setLoansLoading(true);
  }
}
