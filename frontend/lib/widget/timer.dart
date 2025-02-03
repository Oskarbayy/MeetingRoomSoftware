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
  DateTime? fromTimeUtc; // Store meeting start time from server
  DateTime? toTimeUtc; // Store meeting end time from server

  String get countText {
    final Duration count = duration * controller.value;
    final int hours = count.inHours % 24;
    final int minutes = count.inMinutes % 60;

    if (hours == 0) {
      // Show only minutes (e.g. "20")
      return '$minutes';
    } else {
      // Show hours and minutes (e.g. "01:20")
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
  }


  @override
  void initState() {
    super.initState();

    // Initialize controller with a default duration
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..value = 1.0;

    // Add a listener to update `progress` every frame based on animation
    controller.addListener(() {
      if (mounted && fromTimeUtc != null && toTimeUtc != null) {
        DateTime now = DateTime.now().toUtc().add(const Duration(hours: 1));
        Duration totalTime = toTimeUtc!.difference(fromTimeUtc!);
        Duration elapsedTime = now.difference(fromTimeUtc!);

        setState(() {
          progress = totalTime.inSeconds > 0 ? elapsedTime.inSeconds / totalTime.inSeconds : 0.0;
        });
      }
    });

    fetchMeetingStatus(); // Fetch initial status

    // Start a periodic timer to refresh the meeting status every 10 seconds
    refreshTimer = Timer.periodic(const Duration(seconds: 10), (Timer t) {
      fetchMeetingStatus();
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
          String fromTimeStr = data['roomAvailability']['FromTime'] ?? "";
          String toTimeStr = data['roomAvailability']['ToTime'] ?? "";

          print("[LOG] isAvailable: $isAvailable");
          print("[LOG] FromTime: $fromTimeStr");
          print("[LOG] ToTime: $toTimeStr");

          if (fromTimeStr.isNotEmpty && toTimeStr.isNotEmpty) {
            DateTime newFromTime = DateTime.parse(fromTimeStr); // IS ALREADY UTC+1
            DateTime newToTime = DateTime.parse(toTimeStr); // IS ALREADY UTC+1

            // Only update fromTimeUtc if it has changed
            if (fromTimeUtc == null || fromTimeUtc != newFromTime) {
              fromTimeUtc = newFromTime;
            }

            toTimeUtc = newToTime; // Always update end time
            DateTime now = DateTime.now().toUtc().add(const Duration(hours: 1)); // Convert current time to UTC+1
            
            Duration totalTime = toTimeUtc!.difference(fromTimeUtc!); // Full meeting duration
            Duration elapsedTime = now.difference(fromTimeUtc!); // Time since meeting started
            Duration remainingTime = toTimeUtc!.difference(now); // Time left until meeting ends

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
              statusText = now.isBefore(fromTimeUtc!) ? "Meeting starts in" : "Meeting ends in";
              toTime = toTimeUtc.toString(); // Ensure `toTime` is updated for UI logic

              print(toTime);
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
    refreshTimer.cancel();
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
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: circleDiameter,
                          width: circleDiameter,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(
                          height: circleDiameter,
                          width: circleDiameter,
                          child: CircularProgressIndicator(
                            strokeWidth: 8.0,
                            value: (fromTimeUtc == null) ? 1.0 : (1-progress),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 22, 201, 49),
                            ),
                            backgroundColor: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: controller,
                          builder: (context, child) {
                            final bool noMeeting = (fromTimeUtc == null);
                            final String mainText = noMeeting 
                                ? DateFormat('HH:mm').format(DateTime.now()) 
                                : countText;
                            final String status = noMeeting 
                                ? 'No meetings scheduled' 
                                : statusText;
                            
                            return Stack(
                              alignment: Alignment.center, // Base alignment for all children
                              children: [
                                // The big text in the *exact* center
                                Align(
                                  alignment: Alignment.center, 
                                  child: Text(
                                    mainText,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenHeight * 0.06,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // Text above the count text (slightly above center)
                                Align(
                                  alignment: const Alignment(0, -0.5), 
                                  // adjust the second parameter to move it closer/farther from center
                                  child: Text(
                                    status,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: noMeeting 
                                          ? screenHeight * 0.014 
                                          : screenHeight * 0.0175,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // Text below the count text (slightly below center)
                                Align(
                                  alignment: const Alignment(0, 0.55), 
                                  // adjust the second parameter to move it closer/farther from center
                                  child: Text(
                                    DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                                    style: TextStyle(
                                      color: const Color.fromARGB(255, 155, 155, 155),
                                      fontSize: screenHeight * 0.0125,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
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
