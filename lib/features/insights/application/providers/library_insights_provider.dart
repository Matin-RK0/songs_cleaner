import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/application/providers/library_providers.dart';
import '../../domain/entities/library_insights.dart';
import '../../domain/services/library_insights_analyzer.dart';

final libraryInsightsProvider = Provider<LibraryInsights>(
  (ref) => LibraryInsightsAnalyzer.analyze(ref.watch(allSongsProvider)),
);
