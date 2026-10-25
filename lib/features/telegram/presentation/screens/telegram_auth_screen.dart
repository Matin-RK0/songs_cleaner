import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/telegram_controller.dart';
import '../../domain/telegram_models.dart';
import '../../domain/telegram_auth_defaults.dart';
import '../widgets/telegram_feedback.dart';

class TelegramAuthScreen extends ConsumerStatefulWidget {
  const TelegramAuthScreen({super.key});
  @override
  ConsumerState<TelegramAuthScreen> createState() => _TelegramAuthScreenState();
}

class _TelegramAuthScreenState extends ConsumerState<TelegramAuthScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(telegramProvider.notifier).connect());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(telegramProvider.select((e) => e.auth), (_, next) {
      if (next == TelegramAuth.ready && mounted) Navigator.of(context).pop();
    });
    final state = ref.watch(telegramProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final input = {
      TelegramAuth.phone,
      TelegramAuth.code,
      TelegramAuth.password,
    }.contains(state.auth);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.telegramConnect)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.contentMaxWidth,
            ),
            child: ListView(
              padding: AppSpacing.allLg,
              children: [
                Icon(
                  Icons.telegram_rounded,
                  size: AppSpacing.iconHero,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.auth == TelegramAuth.starting ||
                    state.busy && !input) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.telegramStarting, textAlign: TextAlign.center),
                ] else if (input)
                  _TelegramAuthForm(
                    key: ValueKey(state.auth),
                    auth: state.auth,
                    busy: state.busy,
                  )
                else ...[
                  Text(
                    switch (state.auth) {
                      TelegramAuth.unconfigured => l10n.telegramSetup,
                      TelegramAuth.unsupported => l10n.telegramUnsupported,
                      TelegramAuth.other => l10n.telegramOtherAuth,
                      _ => l10n.telegramConnect,
                    },
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (state.auth == TelegramAuth.unconfigured)
                    Text(l10n.telegramSetupHint),
                  if (state.auth == TelegramAuth.disconnected)
                    FilledButton.icon(
                      onPressed: ref.read(telegramProvider.notifier).connect,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.telegramReconnect),
                    ),
                ],
                if (state.failure != null)
                  TelegramErrorBanner(failure: state.failure!),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.telegramPrivacy,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TelegramAuthForm extends ConsumerStatefulWidget {
  const _TelegramAuthForm({super.key, required this.auth, required this.busy});
  final TelegramAuth auth;
  final bool busy;
  @override
  ConsumerState<_TelegramAuthForm> createState() => _TelegramAuthFormState();
}

class _TelegramAuthFormState extends ConsumerState<_TelegramAuthForm> {
  late final TextEditingController _input;

  @override
  void initState() {
    super.initState();
    final initial = widget.auth == TelegramAuth.phone
        ? TelegramAuthDefaults.phoneCountryCode
        : '';
    _input = TextEditingController.fromValue(
      TextEditingValue(
        text: initial,
        selection: TextSelection.collapsed(offset: initial.length),
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.busy) ref.read(telegramProvider.notifier).submit(_input.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final password = widget.auth == TelegramAuth.password;
    final phone = widget.auth == TelegramAuth.phone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          phone
              ? l10n.telegramPhone
              : password
              ? l10n.telegramPassword
              : l10n.telegramCode,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          phone
              ? l10n.telegramPhoneHint
              : password
              ? l10n.telegramPasswordHint
              : l10n.telegramCodeHint,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _input,
          autofocus: true,
          enabled: !widget.busy,
          textDirection: TextDirection.ltr,
          obscureText: password,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: password
              ? TextInputType.visiblePassword
              : phone
              ? TextInputType.phone
              : TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: password
              ? null
              : [
                  phone
                      ? AutofillHints.telephoneNumber
                      : AutofillHints.oneTimeCode,
                ],
          decoration: InputDecoration(
            labelText: phone
                ? l10n.telegramPhone
                : password
                ? l10n.telegramPassword
                : l10n.telegramCode,
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: widget.busy ? null : _submit,
          child: Text(
            widget.busy ? l10n.telegramStarting : l10n.telegramContinue,
          ),
        ),
      ],
    );
  }
}
