# Reglas de R8/ProGuard para el build release (minify activado).
# Flutter y sus plugins ya incluyen sus propias reglas; esto solo evita
# avisos por clases opcionales de Play Core que Flutter referencia.
-dontwarn com.google.android.play.core.**
