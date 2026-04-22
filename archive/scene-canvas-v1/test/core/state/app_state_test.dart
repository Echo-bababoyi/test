import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zlb_elder/core/state/app_state.dart';

void main() {
  group('loginProvider', () {
    test('initial state is logged out', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(loginProvider).isLoggedIn, isFalse);
      expect(c.read(loginProvider).userName, isNull);
    });

    test('login sets isLoggedIn=true with userName', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(loginProvider.notifier).login('宇澄');
      expect(c.read(loginProvider).isLoggedIn, isTrue);
      expect(c.read(loginProvider).userName, '宇澄');
    });

    test('logout resets to logged out', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(loginProvider.notifier).login('宇澄');
      c.read(loginProvider.notifier).logout();
      expect(c.read(loginProvider).isLoggedIn, isFalse);
    });
  });

  group('loginBannerDismissedProvider', () {
    test('initial state is not dismissed', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(loginBannerDismissedProvider), isFalse);
    });

    test('dismiss() sets state to true', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(loginBannerDismissedProvider.notifier).dismiss();
      expect(c.read(loginBannerDismissedProvider), isTrue);
    });

    test('dismissed state is NOT reset by logout (session-level invariant)', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(loginProvider.notifier).login('宇澄');
      c.read(loginBannerDismissedProvider.notifier).dismiss();
      c.read(loginProvider.notifier).logout();
      // Core invariant: loginBannerDismissedProvider is independent of loginProvider
      expect(
        c.read(loginBannerDismissedProvider),
        isTrue,
        reason: 'Banner dismiss must survive logout — two providers are independent',
      );
    });
  });
}
