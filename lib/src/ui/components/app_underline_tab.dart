import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppUnderlineTab extends StatelessWidget {
  const AppUnderlineTab({
    super.key,
    required this.label,
    required this.width,
    required this.isSelected,
    required this.onTap,
    this.height = 31,
    this.fontSize = 17,
    this.fontWeightSelected = FontWeight.w600,
    this.fontWeightUnselected = FontWeight.w400,
    this.activeColor = AppColors.gray1000,
    this.inactiveColor = AppColors.gray600,
    this.underlineWidth,
    this.underlineHeight = 2,
  });

  final String label;
  final double width;
  final bool isSelected;
  final VoidCallback onTap;
  final double height;
  final double fontSize;
  final FontWeight fontWeightSelected;
  final FontWeight fontWeightUnselected;
  final Color activeColor;
  final Color inactiveColor;
  final double? underlineWidth;
  final double underlineHeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: fontSize,
                      height: 1,
                      fontWeight: isSelected
                          ? fontWeightSelected
                          : fontWeightUnselected,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: isSelected ? (underlineWidth ?? width) : 0,
                height: underlineHeight,
                color: AppColors.orange500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
