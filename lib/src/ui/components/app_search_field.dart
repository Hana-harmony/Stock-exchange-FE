import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.onChanged,
    required this.hintText,
    this.fieldKey,
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: fieldKey,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search, color: AppColors.gray600),
          hintText: 'Search all Korean stocks',
        ).copyWith(hintText: hintText),
        onChanged: onChanged,
      ),
    );
  }
}
