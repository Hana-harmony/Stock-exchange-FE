part of '../exchange_pages.dart';

const _compactHeaderPadding = EdgeInsets.fromLTRB(12, 4, 12, 4);
const _bottomSheetOuterPadding = EdgeInsets.fromLTRB(12, 0, 12, 12);
const _bottomSheetContentPadding = EdgeInsets.fromLTRB(20, 18, 20, 20);
const _primaryActionPadding = EdgeInsets.symmetric(vertical: 16);
const _secondaryActionPadding = EdgeInsets.symmetric(vertical: 14);
const _bottomSheetRadius = 20.0;

ButtonStyle _exchangePrimaryButtonStyle({
  required Color backgroundColor,
  EdgeInsetsGeometry padding = _primaryActionPadding,
  double radius = 12,
}) {
  return FilledButton.styleFrom(
    backgroundColor: backgroundColor,
    foregroundColor: AppColors.white,
    padding: padding,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
