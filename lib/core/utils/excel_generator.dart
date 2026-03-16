import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class ExcelGenerator {
  ExcelGenerator._();

  static Future<File> buildAttendanceExcel({
    required String courseCode,
    required int semester,
    required List<Map<String, dynamic>> students,
    required List<Map<String, dynamic>> sessions,
    required List<Map<String, dynamic>> records,
  }) async {
    final excel = Excel.createExcel();

    // Sheet 1: Attendance Summary
    final summarySheet = excel['Attendance Summary'];
    _buildSummarySheet(summarySheet, students, sessions, records);

    // Sheet 2: Session Log
    final sessionSheet = excel['Session Log'];
    _buildSessionSheet(sessionSheet, sessions);

    // Remove default sheet
    excel.delete('Sheet1');

    // Save file
    final dir = await getApplicationDocumentsDirectory();
    final date = DateTime.now();
    final fileName =
        'KUET_${courseCode}_${semester}Sem_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.xlsx';
    final file = File('${dir.path}/$fileName');
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    return file;
  }

  static void _buildSummarySheet(
    Sheet sheet,
    List<Map<String, dynamic>> students,
    List<Map<String, dynamic>> sessions,
    List<Map<String, dynamic>> records,
  ) {
    // Header style
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1A3A6B'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // Build header row
    final headers = [
      'Roll No',
      'Student ID',
      'Student Name',
      ...sessions.map((s) => 'Class ${s['class_number']} (${s['date']})'),
      'Total Classes',
      'Present',
      'Absent',
      'Late',
      'Attendance %',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Build data rows
    for (var si = 0; si < students.length; si++) {
      final student = students[si];
      final roll = student['roll_number'] as int;
      final rowIdx = si + 1;
      final altStyle = CellStyle(
        backgroundColorHex: rowIdx % 2 == 0
            ? ExcelColor.fromHexString('#F5F5F5')
            : ExcelColor.fromHexString('#FFFFFF'),
      );

      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: rowIdx))
        ..value = IntCellValue(roll)
        ..cellStyle = altStyle;
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: rowIdx))
        ..value = TextCellValue(student['student_id'] ?? '')
        ..cellStyle = altStyle;
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 2, rowIndex: rowIdx))
        ..value = TextCellValue(student['name'] ?? 'Student $roll')
        ..cellStyle = altStyle;

      int present = 0, absent = 0, late = 0;
      for (var j = 0; j < sessions.length; j++) {
        final sessionId = sessions[j]['id'];
        final record = records.where((r) =>
            r['session_id'] == sessionId && r['roll_number'] == roll);
        final status = record.isNotEmpty ? record.first['status'] : '-';

        final colIdx = 3 + j;
        final statusColor = _getStatusCellColor(status);
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: colIdx, rowIndex: rowIdx))
          ..value = TextCellValue(status)
          ..cellStyle = CellStyle(
            backgroundColorHex: statusColor,
            horizontalAlign: HorizontalAlign.Center,
          );

        if (status == 'P') present++;
        if (status == 'A') absent++;
        if (status == 'LA') late++;
      }

      final total = sessions.length;
      final pct = total > 0 ? (present / total * 100) : 0.0;
      final metaCols = 3 + sessions.length;

      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: metaCols, rowIndex: rowIdx))
        ..value = IntCellValue(total)
        ..cellStyle = altStyle;
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: metaCols + 1, rowIndex: rowIdx))
        ..value = IntCellValue(present)
        ..cellStyle = altStyle;
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: metaCols + 2, rowIndex: rowIdx))
        ..value = IntCellValue(absent)
        ..cellStyle = altStyle;
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: metaCols + 3, rowIndex: rowIdx))
        ..value = IntCellValue(late)
        ..cellStyle = altStyle;
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: metaCols + 4, rowIndex: rowIdx))
        ..value = TextCellValue('${pct.toStringAsFixed(1)}%')
        ..cellStyle = CellStyle(
          bold: true,
          fontColorHex: pct < 60
              ? ExcelColor.fromHexString('#D32F2F')
              : pct < 75
                  ? ExcelColor.fromHexString('#F9A825')
                  : ExcelColor.fromHexString('#2E7D32'),
        );
    }
  }

  static void _buildSessionSheet(
    Sheet sheet,
    List<Map<String, dynamic>> sessions,
  ) {
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1A3A6B'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final headers = [
      'Class #', 'Date', 'Topic', 'Total', 'Present', 'Absent', 'Late',
      'Submitted At',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(headers[i])
        ..cellStyle = headerStyle;
    }

    for (var i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      final row = i + 1;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = IntCellValue(s['class_number'] ?? 0);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(s['date'] ?? '');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(s['topic'] ?? '');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = IntCellValue(s['total'] ?? 0);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = IntCellValue(s['present'] ?? 0);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = IntCellValue(s['absent'] ?? 0);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = IntCellValue(s['late'] ?? 0);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
          .value = TextCellValue(s['created_at'] ?? '');
    }
  }

  static ExcelColor _getStatusCellColor(String status) {
    return switch (status) {
      'P' => ExcelColor.fromHexString('#C8E6C9'),
      'A' => ExcelColor.fromHexString('#FFCDD2'),
      'LA' => ExcelColor.fromHexString('#FFF9C4'),
      'E' => ExcelColor.fromHexString('#BBDEFB'),
      _ => ExcelColor.fromHexString('#FFFFFF'),
    };
  }
}
