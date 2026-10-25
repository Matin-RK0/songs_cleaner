import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
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
    }.contains(state.authStep);
    final interceptBack =
        state.busy || (state.auth == TelegramAuth.code && !state.editingPhone);
    final connectionFailed = !input && !state.busy && state.failure != null;
    final credentialFailure =
        input &&
        {
          TelegramFailure.phone,
          TelegramFailure.code,
          TelegramFailure.password,
        }.contains(state.failure);
    return PopScope(
      canPop: !interceptBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(state);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.telegramConnect),
          leading: BackButton(
            onPressed: state.busy ? null : () => _back(state),
          ),
        ),
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
                  if (!connectionFailed &&
                          state.auth == TelegramAuth.starting ||
                      state.busy && !input) ...[
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.telegramStarting, textAlign: TextAlign.center),
                  ] else if (input)
                    _TelegramAuthForm(
                      key: ValueKey((state.authStep, state.editingPhone)),
                      auth: state.authStep,
                      busy: state.busy,
                      phone: state.phone,
                      editingPhone: state.editingPhone,
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
                    if (state.auth == TelegramAuth.disconnected ||
                        connectionFailed)
                      FilledButton.icon(
                        onPressed: ref.read(telegramProvider.notifier).connect,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.telegramReconnect),
                      ),
                  ],
                  if (state.failure != null && !credentialFailure)
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
      ),
    );
  }

  void _back(TelegramState state) {
    if (state.busy) return;
    final controller = ref.read(telegramProvider.notifier);
    if (state.auth == TelegramAuth.code && !state.editingPhone) {
      controller.editPhone();
    } else {
      Navigator.of(context).pop();
    }
  }
}

class _TelegramAuthForm extends ConsumerStatefulWidget {
  const _TelegramAuthForm({
    super.key,
    required this.auth,
    required this.busy,
    required this.phone,
    required this.editingPhone,
  });
  final TelegramAuth auth;
  final bool busy;
  final String phone;
  final bool editingPhone;
  @override
  ConsumerState<_TelegramAuthForm> createState() => _TelegramAuthFormState();
}

class _TelegramAuthFormState extends ConsumerState<_TelegramAuthForm> {
  late final TextEditingController _input;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.auth == TelegramAuth.phone
        ? (widget.phone.isEmpty
              ? TelegramAuthDefaults.phoneCountryCode
              : widget.phone)
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
    if (!widget.busy && _input.text.trim().isNotEmpty) {
      ref.read(telegramProvider.notifier).submit(_input.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final password = widget.auth == TelegramAuth.password;
    final phone = widget.auth == TelegramAuth.phone;
    final theme = Theme.of(context);
    final failure = ref.watch(
      telegramProvider.select((state) => state.failure),
    );
    final fieldFailure = switch ((widget.auth, failure)) {
      (TelegramAuth.phone, TelegramFailure.phone) ||
      (TelegramAuth.code, TelegramFailure.code) ||
      (TelegramAuth.password, TelegramFailure.password) => failure,
      _ => null,
    };
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
        if (!phone && widget.phone.isNotEmpty) ...[
          Material(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.lg,
            child: Padding(
              padding: AppSpacing.allMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.phone,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (widget.auth == TelegramAuth.code)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: widget.busy
                            ? null
                            : ref.read(telegramProvider.notifier).editPhone,
                        icon: const Icon(Icons.edit_rounded),
                        label: Text(l10n.telegramEditPhone),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (widget.auth == TelegramAuth.code && widget.phone.isEmpty)
          TextButton.icon(
            onPressed: widget.busy
                ? null
                : ref.read(telegramProvider.notifier).editPhone,
            icon: const Icon(Icons.edit_rounded),
            label: Text(l10n.telegramEditPhone),
          ),
        TextField(
          controller: _input,
          autofocus: true,
          enabled: !widget.busy,
          textDirection: TextDirection.ltr,
          obscureText: password && !_showPassword,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: password
              ? TextInputType.visiblePassword
              : phone
              ? TextInputType.phone
              : TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: password
              ? [AutofillHints.password]
              : [
                  phone
                      ? AutofillHints.telephoneNumber
                      : AutofillHints.oneTimeCode,
                ],
          decoration: InputDecoration(
            errorText: fieldFailure == null
                ? null
                : telegramFailureText(context, fieldFailure),
            errorMaxLines: 3,
            suffixIcon: !password
                ? null
                : IconButton(
                    tooltip: _showPassword
                        ? l10n.telegramHidePassword
                        : l10n.telegramShowPassword,
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
            labelText: phone
                ? l10n.telegramPhone
                : password
                ? l10n.telegramPassword
                : l10n.telegramCode,
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.lg),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _input,
          builder: (context, value, _) => FilledButton(
            onPressed: widget.busy || value.text.trim().isEmpty
                ? null
                : _submit,
            child: Text(
              widget.busy
                  ? phone
                        ? l10n.telegramSendingCode
                        : password
                        ? l10n.telegramSigningIn
                        : l10n.telegramVerifyingCode
                  : phone
                  ? l10n.telegramSendCode
                  : l10n.telegramContinue,
            ),
          ),
        ),
        if (widget.editingPhone)
          TextButton(
            onPressed: widget.busy
                ? null
                : ref.read(telegramProvider.notifier).cancelPhoneEdit,
            child: Text(l10n.telegramReturnToCode),
          ),
      ],
    );
  }
}
