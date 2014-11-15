import "package:android/android.dart";

void main() {
  var device = ADB.getDefaultDevice();

  device.type("Hello World");
}