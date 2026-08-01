import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_app/features/voice/data/jarvis_tts.dart';

void main() {
  group('JarvisTts.sanitizeForSpeech', () {
    test('keeps the link text and drops the URL', () {
      // Regression guard: with String.replaceAll, the r"$1" replacement is
      // taken literally, so this used to come out as "See dollar-one for
      // details" instead of the link text.
      expect(
        JarvisTts.sanitizeForSpeech('See [the docs](https://example.com/x) for details'),
        'See the docs for details',
      );
    });

    test('replaces bare URLs with a spoken placeholder', () {
      expect(
        JarvisTts.sanitizeForSpeech('Source: https://example.com/a/b?c=1'),
        'Source: a link',
      );
    });

    test('removes fenced code blocks entirely', () {
      expect(
        JarvisTts.sanitizeForSpeech('Before ```dart\nvoid main() {}\n``` after'),
        'Before after',
      );
    });

    test('strips inline markdown emphasis characters', () {
      expect(
        JarvisTts.sanitizeForSpeech('**Bold** and _italic_ and `code` and # head'),
        'Bold and italic and code and head',
      );
    });

    test('collapses whitespace and trims', () {
      expect(JarvisTts.sanitizeForSpeech('  a\n\n  b\t c  '), 'a b c');
    });

    test('returns empty string for empty or whitespace-only input', () {
      expect(JarvisTts.sanitizeForSpeech(''), '');
      expect(JarvisTts.sanitizeForSpeech('   \n '), '');
    });

    test('leaves ordinary prose untouched', () {
      const prose = 'Good evening. All systems are operational.';
      expect(JarvisTts.sanitizeForSpeech(prose), prose);
    });
  });
}
