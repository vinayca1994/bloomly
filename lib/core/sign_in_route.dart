/// Where a successful sign-in should land, and an optional message.
class SignInLanding {
  const SignInLanding(this.location, {this.notice});

  final String location;
  final String? notice;
}

/// A same-app path from the login `next` query. Anything else is dropped.
String? safeReturnPath(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty || !value.startsWith('/') || value.startsWith('//')) {
    return null;
  }
  if (value.contains('\\') ||
      value.contains('://') ||
      value.contains('\n') ||
      value.contains('..')) {
    return null;
  }
  final path = value.split('?').first;
  const roots = [
    '/categories',
    '/orders',
    '/account',
    '/search',
    '/cart',
    '/checkout',
    '/owner',
    '/rider',
  ];
  if (path == '/') return value;
  for (final root in roots) {
    if (path == root || path.startsWith('$root/')) return value;
  }
  return null;
}

/// Customer, owner, and rider each leave sign-in on their own screen.
SignInLanding landingAfterSignIn({
  required String? role,
  required String? next,
}) {
  final safe = safeReturnPath(next);
  if (role == 'rider') return const SignInLanding('/rider');
  if (role == 'owner') {
    if (safe != null &&
        !safe.startsWith('/owner') &&
        !safe.startsWith('/rider')) {
      return SignInLanding(safe);
    }
    if (safe != null && safe.startsWith('/owner')) return SignInLanding(safe);
    return const SignInLanding('/owner');
  }
  if (safe != null && safe.startsWith('/owner')) {
    return const SignInLanding(
      '/account',
      notice: 'The store console is for the owner account.',
    );
  }
  if (safe != null && safe.startsWith('/rider')) {
    return const SignInLanding(
      '/account',
      notice: 'Deliveries are for rider accounts.',
    );
  }
  if (safe != null) return SignInLanding(safe);
  return const SignInLanding('/');
}
