class ApiResponse {
  final int code;
  final String title;
  final String msg;
  final dynamic data;

  ApiResponse({
    required this.code,
    required this.title,
    required this.msg,
    this.data,
  });

  factory ApiResponse.from_json(Map<String, dynamic> json) {
    return ApiResponse(
      code:  json['code'] is int ? json['code'] : int.tryParse('${json['code']}') ?? 0,
      title: json['title']?.toString() ?? 'Ooops!',
      msg:   json['msg']?.toString() ?? 'Something went wrong.',
      data:  json['data'],
    );
  }

  factory ApiResponse.error(String msg, {String title = 'Ooops!'}) {
    return ApiResponse(
      code:  0,
      title: title,
      msg:   msg,
    );
  }
}
