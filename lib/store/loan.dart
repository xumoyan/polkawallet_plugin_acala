import 'package:mobx/mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/loanType.dart';
import 'package:polkawallet_plugin_acala/store/cache/storeCache.dart';

part 'loan.g.dart';

class LoanStore extends _LoanStore with _$LoanStore {
  LoanStore(StoreCache cache) : super(cache);
}

abstract class _LoanStore with Store {
  _LoanStore(this.cache);

  final StoreCache cache;

  @observable
  List<LoanType> loanTypes = [];

  @observable
  Map<String, LoanData> loans = Map<String, LoanData>();

  @observable
  bool loansLoading = true;

  @action
  void setLoanTypes(List<LoanType> list) {
    loanTypes = list;
  }

  @action
  void setAccountLoans(Map<String, LoanData> data) {
    loans = data;
  }

  @action
  void setLoansLoading(bool loading) {
    loansLoading = loading;
  }

  @action
  void loadCache(String pubKey) {
    if (pubKey == null || pubKey.isEmpty) return;

    setAccountLoans(Map<String, LoanData>());
  }
}
