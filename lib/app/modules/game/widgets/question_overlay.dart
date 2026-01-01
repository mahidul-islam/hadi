import 'package:flutter/material.dart';
import 'package:hadi/app/data/models/question_model.dart';

class QuestionOverlay extends StatelessWidget {
  final QuestionModel question;
  final void Function(int index, OptionEffect effect) onAnswerSelected;

  const QuestionOverlay({
    super.key,
    required this.question,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: Stack(
            children: [
              // Background image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/letter_bg.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              // Content overlay
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question text - takes remaining space
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          question.question,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Options - flexible wrap layout, takes minimal space
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 5.0,
                          runSpacing: 5.0,
                          alignment: WrapAlignment.center,
                          children: List.generate(question.options.length, (i) {
                            return _OptionButton(
                              index: i,
                              text: question.options[i].text,
                              onTap: () => onAnswerSelected(
                                i,
                                question.options[i].effect,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final int index;
  final String text;
  final VoidCallback onTap;

  const _OptionButton({
    required this.index,
    required this.text,
    required this.onTap,
  });

  // static const List<String> _optionLabels = [
  //   'ক',
  //   'খ',
  //   'গ',
  //   'ঘ',
  //   'ঙ',
  //   'চ',
  //   'ছ',
  //   'জ',
  // ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          border: Border.all(color: Colors.grey[400]!, width: 1.0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CircleAvatar(
            //   radius: 12,
            //   backgroundColor: const Color(0xFFe94560),
            //   child: Text(
            //     index < _optionLabels.length
            //         ? _optionLabels[index]
            //         : '${index + 1}',
            //     style: const TextStyle(
            //       color: Colors.white,
            //       fontWeight: FontWeight.bold,
            //       fontSize: 11,
            //     ),
            //   ),
            // ),
            const SizedBox(width: 0),
            Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
