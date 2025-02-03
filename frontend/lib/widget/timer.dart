import 'dart:async'; // Import Timer
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  double progress = 0.0; // Holds the progress value for the progress bar
  late AnimationController controller;
  late Timer refreshTimer; // Timer for periodic updates
  bool isLoading = true;
  Duration duration = const Duration(seconds: 0);
  String toTime = "";
  bool isAvailable = true; // Default state
  String statusText = ""; // Text above the timer

  String get countText {
    Duration count = duration * controller.value;
    return '${(count.inHours % 24).toString().padLeft(2, '0')}:${(count.inMinutes % 60).toString().padLeft(2, '0')}:${(count.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();

    // Initialize controller with a default duration
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..value = 1.0; // Prevents errors if fetchMeetingStatus() fails

    fetchMeetingStatus();

    // Start a periodic timer to refresh the meeting status
    refreshTimer = Timer.periodic(const Duration(seconds: 10), (Timer t) {
      fetchMeetingStatus(); // Fetch updated data every 10 seconds
    });
  }

  Future<void> fetchMeetingStatus() async {
    final url = Uri.parse('http://localhost:8080/api/checkMeetingStatus'); // API endpoint

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['roomAvailability'] != null) {
          isAvailable = data['roomAvailability']['isAvailable'];
          String fromTime = data['roomAvailability']['FromTime'] ?? "";
          toTime = data['roomAvailability']['ToTime'] ?? "";

          print("[LOG] isAvailable: $isAvailable");
          print("[LOG] FromTime: $fromTime");
          print("[LOG] ToTime: $toTime");

          if (fromTime.isNotEmpty && toTime.isNotEmpty) {
            DateTime fromTimeUtc = DateTime.parse(fromTime); // IS ALREADY UTC+1
            DateTime toTimeUtc = DateTime.parse(toTime); // IS ALREADY UTC+1
            DateTime now = DateTime.now().toUtc().add(const Duration(hours: 1)); // Convert current time to UTC+1
            
            Duration totalTime = toTimeUtc.difference(fromTimeUtc); // Full meeting duration
            Duration elapsedTime = now.difference(fromTimeUtc); // Time since meeting started
            Duration remainingTime = toTimeUtc.difference(now); // Time left until meeting ends

            // Ensure values are within valid range
            if (elapsedTime.isNegative) elapsedTime = Duration.zero;
            if (remainingTime.isNegative) remainingTime = Duration.zero;
            if (elapsedTime > totalTime) elapsedTime = totalTime;

            progress = totalTime.inSeconds > 0 ? elapsedTime.inSeconds / totalTime.inSeconds : 0.0;

            print("[LOG] Total Meeting Time: ${totalTime.inSeconds} seconds");
            print("[LOG] Elapsed Time: ${elapsedTime.inSeconds} seconds");
            print("[LOG] Remaining Time: ${remainingTime.inSeconds} seconds");
            print("[LOG] Progress Percentage: ${(progress * 100).toStringAsFixed(2)}%");

            controller.stop();
            controller.reset();
            controller.duration = remainingTime; // Set countdown duration to the remaining time

            setState(() {
              duration = remainingTime;
              isLoading = false;
              progress = totalTime.inSeconds > 0 ? elapsedTime.inSeconds / totalTime.inSeconds : 0.0;
              statusText = now.isBefore(fromTimeUtc) ? "Meeting starts in" : "Meeting ends in";
            });

            print("[LOG] Updated Progress Value: $progress");

            // Ensure the UI updates first before triggering animations
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.stop();
              controller.reset();
              controller.duration = remainingTime; 
              controller.value = 1.0; 
              controller.reverse(from: 1.0);
            });

            controller.value = 1.0; // Start at full remaining time
            controller.reverse(from: 1.0); // Count down to zero
          } else {
            // No upcoming meetings
            setState(() {
              isLoading = false;
              statusText = "Room available"; 
            });

            controller.stop();
            controller.reset();
            controller.duration = const Duration(seconds: 1);
            controller.value = 1.0;
          }
        }
      } else {
        throw Exception('Failed to get meeting status: ${response.statusCode}');
      }
    } catch (e) {
      print('[ERROR] $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    refreshTimer.cancel(); // Stop the timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double circleDiameter = screenHeight * 0.2;
    double textContainerWidth = circleDiameter * 0.8; // 80% of the circle diameter
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: circleDiameter,
                          width: circleDiameter,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(
                          height: circleDiameter,
                          width: circleDiameter,
                          child: CircularProgressIndicator(
                            strokeWidth: 8.0,
                            value: toTime.isEmpty ? 1.0 : (1-progress),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 238, 189, 49),
                            ),
                            backgroundColor: Colors.grey.shade300,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: controller,
                          builder: (context, child) => Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: textContainerWidth, // Restrict width
                                child: Text(
                                  toTime.isEmpty ? "No meetings scheduled" : statusText,
                                  textAlign: TextAlign.center, // Center text
                                  softWrap: true, // Allow text wrapping
                                  overflow: TextOverflow.visible, // Prevent text clipping
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: toTime.isEmpty ? screenHeight * 0.014 : screenHeight * 0.0175, // Adjust size if no meeting
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                toTime.isEmpty ? DateFormat('HH:mm').format(DateTime.now()) : countText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenHeight * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                                style: TextStyle(
                                  color: Color.fromARGB(255, 233, 233, 233),
                                  fontSize: screenHeight * 0.0125,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

}
