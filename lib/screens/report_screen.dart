import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/hive_service.dart';
import '../services/calculation_service.dart';

/// Monthly report screen with stats and PDF export.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late int _selectedYear;
  late int _selectedMonth;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  @override
  Widget build(BuildContext context) {
    final sessions = HiveService.getAllSessions();
    final totalDuration = CalculationService.totalWorkedForMonth(
        sessions, _selectedYear, _selectedMonth);
    final avgPerDay = CalculationService.averageHoursPerDay(
        sessions, _selectedYear, _selectedMonth);
    final weeklyMap = CalculationService.hoursPerWeek(
        sessions, _selectedYear, _selectedMonth);
    final monthSessions = sessions
        .where((s) =>
            s.startTime.year == _selectedYear &&
            s.startTime.month == _selectedMonth &&
            !s.isActive)
        .toList();

    final monthName =
        DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Month picker
            _MonthPicker(
              year: _selectedYear,
              month: _selectedMonth,
              onChanged: (y, m) => setState(() {
                _selectedYear = y;
                _selectedMonth = m;
              }),
            ),
            const SizedBox(height: 24),
            Text(
              monthName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total Hours',
                    value: CalculationService.formatDurationShort(totalDuration),
                    icon: Icons.schedule,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Sessions',
                    value: monthSessions.length.toString(),
                    icon: Icons.repeat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatCard(
              label: 'Avg Hours / Day',
              value: avgPerDay.toStringAsFixed(1),
              icon: Icons.today,
            ),
            if (weeklyMap.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Hours per Week',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...weeklyMap.entries
                  .toList()
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _WeekRow(week: e.key, hours: e.value),
                    ),
                  ),
            ],
            const SizedBox(height: 32),
            // Export button
            FilledButton.icon(
              onPressed: _exporting
                  ? null
                  : () => _exportPdf(context, monthName, totalDuration,
                      avgPerDay, weeklyMap, monthSessions.length),
              icon: _exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_exporting ? 'Generating PDF…' : 'Export Monthly Report'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(
    BuildContext context,
    String monthName,
    Duration total,
    double avgPerDay,
    Map<int, double> weeklyMap,
    int sessionCount,
  ) async {
    setState(() => _exporting = true);

    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Work Hours Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  monthName,
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.Divider(height: 32),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Hours:'),
                    pw.Text(
                      CalculationService.formatDurationShort(total),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Sessions:'),
                    pw.Text(
                      sessionCount.toString(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Avg Hours / Day:'),
                    pw.Text(
                      avgPerDay.toStringAsFixed(1),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                if (weeklyMap.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Hours per Week',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  ...weeklyMap.entries.map(
                    (e) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Week ${e.key}:'),
                        pw.Text('${e.value.toStringAsFixed(1)}h'),
                      ],
                    ),
                  ),
                ],
                pw.SizedBox(height: 16),
                pw.Text(
                  'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            );
          },
        ),
      );

      // Save to documents directory
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'report_${_selectedYear}_${_selectedMonth.toString().padLeft(2, '0')}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        // Show print/share dialog (works on Android, iOS, web)
        await Printing.layoutPdf(
          onLayout: (_) async => pdf.save(),
          name: fileName,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _MonthPicker extends StatelessWidget {
  final int year;
  final int month;
  final void Function(int year, int month) onChanged;

  const _MonthPicker({
    required this.year,
    required this.month,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            var m = month - 1;
            var y = year;
            if (m < 1) {
              m = 12;
              y--;
            }
            onChanged(y, m);
          },
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          DateFormat('MMMM yyyy').format(DateTime(year, month)),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        IconButton(
          onPressed: year < now.year || (year == now.year && month < now.month)
              ? () {
                  var m = month + 1;
                  var y = year;
                  if (m > 12) {
                    m = 1;
                    y++;
                  }
                  onChanged(y, m);
                }
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
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
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final int week;
  final double hours;

  const _WeekRow({required this.week, required this.hours});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Assume max 60h per week for bar width
    final fraction = (hours / 60).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            'Week $week',
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${hours.toStringAsFixed(1)}h',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
