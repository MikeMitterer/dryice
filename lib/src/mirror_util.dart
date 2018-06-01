// Copyright (c) 2017, the project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed
// by a Apache license that can be found in the LICENSE file.

part of dryice;

// final Logger _logger = new Logger('dryice._validate');

/// Wrapper for [TypeMirror] to support multiple named registration for the same [Type] */
class TypeMirrorWrapper {
    /// Unique name that represents the combination of Type, name annotation where
    /// name and annotation is optional
    final String qualifiedName;

    factory TypeMirrorWrapper(final TypeMirror typeMirror, final String named, final TypeMirror annotationTypeMirror) {
        return new TypeMirrorWrapper._internal(
            TypeMirrorWrapper._createQualifiedName(typeMirror.qualifiedName, named, annotationTypeMirror)
        );
    }

    factory TypeMirrorWrapper.fromType(final Type type, final String named, final Type annotationType) {
        return new TypeMirrorWrapper._internal(
            TypeMirrorWrapper._createQualifiedName(
                inject.canReflectType(type) ? inject.reflectType(type).qualifiedName : type.toString(),
                named,
                (annotationType != null ? inject.reflectType(annotationType) : null))
        );
    }

    get hashCode => qualifiedName.hashCode;

    bool operator ==(final Object other) => other is TypeMirrorWrapper
          && this.qualifiedName == other.qualifiedName;

    // private CTOR
    TypeMirrorWrapper._internal(this.qualifiedName);

    static String _createQualifiedName(final String qualifiedName, final String named, final TypeMirror annotationType) {
        return qualifiedName
            + (named != null ? "[N]$named[/N]" : "")
            + (annotationType != null ? "[A]${(annotationType.qualifiedName)}[/A]" : "");
    }

    @override
    String toString() => qualifiedName;
}

// helpers
String symbolAsString(final Symbol symbol) => symbol.toString();

Symbol stringAsSymbol(final String string) => new Symbol(string);

bool isInjectable(final Type type) {
    final List<Object> metadata = inject.reflectType(type).metadata;
//    metadata.forEach((final Object object) {
//        _logger.info(object.runtimeType);
//    });

    final bool hasAnnotation = metadata.firstWhere((final Object object) => object is InjectAnnotation,orElse: null) != null;
//    _logger.info("Has Annotation $hasAnnotation");
    
    return hasAnnotation;
}

/// Makes some basic validation checks.
/// if [codition] is false an [ArgumentError] is thrown
/// 
/// [assert] does not work for this because it is always off by default
/// See: https://github.com/dart-lang/pub/issues/932
void _validate(final bool condition,final String message) {
    if(!condition) {
        throw new ArgumentError(message);
    }
}
