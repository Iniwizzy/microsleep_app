// lib/statistics_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:microsleep/providers/eye_detection_provider.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistik Deteksi"),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Consumer<EyeDetectionProvider>(
        builder: (context, provider, child) {
          final total = provider.openCount + provider.closedCount;
          final openPercentage =
              total > 0 ? (provider.openCount / total * 100) : 0.0;
          final closedPercentage =
              total > 0 ? (provider.closedCount / total * 100) : 0.0;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Total Deteksi",
                        total.toString(),
                        Icons.analytics,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        "Status Terakhir",
                        provider.eyeStatus,
                        provider.eyeStatus.toLowerCase() == 'open'
                            ? Icons.visibility
                            : Icons.visibility_off,
                        provider.eyeStatus.toLowerCase() == 'open'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Detailed Statistics
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Statistik Detail",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Eye Open Statistics
                      _buildDetailRow(
                        "Mata Terbuka",
                        provider.openCount.toString(),
                        "${openPercentage.toStringAsFixed(1)}%",
                        Colors.green,
                        openPercentage / 100,
                      ),
                      const SizedBox(height: 16),

                      // Eye Closed Statistics
                      _buildDetailRow(
                        "Mata Tertutup",
                        provider.closedCount.toString(),
                        "${closedPercentage.toStringAsFixed(1)}%",
                        Colors.red,
                        closedPercentage / 100,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Session Information
                if (provider.lastDetectionTime != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              "Informasi Sesi",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          "Deteksi Terakhir",
                          _formatDateTime(provider.lastDetectionTime!),
                        ),
                        _buildInfoRow(
                          "Confidence Terakhir",
                          "${(provider.confidence * 100).toStringAsFixed(1)}%",
                        ),
                        _buildInfoRow(
                          "Status Deteksi",
                          provider.isDetecting ? "Aktif" : "Tidak Aktif",
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          provider.resetCounters();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Statistik telah direset"),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Reset Statistik"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Kembali"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String count,
    String percentage,
    Color color,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  percentage,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}
