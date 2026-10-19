import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

const _database = 'bloomly';

Future<dynamic> main(dynamic context) async {
  try {
    final userId = Platform.environment['APPWRITE_FUNCTION_USER_ID'] ?? '';
    if (userId.isEmpty) {
      return context.res.json({'error': 'Sign in first.'}, 400);
    }
    final client = _client();
    final users = Users(client);
    final user = await users.get(userId: userId);
    if (user.labels.contains('owner')) {
      return context.res.json({'error': 'The store owner account cannot be deleted here.'}, 400);
    }
    final tables = TablesDB(client);
    final orders = await tables.listRows(
      databaseId: _database,
      tableId: 'orders',
      queries: [Query.equal('userId', userId), Query.limit(100)],
    );
    for (final order in orders.rows) {
      final items = await tables.listRows(
        databaseId: _database,
        tableId: 'order_items',
        queries: [Query.equal('orderId', order.$id), Query.limit(100)],
      );
      for (final item in items.rows) {
        await tables.deleteRow(databaseId: _database, tableId: 'order_items', rowId: item.$id);
      }
      await tables.deleteRow(databaseId: _database, tableId: 'orders', rowId: order.$id);
    }
    final addresses = await tables.listRows(
      databaseId: _database,
      tableId: 'addresses',
      queries: [Query.equal('userId', userId), Query.limit(100)],
    );
    for (final address in addresses.rows) {
      await tables.deleteRow(databaseId: _database, tableId: 'addresses', rowId: address.$id);
    }
    try {
      await tables.deleteRow(databaseId: _database, tableId: 'profiles', rowId: userId);
    } on AppwriteException {
      // Phone accounts may not have a profile row.
    }
    await users.delete(userId: userId);
    return context.res.json({'ok': true});
  } catch (error) {
    context.error('$error');
    return context.res.json({'error': 'Could not delete the account.'}, 500);
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
