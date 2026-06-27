import 'package:flutter/material.dart';

abstract final class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const gray1000 = Color(0xFF0F1112);
  static const gray700 = Color(0xFF3C3D41);
  static const gray600 = Color(0xFF909499);
  static const gray300 = Color(0xFFDDDDDD);
  static const gray200 = Color(0xFFE9EAEA);
  static const orange500 = Color(0xFFFF791B);
}

abstract final class AppRadii {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
}

abstract final class AppInsets {
  static const screen = EdgeInsets.fromLTRB(16, 16, 16, 24);
}

abstract final class AppShadows {
  static const navigation = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.02),
      blurRadius: 20,
      offset: Offset(0, -4),
    ),
  ];
}
