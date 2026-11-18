import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/core/services/rep_chime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a beep that cannot play does not break the session', () async {
    // There is no audio plugin under test, exactly as when the platform
    // refuses to play: play() has to swallow that rather than throw into the
    // rep listener that called it.
    final chime = RepChime();
    await expectLater(chime.play(), completes);
    await expectLater(chime.play(), completes);
    await chime.dispose();
  });
}
