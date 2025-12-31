class QuestionModel {
  final int id;
  final String question;
  final List<String> options;
  final int correctIndex;

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as int,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
    };
  }

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;
}

class QuestionsData {
  final List<QuestionModel> questions;

  QuestionsData({required this.questions});

  factory QuestionsData.fromJson(Map<String, dynamic> json) {
    return QuestionsData(
      questions: (json['questions'] as List)
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}
