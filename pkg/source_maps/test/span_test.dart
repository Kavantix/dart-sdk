// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.span_test;

import 'package:unittest/unittest.dart';
import 'package:source_maps/span.dart';

const String TEST_FILE = '''
+23456789_
 +       _123456789_123456789_123456789_123456789_123456789_123456789_123456789_
  +                _123456789_1
123+56789_123456789_1234567
1234+6789_1234
12345+789_123456789_12345
123456+89_123456789_123456789_123456789_123456789_123456789_123456789_123456789
1234567+9_123456789_123456789_123456789_123456789_123456789_123456789_123
12345678+_123456789_123456789_123456789_123456789_1
123456789+123456789_123456789_12345678
123456789_+23456789_123456789_123456789_123
123456789_1+3456789_123456789
''';

List<int> newLines = TEST_FILE.split('\n').map((s) => s.length).toList();

main() {
  var file = new SourceFile.text('file', TEST_FILE);
  span(int start, int end) => file.span(start, end);
  loc(int offset) => file.location(offset);

  test('validate test input', () {
    expect(newLines,
      const [10, 80, 31, 27, 14, 25, 79, 73, 51, 38, 43, 29, 0]);
  });

  test('get line and column', () {
    line(int n) => file.getLine(n);
    col(int n) => file.getColumn(file.getLine(n), n);

    expect(line(8), 0);
    expect(line(10), 0);
    expect(line(11), 1);
    expect(line(12), 1);
    expect(line(91), 1);
    expect(line(92), 2);
    expect(line(93), 2);
    expect(col(11), 0);
    expect(col(12), 1);
    expect(col(91), 80);
    expect(col(92), 0);
    expect(col(93), 1);

    int j = 0;
    int lineOffset = 0;
    for (int i = 0; i < TEST_FILE.length; i++) {
      if (i > lineOffset + newLines[j]) {
        lineOffset += newLines[j] + 1;
        j++;
      }
      expect(line(i), j, reason: 'position: $i');
      expect(col(i), i - lineOffset, reason: 'position: $i');
    }
  });

  test('get text', () {
    // fifth line (including 4 new lines), columns 2 .. 11
    var line = 10 + 80 + 31 + 27 + 4;
    expect(file.getText(line + 2, line + 11), '34+6789_1');
  });

  test('get location message', () {
    // fifth line (including 4 new lines), columns 2 .. 11
    var line = 10 + 80 + 31 + 27 + 4;
    expect(file.getLocationMessage('the message', line + 2, line + 11),
        'file:5:3: the message\n'
        '1234+6789_1234\n'
        '  ^^^^^^^^^');
  });

  test('get location message - no file url', () {
    var line = 10 + 80 + 31 + 27 + 4;
    expect(new SourceFile.text(null, TEST_FILE).getLocationMessage(
        'the message', line + 2, line + 11),
        ':5:3: the message\n'
        '1234+6789_1234\n'
        '  ^^^^^^^^^');
  });

  test('location getters', () {
    expect(loc(8).line, 0);
    expect(loc(8).column, 8);
    expect(loc(9).line, 0);
    expect(loc(9).column, 9);
    expect(loc(8).formatString, 'file:1:9');
    expect(loc(12).line, 1);
    expect(loc(12).column, 1);
    expect(loc(95).line, 2);
    expect(loc(95).column, 3);
  });

  test('location compare', () {
    var list = [9, 8, 11, 14, 6, 6, 1, 1].map((n) => loc(n)).toList();
    list.sort();
    var lastOffset = 0;
    for (var location in list) {
      expect(location.offset, greaterThanOrEqualTo(lastOffset));
      lastOffset = location.offset;
    }
  });

  test('span getters', () {
    expect(span(8, 9).start.line, 0);
    expect(span(8, 9).start.column, 8);
    expect(span(8, 9).end.line, 0);
    expect(span(8, 9).end.column, 9);
    expect(span(8, 9).text, '9');
    expect(span(8, 9).isIdentifier, false);
    expect(span(8, 9).formatLocation, 'file:1:9');

    var line = 10 + 80 + 31 + 27 + 4;
    expect(span(line + 2, line + 11).getLocationMessage('the message'),
        'file:5:3: the message\n'
        '1234+6789_1234\n'
        '  ^^^^^^^^^');

    expect(span(12, 95).start.line, 1);
    expect(span(12, 95).start.column, 1);
    expect(span(12, 95).end.line, 2);
    expect(span(12, 95).end.column, 3);
    expect(span(12, 95).text,
        '+       _123456789_123456789_123456789_123456789_123456789_1234567'
        '89_123456789_\n  +');
    expect(span(12, 95).formatLocation, 'file:2:2');
  });

  test('span union', () {
    var union = new FileSpan.union(span(8, 9), span(12, 95));
    expect(union.start.offset, 8);
    expect(union.start.line, 0);
    expect(union.start.column, 8);
    expect(union.end.offset, 95);
    expect(union.end.line, 2);
    expect(union.end.column, 3);
    expect(union.text,
        '9_\n'
        ' +       _123456789_123456789_123456789_123456789_123456789_'
        '123456789_123456789_\n  +');
    expect(union.formatLocation, 'file:1:9');
  });

  test('span compare', () {
    var list = [span(9, 10), span(8, 9), span(11, 12), span(14, 19),
        span(6, 12), span(6, 8), span(1, 9), span(1, 2)];
    list.sort();
    var lastStart = 0;
    var lastEnd = 0;
    for (var span in list) {
      expect(span.start.offset, greaterThanOrEqualTo(lastStart));
      if (span.start.offset == lastStart) {
        expect(span.end.offset, greaterThanOrEqualTo(lastEnd));
      }
      lastStart = span.start.offset;
      lastEnd = span.end.offset;
    }
  });

  test('range check for large offsets', () {
    var start = TEST_FILE.length;
    expect(file.getLocationMessage('the message', start, start + 9),
        'file:13:1: the message\n');
  });

  group('file segment', () {
    var baseOffset = 123;
    var segmentText = TEST_FILE.substring(baseOffset, TEST_FILE.length - 100);
    var segment = new SourceFileSegment('file', segmentText, loc(baseOffset));
    sline(int n) => segment.getLine(n);
    scol(int n) => segment.getColumn(segment.getLine(n), n);
    line(int n) => file.getLine(n);
    col(int n) => file.getColumn(file.getLine(n), n);

    test('get line and column', () {
      int j = 0;
      int lineOffset = 0;
      for (int i = baseOffset; i < segmentText.length; i++) {
        if (i > lineOffset + newLines[j]) {
          lineOffset += newLines[j] + 1;
          j++;
        }
        expect(segment.location(i - baseOffset).offset, i);
        expect(segment.location(i - baseOffset).line, line(i));
        expect(segment.location(i - baseOffset).column, col(i));
        expect(segment.span(i - baseOffset).start.offset, i);
        expect(segment.span(i - baseOffset).start.line, line(i));
        expect(segment.span(i - baseOffset).start.column, col(i));

        expect(sline(i), line(i));
        expect(scol(i), col(i));
      }
    });

    test('get text', () {
      var start = 10 + 80 + 31 + 27 + 4 + 2;
      expect(segment.getText(start, start + 9), file.getText(start, start + 9));
    });

    group('location message', () {
      test('first line', () {
        var start = baseOffset + 7;
        expect(segment.getLocationMessage('the message', start, start + 2),
            file.getLocationMessage('the message', start, start + 2));
      });

      test('in a middle line', () {
        // Example from another test above:
        var start = 10 + 80 + 31 + 27 + 4 + 2;
        expect(segment.getLocationMessage('the message', start, start + 9),
            file.getLocationMessage('the message', start, start + 9));
      });

      test('last segment line', () {
        var start = segmentText.length - 4;
        expect(segment.getLocationMessage('the message', start, start + 2),
            file.getLocationMessage('the message', start, start + 2));
      });

      test('past segment, same as last segment line', () {
        var start = segmentText.length;
        expect(segment.getLocationMessage('the message', start, start + 2),
            file.getLocationMessage('the message', start, start + 2));

        start = segmentText.length + 20;
        expect(segment.getLocationMessage('the message', start, start + 2),
            file.getLocationMessage('the message', start, start + 2));
      });

      test('past segment, past its line', () {
        var start = TEST_FILE.length - 2;
        expect(file.getLocationMessage('the message', start, start + 1),
          'file:12:29: the message\n'
          '123456789_1+3456789_123456789\n'
          '                            ^');

        // TODO(sigmund): consider also fixing this and report file:10:4
        // The answer below is different because the segment parsing only knows
        // about the 10 lines it has (and nothing about the possible extra lines
        // afterwards)
        expect(segment.getLocationMessage('the message', start, start + 1),
          'file:10:112: the message\n');

        // The number 112 includes the count of extra characters past the
        // segment, which we verify here:
        var lastSegmentLineStart = segmentText.lastIndexOf('\n');
        expect(start - baseOffset - lastSegmentLineStart, 112);
      });
    });
  });

  test('span isIdentifier defaults to false', () {
    var start = new TestLocation(0);
    var end = new TestLocation(1);
    expect(new TestSpan(start, end).isIdentifier, false);
    expect(file.span(8, 9, null).isIdentifier, false);
    expect(new FixedSpan('', 8, 1, 8, isIdentifier: null).isIdentifier, false);
  });
}

class TestSpan extends Span {
  TestSpan(Location start, Location end) : super(start, end, null);
  get text => null;
}

class TestLocation extends Location {
  String get sourceUrl => '';
  TestLocation(int offset) : super(offset);
  get line => 0;
  get column => 0;
}
