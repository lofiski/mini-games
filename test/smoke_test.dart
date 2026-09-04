import 'package:flutter_test/flutter_test.dart';
import 'package:mini_games/main.dart';

void main() {
  testWidgets('应用能够启动并渲染标题', (tester) async {
    await tester.pumpWidget(const MiniGamesApp());
    expect(find.text('Mini Games'), findsOneWidget);
  });
}
