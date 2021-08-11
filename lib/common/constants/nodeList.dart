import 'package:polkawallet_plugin_acala/common/constants/base.dart';

const node_list = {
  plugin_name_acala: [
    {
      'name': 'Acala Mandala (Hosted by Acala Network)',
      'ss58': ss58_prefix_acala,
      'endpoint': 'wss://mandala6.laminar.codes',
    },
    {
      'name': 'Mandala TC6 Node 1 (Hosted by OnFinality)',
      'ss58': ss58_prefix_acala,
      'endpoint': 'wss://node-6775973502614921216.rz.onfinality.io/ws',
    },
  ],
  plugin_name_karura: [
    {
      'name': 'Karura (Hosted by Polkawallet)',
      'ss58': ss58_prefix_karura,
      'endpoint': 'wss://karura.polkawallet.io',
    },
    {
      'name': 'Karura (Hosted by Acala Foundation 0)',
      'ss58': ss58_prefix_karura,
      'endpoint': 'wss://karura-rpc-0.aca-api.network',
    },
    {
      'name': 'Karura (Hosted by Acala Foundation 1)',
      'ss58': ss58_prefix_karura,
      'endpoint': 'wss://karura-rpc-1.aca-api.network',
    },
    {
      'name': 'Karura (Hosted by Acala Foundation 2)',
      'ss58': ss58_prefix_karura,
      'endpoint': 'wss://karura-rpc-2.aca-api.network',
    },
    {
      'name': 'Karura (Hosted by Acala Foundation 3)',
      'ss58': ss58_prefix_karura,
      'endpoint': 'wss://karura-rpc-3.aca-api.network',
    },
    {
      'name': 'Karura (Hosted by OnFinality)',
      'ss58': ss58_prefix_karura,
      'endpoint': 'wss://karura.api.onfinality.io',
    },
    // {
    //   'name': 'Acala Karura (Polkawallet dev node)',
    //   'ss58': ss58_prefix_karura,
    //   'endpoint': 'wss://kusama-1.polkawallet.io:9944',
    // },
  ],
};
