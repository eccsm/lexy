class TranscriptionResponse {
  final String text;
  
  TranscriptionResponse({required this.text});
  
  factory TranscriptionResponse.fromJson(Map<String, dynamic> json) {
    return TranscriptionResponse(
      text: json['text'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }
}