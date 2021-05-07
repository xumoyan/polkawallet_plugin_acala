import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_acala/common/constants.dart';

class StoreCache {
  static final _storage = () => GetStorage(acala_plugin_cache_key);

  final tokens = {}.val('tokens', getBox: _storage);

  final loanTxs = {}.val('loanTxs', getBox: _storage);
  final homaTxs = {}.val('homaTxs', getBox: _storage);
}
