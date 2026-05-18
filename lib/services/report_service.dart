import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../shared/models/task_model.dart';
import '../services/task_service.dart';

class ReportService {
  final _db = FirebaseFirestore.instance;

  // ── Generate report for one elder ──
  Future<void> generateDailyReport({
    required String elderUid,
    required String elderName,
    required String? caretakerUid,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // ✅ Single where clause — no index needed
    final taskSnap = await _db
        .collection('tasks')
        .where('userId', isEqualTo: elderUid)
        .get();

    // Filter client-side
    final allTasks = taskSnap.docs
        .map((d) => TaskModel.fromFirestore(d))
        .toList();

    final tasks = allTasks.where((t) =>
        t.dueTime.isAfter(today.subtract(const Duration(seconds: 1))) &&
        t.dueTime.isBefore(tomorrow)).toList();

    final done = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;
    final wellness = TaskService.calculateWellness(tasks);

    // SOS — single where
    final sosSnap = await _db
        .collection('sos_alerts')
        .where('elderUid', isEqualTo: elderUid)
        .get();

    final sosList = sosSnap.docs
        .map((d) => d.data() as Map<String, dynamic>)
        .where((s) {
          final created = s['createdAt'] as Timestamp?;
          if (created == null) return false;
          final t = created.toDate();
          return t.isAfter(today) && t.isBefore(tomorrow);
        }).toList();

    final taskDetails = tasks.map((t) {
      String timingStatus = 'Not done';
      if (t.isCompleted && t.completedAt != null) {
        final mins = t.completedAt!.difference(t.dueTime).inMinutes;
        timingStatus = mins <= 0 ? 'On time ✓' :
            mins <= 30 ? '${mins}m late' : 'Very late (${mins}m)';
      }
      return {
        'title': t.title,
        'emoji': t.emoji,
        'category': t.category,
        'completed': t.isCompleted,
        'reminderTime': DateFormat('h:mm a').format(t.dueTime),
        'completedAt': t.completedAt != null
            ? DateFormat('h:mm a').format(t.completedAt!) : null,
        'timingStatus': timingStatus,
      };
    }).toList();

    final reportData = {
      'elderUid': elderUid,
      'elderName': elderName,
      'caretakerUid': caretakerUid,
      'date': Timestamp.fromDate(today),
      'wellness': wellness,
      'totalTasks': total,
      'completedTasks': done,
      'pendingTasks': total - done,
      'sosCount': sosList.length,
      'sosDetails': sosList.map((s) => {
        'time': s['createdAt'] != null
            ? DateFormat('h:mm a').format(
                (s['createdAt'] as Timestamp).toDate()) : 'Unknown',
        'resolved': s['resolved'] ?? false,
      }).toList(),
      'taskDetails': taskDetails,
      'generatedAt': FieldValue.serverTimestamp(),
    };

    // Check if report exists today — single where only
    final existing = await _db
        .collection('reports')
        .where('elderUid', isEqualTo: elderUid)
        .get();

    // Filter client-side for today
    final todayReports = existing.docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp?)?.toDate();
      if (date == null) return false;
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).toList();

    if (todayReports.isNotEmpty) {
      await _db
          .collection('reports')
          .doc(todayReports.first.id)
          .update(reportData);
    } else {
      await _db.collection('reports').add(reportData);
    }
  }

  // ── Get reports stream for caretaker ──
  Stream<QuerySnapshot> getReportsForCaretaker(
      String caretakerUid) {
    return _db
        .collection('reports')
        .where('caretakerUid', isEqualTo: caretakerUid)
        .snapshots();
  }

  // ── Generate + share PDF ──
  Future<void> generateAndSharePdf(
      Map<String, dynamic> report) async {
    final pdf = pw.Document();
    final date = (report['date'] as Timestamp).toDate();
    final tasks = List<Map<String, dynamic>>.from(
        report['taskDetails'] ?? []);
    final sosList = List<Map<String, dynamic>>.from(
        report['sosDetails'] ?? []);
    final wellness = report['wellness'] ?? 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.brown800,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('AASHRAYA',
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    )),
                pw.Text('Daily Health Report',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.white,
                    )),
                pw.SizedBox(height: 4),
                pw.Text(
                  DateFormat('EEEE, d MMMM yyyy').format(date),
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Text('Patient: ${report['elderName']}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              )),

          pw.SizedBox(height: 16),

          // Summary stats
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
              color: wellness >= 75
                  ? PdfColors.green50
                  : wellness >= 50
                      ? PdfColors.orange50
                      : PdfColors.red50,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _stat('Wellness', '$wellness%'),
                _stat('Total', '${report['totalTasks']}'),
                _stat('Done', '${report['completedTasks']}'),
                _stat('Pending', '${report['pendingTasks']}'),
                _stat('SOS', '${report['sosCount']}'),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Task table
          pw.Text('Task Analysis',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  'Task', 'Reminder', 'Completed At', 'Status', 'Timing'
                ]
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9,
                              )),
                        ))
                    .toList(),
              ),
              ...tasks.map((t) => pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: t['completed'] == true
                          ? PdfColors.green50
                          : PdfColors.red50,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          '${t['emoji']} ${t['title']}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          t['reminderTime'] ?? '-',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          t['completedAt'] ?? 'Not done',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          t['completed'] == true ? 'Done ✓' : 'Pending',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: t['completed'] == true
                                ? PdfColors.green700
                                : PdfColors.red700,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          t['timingStatus'] ?? '-',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: t['timingStatus'] == 'On time ✓'
                                ? PdfColors.green700
                                : PdfColors.orange700,
                          ),
                        ),
                      ),
                    ],
                  )),
            ],
          ),

          // SOS section
          if (sosList.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('SOS Alerts Today',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red700,
                )),
            pw.SizedBox(height: 8),
            ...sosList.map((s) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    border: pw.Border.all(color: PdfColors.red200),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(children: [
                    pw.Text('🆘 Alert at ${s['time']}  ',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      s['resolved'] == true ? '✓ Resolved' : '⚠ Unresolved',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: s['resolved'] == true
                            ? PdfColors.green700
                            : PdfColors.red700,
                      ),
                    ),
                  ]),
                )),
          ],

          pw.SizedBox(height: 20),

          pw.Text(
            'Generated by Aashraya · ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'Aashraya_${report['elderName']}_${DateFormat('dd_MM_yyyy').format(date)}.pdf',
    );
  }

  pw.Widget _stat(String label, String value) {
    return pw.Column(children: [
      pw.Text(value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          )),
      pw.Text(label,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
          )),
    ]);
  }
}