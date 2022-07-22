import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:glucowar/commands.dart';
import 'package:realm_dart/realm.dart';

Future<void> main(List<String> arguments) async {
  try {
    await init();
    final x = await Runner().run(arguments);
    await x;
    print('bye!');
  } on UsageException catch (error) {
    print(error);
    exit(64); // Exit code 64 indicates a usage error.
  }
  Realm.shutdown();
}
