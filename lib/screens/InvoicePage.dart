import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

class InvoicePage extends StatelessWidget {
  final String invoiceId;
  final String plan;
  final String amount;
  final String start;
  final String end;
  final bool isActive;

  const InvoicePage({
    super.key,
    required this.invoiceId,
    required this.plan,
    required this.amount,
    required this.start,
    required this.end,
    required this.isActive,
  });

  Future<void> _downloadPdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColor.fromHex("#0F3D2E"),
                width: 8,
              ),
            ),
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                /// HEADER
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Invoice",
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex("#2E7D32"),
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("POSTER APP",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text("support@posterapp.com",
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    )
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Divider(),

                pw.SizedBox(height: 20),

                /// INFO SECTION
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [

                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("INVOICE DETAILS",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text("Invoice ID: #$invoiceId"),
                        pw.Text("Start Date: $start"),
                        pw.Text("End Date: $end"),
                      ],
                    ),

                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("STATUS",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text(isActive ? "Active" : "Expired"),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                /// TABLE
                pw.Table(
                  border: pw.TableBorder.all(
                      color: PdfColor.fromHex("#CCCCCC")),
                  children: [

                    /// HEADER ROW
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex("#0F3D2E"),
                      ),
                      children: [
                        _tableCell("PLAN", true),
                        _tableCell("START", true),
                        _tableCell("END", true),
                        _tableCell("PRICE", true),
                      ],
                    ),

                    /// DATA ROW
                    pw.TableRow(
                      children: [
                        _tableCell(plan, false),
                        _tableCell(start, false),
                        _tableCell(end, false),
                        _tableCell(amount, false),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    "Total Amount: $amount",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex("#2E7D32"),
                    ),
                  ),
                ),

                pw.SizedBox(height: 40),

                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Authorized Signature"),
                      pw.SizedBox(height: 20),
                      pw.Text("Poster App",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),

                pw.Spacer(),

                pw.Divider(),

                pw.SizedBox(height: 8),

                pw.Text(
                  "Thank you for choosing Poster App. If you have any questions, please contact support.",
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromHex("#666666"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File("${directory.path}/Invoice_$invoiceId.pdf");

    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Invoice #$invoiceId",
    );
  }

  pw.Widget _tableCell(String text, bool isHeader) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight:
          isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader
              ? PdfColors.white
              : PdfColors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Invoice",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row("Invoice ID", "#$invoiceId"),
                  const SizedBox(height: 12),
                  _row("Plan", plan),
                  const SizedBox(height: 12),
                  _row("Start Date", start),
                  const SizedBox(height: 12),
                  _row("End Date", end),
                  const SizedBox(height: 12),
                  _row("Amount Paid", amount),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _downloadPdf(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Download Invoice PDF",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 14)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ],
    );
  }
}
