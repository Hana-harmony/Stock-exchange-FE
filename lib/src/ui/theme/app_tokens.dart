import 'package:flutter/material.dart';

abstract final class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF7F7F5);
  static const surface = Color(0xFFF1F3F5);
  static const gray50 = Color(0xFFF5F6F6);
  static const gray100 = Color(0xFFF1F2F3);
  static const green100 = Color(0xFFE8F7ED);
  static const red100 = Color(0xFFFFF0F0);
  static const orange100 = Color(0xFFFFF4EC);
  static const gray1000 = Color(0xFF0F1112);
  static const gray900 = Color(0xFF1D1F21);
  static const gray800 = Color(0xFF27292B);
  static const gray700 = Color(0xFF3C3D41);
  static const gray600 = Color(0xFF909499);
  static const gray400 = Color(0xFFA0A1A3);
  static const gray500 = Color(0xFFB0B4B8);
  static const gray300 = Color(0xFFDDDDDD);
  static const gray200 = Color(0xFFE9EAEA);
  static const green500 = Color(0xFF00AB6B);
  static const red500 = Color(0xFFFF1550);
  static const blue500 = Color(0xFF377DFF);
  static const orange300 = Color(0xFFFFAD77);
  static const orange500 = Color(0xFFFF791B);
}

abstract final class AppRadii {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
}

abstract final class AppInsets {
  static const screen = EdgeInsets.fromLTRB(16, 16, 16, 24);
  static const compactScreen = EdgeInsets.fromLTRB(20, 12, 20, 24);
}

abstract final class AppShadows {
  static const navigation = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.02),
      blurRadius: 20,
      offset: Offset(0, -4),
    ),
  ];

  static const card = [
    BoxShadow(
      color: Color.fromRGBO(15, 17, 18, 0.05),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];
}
