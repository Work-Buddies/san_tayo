class ApiResponse {
  final int code;
  final String title;
  final String msg;
  final dynamic data;

  /// True only when the request never produced a server response (no network, timeout,
  /// unreadable body). Callers use this to tell "the server rejected me" apart from
  /// "I could not reach the server" — both of which otherwise look like code 0.
  final bool is_network_error;

  ApiResponse({
    required this.code,
    required this.title,
    required this.msg,
    this.data,
    this.is_network_error = false,
  });

  factory ApiResponse.from_json(Map<String, dynamic> json) {
    return ApiResponse(
      code:  json['code'] is int ? json['code'] : int.tryParse('${json['code']}') ?? 0,
      title: json['title']?.toString() ?? 'Ooops!',
      msg:   json['msg']?.toString() ?? 'Something went wrong.',
      data:  json['data'],
    );
  }

  factory ApiResponse.error(String msg, {String title = 'Ooops!', bool is_network_error = false}) {
    return ApiResponse(
      code:             0,
      title:            title,
      msg:              msg,
      is_network_error: is_network_error,
    );
  }
}
