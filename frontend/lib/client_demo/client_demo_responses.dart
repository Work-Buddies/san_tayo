import 'package:san_tayo/core/models/api_response.dart';

ApiResponse client_demo_success(String msg, [dynamic data]) {
  return ApiResponse(
    code:  1,
    title: 'Success!',
    msg:   msg,
    data:  data,
  );
}

ApiResponse client_demo_fail(String msg, {dynamic data}) {
  return ApiResponse(
    code:  0,
    title: 'Ooops!',
    msg:   msg,
    data:  data,
  );
}
