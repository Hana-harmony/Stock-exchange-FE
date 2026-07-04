part of '../exchange_pages.dart';

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.inactiveAssetPath = AppAssets.favoriteIcon,
  });

  final bool isFavorite;
  final VoidCallback onTap;
  final String inactiveAssetPath;

  @override
  Widget build(BuildContext context) {
    return _AnimatedFavoriteIconButton(
      isFavorite: isFavorite,
      activeAssetPath: AppAssets.favoriteIconActive,
      inactiveAssetPath: inactiveAssetPath,
      onTap: onTap,
    );
  }
}

class _AnimatedFavoriteIconButton extends StatefulWidget {
  const _AnimatedFavoriteIconButton({
    required this.isFavorite,
    required this.activeAssetPath,
    required this.inactiveAssetPath,
    required this.onTap,
  });

  final bool isFavorite;
  final String activeAssetPath;
  final String inactiveAssetPath;
  final VoidCallback onTap;

  @override
  State<_AnimatedFavoriteIconButton> createState() =>
      _AnimatedFavoriteIconButtonState();
}

class _AnimatedFavoriteIconButtonState
    extends State<_AnimatedFavoriteIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.16,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.16,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _AnimatedFavoriteIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _controller
        ..stop()
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetPath =
        widget.isFavorite ? widget.activeAssetPath : widget.inactiveAssetPath;
    const iconSize = 24.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale:
                          Tween<double>(begin: 0.92, end: 1).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  assetPath,
                  key: ValueKey<String>(assetPath),
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultAvatar extends StatelessWidget {
  const _SearchResultAvatar({
    this.stockCode = '',
    this.stockName = '',
    this.logoUrl = '',
  });

  final String stockCode;
  final String stockName;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedLogoUrl = logoUrl.trim();
    if (normalizedLogoUrl.isNotEmpty) {
      return Semantics(
        label: stockName.isEmpty ? 'Stock logo' : '$stockName logo',
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.08),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            normalizedLogoUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              return loadingProgress == null ? child : _fallbackAvatar(context);
            },
            errorBuilder: (context, error, stackTrace) {
              return _fallbackAvatar(context);
            },
          ),
        ),
      );
    }
    return _fallbackAvatar(context);
  }

  Widget _fallbackAvatar(BuildContext context) {
    final color = _stockLogoColor(stockCode, stockName);
    final label = _stockLogoLabel(stockCode, stockName);
    return Semantics(
      label: stockName.isEmpty ? 'Stock logo' : '$stockName logo',
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              Color.lerp(color, AppColors.gray1000, 0.28)!,
            ],
          ),
          border: Border.all(color: AppColors.white, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: SizedBox.square(
          dimension: 34,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.white,
                    fontSize: label.length > 2 ? 10 : 11,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

String _stockLogoLabel(String stockCode, String stockName) {
  final normalizedName = stockName.trim();
  if (normalizedName.isNotEmpty) {
    final tokens = normalizedName
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .split(RegExp(r'[\s._-]+'))
        .map((token) => token.trim())
        .where((token) => RegExp(r'^[A-Za-z0-9]+$').hasMatch(token))
        .toList(growable: false);
    if (tokens.length >= 2) {
      return tokens.take(2).map((token) => token[0]).join().toUpperCase();
    }
    if (tokens.isNotEmpty) {
      final token = tokens.first;
      return token.substring(0, token.length >= 2 ? 2 : 1).toUpperCase();
    }
  }
  final digits = stockCode.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 2 ? digits.substring(digits.length - 2) : 'KR';
}

Color _stockLogoColor(String stockCode, String stockName) {
  const palette = [
    Color(0xFF006C67),
    Color(0xFF2E6BFF),
    Color(0xFF7A4DFF),
    Color(0xFFD63C6B),
    Color(0xFF008C45),
    Color(0xFFB45F06),
    Color(0xFF0F766E),
    Color(0xFF4D7C0F),
  ];
  final source = '$stockCode$stockName';
  final seed = source.codeUnits.fold<int>(0, (sum, value) => sum + value);
  return palette[seed % palette.length];
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MutedInfoCard extends StatelessWidget {
  const _MutedInfoCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showComingSoonDialog(
  BuildContext context, {
  required String featureName,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        key: ValueKey('coming-soon-dialog-$featureName'),
        title: const Text('Coming soon'),
        content: Text('$featureName is being prepared.'),
        actions: [
          TextButton(
            key: const ValueKey('coming-soon-confirm'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: AppColors.red500),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search error',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketBadge extends StatelessWidget {
  const _MarketBadge({
    required this.assetPath,
  });

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: 28,
      height: 21,
      fit: BoxFit.contain,
    );
  }
}
