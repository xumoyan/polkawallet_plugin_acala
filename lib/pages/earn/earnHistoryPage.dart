import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:polkawallet_plugin_acala/api/types/txIncentiveData.dart';
import 'package:polkawallet_plugin_acala/api/types/txLiquidityData.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/common/constants/graphQLQuery.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/earn/earnDetailPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/liquidityDetailPage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/MainTabBar.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/utils/format.dart';

class EarnHistoryPage extends StatefulWidget {
  EarnHistoryPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/earn/txs';

  @override
  _EarnHistoryPageState createState() => _EarnHistoryPageState();
}

const _actionsMap = {
  'addLiquidity': 'earn.deposit',
  'removeLiquidity': 'earn.withdraw',
  'depositDexShare': 'earn.stake',
  'withdrawDexShare': 'earn.unStake',
  'dexIncentive': 'earn.incentive',
  'dexSaving': 'earn.saving',
};

class _EarnHistoryPageState extends State<EarnHistoryPage> {
  int _tab = 0;

  Widget _buildLiquidityTxs(String stableCoinSymbol) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    return Query(
      options: QueryOptions(
        document: gql(graphDexPoolQuery),
        variables: <String, String>{
          'account': widget.keyring.current.address,
        },
      ),
      builder: (
        QueryResult result, {
        Future<QueryResult> Function() refetch,
        FetchMore fetchMore,
      }) {
        if (result.data == null) {
          return Container(
            height: MediaQuery.of(context).size.height / 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CupertinoActivityIndicator()],
            ),
          );
        }
        final ls = List.of(result.data['calls']['nodes']);
        if (ls.length > 0 && ls[0]['section'] != 'dex') {
          return ListTail(isEmpty: true, isLoading: true);
        }
        final list = ls
            .map((i) => TxDexLiquidityData.fromJson(
                i as Map,
                stableCoinSymbol,
                widget.plugin.networkState.tokenSymbol,
                widget.plugin.networkState.tokenDecimals))
            .toList();

        return ListView.builder(
          itemCount: list.length + 1,
          itemBuilder: (BuildContext context, int i) {
            if (i == list.length) {
              return ListTail(isEmpty: list.length == 0, isLoading: false);
            }

            TxDexLiquidityData detail = list[i];
            String amount = '';
            bool isReceive = true;
            switch (detail.action) {
              case TxDexLiquidityData.actionDeposit:
                amount = '${detail.amountLeft} + ${detail.amountRight}';
                isReceive = false;
                break;
              case TxDexLiquidityData.actionWithdraw:
                amount = detail.amountShare;
                break;
            }
            return Container(
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(width: 0.5, color: Colors.black12)),
              ),
              child: ListTile(
                title: Text(amount),
                subtitle: Text(Fmt.dateTime(DateTime.parse(detail.time))),
                leading: SvgPicture.asset(
                    'packages/polkawallet_plugin_acala/assets/images/${detail.isSuccess ? isReceive ? 'assets_down' : 'assets_up' : 'tx_failed'}.svg',
                    width: 32),
                trailing: Text(
                  dic[_actionsMap[detail.action]],
                  style: Theme.of(context).textTheme.headline4,
                  textAlign: TextAlign.end,
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    EarnLiquidityDetailPage.route,
                    arguments: detail,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStakeTxs(String stableCoinSymbol) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    return Query(
      options: QueryOptions(
        document: gql(graphDexStakeQuery),
        variables: <String, String>{
          'account': widget.keyring.current.address,
        },
      ),
      builder: (
        QueryResult result, {
        Future<QueryResult> Function() refetch,
        FetchMore fetchMore,
      }) {
        if (result.data == null) {
          return Container(
            height: MediaQuery.of(context).size.height / 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CupertinoActivityIndicator()],
            ),
          );
        }
        final ls = List.of(result.data['calls']['nodes']);
        if (ls.length > 0 &&
            ls[0]['method'] != 'withdrawDexShare' &&
            ls[0]['method'] != 'depositDexShare') {
          return ListTail(isEmpty: true, isLoading: true);
        }
        final list = ls
            .map((i) => TxDexIncentiveData.fromJson(
                i as Map,
                stableCoinSymbol,
                widget.plugin.networkState.tokenSymbol,
                widget.plugin.networkState.tokenDecimals))
            .toList();

        return ListView.builder(
          itemCount: list.length + 1,
          itemBuilder: (BuildContext context, int i) {
            if (i == list.length) {
              return ListTail(isEmpty: list.length == 0, isLoading: false);
            }

            final detail = list[i];
            String amount = '';
            bool isReceive = true;
            switch (detail.action) {
              case TxDexIncentiveData.actionStake:
                amount = detail.amountShare;
                isReceive = false;
                break;
              case TxDexIncentiveData.actionUnStake:
                amount = detail.amountShare;
                break;
            }
            return Container(
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(width: 0.5, color: Colors.black12)),
              ),
              child: ListTile(
                title: Text(amount),
                subtitle: Text(Fmt.dateTime(DateTime.parse(detail.time))),
                leading: SvgPicture.asset(
                    'packages/polkawallet_plugin_acala/assets/images/${detail.isSuccess ? isReceive ? 'assets_down' : 'assets_up' : 'tx_failed'}.svg',
                    width: 32),
                trailing: Text(
                  dic[_actionsMap[detail.action]],
                  style: Theme.of(context).textTheme.headline4,
                  textAlign: TextAlign.end,
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    EarnIncentiveDetailPage.route,
                    arguments: detail,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIncentiveTxs(String stableCoinSymbol) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    return Query(
      options: QueryOptions(
        document: gql(graphEarnQuery),
        variables: <String, String>{
          'account': widget.keyring.current.address,
        },
      ),
      builder: (
        QueryResult result, {
        Future<QueryResult> Function() refetch,
        FetchMore fetchMore,
      }) {
        if (result.data == null) {
          return Container(
            height: MediaQuery.of(context).size.height / 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CupertinoActivityIndicator()],
            ),
          );
        }
        final ls = List.of(result.data['calls']['nodes']);
        if (ls.length > 0 && ls[0]['method'] != 'claimRewards') {
          return ListTail(isEmpty: true, isLoading: true);
        }
        final list = ls
            .map((i) => TxDexIncentiveData.fromJson(
                i as Map,
                stableCoinSymbol,
                widget.plugin.networkState.tokenSymbol,
                widget.plugin.networkState.tokenDecimals))
            .toList();

        return ListView.builder(
          itemCount: list.length + 1,
          itemBuilder: (BuildContext context, int i) {
            if (i == list.length) {
              return ListTail(isEmpty: list.length == 0, isLoading: false);
            }

            final detail = list[i];
            String amount = '';
            bool isReceive = true;
            switch (detail.action) {
              case TxDexIncentiveData.actionRewardIncentive:
                amount = widget.plugin.networkState.tokenSymbol[0];
                break;
              case TxDexIncentiveData.actionRewardSaving:
                final isKar = widget.plugin.basic.name == plugin_name_karura;
                amount =
                    isKar ? karura_stable_coin_view : acala_stable_coin_view;
                break;
            }
            return Container(
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(width: 0.5, color: Colors.black12)),
              ),
              child: ListTile(
                title: Text(amount),
                subtitle: Text(Fmt.dateTime(DateTime.parse(detail.time))),
                leading: SvgPicture.asset(
                    'packages/polkawallet_plugin_acala/assets/images/${detail.isSuccess ? isReceive ? 'assets_down' : 'assets_up' : 'tx_failed'}.svg',
                    width: 32),
                trailing: Text(
                  dic[_actionsMap[detail.action]],
                  style: Theme.of(context).textTheme.headline4,
                  textAlign: TextAlign.end,
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    EarnIncentiveDetailPage.route,
                    arguments: detail,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    final isKar = widget.plugin.basic.name == plugin_name_karura;
    final stableCoinSymbol = isKar ? karura_stable_coin : acala_stable_coin;
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['loan.txs']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: MainTabBar(
                tabs: [
                  dic['earn.pool'],
                  dic['earn.stake.pool'],
                  dic['earn.reward']
                ],
                activeTab: _tab,
                fontSize: 20,
                lineWidth: 6,
                onTap: (i) {
                  if (_tab != i) {
                    setState(() {
                      _tab = i;
                    });
                  }
                },
              ),
            ),
            Expanded(
              child: _tab == 0
                  ? _buildLiquidityTxs(stableCoinSymbol)
                  : _tab == 1
                      ? _buildStakeTxs(stableCoinSymbol)
                      : _buildIncentiveTxs(stableCoinSymbol),
            )
          ],
        ),
      ),
    );
  }
}
