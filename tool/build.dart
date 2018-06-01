import 'package:reflectable/reflectable_builder.dart' as builder;

const String _DEFAULT_ENTRY_POINT = "web/main.dart";

/// Builds all the xxx.reflectable.dart files
///
///     dart tool/build.dart
///
/// For tests:
///     dart tool/build.dart test/**/*.dart
main(List<String> arguments) async {
    await builder.reflectableBuild(arguments.isNotEmpty ? arguments : [ _DEFAULT_ENTRY_POINT ]);
}