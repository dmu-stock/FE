import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gamjabi/core/api_client.dart';
import 'package:gamjabi/core/json_utils.dart';
import 'package:gamjabi/main.dart';
import 'package:gamjabi/models/watchlist_item.dart';
import 'package:gamjabi/state/app_scope.dart';
import 'package:gamjabi/state/app_state.dart';

/// Answers every request with an empty watchlist so the screens can mount
/// without reaching the network (which would leave pending timers and fail
/// the test).
AppState _testState() => AppState(
      api: ApiClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/watchlist')) {
            return http.Response.bytes(
              utf8.encode('{"discord_id":"test","count":0,"items":[]}'),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response.bytes(
            utf8.encode('{"status":"ok"}'),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

void main() {
  testWidgets('GamJabi renders main tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(state: _testState(), child: const GamJabiApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('등록'), findsOneWidget);

    await tester.tap(find.text('등록'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('자산 등록'), findsOneWidget);
  });

  group('json_utils', () {
    test('asDouble accepts ints, doubles and numeric strings', () {
      // The API types quantity/avg_buy_price as `number`, so a whole value
      // arrives as an int and `as double` would throw.
      expect(asDouble(0), 0.0);
      expect(asDouble(4), 4.0);
      expect(asDouble(219.34), 219.34);
      expect(asDouble('219.34'), 219.34);
      expect(asDouble(null), 0.0);
      expect(asDouble('nonsense', 1.5), 1.5);
    });

    test('asInt rounds non-integer numbers', () {
      expect(asInt(4.0), 4);
      expect(asInt(4.6), 5);
      expect(asInt(null, 3), 3);
    });
  });

  group('WatchlistItem', () {
    test('parses a server payload and derives cost', () {
      final item = WatchlistItem.fromJson({
        'ticker': 'nvda',
        'quantity': 4,
        'avg_buy_price': 219.34,
      });

      expect(item.ticker, 'NVDA');
      expect(item.quantity, 4.0);
      expect(item.cost, closeTo(877.36, 0.001));
      expect(item.currentPrice, isNull);
      expect(item.returnPct, isNull);
    });

    test('computes return once a price lands', () {
      final item = WatchlistItem(
        ticker: 'NVDA',
        quantity: 2,
        avgBuyPrice: 100,
      )..currentPrice = 110;

      expect(item.value, 220.0);
      expect(item.returnPct, closeTo(10.0, 0.001));
    });
  });
}
