// Copyright (c) 2017, the project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed
// by a Apache license that can be found in the LICENSE file.

/** Lightweight dependency injection framework for Dart. */
library dryice;

import 'dart:collection';

import 'package:reflectable/reflectable.dart';
import 'package:logging/logging.dart';

part 'src/assert_messages.dart';
part 'src/injector.dart';
part 'src/mirror_util.dart';
part 'src/module.dart';
part 'src/Registration.dart';

class InjectAnnotation extends Reflectable {
    const InjectAnnotation() : super(

        // instanceInvokeCapability,
        invokingCapability,
        reflectedTypeCapability,
        typeCapability,
        typingCapability,
        metadataCapability,
        // newInstanceCapability,
    );
}

/// Used in conjunction with [Inject] to select a specific named target for injection
class Named {
    const Named(this.name);

    final String name;
}


/// Compatibility to JSR-330
/// https://github.com/google/guice/wiki/JSR330
const InjectAnnotation inject = const InjectAnnotation();

@deprecated
const InjectAnnotation injectable = const InjectAnnotation();

