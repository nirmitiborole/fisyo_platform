import 'dart:math';
import 'package:flutter/material.dart';
import 'package:goniometer/pages/left_right/report_service.dart';
import '../left_right.dart';
import 'circular_heatmap_painter.dart';


// --- Widget 1: StatusIndicators ---
// Replaces _buildStatusIndicators()
class StatusIndicators extends StatelessWidget {
  final bool isConnected;
  final bool isReading;

  const StatusIndicators({
    Key? key,
    required this.isConnected,
    required this.isReading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                size: 18,
                color: isConnected ? Colors.green : Colors.red,
              ),
              SizedBox(width: 6),
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  fontSize: 13,
                  color: isConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: isReading ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isReading ? Icons.sensors : Icons.sensors_off,
                size: 18,
                color: isReading ? Colors.blue : Colors.grey,
              ),
              SizedBox(width: 6),
              Text(
                isReading ? 'Reading' : 'Stopped',
                style: TextStyle(
                  fontSize: 13,
                  color: isReading ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Widget 2: ControlButtons ---
// Replaces _buildControlButtons()
class ControlButtons extends StatelessWidget {
  final bool isConnected;
  final bool isReading;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const ControlButtons({
    Key? key,
    required this.isConnected,
    required this.isReading,
    required this.onStart,
    required this.onStop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: isConnected ? (isReading ? onStop : onStart) : null,
          icon: Icon(isReading ? Icons.stop : Icons.play_arrow),
          label: Text(isReading ? 'Stop' : 'Start'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isReading ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ],
    );
  }
}

// --- Widget 3: StabilityScoreDisplay ---
// Replaces _buildScoreDisplay()
class StabilityScoreDisplay extends StatelessWidget {
  final double currentScore;

  const StabilityScoreDisplay({Key? key, required this.currentScore})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color scoreColor;
    String scoreLabel;

    if (currentScore >= 75) {
      scoreColor = Colors.blue;
      scoreLabel = 'Highly Stable';
    } else if (currentScore >= 50) {
      scoreColor = Colors.green;
      scoreLabel = 'Stable';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Unstable';
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withOpacity(0.3), scoreColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Current Stability Score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            currentScore.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              scoreLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: currentScore / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Widget 4: CircleVisualization ---
// Replaces _buildCircleVisualization()
class CircleVisualization extends StatelessWidget {
  final double circleX;
  final double circleY;
  final double outerCircleRadius;
  final double innerCircleRadius;
  final double smallCircleRadius;
  final Color movementColor;

  const CircleVisualization({
    Key? key,
    required this.circleX,
    required this.circleY,
    required this.outerCircleRadius,
    required this.innerCircleRadius,
    required this.smallCircleRadius,
    required this.movementColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double distance = sqrt(circleX * circleX + circleY * circleY);
    double maxAllowedRadius = outerCircleRadius - smallCircleRadius;
    double actualX, actualY;

    if (distance <= 0.67) {
      double maxRadius = innerCircleRadius - smallCircleRadius;
      actualX = circleX * maxRadius;
      actualY = circleY * maxRadius;
    } else {
      double scaleFactor = (distance - 0.67) / 0.33;
      double extraRadius = (outerCircleRadius - innerCircleRadius) * scaleFactor;
      double dirX = (distance == 0) ? 0 : circleX / distance;
      double dirY = (distance == 0) ? 0 : circleY / distance;
      double targetRadius = (innerCircleRadius - smallCircleRadius + extraRadius);
      targetRadius = targetRadius.clamp(0.0, maxAllowedRadius);
      actualX = dirX * targetRadius;
      actualY = dirY * targetRadius;
    }

    return Container(
      width: outerCircleRadius * 2,
      height: outerCircleRadius * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: outerCircleRadius * 2,
            height: outerCircleRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey, width: 2),
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
          Container(
            width: innerCircleRadius * 2,
            height: innerCircleRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.lightBlue, width: 2),
              color: Colors.lightBlue.withOpacity(0.1),
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            left: (outerCircleRadius - smallCircleRadius) + actualX,
            top: (outerCircleRadius - smallCircleRadius) + actualY,
            child: Container(
              width: smallCircleRadius * 2,
              height: smallCircleRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: movementColor,
                boxShadow: [
                  BoxShadow(
                    color: movementColor.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: smallCircleRadius * 1.2,
                  height: smallCircleRadius * 1.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          // ... (The rest of your Stack children: lines, labels) ...
          Container(
            width: outerCircleRadius * 2,
            height: 2,
            color: Colors.black.withOpacity(0.4),
          ),
          Container(
            width: 2,
            height: outerCircleRadius * 2,
            color: Colors.black.withOpacity(0.4),
          ),
          Positioned(
            left: 15,
            top: outerCircleRadius - 10,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('LEFT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            right: 15,
            top: outerCircleRadius - 10,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('RIGHT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            top: 15,
            left: outerCircleRadius - 12,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('UP', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            bottom: 15,
            left: outerCircleRadius - 18,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('DOWN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Widget 5: SensorDataDisplay ---
// Replaces _buildSensorDataDisplay()
class SensorDataDisplay extends StatelessWidget {
  final double angle, ax, ay, az, gx, gy, gz;

  const SensorDataDisplay({
    Key? key,
    required this.angle,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Angle
          Text(
            'Angle: ${angle.toStringAsFixed(2)}°',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),

          // Accelerometer values
          Text(
            'Accelerometer',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Ax: ${ax.toStringAsFixed(2)}  Ay: ${ay.toStringAsFixed(2)}  Az: ${az.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),

          SizedBox(height: 8),

          // Gyroscope values
          Text(
            'Gyroscope',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Gx: ${gx.toStringAsFixed(2)}  Gy: ${gy.toStringAsFixed(2)}  Gz: ${gz.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

// --- Widget 6: SessionReportDialog ---
// Replaces _showReportDialog()
class SessionReportDialog extends StatelessWidget {
  final String classification;
  final double score;
  final double duration;
  final int dataPoints;
  final double avgDeviation;
  final double maxDeviation;
  final double timeInCenter;
  final Color color;
  final IconData icon;
  final String? filePath;
  final Map<String, double> sectorPercentages; // <-- Pass this in

  // We instantiate the service right here, since this dialog is
  // the only place that needs it.
  final ReportService _reportService = ReportService();

  SessionReportDialog({
    Key? key,
    required this.classification,
    required this.score,
    required this.duration,
    required this.dataPoints,
    required this.avgDeviation,
    required this.maxDeviation,
    required this.timeInCenter,
    required this.color,
    required this.icon,
    this.filePath,
    required this.sectorPercentages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Icon(icon, size: 64, color: color),
          SizedBox(height: 12),
          Text(
            classification,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'Overall Session Score',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    score.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Use the helper methods from below
            _buildReportRow('Duration', '${duration.toStringAsFixed(1)}s'),
            _buildReportRow('Data Points', '$dataPoints'),
            _buildReportRow('Avg Deviation', '${(avgDeviation * 100).toStringAsFixed(1)}%'),
            _buildReportRow('Max Deviation', '${(maxDeviation * 100).toStringAsFixed(1)}%'),
            _buildReportRow('Time in Center', '${timeInCenter.toStringAsFixed(1)}s'),

            SizedBox(height: 16),

            _buildHeatmapWidget(), // Helper method
          ],
        ),
      ),
      actions: [
        if (filePath != null)
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _reportService.shareReport(filePath!);
            },
            icon: Icon(Icons.share, color: Colors.white),
            label: Text('Share Report', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  // --- All the helper methods for the dialog are now here ---
  // (These were _buildHeatmapWidget, _buildSectorLabel, etc.)

  Widget _buildHeatmapWidget() {
    // Get all percentages from the map
    double centerPercent = sectorPercentages['center'] ?? 0.0;
    double northPercent = sectorPercentages['north'] ?? 0.0;
    double northEastPercent = sectorPercentages['north_east'] ?? 0.0;
    double eastPercent = sectorPercentages['east'] ?? 0.0;
    double southEastPercent = sectorPercentages['south_east'] ?? 0.0;
    double southPercent = sectorPercentages['south'] ?? 0.0;
    double southWestPercent = sectorPercentages['south_west'] ?? 0.0;
    double westPercent = sectorPercentages['west'] ?? 0.0;
    double northWestPercent = sectorPercentages['north_west'] ?? 0.0;

    Color getHeatColor(double percent) {
      if (percent < 15) {
        return Colors.red.withOpacity(0.6);
      } else if (percent < 25) {
        return Colors.green.withOpacity(0.7);
      } else {
        return Colors.blue.withOpacity(0.8);
      }
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Movement Heatmap',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Container(
            width: 220,
            height: 220,
            child: CustomPaint(
              size: Size(220, 220),
              painter: CircularHeatmapPainter(
                centerPercent: centerPercent,
                northPercent: northPercent,
                northEastPercent: northEastPercent,
                eastPercent: eastPercent,
                southEastPercent: southEastPercent,
                southPercent: southPercent,
                southWestPercent: southWestPercent,
                westPercent: westPercent,
                northWestPercent: northWestPercent,
                getHeatColor: getHeatColor,
              ),
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildSectorLabel('Center', centerPercent, Colors.green[700]!),
              _buildSectorLabel('N', northPercent),
              _buildSectorLabel('NE', northEastPercent),
              _buildSectorLabel('E', eastPercent),
              _buildSectorLabel('SE', southEastPercent),
              _buildSectorLabel('S', southPercent),
              _buildSectorLabel('SW', southWestPercent),
              _buildSectorLabel('W', westPercent),
              _buildSectorLabel('NW', northWestPercent),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(Colors.red.withOpacity(0.6), 'Unstable (<15%)'),
              _buildLegendItem(Colors.green.withOpacity(0.7), 'Stable (15-25%)'),
              _buildLegendItem(Colors.blue.withOpacity(0.8), 'Highly Stable (>25%)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectorLabel(String label, double percent, [Color? color]) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey[300])?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${percent.toStringAsFixed(1)}%',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.grey),
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}