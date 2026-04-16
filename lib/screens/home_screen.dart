import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/timer_provider.dart';
import '../services/hive_service.dart';
import '../services/calculation_service.dart';
import '../widgets/timer_display.dart';
import 'history_screen.dart';
import 'report_screen.dart';

/// Main screen: shows the active timer, controls, and today's summary.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Tracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Monthly Report',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
          ),
        ],
      ),
      body: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timer, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timer display card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 48, horizontal: 24),
                  child: TimerDisplay(
                    elapsed: timer.elapsed,
                    state: timer.state,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Primary action button
              _PrimaryButton(state: timer.state),
              const SizedBox(height: 12),
              // Stop button (only visible when a session is active)
              if (timer.state != TimerState.stopped)
                const _StopButton(),
              const SizedBox(height: 40),
              // Today's summary
              const _DailySummary(),
            ],
          ),
        );
      },
    );
  }
}

/// Primary action button that changes label/action based on timer state.
class _PrimaryButton extends StatelessWidget {
  final TimerState state;

  const _PrimaryButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final timer = context.read<TimerProvider>();

    String label;
    IconData icon;
    VoidCallback onPressed;

    switch (state) {
      case TimerState.stopped:
        label = 'Start Session';
        icon = Icons.play_arrow_rounded;
        onPressed = timer.startSession;
        break;
      case TimerState.working:
        label = 'Take a Break';
        icon = Icons.pause_rounded;
        onPressed = timer.pauseSession;
        break;
      case TimerState.onBreak:
        label = 'Resume Work';
        icon = Icons.play_arrow_rounded;
        onPressed = timer.resumeSession;
        break;
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Stop button shown only when a session is active.
class _StopButton extends StatelessWidget {
  const _StopButton();

  @override
  Widget build(BuildContext context) {
    final timer = context.read<TimerProvider>();
    return OutlinedButton.icon(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Stop Session'),
            content: const Text('Are you sure you want to stop this session?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Stop'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await timer.stopSession();
        }
      },
      icon: const Icon(Icons.stop_rounded, size: 22),
      label: const Text('Stop Session', style: TextStyle(fontSize: 16)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        foregroundColor: Theme.of(context).colorScheme.error,
        side: BorderSide(color: Theme.of(context).colorScheme.error),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Summary card showing today's totals.
class _DailySummary extends StatelessWidget {
  const _DailySummary();

  @override
  Widget build(BuildContext context) {
    // Rebuild whenever timer ticks (via Consumer in parent) or sessions change
    final sessions = HiveService.getAllSessions();
    final today = DateTime.now();
    final todaySessions =
        CalculationService.sessionsForDay(sessions, today);
    final totalToday =
        CalculationService.totalWorkedForDay(sessions, today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            "Today · ${DateFormat('EEEE, MMM d').format(today)}",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.access_time,
                label: 'Total today',
                value: CalculationService.formatDurationShort(totalToday),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.repeat,
                label: 'Sessions',
                value: todaySessions.length.toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
