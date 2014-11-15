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

      var split = line.split("\t");

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

  ProcessResult shellSync(String command, List<String> args, {bool raw: false}) {
    return executeSync(["shell", command]..addAll(args), raw: raw);
  }

  void type(String text) {
    var words = text.split(" ");
    for (int i = 0; i < words.length; i++) {
      shellSync("input", ["text", words[i]]);
      if (i < words.length) {
        keyEvent(KeyCode.SPACE);
      }
    }
  }

  void tap(int x, int y) {
    shellSync("input", ["tap", x.toString(), y.toString()]);
  }

  void swipe(int ax, int ay, int bx, int by) {
    shellSync("input", ["swipe", ax.toString(), ay.toString(), bx.toString(), by.toString()]);
  }

  void keyEvent(int code, {bool longpress: false}) {
    var args = ["keyevent"];

    if (longpress) {
      args.add("--longpress");
    }

    args.add(code.toString());

    shellSync("input", [args]);
  }

  void press() {
    shellSync("input", ["press"]);
  }

  Future<Process> execute(List<String> args) {
    args.insertAll(0, ["-s", name]);
    return Process.start("adb", args);
  }

  List<Package> listPackages() {
    var packages = [];
    String data = shellSync("pm", ["list", "packages", "-f"]).stdout.toString();
    var lines = data.split("\n");
    for (var line in lines) {
      var split = line.split(":");
      if (split.length != 2 || split[0] != "package") {
        continue;
      }

      var parts = split[1].split("=");
      var pkg = new Package(parts[1], parts[0]);
      packages.add(pkg);
    }

    return packages;
  }

  Screenshot takeScreenshot() {
    var result = shellSync("screencap", ["-p"], raw: true);
    List<int> original = result.stdout;

    var str = "\x0D\x0A"; // Bad Stuff
    var replace = "\x0A";
    var stuff = ASCII.decode(original);
    var newStuff = stuff.replaceAll(str, replace);

    return new Screenshot(newStuff.codeUnits);
  }

  ProcessResult executeSync(List<String> args, {bool raw: false}) {
    var actual = ["-s", name];
    for (var arg in args) {
      actual.add(arg.toString());
    }
    return Process.runSync("adb", actual, stdoutEncoding: raw ? null : SYSTEM_ENCODING);
  }
}

class Screenshot {
  final List<int> data;

  Screenshot(this.data);

  void saveTo(File file) {
    file.writeAsBytesSync(data);
  }
}

class KeyCode {
  static final int POWER = 26;
  static final int UNLOCK = 82;
  static final int SPACE = 62;
}

class Package {
  final String name;
  final String path;

  Package(this.name, this.path);
}