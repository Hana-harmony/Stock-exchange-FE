part of '../exchange_pages.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({
    super.key,
    required this.sessionController,
    required this.accountController,
    required this.tradeController,
    required this.watchlistController,
    required this.onSignedOut,
  });

  final ExchangeSessionController sessionController;
  final AccountController accountController;
  final TradeController tradeController;
  final WatchlistController watchlistController;
  final VoidCallback onSignedOut;

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.sessionController,
        widget.accountController,
        widget.tradeController,
        widget.watchlistController,
      ]),
      builder: (context, _) {
        final session = widget.sessionController.session;
        final account = widget.accountController.value.account;
        final portfolio = widget.tradeController.value.portfolio;
        final watchlist = widget.watchlistController.value.watchlist;
        final sessionState = widget.sessionController.value;

        return ListView(
          key: const ValueKey('my-screen'),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          children: [
            Text(
              'MY',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray1000,
                  ),
            ),
            const SizedBox(height: 16),
            if (session == null)
              _MySignInCard(
                usernameController: _usernameController,
                passwordController: _passwordController,
                isLoading: sessionState.status == ExchangeSessionStatus.loading,
                errorMessage: sessionState.errorMessage,
                onSignIn: _signIn,
                onCreateAccount: _createAccount,
              )
            else ...[
              _MyInfoCard(
                title: 'Profile',
                rows: [
                  _MyInfoRow(label: 'Username', value: session.username),
                  _MyInfoRow(label: 'Account', value: session.accountId),
                ],
              ),
              const SizedBox(height: 12),
              _MyInfoCard(
                title: 'Account',
                rows: [
                  _MyInfoRow(
                    label: 'Cash',
                    value: account?.cashDisplay ?? 'Loading',
                  ),
                  _MyInfoRow(
                    label: 'Total assets',
                    value: portfolio?.totalAssetValueDisplay ?? 'Loading',
                  ),
                  _MyInfoRow(
                    label: 'Watchlist',
                    value: '${watchlist?.itemCount ?? 0} stocks',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton(
                  key: const ValueKey('my-logout-button'),
                  onPressed: widget.sessionController.value.status ==
                          ExchangeSessionStatus.loading
                      ? null
                      : () => _logout(context),
                  style: _exchangePrimaryButtonStyle(
                    backgroundColor: AppColors.gray1000,
                    radius: 8,
                  ),
                  child: const Text('Log out'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _signIn() async {
    await widget.sessionController.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _createAccount() async {
    await widget.sessionController.signUpAndLogin(
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _logout(BuildContext context) async {
    await widget.sessionController.signOut();
    widget.accountController.clear();
    widget.tradeController.clear();
    widget.watchlistController.clear();
    widget.onSignedOut();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Logged out.')),
      );
  }
}

class _MySignInCard extends StatelessWidget {
  const _MySignInCard({
    required this.usernameController,
    required this.passwordController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSignIn,
    required this.onCreateAccount,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onSignIn;
  final Future<void> Function() onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign in',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray1000,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use your exchange account to access assets, portfolio, and watchlists.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray600,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('my-login-username'),
              controller: usernameController,
              enabled: !isLoading,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: 30,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                labelText: 'Username',
                helperText: '4-30 letters, numbers, or underscores',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('my-login-password'),
              controller: passwordController,
              enabled: !isLoading,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) {
                if (!isLoading) {
                  unawaited(onSignIn());
                }
              },
              decoration: const InputDecoration(
                labelText: 'Password',
                helperText: '8-72 characters',
                border: OutlineInputBorder(),
              ),
            ),
            if (errorMessage != null && errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                key: const ValueKey('my-login-error'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.red500,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: const ValueKey('my-login-submit'),
                onPressed: isLoading ? null : () => unawaited(onSignIn()),
                style: _exchangePrimaryButtonStyle(
                  backgroundColor: AppColors.orange500,
                  radius: 8,
                ),
                child: Text(isLoading ? 'Signing in' : 'Sign in'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                key: const ValueKey('my-create-account-submit'),
                onPressed:
                    isLoading ? null : () => unawaited(onCreateAccount()),
                child: const Text('Create account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyInfoCard extends StatelessWidget {
  const _MyInfoCard({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_MyInfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray1000,
                  ),
            ),
            const SizedBox(height: 12),
            for (final row in rows) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray600,
                          ),
                    ),
                  ),
                  Text(
                    row.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.gray1000,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              if (row != rows.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _MyInfoRow {
  const _MyInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
