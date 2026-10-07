import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/station_submission.dart';
import '../../domain/errors/station_submission_failure.dart';
import '../../providers.dart';

class MyStationSubmissionsPage extends ConsumerStatefulWidget {
  const MyStationSubmissionsPage({super.key});

  @override
  ConsumerState<MyStationSubmissionsPage> createState() =>
      _MyStationSubmissionsPageState();
}

class _MyStationSubmissionsPageState
    extends ConsumerState<MyStationSubmissionsPage> {
  late Future<List<StationSubmission>> _submissions;

  @override
  void initState() {
    super.initState();
    _submissions = _loadSubmissions();
  }

  Future<List<StationSubmission>> _loadSubmissions() {
    return ref.read(stationSubmissionRepositoryProvider).getMySubmissions();
  }

  void _retry() {
    setState(() => _submissions = _loadSubmissions());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Submissions'),
        actions: [
          IconButton(
            tooltip: 'Refresh submissions',
            onPressed: _retry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<StationSubmission>>(
        future: _submissions,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is StationSubmissionFailure
                ? error.message
                : 'Could not load your submissions. Please try again.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final submissions = snapshot.data ?? const [];
          if (submissions.isEmpty) {
            return Center(
              child: Text(
                'You have no station submissions yet.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final submission = submissions[index];
              return Card(
                color: scheme.surfaceContainer,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              submission.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          _SubmissionStatus(status: submission.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        submission.address?.isNotEmpty == true
                            ? submission.address!
                            : '${submission.latitude.toStringAsFixed(5)}, '
                                  '${submission.longitude.toStringAsFixed(5)}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Submitted ${submission.createdAt.toLocal()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (submission.adminNotes?.isNotEmpty == true) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Review notes: ${submission.adminNotes}',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SubmissionStatus extends StatelessWidget {
  const _SubmissionStatus({required this.status});

  final StationSubmissionStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      StationSubmissionStatus.pending => ('Pending', scheme.tertiary),
      StationSubmissionStatus.approved => ('Approved', Colors.green),
      StationSubmissionStatus.rejected => ('Rejected', scheme.error),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
