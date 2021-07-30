import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_acala/api/types/dexPoolInfoData.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_acala/common/constants/index.dart';
import 'package:polkawallet_plugin_acala/pages/earn/LPStakePage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/addLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/earnHistoryPage.dart';
import 'package:polkawallet_plugin_acala/pages/earn/withdrawLiquidityPage.dart';
import 'package:polkawallet_plugin_acala/pages/loan/loanCreatePage.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_acala/utils/format.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class EarnPage extends StatefulWidget {
  EarnPage(this.plugin, this.keyring);
  final PluginAcala plugin;
  final Keyring keyring;

  static const String route = '/acala/earn';

  @override
  _EarnPageState createState() => _EarnPageState();
}

class _EarnPageState extends State<EarnPage> {
  String _poolId;

  Timer _timer;

  Future<void> _fetchData() async {
    if (widget.plugin.store.earn.dexPools.length == 0) {
      await widget.plugin.service.earn.getDexPools();
    }
    final tabNow = _poolId ??
        (widget.plugin.basic.name == plugin_name_karura
            ? 'KAR-KUSD'
            : 'ACA-AUSD');
    await Future.wait([
      widget.plugin.service.earn.queryDexPoolInfo(tabNow),
      widget.plugin.service.assets
          .queryMarketPrices(PluginFmt.getAllDexTokens(widget.plugin))
    ]);

    widget.plugin.service.earn.queryDexPoolRewards(
        widget.plugin.store.earn.dexPools.firstWhere(
            (e) => e.tokens.map((t) => t['token']).join('-') == tabNow));

    if (mounted) {
      _timer = Timer(Duration(seconds: 10), () {
        _fetchData();
      });
    }
  }

  Future<void> _onStake(String action) async {
    Navigator.of(context).pushNamed(
      LPStakePage.route,
      arguments: LPStakePageParams(_poolId, action),
    );
  }

  void _onWithdrawReward(LPRewardData reward, double loyaltyBonus) {
    final symbol = widget.plugin.networkState.tokenSymbol[0];
    final incentiveReward =
        Fmt.priceFloor(reward.incentive * (1 - loyaltyBonus), lengthMax: 4);
    final savingReward =
        Fmt.priceFloor(reward.saving * (1 - loyaltyBonus), lengthMax: 2);

    // todo: fix this after new acala online
    final isTC6 = widget.plugin.basic.name == plugin_name_acala;
    final pool = jsonEncode(isTC6
        ? _poolId.split('-')
        : _poolId.split('-').map((e) => ({'Token': e})).toList());

    if (reward.saving > 0 && reward.incentive > 0) {
      final params = [
        'api.tx.incentives.claimRewards({DexIncentive: {DEXShare: $pool}})',
        'api.tx.incentives.claimRewards({DexSaving: {DEXShare: $pool}})',
      ];
      Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'utility',
            call: 'batch',
            txTitle: I18n.of(context)
                .getDic(i18n_full_dic_acala, 'acala')['earn.claim'],
            txDisplay: {
              "poolId": _poolId,
              "incentiveReward": '$incentiveReward $symbol',
              "savingReward": '$savingReward $acala_stable_coin_view',
            },
            params: [],
            rawParams: '[[${params.join(',')}]]',
          ));
    } else if (reward.incentive > 0) {
      Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'incentives',
            call: 'claimRewards',
            txTitle: I18n.of(context)
                .getDic(i18n_full_dic_acala, 'acala')['earn.claim'],
            txDisplay: {
              "poolId": _poolId,
              "incentiveReward": '$incentiveReward $symbol',
            },
            params: [],
            rawParams: '[{DexIncentive: {DEXShare: $pool}}]',
          ));
    } else if (reward.saving > 0) {
      Navigator.of(context).pushNamed(TxConfirmPage.route,
          arguments: TxConfirmParams(
            module: 'incentives',
            call: 'claimRewards',
            txTitle: I18n.of(context)
                .getDic(i18n_full_dic_acala, 'acala')['earn.claim'],
            txDisplay: {
              "poolId": _poolId,
              "savingReward": '$savingReward $acala_stable_coin_view',
            },
            params: [],
            rawParams: '[{DexSaving: {DEXShare: $pool}}]',
          ));
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();

      final isKar = widget.plugin.basic.name == plugin_name_karura;
      setState(() {
        _poolId = isKar ? 'KAR-KUSD' : 'ACA-AUSD';
      });
    });
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    final symbols = widget.plugin.networkState.tokenSymbol;
    final isKar = widget.plugin.basic.name == plugin_name_karura;

    final bool enabled = !isKar || ModalRoute.of(context).settings.arguments;
    final stableCoinSymbol = isKar ? karura_stable_coin : acala_stable_coin;
    final tabNow = _poolId ?? (isKar ? 'KAR-KUSD' : 'ACA-AUSD');
    final pair = tabNow.split('-');
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['earn.title']),
        centerTitle: true,
        actions: [
          isKar
              ? IconButton(
                  icon: Icon(Icons.history, color: Theme.of(context).cardColor),
                  onPressed: enabled
                      ? () => Navigator.of(context)
                          .pushNamed(EarnHistoryPage.route, arguments: tabNow)
                      : null,
                )
              : Container()
        ],
      ),
      body: Observer(
        builder: (_) {
          final balancePair = PluginFmt.getBalancePair(widget.plugin, pair);

          BigInt issuance = BigInt.zero;
          BigInt shareTotal = BigInt.zero;
          BigInt share = BigInt.zero;
          double stakeShare = 0;
          double poolShare = 0;

          String lpAmountString = '~';

          final poolInfo = widget.plugin.store.earn.dexPoolInfoMap[tabNow];
          if (poolInfo != null) {
            issuance = poolInfo.issuance;
            shareTotal = poolInfo.sharesTotal;
            share = poolInfo.shares;
            stakeShare = share / shareTotal;
            poolShare = share / issuance;

            final lpAmount = Fmt.bigIntToDouble(
                    poolInfo.amountLeft, balancePair[0].decimals) *
                poolShare;
            final lpAmount2 = Fmt.bigIntToDouble(
                    poolInfo.amountRight, balancePair[1].decimals) *
                poolShare;
            lpAmountString =
                '${Fmt.priceFloor(lpAmount)} ${PluginFmt.tokenView(pair[0])} + ${Fmt.priceFloor(lpAmount2, lengthFixed: 4)} ${PluginFmt.tokenView(pair[1])}';
          }

          final loyaltyBonus = widget.plugin.store.earn.loyaltyBonus[tabNow];

          final balance = Fmt.balanceInt(widget.plugin.store.assets
                  .tokenBalanceMap[tabNow.toUpperCase()]?.amount ??
              '0');

          Color cardColor = Theme.of(context).cardColor;
          Color primaryColor = Theme.of(context).primaryColor;

          return SafeArea(
            child: Column(
              children: <Widget>[
                CurrencySelector(
                  token: tabNow,
                  tokenOptions: widget.plugin.store.earn.dexPools
                      .map((e) => e.tokens.map((e) => e['token']).join('-'))
                      .toList(),
                  tokenIcons: widget.plugin.tokenIcons,
                  onSelect: (res) {
                    setState(() {
                      _poolId = res;
                    });
                    _fetchData();
                  },
                ),
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      _SystemCard(
                        token: tabNow,
                        total: poolInfo?.sharesTotal ?? BigInt.zero,
                        userStaked: poolInfo?.shares ?? BigInt.zero,
                        decimals: balancePair[0].decimals,
                        lpAmountString: lpAmountString,
                        actions: Row(
                          children: [
                            Expanded(
                              child: RoundedButton(
                                color: isKar ? Colors.redAccent : Colors.blue,
                                text: dic['earn.stake'],
                                onPressed: enabled && balance > BigInt.zero
                                    ? () => _onStake(LPStakePage.actionStake)
                                    : null,
                              ),
                            ),
                            (poolInfo?.shares ?? BigInt.zero) > BigInt.zero
                                ? Container(width: 16)
                                : Container(),
                            (poolInfo?.shares ?? BigInt.zero) > BigInt.zero
                                ? Expanded(
                                    child: RoundedButton(
                                      text: dic['earn.unStake'],
                                      onPressed: () =>
                                          _onStake(LPStakePage.actionUnStake),
                                    ),
                                  )
                                : Container()
                          ],
                        ),
                      ),
                      _UserCard(
                        share: stakeShare,
                        poolInfo: poolInfo,
                        token: tabNow,
                        rewardAPY:
                            widget.plugin.store.earn.swapPoolRewards[tabNow] ??
                                0,
                        rewardSavingAPY: widget.plugin.store.earn
                                .swapPoolSavingRewards[tabNow] ??
                            0,
                        loyaltyBonus: loyaltyBonus,
                        fee: widget.plugin.service.earn.getSwapFee(),
                        onWithdrawReward: () =>
                            _onWithdrawReward(poolInfo.reward, loyaltyBonus),
                        incentiveCoinSymbol: symbols[0],
                        stableCoinSymbol: stableCoinSymbol,
                        stableCoinDecimal: widget.plugin.networkState
                            .tokenDecimals[symbols.indexOf(stableCoinSymbol)],
                      )
                    ],
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        color: !enabled
                            ? Colors.black26
                            : isKar
                                ? Colors.redAccent
                                : Colors.blue,
                        child: TextButton(
                            child: Text(
                              dic['earn.add'],
                              style: TextStyle(color: cardColor),
                            ),
                            onPressed: enabled
                                ? () {
                                    Navigator.of(context).pushNamed(
                                      AddLiquidityPage.route,
                                      arguments: tabNow,
                                    );
                                  }
                                : null),
                      ),
                    ),
                    balance > BigInt.zero
                        ? Expanded(
                            child: Container(
                              color: primaryColor,
                              child: TextButton(
                                child: Text(
                                  dic['earn.remove'],
                                  style: TextStyle(color: cardColor),
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pushNamed(
                                  WithdrawLiquidityPage.route,
                                  arguments: tabNow,
                                ),
                              ),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SystemCard extends StatelessWidget {
  _SystemCard({
    this.token,
    this.total,
    this.userStaked,
    this.decimals,
    this.lpAmountString,
    this.actions,
  });
  final String token;
  final BigInt total;
  final BigInt userStaked;
  final int decimals;
  final String lpAmountString;
  final Widget actions;
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    final primary = Theme.of(context).primaryColor;
    final TextStyle primaryText = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: primary,
      letterSpacing: -0.8,
    );
    return RoundedCard(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Column(
            children: <Widget>[
              Text('${dic['earn.staked']} ${PluginFmt.tokenView(token)}'),
              Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                    Fmt.priceFloorBigInt(userStaked, decimals, lengthFixed: 4),
                    style: primaryText),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              '≈ $lpAmountString',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Row(
            children: <Widget>[
              InfoItem(
                crossAxisAlignment: CrossAxisAlignment.center,
                title: dic['earn.stake.pool'],
                content: Fmt.priceFloorBigInt(total, decimals, lengthFixed: 4),
              ),
              InfoItem(
                crossAxisAlignment: CrossAxisAlignment.center,
                title: dic['earn.share'],
                content:
                    Fmt.ratio(total > BigInt.zero ? userStaked / total : 0),
              ),
            ],
          ),
          Divider(height: 24),
          actions
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  _UserCard({
    this.share,
    this.poolInfo,
    this.token,
    this.rewardAPY,
    this.rewardSavingAPY,
    this.loyaltyBonus,
    this.fee,
    this.onWithdrawReward,
    this.incentiveCoinSymbol,
    this.stableCoinSymbol,
    this.stableCoinDecimal,
  });
  final double share;
  final DexPoolInfoData poolInfo;
  final String token;
  final double rewardAPY;
  final double rewardSavingAPY;
  final double loyaltyBonus;
  final double fee;
  final Function onWithdrawReward;
  final String incentiveCoinSymbol;
  final String stableCoinSymbol;
  final int stableCoinDecimal;

  Future<void> _onClaim(BuildContext context) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(dic['earn.claim']),
          content: Text(dic['earn.claim.info']),
          actions: <Widget>[
            CupertinoButton(
              child: Text(I18n.of(context)
                  .getDic(i18n_full_dic_acala, 'common')['cancel']),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoButton(
              child: Text(
                  I18n.of(context).getDic(i18n_full_dic_acala, 'common')['ok']),
              onPressed: () {
                Navigator.of(context).pop();
                onWithdrawReward();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    var reward = (poolInfo?.reward?.incentive ?? 0) * (1 - loyaltyBonus);
    var rewardSaving = (poolInfo?.reward?.saving ?? 0) * (1 - loyaltyBonus);
    if (reward < 0) {
      reward = 0;
    }
    if (rewardSaving < 0) {
      rewardSaving = 0;
    }

    final Color primary = Theme.of(context).primaryColor;
    final TextStyle primaryText = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: primary,
      letterSpacing: -0.8,
    );

    final savingRewardTokenMin = Fmt.balanceDouble(
        existential_deposit[stableCoinSymbol], stableCoinDecimal);
    final canClaim = reward > 0.0001 || rewardSaving > savingRewardTokenMin;

    return RoundedCard(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: EdgeInsets.all(16),
      child: Stack(
        alignment: AlignmentDirectional.topEnd,
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(dic['earn.reward']),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Text(
                        '${dic['earn.incentive']} ($incentiveCoinSymbol)',
                        style: TextStyle(fontSize: 12),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(Fmt.priceFloor(reward, lengthMax: 4),
                            style: primaryText),
                      ),
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Text(
                        '${dic['earn.saving']} ($stableCoinSymbol)',
                        style: TextStyle(fontSize: 12),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(Fmt.priceFloor(rewardSaving, lengthMax: 2),
                            style: primaryText),
                      ),
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Text(dic['loan.apy'], style: TextStyle(fontSize: 12)),
                      Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(Fmt.ratio(rewardAPY + rewardSavingAPY),
                            style: primaryText),
                      ),
                    ],
                  )
                ],
              ),
              Container(
                margin: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    InfoItem(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      title: dic['earn.fee'],
                      content: Fmt.ratio(fee),
                      titleToolTip: dic['earn.fee.info'],
                    ),
                    InfoItem(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      title: dic['earn.loyal'],
                      content: Fmt.ratio(loyaltyBonus),
                      titleToolTip: dic['earn.loyal.info'],
                    )
                  ],
                ),
              ),
              canClaim
                  ? Container(
                      margin: EdgeInsets.only(top: 16),
                      child: RoundedButton(
                          text: dic['earn.claim'],
                          onPressed: () => _onClaim(context)),
                    )
                  : Container(),
            ],
          ),
        ],
      ),
    );
  }
}
