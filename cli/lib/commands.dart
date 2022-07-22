import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_console/dart_console.dart';
import 'package:glucowar/settings.dart';
import 'package:path/path.dart' as path;
import 'package:qr/qr.dart';
import 'package:realm_dart/realm.dart';

const appName = 'glucowar';
const appDescription = 'Command line tool for the glucowar application';

/// Globals
final console = Console();
final schemaObjects = <SchemaObject>[];

late final Directory storageDirectory;
late final Settings settings;

const appIdOptionName = 'appId';
var appId = settings[appIdOptionName];

const hostOptionName = 'host';
var host = Uri.tryParse(settings[hostOptionName] ?? '::') ?? Uri.parse('https://cloud.mongodb.com');

Future<void> init() async {
  storageDirectory = await _getOrCreateAppDataDirectory(appName);
  settings = Settings(storageDirectory);
}

Future<Directory> _getOrCreateAppDataDirectory(String appName) {
  late String appDataPath;
  if (Platform.isWindows) {
    appDataPath = path.join(Platform.environment['APPDATA']!, appName);
  } else if (Platform.isMacOS) {
    appDataPath = path.join(Platform.environment['HOME']!, 'Library', 'Application Support', appName);
  } else if (Platform.isLinux) {
    appDataPath = path.join(Platform.environment['HOME']!, '.$appName');
  } else {
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
  return Directory(appDataPath).create(recursive: true);
}

class Runner extends CommandRunner<Future<void>> {
  Runner()
      : super(
          appName,
          appDescription,
          usageLineLength: console.windowWidth,
        ) {
    addCommand(BarcodeCommand());
    addCommand(AuthCommand());
    addCommand(InitCommand());
    argParser
      ..addOption(
        appIdOptionName,
        abbr: 'a',
        mandatory: appId == null,
        defaultsTo: appId,
        callback: (o) => appId = o,
      )
      ..addOption(
        hostOptionName,
        defaultsTo: host.toString(),
        callback: (o) => host = Uri.tryParse(o ?? '::') ?? host,
      );
  }
}

abstract class CommandBase extends Command<Future<void>> {}

class BarcodeCommand extends CommandBase {
  @override
  final description = 'Render QR barcode of the settings';

  @override
  final name = 'barcode';

  @override
  Future<void> run() async {
    final data = settings.toString(); // TODO: Use json
    final image = _findSmallestQrCode(data);
    if (image != null) {
      final width = image.moduleCount * 2 + 4;
      console.writeAlignedWithBackground('Type: ${image.typeNumber}  ', width: width);
      console.writeLine();
      for (var row = 0; row < image.moduleCount; row++) {
        console.drawBox(ConsoleColor.brightRed);
        for (var col = 0; col < image.moduleCount; col++) {
          console.drawBox(image.isDark(row, col) ? ConsoleColor.black : ConsoleColor.brightWhite);
        }
        console.drawBox(ConsoleColor.brightRed);
        console.writeLine();
      }
      console.writeAlignedWithBackground('Error Correction: ${QrErrorCorrectLevel.getName(image.errorCorrectLevel)}  ', width: width);
      console.writeLine();
      console.resetColorAttributes();
    }
  }
}

QrImage? _findSmallestQrCode(String data) {
  // Find lowest QR type that can contain data with maximum error correction
  for (int type = 1; type < 40; ++type) {
    for (final level in QrErrorCorrectLevel.levels.reversed) {
      final code = QrCode(type, level)..addData(data);
      try {
        return QrImage(code);
      } catch (_) {}
    }
  }
  return null;
}

extension on Console {
  void writeAlignedWithBackground(
    String text, {
    int? width,
    TextAlignment alignment = TextAlignment.right,
    ConsoleColor color = ConsoleColor.brightRed,
  }) {
    console.setBackgroundColor(color);
    console.writeAligned(text, width, alignment);
    console.resetColorAttributes();
  }

  void drawBox(ConsoleColor color) => writeAlignedWithBackground('  ', color: color);
}

class AuthCommand extends CommandBase {
  @override
  final description = 'Authenticate user';

  @override
  final name = 'auth';

  String? email;
  String? password;
  bool anonymous = false;

  AuthCommand() {
    argParser
      ..addOption('email', abbr: 'e', callback: (o) => email = o)
      ..addOption('password', abbr: 'p', callback: (o) => password = o)
      ..addFlag('anonymous', abbr: 'a', callback: (o) => anonymous = o);
  }

  @override
  Future<void> run() async {
    final app = App(AppConfiguration(appId!, baseFilePath: storageDirectory));
    Credentials credentials;
    if (anonymous) {
      credentials = Credentials.anonymous();
    } else {
      credentials = Credentials.emailPassword(email!, password!);
    }
    await app.logIn(credentials);
  }
}

class InitCommand extends CommandBase {
  @override
  final description = 'Initialize default values in settings';

  @override
  final name = 'init';

  @override
  Future<void> run() async {
    final s = settings;
    s[appIdOptionName] = appId!;
    s[hostOptionName] = host.toString();
    print(s);
  }
}
