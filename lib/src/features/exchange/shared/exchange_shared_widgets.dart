part of '../exchange_pages.dart';

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
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
  const _SearchResultAvatar();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(34),
      painter: _SearchResultAvatarPainter(),
    );
  }
}

class _SearchResultAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final circleRect = Offset.zero & size;
    final clipPath = Path()..addOval(circleRect);
    canvas.save();
    canvas.clipPath(clipPath);

    final backgroundPaint = Paint()
      ..color = AppColors.gray200.withValues(alpha: 0.45);
    canvas.drawOval(circleRect, backgroundPaint);

    final dotPaint = Paint()..color = AppColors.gray300.withValues(alpha: 0.9);
    const spacing = 4.0;
    const radius = 0.9;
    for (var x = 1.5; x < size.width; x += spacing) {
      for (var y = 1.5; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
