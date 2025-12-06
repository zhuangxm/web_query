import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

Logger logger(String name, {Level? level}) {
  //debugPrint("create logger $name");
  final logger_ = Logger(name);
  logger_.level = level;
  return logger_;
}

const String _red = '\x1B[31m';
const String _green = '\x1B[32m';
const String _yellow = '\x1B[33m';
// final String _bold = '\x1B[1m';
const String _cyan = '\x1b[36m';
// final String _purple = '\x1B[35m';
const String _normal = '\x1B[0m';

String getLevelString(Level level) {
  switch (level) {
    case Level.SEVERE:
    case Level.SHOUT:
      return "$_red$level$_normal";
    case Level.WARNING:
      return "$_yellow$level$_normal";
    case Level.INFO:
      return "$_green$level$_normal";
    case Level.FINE:
    case Level.FINER:
    case Level.FINEST:
      return "$_cyan$level$_normal";

    default:
      return level.toString();
  }
}

void printLog(LogRecord record) {
  if (!kReleaseMode || record.level > Level.INFO) {
    // ignore: avoid_print
    print(
        '${record.time} {${getLevelString(record.level)}} [${record.loggerName}]: ${record.message}');
    if (record.error != null) debugPrint(record.error.toString());
    if (record.stackTrace != null) {
      debugPrintStack(stackTrace: record.stackTrace);
    }
  }
}

void logInit() {
  if (kReleaseMode) {
    Logger.root.level = Level.INFO;
  } else {
    Logger.root.level = Level.FINER;
  }
  hierarchicalLoggingEnabled = true;
  Logger.root.onRecord.listen(printLog);
  resetLogLevel();
}

//convenient to setup log level in debug.
void resetLogLevel() {
  if (kDebugMode) {
    Logger('main').level = Level.INFO;
    Logger('db').level = Level.INFO;
    Logger('history').level = Level.INFO;
    Logger('quark').level = Level.ALL;
    Logger('provider').level = Level.ALL;
    Logger('fvp').level = Level.INFO;
    Logger('mdk').level = Level.INFO;
    Logger('player').level = Level.ALL;
    Logger('QueryString').level = Level.INFO;
  }
}
