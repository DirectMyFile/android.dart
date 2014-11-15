part of android;

class ADB {
  ADB._();

  static Future<Device> waitForDevice() {
    return execute(["wait-for-device"]).then((process) {
      return process.exitCode;
    }).then((exitCode) {
      return exitCode == 0;
    }).then((good) {
      if (good) {
        return getDefaultDevice();
      }
    });
  }

  static Device getDefaultDevice() {
    return listDevices().first;
  }

  static Future<Process> execute(List<String> args) {
    return Process.start("adb", args);
  }

  static ProcessResult executeSync(List<String> args) {
    return Process.runSync("adb", args);
  }

  static List<Device> listDevices() {
    var devices = [];
    ProcessResult result = executeSync(["devices"]);

    String stdout = result.stdout.toString();

    var lines = stdout.split("\n");
    lines.removeAt(0);
    for (var line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }

      var split = line.split(" ");

      var name = split[0];

      devices.add(new Device(name));
    }

    return devices;
  }
}

class DeviceState {
  final String name;

  DeviceState(this.name);

  bool get isOffline => name == "offline";
  bool get isDevice => name == "device";
  bool get isBootloader => name == "bootloader";
}

class Device {
  final String name;

  Device(this.name);

  DeviceState getState() {
    return new DeviceState((executeSync(["get-state"]).stdout as String).replaceAll("\n", ""));
  }

  bool install(File file) {
    return executeSync(["install", file.absolute.path]).exitCode == 0;
  }

  Future<Process> runShell() {
    return execute(["shell"]);
  }

  Future<Process> shell(String command, List<String> args) {
    return execute(["shell", command]..addAll(args));
  }

  ProcessResult shellSync(String command, List<String> args) {
    return executeSync(["shell", command]..addAll(args));
  }

  void type(String text) {
    shellSync("input", ["text", text]);
  }

  void tap(int x, int y) {
    shellSync("input", ["tap", x.toString(), y.toString()]);
  }

  void swipe(int ax, int ay, int bx, int by) {
    shellSync("input", ["swipe", ax.toString(), ay.toString(), bx.toString(), by.toString()]);
  }

  void keyEvent(code_or_number, {bool longpress: false}) {
    var args = ["keyevent"];

    if (longpress) {
      args.add("--longpress");
    }

    args.add(code_or_number.toString());

    shellSync("input", [args]);
  }

  void press() {
    shellSync("input", ["press"]);
  }

  Future<Process> execute(List<String> args) {
    args.insertAll(0, ["-s", name]);
    return Process.start("adb", args);
  }

  ProcessResult executeSync(List<String> args) {
    args.insertAll(0, ["-s", name]);
    return Process.runSync("adb", args);
  }
}

class KeyCode {
  static final int POWER = 26;
  static final int UNLOCK = 82;
}