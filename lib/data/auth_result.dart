class PhoneLoginStart {
  const PhoneLoginStart({this.userId, this.error, this.isNew = false});

  final String? userId;
  final String? error;
  final bool isNew;

  bool get ok => error == null && (userId ?? '').isNotEmpty;

  const PhoneLoginStart.failure(this.error) : userId = null, isNew = false;
}

class RecoveryStart {
  const RecoveryStart({this.userId, this.error});

  final String? userId;
  final String? error;

  bool get ok => error == null && (userId ?? '').isNotEmpty;

  const RecoveryStart.failure(this.error) : userId = null;
}
