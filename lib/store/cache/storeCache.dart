import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_plugin_acala/common/constants.dart';

class StoreCache {
  static final _storage = () => GetStorage(plugin_cache_key[plugin_name_acala]);

  final tokens = {}.val('tokens', getBox: _storage);

  final homaTxs = {}.val('homaTxs', getBox: _storage);
}

class StoreCacheKar extends StoreCache {
  static final _storage =
      () => GetStorage(plugin_cache_key[plugin_name_karura]);

  final tokens = {}.val('tokens', getBox: _storage);

  final homaTxs = {}.val('homaTxs', getBox: _storage);
}
