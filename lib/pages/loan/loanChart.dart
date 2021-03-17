import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/api/types/loanType.dart';
import 'package:polkawallet_plugin_acala/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/format.dart';

class LoanChart extends StatelessWidget {
  LoanChart(this.loan);
  final LoanData loan;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_acala, 'acala');
    double requiredCollateralRatio =
        double.parse(Fmt.token(loan.type.requiredCollateralRatio, 18));
    double liquidationRatio =
        double.parse(Fmt.token(loan.type.liquidationRatio, 18));

    const double heightTotal = 160;
    final double widthChart = MediaQuery.of(context).size.width / 4;
    double heightBorrowed = 0;
    double heightRequired = 0;
    double heightLiquidation = 0;
    double heightBorrowedAdjusted = 0;
    double heightRequiredAdjusted = 0;
    double heightLiquidationAdjusted = 0;
    if (loan.debitInUSD > BigInt.zero) {
      heightBorrowed = heightTotal * (loan.debitInUSD / loan.collateralInUSD);
      heightRequired = heightTotal / requiredCollateralRatio;
      heightLiquidation = heightTotal / liquidationRatio;

      heightBorrowedAdjusted = heightBorrowed;
      heightRequiredAdjusted = heightRequired;
      heightLiquidationAdjusted = heightLiquidation;

      if (heightTotal - heightLiquidationAdjusted < 20) {
        heightLiquidationAdjusted = heightTotal - 20;
      }
      if (heightLiquidationAdjusted - heightRequiredAdjusted < 20) {
        heightRequiredAdjusted = heightLiquidationAdjusted - 20;
      }
      if (heightRequiredAdjusted - heightBorrowedAdjusted < 20) {
        heightBorrowedAdjusted = heightRequiredAdjusted - 24;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: EdgeInsets.fromLTRB(24, 8, 0, 8),
          child: _ChartContainer(
            heightBorrowedAdjusted,
            heightRequiredAdjusted,
            heightLiquidationAdjusted,
            collateral: Text('100%'),
            debits: Text(
              loan.collateralRatio < 10
                  ? Fmt.ratio(loan.collateralRatio)
                  : '1000+%',
              style: TextStyle(color: Colors.orange),
            ),
            liquidation: Text(
              Fmt.ratio(liquidationRatio),
              style: TextStyle(color: Colors.red),
            ),
            required: Text(
              Fmt.ratio(requiredCollateralRatio),
              style: TextStyle(color: Colors.blue),
            ),
            alignment: AlignmentDirectional.bottomEnd,
          ),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(8, 8, 8, 8),
          padding: EdgeInsets.only(top: 8, right: 8),
          width: widthChart,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Theme.of(context).unselectedWidgetColor),
              bottom:
                  BorderSide(color: Theme.of(context).unselectedWidgetColor),
            ),
          ),
          child: _ChartContainer(
            heightBorrowed,
            heightRequired,
            heightLiquidation,
            liquidation: Divider(color: Colors.red, height: 2, thickness: 2),
            required: Divider(color: Colors.blue, height: 2, thickness: 2),
          ),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(0, 0, 24, 8),
          child: _ChartContainer(
            heightBorrowedAdjusted,
            heightRequiredAdjusted,
            heightLiquidationAdjusted,
            collateral: Text(dic['loan.collateral']),
//              debits: Text(
//                dic['liquid.ratio.current'],
//                style: TextStyle(color: Colors.orange),
//              ),
            liquidation: Text(
              dic['liquid.ratio'],
              style: TextStyle(color: Colors.red),
            ),
            required: Text(
              dic['liquid.ratio.require'],
              style: TextStyle(color: Colors.blue),
            ),
            debits: Text(
              dic['liquid.ratio.current'],
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartContainer extends StatelessWidget {
  _ChartContainer(
    this.heightBorrowed,
    this.heightRequired,
    this.heightLiquidation, {
    this.collateral,
    this.debits,
    this.required,
    this.liquidation,
    this.alignment,
  });

  final double heightBorrowed;
  final double heightRequired;
  final double heightLiquidation;
  final Widget collateral;
  final Widget debits;
  final Widget required;
  final Widget liquidation;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: alignment ?? AlignmentDirectional.bottomStart,
      children: <Widget>[
        // collateral amount
        Container(
          height: 160,

          decoration: collateral == null
              ? BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: Theme.of(context).dividerColor, width: 2),
                    right: BorderSide(
                        color: Theme.of(context).dividerColor, width: 2),
                  ),
                )
              : null,
//          color: collateral == null
//              ? Theme.of(context).dividerColor
//              : Colors.transparent,
          child: collateral,
        ),
        // borrowed amount
        Container(
          height: heightBorrowed > 30 ? heightBorrowed : 30,
          color: debits == null ? Colors.orangeAccent : Colors.transparent,
          child: debits,
        ),
        // the liquidation line
        Container(
          height: heightLiquidation,
          alignment: Alignment.topLeft,
          child: liquidation,
        ),
        // the required line
        Container(
          height: heightRequired,
          alignment: Alignment.topLeft,
          child: required,
        ),
      ],
    );
  }
}
