// Smoke test básico: verifica que la app arranca y muestra la pantalla
// principal sin lanzar excepciones.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moto_taxi_app/app.dart';

void main() {
  testWidgets('La app arranca y muestra la pantalla principal',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MotoTaxiApp());
    await tester.pumpAndSettle();

    // La pantalla principal debe construirse sin errores.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
