# Moto Taxi

Calculadora de tarifas con GPS para mototaxistas (Flutter, Android).

## Flujo de trabajo (Git)

- `main`: versión estable, de la que se genera el APK de release.
- `develop`: integración. Aquí se unen y prueban los cambios nuevos.
- `feature/...`: una rama por cambio, creada desde `develop`; se une con Pull Request.

## Comandos habituales

```bash
flutter pub get
flutter analyze
flutter test
flutter run                      # prueba en el celular
flutter build apk --release      # APK de producción (requiere android/key.properties)
```

Antes de hacer commit: agrega solo los archivos que cambiaste
(`git add <archivo>`). Evita `git add .` / `git commit -a`, porque `flutter`
puede modificar `pubspec.lock` sin que lo hayas pedido.

## Ajustes útiles

- `lib/core/constants.dart` → `forceGpsOnly`: `true` usa GPS puro; si en la calle
  tarda mucho en obtener el primer punto, ponerlo en `false` (GPS + red).
- **Calentamiento del GPS:** al abrir la app, la pantalla principal empieza a buscar
  satélites y muestra "GPS LISTO" o "BUSCANDO GPS". Se apaga solo al iniciar la
  carrera, al minimizar la app o al salir.
- La carrera en curso se guarda cada ~10 s; si la app se cierra, al abrirla
  ofrece **Reanudar** o **Descartar**.
- Mientras hay una carrera activa, Android muestra una notificación
  "Carrera en curso": es el servicio en primer plano que mantiene el GPS.
