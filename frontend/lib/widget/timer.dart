import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<bool> checkMeetingStatus(String meetingId) async {
  // Replace with your local server's IP and port
    final serverPort = appConfig?['server_port'] ?? 8080;
  final url = Uri.parse('http://localhost:$serverPort/api/checkMeetingStatus');
  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isRunning'] ?? false;
    } else {
      throw Exception('Failed to get meeting status: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
    return false;
  }
}
class Timer extends StatefulWidget {
  const Timer({Key? key}) : super(key: key);

  @override
  _TimerState createState() => _TimerState();
}

class _TimerState extends State<Timer> with TickerProviderStateMixin {
  late AnimationController controller;

  String get countText {
    Duration count = controller.duration! * controller.value;
    return '${(count.inHours % 24).toString().padLeft(2, '0')}:${(count.inMinutes % 60).toString().padLeft(2, '0')}:${(count.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25), // Set timer duration
    );

    // Start the animation in reverse (countdown)
    controller.reverse(from: 1.0);

    // Listen to the animation updates
    controller.addListener(() {
      setState(() {
        // Triggers UI updates every frame as the controller value changes
      });
    });
  }

  @override
  void dispose() {
    controller.dispose(); // Dispose controller to free resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent background
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Darker Circle Background
                  Container(
                    height: screenHeight * 0.2,
                    width: screenHeight * 0.2,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2), // Darker color inside
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Circular Progress Indicator
                  SizedBox(
                    height: screenHeight * 0.2,
                    width: screenHeight * 0.2,
                    child: CircularProgressIndicator(
                      strokeWidth: 8.0,
                      value: controller.value, // Link progress to animation controller
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 238, 189, 49),
                      ),
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),

                  // Timer Text
                  AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) => Text(
                      countText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenHeight * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
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
