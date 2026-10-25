import 'package:flutter/material.dart';
import '../../../../core/extensions/context_l10n.dart';
import '../widgets/telegram_download_sheet.dart';

class TelegramDownloadsScreen extends StatelessWidget {
  const TelegramDownloadsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.telegramDownloads)),
    body: const SafeArea(top: false, child: TelegramDownloadsView(fill: true)),
  );
}
