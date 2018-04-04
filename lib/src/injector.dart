// Copyright (c) 2017, the project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed
// by a Apache license that can be found in the LICENSE file.

part of dryice;

/// Helper for finding the right annotation
class _Annotation {
    final String name;
    final Type type;

    factory _Annotation.fromMirror(final VariableMirror variable) {

        // typed-Annotation has priority - if we have one ignore a named-Annotation
        final Type annotation = _injectionType(variable);

        // Only if we have no typed-Annotation
        final String name = annotation == null ? _injectionName(variable) : null;

        return new _Annotation._private(name, annotation);
    }

    _Annotation._private(this.name, this.type);

    /// Returns the first annotation after @inject or null if it's unannotated
    static Type _injectionType(final DeclarationMirror declaration) {
        final Object metadata = declaration.metadata.firstWhere( (final Object im) {
            //print("T ${im.reflectee}");
            return (im is! InjectAnnotation && im is! Named);

        }, orElse: () => null);

        if(metadata == null) {
            return null;
        }
        else if(metadata is InstanceMirror) {
            return metadata.runtimeType;
        }
        return metadata.runtimeType;
    }

    /** Returns name of injection or null if it's unnamed */
    static String _injectionName(final DeclarationMirror declaration) {
        var namedMirror = _namedAnnotationOf(declaration);
        if (namedMirror == null) {
            return null;
        }
        return namedMirror.name;
    }

    /** Get [Named] annotation for [declaration]. Returns null is non exists */
    static Named _namedAnnotationOf(DeclarationMirror declaration) {
        var namedMirror = declaration.metadata.firstWhere((Object im) => im is Named,
            orElse: () => null);
        if (namedMirror != null) {
            return (namedMirror as Named);
        }
        return null;
    }
}

/// Resolve types to their implementing classes
abstract class Injector {
    factory Injector([Module module = null]) => new InjectorImpl(module);

    factory Injector.fromModules(List<Module> modules) => new InjectorImpl(new _ModuleContainer(modules));

    factory Injector.fromInjectors(List<Injector> injectors) {
        var injector = new InjectorImpl();
        injectors.forEach((ijtor) =>
            ijtor.registrations.forEach((typeMirrorWrapper, registration) {
                if (!injector._registrations.containsKey(typeMirrorWrapper)) {
                    injector._registrations[typeMirrorWrapper] = registration;
                }
            })
        );
        return injector;
    }

    /// register a [type] with [named] (optional) to an implementation
    Registration register(final Type type, { final String named = null, final Type annotatedWith: null });

    /// Compatibility with di:package
    /// see [register]
    Registration bind(final Type type,  { final String named = null, final Type annotatedWith: null })
        => register(type,named: named, annotatedWith: annotatedWith);

    /// unregister a [type] and [named] (optional), returns [true] if registration has been removed
    bool unregister(final Type type, { final String named: null, final Type annotatedWith: null });

    /// Get new instance of [type] with [named] (optional) and all dependencies resolved
    dynamic getInstance(final Type type, { final String named: null, final Type annotatedWith: null });

    /// Compatibility with di:package
    /// see [getInstance]
    dynamic get(final Type type, { final String named: null, final Type annotatedWith: null })
        => getInstance(type,named: named, annotatedWith: annotatedWith);

    /// Resolve injections in existing Object (does not create a new instance)
    Object resolveInjections(Object obj);

    /// Get unmodifiable map of registrations
    Map<TypeMirrorWrapper, Registration> get registrations;

    Injector._private();
}

/// Implementation of [Injector].
class InjectorImpl extends Injector {
    final Logger _logger = new Logger('dice.InjectorImpl');

    final Map<TypeMirrorWrapper, Registration> _registrations = new Map<TypeMirrorWrapper, Registration>();

    InjectorImpl([module = null]) : super._private() {
        if (module != null) {
            module.configure();
            _registrations.addAll(module._registrations);
        }
    }

    @override
    Registration register(final Type type, { final String named: null, final Type annotatedWith: null }) {
        _validate(annotatedWith == null && named == null ? isInjectable(type) : true,
            _ASSERT_REGISTER_TYPE_NOT_MARKED(type));

        _validate(annotatedWith != null ? isInjectable(annotatedWith) : true,
            _ASSERT_REGISTER_ANNOTATION_NOT_MARKED(type,annotatedWith));

        var registration = new Registration(type);
        var typeMirrorWrapper = new TypeMirrorWrapper.fromType(type, named, annotatedWith);
        
        _registrations[typeMirrorWrapper] = registration;

        return registration;
    }

    @override
    bool unregister(final Type type, { final String named: null, final Type annotatedWith: null }) {
        
        return _removeRegistrationFor(new TypeMirrorWrapper.fromType(type, named, annotatedWith)) != null;
    }

    bool _hasRegistrationFor(final TypeMirrorWrapper tmw) => _registrations.containsKey(tmw);

    Registration _getRegistrationFor(final TypeMirrorWrapper tmw) => _registrations[tmw];

    Registration _removeRegistrationFor(final TypeMirrorWrapper tmw) {
        final Registration registration = _registrations.remove(tmw);

        // Remove reference to our instance if there is one
        registration ?._instance = null;
        
        return registration;
    }

    @override
    dynamic getInstance(final Type type, { final String named: null, final Type annotatedWith: null }) {
        _validate(annotatedWith == null && named == null ? isInjectable(type) : true,
            _ASSERT_GET_TYPE_NOT_MARKED(type));

        _validate(annotatedWith != null ? isInjectable(annotatedWith) : true,
            _ASSERT_GET_ANNOTATION_NOT_MARKED(type,annotatedWith));

        final TypeMirrorWrapper typeMirrorWrapper = new TypeMirrorWrapper.fromType(type, named, annotatedWith);
        return _getInstanceFor(typeMirrorWrapper);
    }

    @override
    Object resolveInjections(Object obj) {
        var instanceMirror = inject.reflect(obj);
        return _resolveInjections(instanceMirror);
    }

    @override
    Map<TypeMirrorWrapper, Registration> get registrations => new UnmodifiableMapView(_registrations);

    dynamic _getInstanceFor(final TypeMirrorWrapper typeMirrorWrapper) {
        //final annotationTypeMirror = annotatedWith != null ? inject.reflectType(annotatedWith) : null;
        
        if (!_hasRegistrationFor(typeMirrorWrapper)) {
//            registrations.forEach((final TypeMirrorWrapper wrapper, final Registration registration) {
//                _logger.info("Registered: ${wrapper.qualifiedName}");
//            });
//            final TypeMirrorWrapper wrapper = new TypeMirrorWrapper(tm, named, annotationTypeMirror);
//            _logger.info("QN: ${wrapper.qualifiedName}");
            
            throw new ArgumentError(
                "no instance registered for type '${typeMirrorWrapper}'!");
        }

        final registration = _getRegistrationFor(typeMirrorWrapper);

        // Check if we want a singleton
        if (registration._asSingleton && registration._instance != null) {
            // If we have one - return it
            return registration._instance;
        }

        final obj = registration._builder();
        if(obj is! Type) {
            _logger.info("obj.runtimeType: ${obj.runtimeType}");
        } else {
            _logger.info("obj.runtimeType: ${obj.runtimeType} obj: ${obj}");
//            final ClassMirror classMirror = inject.reflectType(obj);
//            final Object object = classMirror.newInstance("namedCTOR", []);
//            _logger.info(object);
            
            //classMirror.newInstance("namedCTOR", []);
        }
        final InstanceMirror im = (obj is Type) ? _newInstance(inject.reflectType(obj)) : inject.reflect(obj);

        // type is null e.g. @Named("google")
        if(im.type != null) {
            _debugType(im);
        }

        //InstanceMirror im = inject.reflect(obj);
        final instance = im.type != null ? _resolveInjections(im) : im.reflectee;

        if (registration._asSingleton) {
            // Remember the instance
            registration._instance = instance;
        }
        return instance;
    }

    void _debugType(final InstanceMirror im) {
        _logger.info("Type: ${im.type} / RT: ${im.runtimeType} / ${im.type.runtimeType}");

        final Iterable<DeclarationMirror> setters = injectableSetters(im.type);
        setters.forEach( (final DeclarationMirror setter) {
            _logger.info("Setter: ${setter.qualifiedName}");
        });

        final Iterable<DeclarationMirror> variables = injectableVariables(im.type);
        variables.forEach((final DeclarationMirror variable) {
            _logger.info("Variable: ${variable.qualifiedName}");
        });
    }

    dynamic _resolveInjections(final InstanceMirror im) {

        _injectSetters(im);
        _injectVariables(im);

        return im.reflectee;
    }

    /// create a new instance of classMirror and inject it
    InstanceMirror _newInstance(final TypeMirror typeMirror) {
        // Look for an injectable constructor
        var constructors = injectableConstructors(typeMirror).toList();

        // that has the greatest number of parameters to inject, optional included
        final MethodMirror constructor = constructors.fold(null,
                (MethodMirror previous, DeclarationMirror element) =>
                    previous == null
                        || _injectableParameters(previous).length < _injectableParameters(element).length
                            ? element : previous);

        final positionalArguments = constructor.parameters
            .where((final ParameterMirror param) => !param.hasDefaultValue && !param.isOptional)
                .map((final ParameterMirror param) {

                    final _Annotation _annotation = new _Annotation.fromMirror(param);
                    final TypeMirrorWrapper tmw = new TypeMirrorWrapper.fromType(param.reflectedType, _annotation.name, _annotation.type);

                    return _getInstanceFor(tmw);
        }).toList();

        final namedArguments = new Map<Symbol, dynamic>();
        constructor.parameters
            .where((final ParameterMirror param) => param.hasDefaultValue && !param.isOptional)
                .forEach((final ParameterMirror param)
                    => namedArguments[new Symbol(param.simpleName)] = param.defaultValue);

        constructor.parameters.forEach((final ParameterMirror pm) {
            _logger.info(" RT: ${pm.reflectedType}, DV: ${pm.hasDefaultValue}, OPT: ${pm.isOptional}");
        });
        _logger.info("Type (_newInstance) ${typeMirror}: ${typeMirror.qualifiedName}.${constructor.constructorName}(${positionalArguments},${namedArguments})");

        if(typeMirror is! ClassMirror) {
            throw "${typeMirror.qualifiedName} is not a ClassMirror";
        }
        final ClassMirror classMirror = typeMirror as ClassMirror;
        final Object instance = classMirror.newInstance(constructor.constructorName, positionalArguments , namedArguments);

        return inject.reflect(instance);
    }

    void _injectSetters(final InstanceMirror instanceMirror) {
        final Iterable<DeclarationMirror> setters = injectableSetters(instanceMirror.type);
        setters.forEach((setter) {
            var instanceToInject = _getInstanceFor(_firstParameter(setter));
            // set the resolved injection on the instance mirror we are injecting into
            instanceMirror.invokeSetter(_methodName(setter), instanceToInject);
        });
    }

    void _injectVariables(final InstanceMirror instanceMirror) {
        final Iterable<VariableMirror> variables = injectableVariables(instanceMirror.type)
            .map((final DeclarationMirror dm) => dm as VariableMirror);

        variables.forEach((final VariableMirror variable) {
            final _Annotation _annotation = new _Annotation.fromMirror(variable);
            final TypeMirrorWrapper tmw = new TypeMirrorWrapper.fromType(variable.reflectedType,  _annotation.name, _annotation.type);

            _logger.info("Meta ${variable.metadata.join()} / ${_annotation.name} / ${_annotation.type}");
            _logger.info("TMW: ${tmw}");
            _logger.info("V ${variable.qualifiedName} / ${variable.simpleName} / ${variable.reflectedType}\n");
            
            final instanceToInject = _getInstanceFor(tmw);

            // set the resolved injection on the instance mirror we are injecting into
            instanceMirror.invokeSetter(variable.simpleName, instanceToInject);
        });
    }

    /** Returns setters that can be injected */
    Iterable<DeclarationMirror> injectableSetters(final ClassMirror classMirror) {
        return injectableDeclarations(classMirror).where(_isSetter);
    }

    /** Returns variables that can be injected */
    Iterable<DeclarationMirror> injectableVariables(final ClassMirror classMirror) {
        return injectableDeclarations(classMirror).where(_isVariable);
    }

    /** Returns constructors that can be injected */
    Iterable<DeclarationMirror> injectableConstructors(final ClassMirror classMirror) {
        var constructors = injectableDeclarations(classMirror).where(_isConstructor);
        if (constructors.isEmpty) {
            // no explict injectable constructor exists use the default constructor instead
            constructors = classMirror.declarations.values.where((DeclarationMirror m) =>
            _isConstructor(m) &&
                (m as MethodMirror).parameters.isEmpty);
            if (constructors.isEmpty) {
                throw new StateError("no injectable constructors exists for ${classMirror}");
            }
        }
        return constructors;
    }

    /** Returns injectable instance members such as variables, setters, constructors that need injection */
    Iterable<DeclarationMirror> injectableDeclarations(final ClassMirror classMirror) {
        return classMirror.declarations.values.where(_isInjectable);
    }


    /** Returns true if [mirror] is annotated with [Inject] */
    bool _isInjectable(final DeclarationMirror mirror) {
        return mirror.metadata.any((final Object im) {
            return im is InjectAnnotation;
        });
    }

    /** Returns true if [declaration] is a constructor */
    bool _isConstructor(final DeclarationMirror declaration) => declaration is MethodMirror && declaration.isConstructor;

    /** Returns true if [declaration] is a variable */
    bool _isVariable(final DeclarationMirror declaration) => declaration is VariableMirror;

    /** Returns true if [declaration] is a setter */
    bool _isSetter(final DeclarationMirror declaration) => declaration is MethodMirror && declaration.isSetter;



    /** Returns method name from [MethodMirror] */
    String _methodName(final MethodMirror method) {
        var name = method.simpleName;
        var symbolName = (name[0] == "_") ? name.substring(1, name.length - 1) : name.substring(0, name.length - 1);
        // TODO fix print("name $name symbol $symbolName");
        return (symbolName);
    }

    /** Returns [TypeMirror] for first parameter_methodName(setter) in method */
    TypeMirrorWrapper _firstParameter(final MethodMirror method) => new TypeMirrorWrapper(method.parameters[0].type, null, null);

    /// Returns parameters (including optional) that can be injected
    Iterable<ParameterMirror> _injectableParameters(final MethodMirror method) {
        return method.parameters.where((final ParameterMirror pm) {
            return _hasRegistrationFor(new TypeMirrorWrapper(pm.type, null, null));
        });
    }

}
