import 'dart:convert';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

final _mobile = RegExp(r'^\+91[6-9]\d{9}$');

Future<dynamic> main(dynamic context) async {
  try {
    final body = '${context.req.body ?? ''}';
    final decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
    final phone = decoded is Map ? '${decoded['phone'] ?? ''}' : '';
    if (!_mobile.hasMatch(phone)) {
      return context.res.json({'error': 'Enter a valid 10-digit mobile number.'}, 400);
    }
    final users = Users(_client());
    final existing = await users.list(queries: [Query.equal('phone', phone), Query.limit(1)]);
    if (existing.users.isNotEmpty) {
      return context.res.json({'userId': existing.users.first.$id, 'isNew': false});
    }
    return context.res.json({'userId': ID.unique(), 'isNew': true});
  } catch (error) {
    context.error('$error');
    return context.res.json({'error': 'Could not start phone sign-in.'}, 500);
  }
}

Client _client() {
  return Client()
      .setEndpoint(Platform.environment['APPWRITE_FUNCTION_API_ENDPOINT'] ?? '')
      .setProject(Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'] ?? '')
      .setKey(
        Platform.environment['APPWRITE_FUNCTION_API_KEY'] ??
            Platform.environment['APPWRITE_API_KEY'] ??
            '',
      );
}
