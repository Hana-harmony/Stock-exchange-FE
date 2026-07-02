part of '../exchange_pages.dart';

class ShellPlaceholderScreen extends StatelessWidget {
  const ShellPlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppInsets.compactScreen,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        _MutedInfoCard(
          title: '$title tab',
          body: description,
        ),
        if (actionLabel != null && onActionTap != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: ValueKey<String>('shell-placeholder-action-$title'),
              onPressed: onActionTap,
              style: _exchangePrimaryButtonStyle(
                backgroundColor: AppColors.orange500,
              ),
              child: Text(actionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
