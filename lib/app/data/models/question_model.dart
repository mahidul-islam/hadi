/// Effect model for each option choice
class OptionEffect {
  final int resolve;
  final int publicPower;
  final int systemPressure;

  OptionEffect({
    required this.resolve,
    required this.publicPower,
    required this.systemPressure,
  });

  factory OptionEffect.fromJson(Map<String, dynamic> json) {
    return OptionEffect(
      resolve: json['resolve'] as int? ?? 0,
      publicPower: json['publicPower'] as int? ?? 0,
      systemPressure: json['systemPressure'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resolve': resolve,
      'publicPower': publicPower,
      'systemPressure': systemPressure,
    };
  }
}

/// Option model with text and effect
class OptionModel {
  final String text;
  final OptionEffect effect;

  OptionModel({required this.text, required this.effect});

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      text: json['text'] as String,
      effect: OptionEffect.fromJson(json['effect'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'effect': effect.toJson()};
  }
}

class QuestionModel {
  final int id;
  final String question;
  final List<OptionModel> options;

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as int,
      question: json['question'] as String,
      options: (json['options'] as List)
          .map((o) => OptionModel.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
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
