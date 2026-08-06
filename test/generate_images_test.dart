import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class BoltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF87)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.6, 0);
    path.lineTo(size.width * 0.1, size.height * 0.6);
    path.lineTo(size.width * 0.45, size.height * 0.6);
    path.lineTo(size.width * 0.3, size.height);
    path.lineTo(size.width * 0.9, size.height * 0.35);
    path.lineTo(size.width * 0.5, size.height * 0.35);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void main() {
  testWidgets('Generate Icon', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1024));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          width: 1024,
          height: 1024,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF141E30), Color(0xFF243B55)],
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 500,
              height: 600,
              child: CustomPaint(painter: BoltPainter()),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container).first,
      matchesGoldenFile('../assets/images/generated_icon.png'),
    );
  });

  testWidgets('Generate Splash Logo', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 600));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 500,
          height: 600,
          child: CustomPaint(painter: BoltPainter()),
        ),
      ),
    );
    await expectLater(
      find.byType(SizedBox).first,
      matchesGoldenFile('../assets/images/generated_splash_logo.png'),
    );
  });
}