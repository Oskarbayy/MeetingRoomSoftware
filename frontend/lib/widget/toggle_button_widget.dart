import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:provider/provider.dart';

class ToggleButtonsWidget extends StatelessWidget {
  final List<String> imagePaths;
  final List<String> buttonTexts;

  const ToggleButtonsWidget({
    super.key,
    required this.imagePaths,
    required this.buttonTexts,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(imagePaths.length, (index) {
      return Expanded(
        child: Padding(
          padding: EdgeInsets.all(screenHeight * 0.02),
          child: AspectRatio(
            aspectRatio: 1,
            child: Consumer<SelectedIndexNotifier>(
              builder: (context, selectedIndexNotifier, child) {
                return ElevatedButton(
                  onPressed: () {
                    selectedIndexNotifier.setSelectedIndex(index);
                    previousIndex = context.read<SelectedIndexNotifier>().readSelectedIndex();
                    sendButtonPress(index + 2); // Button IDs start from 2 since turn off and on is on id 0 and 1
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedIndexNotifier.selectedIndex == index
                        ? const Color(0xFFFDC830)
                        : Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: Colors.black54,
                    side: BorderSide(
                      color: selectedIndexNotifier.selectedIndex == index
                          ? const Color(0xFFE4A411)
                          : Colors.black12,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        flex: 2,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromRGBO(0, 0, 0, 0.2),
                                  blurRadius: 50,
                                  spreadRadius: -15,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              imagePaths[index],
                              fit: BoxFit.contain,
                              color: selectedIndexNotifier.selectedIndex == index
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        flex: 1,
                        child: Text(
                          buttonTexts[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenHeight * 0.0275,
                            fontWeight: FontWeight.w600,
                            color: selectedIndexNotifier.selectedIndex == index
                                ? Colors.black87
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }),
  );}
}