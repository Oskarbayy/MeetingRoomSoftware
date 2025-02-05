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

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
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
    final int hours = count.inHours;

    if (hours == 0) {
      // Round up the minutes if there are any leftover seconds.
      final int minutes = (count.inSeconds / 60).ceil();
      return '$minutes';
    } else {
      // For hours, use the current logic (show hours and minutes without rounding)
      final int minutes = count.inMinutes % 60;
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
          progress = totalTime.inSeconds > 0
              ? elapsedTime.inSeconds / totalTime.inSeconds
              : 0.0;
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
    final url = Uri.parse(
        'http://localhost:8080/api/checkMeetingStatus'); // API endpoint

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
            // Parse meeting times (assumed to be already in UTC+1)
            DateTime newFromTime = DateTime.parse(fromTimeStr);
            DateTime newToTime = DateTime.parse(toTimeStr);

            // Update meeting times if needed
            if (fromTimeUtc == null || fromTimeUtc != newFromTime) {
              fromTimeUtc = newFromTime;
            }
            toTimeUtc = newToTime;

            // Get current time in UTC+1
            DateTime now = DateTime.now().toUtc().add(const Duration(hours: 1));

            Duration countdown;
            String newStatusText;

            if (now.isBefore(fromTimeUtc!)) {
              // The meeting has not started yet.
              // Count down to the meeting start time.
              countdown = fromTimeUtc!.difference(now);
              newStatusText = "Meeting starts in";
            } else {
              // The meeting is underway.
              // Count down to the meeting end time.
              countdown = toTimeUtc!.difference(now);
              if (isAvailable) {
                newStatusText = "Meeting starts in";
              } else {
                newStatusText = "Meeting ends in";
              }
            }

            if (countdown.isNegative) countdown = Duration.zero;

            setState(() {
              duration = countdown;
              isLoading = false;
              statusText = newStatusText;
              toTime = toTimeUtc.toString();
            });

            print("[LOG] Countdown Duration: ${countdown.inSeconds} seconds");

            // Configure the animation controller for the new countdown duration.
            controller.stop();
            controller.reset();
            controller.duration = countdown;
            controller.value = 1.0;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.reverse(from: 1.0);
            });
          } else {
            // No upcoming meetings: clear meeting times so the clock shows.
            setState(() {
              isLoading = false;
              statusText = "Room available";
              fromTimeUtc = null;
              toTimeUtc = null;
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
    double textContainerWidth =
        circleDiameter * 0.8; // 80% of the circle diameter

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
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Updated CircularProgressIndicator widget
                        SizedBox(
                          height: circleDiameter,
                          width: circleDiameter,
                          child: CircularProgressIndicator(
                            strokeWidth: 8.0,
                            value: (fromTimeUtc == null) ? 0.0 : (1 - progress),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              () {
                                // Default color: Green
                                Color progressColor =
                                    const Color.fromARGB(255, 22, 201, 49);
                                if (fromTimeUtc != null && toTimeUtc != null) {
                                  Duration remainingTime = toTimeUtc!
                                      .difference(DateTime.now()
                                          .toUtc()
                                          .add(const Duration(hours: 1)));
                                  if (remainingTime.inMinutes < 1) {
                                    progressColor = Colors
                                        .red; // Red if 1 minute or less remains
                                  } else if (remainingTime.inMinutes < 15) {
                                    progressColor = Colors
                                        .orange; // Orange if 15 minutes or less remains
                                  }
                                }
                                return progressColor;
                              }(),
                            ),
                            backgroundColor: Colors.grey.shade300,
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
                              alignment: Alignment.center,
                              children: [
                                // The big text in the center
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
                                  alignment: const Alignment(0, -0.45),
                                  child: Text(
                                    status,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: noMeeting
                                          ? screenHeight * 0.012
                                          : screenHeight * 0.016,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Text below the count text (slightly below center)
                                Align(
                                  alignment: const Alignment(0, 0.55),
                                  child: Text(
                                    DateFormat('EEEE, MMM d, yyyy')
                                        .format(DateTime.now()),
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                          255, 155, 155, 155),
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
