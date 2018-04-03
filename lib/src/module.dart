// Copyright (c) 2017, the project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed
// by a Apache license that can be found in the LICENSE file.

part of dice;

/// Associates types with their concrete instances returned by the [Injector]
abstract class Module {
    final Logger _logger = new Logger('dice.Module');

    /// Compatibility with di:package
    Registration bind(final Type type, { final String named: null, final Type annotatedWith: null }) {
        _validate(annotatedWith == null && named == null ? isInjectable(type) : true,
            _ASSERT_REGISTER_TYPE_NOT_MARKED(type));

        _validate(annotatedWith != null ? isInjectable(annotatedWith) : true,
            _ASSERT_REGISTER_ANNOTATION_NOT_MARKED(type,annotatedWith));

        final registration = new Registration(type);
        final typeMirrorWrapper = new TypeMirrorWrapper.fromType(type, named, annotatedWith);

        _logger.fine("Register: ${typeMirrorWrapper.qualifiedName}");
        _registrations[typeMirrorWrapper] = registration;
        return registration;
    }

    /// register a [type] with [named] (optional) to an implementation
    @deprecated
    Registration register(Type type, { final String named: null, final Type annotatedWith: null })
        => bind(type,named: named, annotatedWith: annotatedWith);


    /// Configure type/instance registrations used in this module
    configure();

    /// Copies all bindings of [module] into this one.
    /// Overwriting when conflicts are found.
    void install(final Module module) {
        module.configure();
        _registrations.addAll(module._registrations);
    }

    bool _hasRegistrationFor(TypeMirror type, String name, TypeMirror annotation) =>
        _registrations.containsKey(new TypeMirrorWrapper(type, name, annotation));

    Registration _getRegistrationFor(TypeMirror type, String name, TypeMirror annotation) =>
        _registrations[new TypeMirrorWrapper(type, name, annotation)];

    final Map<TypeMirrorWrapper, Registration> _registrations = new Map<TypeMirrorWrapper, Registration>();

    @override
    bool operator ==(Object other) =>
        identical(this, other) ||
            other is Module &&
                runtimeType == other.runtimeType &&
                _registrations == other._registrations;

    @override
    int get hashCode => _registrations.hashCode;
}

/// Combines several [Module] into single one, allowing to inject
/// a class from one module into a class from another module.
class _ModuleContainer extends Module {
    final List<Module> _modules;
    
    _ModuleContainer(List<Module> this._modules);

    @override
    configure() {
        _registrations.clear();
        _modules.forEach((final Module module) {
            module.configure();
            module._registrations.forEach((final TypeMirrorWrapper tm, final Registration registration) {
                _registrations[tm] = registration;
            });
        });

        // Old version (reminder)
        // _modules.fold(_registrations, (final acc,final Module module) {
        //     module.configure();
        //     return acc..addAll(module._registrations);
        // });
    }
}
