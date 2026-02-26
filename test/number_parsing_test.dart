import 'package:flutter_test/flutter_test.dart';

// Copy of parsing logic for isolated testing
String normalizePhoneNumber(String number) {
  return number.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
}

List<String> parseNumbers(String text, List<String> existingNumbers) {
  final List<String> numbers = [];
  final existingNormalized = existingNumbers.map(normalizePhoneNumber).toSet();

  final chunks = _extractChunks(text);

  for (final chunk in chunks) {
    final digitsOnly = chunk.replaceAll(RegExp(r'[^\d+]'), '');

    if (digitsOnly.length > 15) {
      final subNumbers = _splitConsecutiveNumbers(digitsOnly);
      for (final sub in subNumbers) {
        _addValidNumber(sub, numbers, existingNormalized);
      }
    } else {
      _addValidNumber(digitsOnly, numbers, existingNormalized);
    }
  }

  return numbers;
}

List<String> _extractChunks(String text) {
  if (RegExp(r'[,;\n\r]').hasMatch(text)) {
    return text
        .split(RegExp(r'[,;\n\r]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  final spaceParts = text.trim().split(RegExp(r'\s+'));
  if (spaceParts.length > 1) {
    final allLookLikeNumbers = spaceParts.every((part) {
      final digits = part.replaceAll(RegExp(r'[^\d+]'), '');
      return digits.length >= 10 && digits.length <= 15;
    });
    if (allLookLikeNumbers) {
      return spaceParts;
    }
  }

  final cleaned = text.replaceAll(RegExp(r'[^\d+]'), '');
  if (cleaned.isEmpty) return [];

  if (cleaned.length > 15) {
    return _splitConsecutiveNumbers(cleaned);
  }
  return [cleaned];
}

void _addValidNumber(
    String digitsOnly, List<String> numbers, Set<String> existingNormalized) {
  if (digitsOnly.isEmpty) return;

  String? number;

  if (RegExp(r'^\+880\d{10}$').hasMatch(digitsOnly)) {
    number = digitsOnly;
  } else if (RegExp(r'^880\d{10}$').hasMatch(digitsOnly)) {
    number = '+$digitsOnly';
  } else if (RegExp(r'^0\d{10}$').hasMatch(digitsOnly)) {
    number = digitsOnly;
  } else if (RegExp(r'^\+?\d{10,15}$').hasMatch(digitsOnly)) {
    number = digitsOnly;
  }

  if (number != null) {
    final normalized = normalizePhoneNumber(number);
    if (!existingNormalized.contains(normalized)) {
      numbers.add(number);
      existingNormalized.add(normalized);
    }
  }
}

List<String> _splitConsecutiveNumbers(String digits) {
  final List<String> results = [];
  int i = 0;

  while (i < digits.length) {
    if (digits[i] == '+' &&
        i + 14 <= digits.length &&
        digits.substring(i + 1, i + 4) == '880') {
      results.add(digits.substring(i, i + 14));
      i += 14;
    } else if (i + 13 <= digits.length &&
        digits.substring(i, i + 3) == '880') {
      results.add(digits.substring(i, i + 13));
      i += 13;
    } else if (i + 11 <= digits.length && digits[i] == '0') {
      results.add(digits.substring(i, i + 11));
      i += 11;
    } else {
      final isDigit = digits.codeUnitAt(i) >= 48 && digits.codeUnitAt(i) <= 57;
      if (digits[i] == '+' || isDigit) {
        int end = i;
        if (end < digits.length && digits[end] == '+') end++;
        while (end < digits.length &&
            digits.codeUnitAt(end) >= 48 &&
            digits.codeUnitAt(end) <= 57 &&
            end - i < 15) {
          end++;
        }
        if (end - i >= 10) {
          results.add(digits.substring(i, end));
        }
        i = end == i ? end + 1 : end;
      } else {
        i++;
      }
    }
  }

  return results;
}

void main() {
  group('Single number input', () {
    test('BD local 11-digit number', () {
      final result = parseNumbers('01687722962', []);
      expect(result, ['01687722962']);
    });

    test('BD international +880 format', () {
      final result = parseNumbers('+8801687722962', []);
      expect(result, ['+8801687722962']);
    });

    test('BD international 880 without +', () {
      final result = parseNumbers('8801687722962', []);
      expect(result, ['+8801687722962']);
    });

    test('number with dashes', () {
      final result = parseNumbers('016-8772-2962', []);
      expect(result, ['01687722962']);
    });

    test('number with spaces within', () {
      final result = parseNumbers('0168 772 2962', []);
      expect(result, ['01687722962']);
    });

    test('number with parentheses', () {
      final result = parseNumbers('(0168) 772-2962', []);
      expect(result, ['01687722962']);
    });

    test('+880 with dashes', () {
      final result = parseNumbers('+880-168-772-2962', []);
      expect(result, ['+8801687722962']);
    });

    test('rejects too short number', () {
      final result = parseNumbers('01687', []);
      expect(result, isEmpty);
    });

    test('rejects random text', () {
      final result = parseNumbers('hello world', []);
      expect(result, isEmpty);
    });

    test('empty input', () {
      final result = parseNumbers('', []);
      expect(result, isEmpty);
    });

    test('only spaces', () {
      final result = parseNumbers('   ', []);
      expect(result, isEmpty);
    });
  });

  group('Comma-separated numbers', () {
    test('two BD local numbers', () {
      final result = parseNumbers('01687722962,01712345678', []);
      expect(result, ['01687722962', '01712345678']);
    });

    test('with spaces after comma', () {
      final result = parseNumbers('01687722962, 01712345678', []);
      expect(result, ['01687722962', '01712345678']);
    });

    test('three numbers', () {
      final result = parseNumbers('01687722962,01712345678,01812345678', []);
      expect(result, ['01687722962', '01712345678', '01812345678']);
    });

    test('mixed formats with comma', () {
      final result = parseNumbers('01687722962, +8801712345678', []);
      expect(result, ['01687722962', '+8801712345678']);
    });

    test('trailing comma', () {
      final result = parseNumbers('01687722962,', []);
      expect(result, ['01687722962']);
    });

    test('leading comma', () {
      final result = parseNumbers(',01687722962', []);
      expect(result, ['01687722962']);
    });

    test('consecutive numbers in one comma chunk', () {
      final result =
          parseNumbers('0168772296201712345678, 01812345678', []);
      expect(result, ['01687722962', '01712345678', '01812345678']);
    });
  });

  group('Newline-separated numbers', () {
    test('two numbers on separate lines', () {
      final result = parseNumbers('01687722962\n01712345678', []);
      expect(result, ['01687722962', '01712345678']);
    });

    test('with empty lines', () {
      final result = parseNumbers('01687722962\n\n01712345678\n', []);
      expect(result, ['01687722962', '01712345678']);
    });

    test('mixed comma and newline', () {
      final result =
          parseNumbers('01687722962, 01712345678\n01812345678', []);
      expect(result, ['01687722962', '01712345678', '01812345678']);
    });
  });

  group('Space-separated numbers', () {
    test('two BD local numbers with space', () {
      final result = parseNumbers('01687722962 01712345678', []);
      expect(result, ['01687722962', '01712345678']);
    });

    test('three numbers with spaces', () {
      final result =
          parseNumbers('01687722962 01712345678 01812345678', []);
      expect(result, ['01687722962', '01712345678', '01812345678']);
    });

    test('international numbers with space', () {
      final result =
          parseNumbers('+8801687722962 +8801712345678', []);
      expect(result, ['+8801687722962', '+8801712345678']);
    });
  });

  group('Consecutive numbers (no separator)', () {
    test('two BD local numbers concatenated', () {
      final result = parseNumbers('0168772296201712345678', []);
      expect(result, ['01687722962', '01712345678']);
    });

    test('three BD local numbers concatenated', () {
      final result =
          parseNumbers('016877229620171234567801812345678', []);
      expect(result, ['01687722962', '01712345678', '01812345678']);
    });

    test('880 format concatenated', () {
      final result =
          parseNumbers('88016877229628801712345678', []);
      expect(result, ['+8801687722962', '+8801712345678']);
    });

    test('+880 format concatenated', () {
      final result =
          parseNumbers('+8801687722962+8801712345678', []);
      expect(result, ['+8801687722962', '+8801712345678']);
    });

    test('mixed BD local and 880 concatenated', () {
      final result =
          parseNumbers('016877229628801712345678', []);
      expect(result, ['01687722962', '+8801712345678']);
    });
  });

  group('Deduplication', () {
    test('same number pasted twice', () {
      final result =
          parseNumbers('01687722962,01687722962', []);
      expect(result, ['01687722962']);
    });

    test('skips already existing number', () {
      final result =
          parseNumbers('01687722962,01712345678', ['01687722962']);
      expect(result, ['01712345678']);
    });
  });

  group('Edge cases', () {
    test('number with dots', () {
      final result = parseNumbers('0168.772.2962', []);
      expect(result, ['01687722962']);
    });

    test('semicolon separator', () {
      final result = parseNumbers('01687722962;01712345678', []);
      expect(result, ['01687722962', '01712345678']);
    });

    test('10-digit generic number', () {
      final result = parseNumbers('1234567890', []);
      expect(result, ['1234567890']);
    });

    test('15-digit number', () {
      final result = parseNumbers('123456789012345', []);
      expect(result, ['123456789012345']);
    });

    test('16+ digits rejected as single number', () {
      // 16 digits is too long for a single phone number
      final result = parseNumbers('1234567890123456', []);
      // Should either reject or split, but not return a 16-digit number
      for (final n in result) {
        expect(n.replaceAll('+', '').length, lessThanOrEqualTo(15));
      }
    });
  });
}
