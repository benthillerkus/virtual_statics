import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:virtual_statics/virtual_statics.dart';

/// Generates all enums for a library.
class VirtualStaticsGenerator extends Generator {
  /// Const constructor for [VirtualStaticsGenerator].
  const VirtualStaticsGenerator();

  static const TypeChecker _virtualStaticsChecker = TypeChecker.fromRuntime(VirtualStatics);
  static const TypeChecker _virtualChecker = TypeChecker.fromRuntime(Virtual);

  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) {
    final potentialRoots = library.annotatedWith(_virtualStaticsChecker);
    if (potentialRoots.isEmpty) return null;

    final roots = [
      for (final AnnotatedElement(:annotation, :element) in potentialRoots)
        if (element case final ClassElement element when element.isSealed)
          (
            element,
            VirtualStatics(
              postfix: switch (annotation.read("postfix").stringValue) {
                "" => throw InvalidGenerationSourceError("[postfix] cannot be an empty String.", element: element),
                final postfix => postfix,
              },
              flattenHierarchy: annotation.read("flattenHierarchy").boolValue,
            )
          )
        else
          throw InvalidGenerationSourceError(
            "VirtualStatics can only be used on sealed classes.",
            element: element,
            todo: switch (element) { ClassElement() => "Make the class sealed.", _ => "Remove the annotation." },
          ),
    ];

    /// Build a type hierarchy for all classes in the library
    final hierarchy = {for (final (root, options) in roots) root: (options, <ClassElement>[])};

    for (final element in library.classes) {
      for (final MapEntry(key: root, value: (_, subtyes)) in hierarchy.entries) {
        if (element.supertype == root.thisType ||
            element.interfaces.contains(root.thisType) ||
            element.mixins.contains(root.thisType)) {
          subtyes.add(element);
        }
      }
    }

    final buffer = StringBuffer();
    final write = buffer.write;
    final writeln = buffer.writeln;

    for (final MapEntry(key: root, value: (options, subtypes)) in hierarchy.entries) {
      final virtualFields = [
        for (final field in root.fields)
          if (_virtualChecker.firstAnnotationOf(field) case final DartObject _)
            if (field.isStatic)
              field
            else
              throw InvalidGenerationSourceError(
                "Only static fields can be annotated with @virtual.",
                element: field,
                todo: "Make the field static or remove the annotation.",
              ),
      ];

      final virtualGetters = [
        for (final field in root.accessors)
          if (_virtualChecker.firstAnnotationOf(field) case final DartObject _)
            if (field.isStatic && field.isGetter)
              field
            else
              throw InvalidGenerationSourceError(
                "Only static getters can be annotated with @virtual.",
                element: field,
                todo: "Make the getter static or remove the annotation.",
              ),
      ];

      final virtualMethods = [
        for (final method in root.methods)
          if (_virtualChecker.firstAnnotationOf(method) case final DartObject _)
            if (method.isStatic)
              method
            else
              throw InvalidGenerationSourceError(
                "Only static methods can be annotated with @virtual.",
                element: method,
                todo: "Make the method static or remove the annotation.",
              ),
      ];

      if (subtypes.isEmpty) {
        throw InvalidGenerationSourceError(
          "Sealed class must have at least one subtype.",
          element: root,
          todo: "Extend or implement the sealed class.",
        );
      }

      // Check that all virtual fields and methods are implemented on each subtype.
      for (final subtype in subtypes) {
        for (final virtual in virtualFields) {
          if (subtype.getField(virtual.name) case final FieldElement field) {
            if (!field.isStatic) {
              throw InvalidGenerationSourceError(
                "Field must be static.",
                element: field,
                todo: "Make the field static.",
              );
            }
            if (virtual.isConst && !field.isConst) {
              throw InvalidGenerationSourceError(
                "Field must be const, because it's const on ${root.name}.",
                element: field,
                todo: "Either make the field const or remove the const annotation from ${root.name}.${virtual.name}.",
              );
            }
            if (field.type != virtual.type) {
              throw InvalidGenerationSourceError(
                "Field must have the same type as the virtual field on ${root.name}.",
                element: field,
                todo: "Change the type to ${virtual.type}.",
              );
            }
          } else {
            throw InvalidGenerationSourceError(
              "Subtype must have a static const field named '${virtual.name}'.",
              element: subtype,
              todo: "Add a static const field named '${virtual.name}'.",
            );
          }
        }

        for (final virtual in virtualGetters) {
          if (subtype.getGetter(virtual.name) case final PropertyAccessorElement getter) {
            if (!getter.isStatic) {
              throw InvalidGenerationSourceError(
                "Getter must be static.",
                element: getter,
              );
            }
            if (getter.returnType != virtual.returnType) {
              throw InvalidGenerationSourceError(
                "Getter must have the same return type as the virtual getter on ${root.name}.",
                element: getter,
                todo: "Change the return type to ${virtual.returnType}.",
              );
            }
          } else {
            throw InvalidGenerationSourceError(
              "Subtype must have a static getter named '${virtual.name}'.",
              element: subtype,
              todo: "Add a static getter named '${virtual.name}'.",
            );
          }
        }

        for (final virtual in virtualMethods) {
          if (subtype.getMethod(virtual.name) case final MethodElement method) {
            if (!method.isStatic) {
              throw InvalidGenerationSourceError(
                "Method must be static.",
                element: method,
              );
            }
            if (method.returnType != virtual.returnType) {
              throw InvalidGenerationSourceError(
                "Method must have the same return type as ${root.name}.${virtual.name}.",
                element: method,
                todo: "Change the return type to ${virtual.returnType}.",
              );
            }
            if (method.parameters.length != virtual.parameters.length) {
              throw InvalidGenerationSourceError(
                "Method must have the same parameters as ${root.name}.${virtual.name}.",
                element: method,
                todo: "Change the number of parameters to ${virtual.parameters.length}.",
              );
            }
            for (int i = 0; i < method.parameters.length; i++) {
              final parameter = method.parameters[i];
              final virtualParameter = virtual.parameters[i];
              if (parameter.type != virtualParameter.type) {
                throw InvalidGenerationSourceError(
                  "Parameter must have the same type as the virtual parameter on ${root.name}.",
                  element: parameter,
                  todo: "Change the type to ${virtualParameter.type}.",
                );
              }
              if (parameter.isRequiredNamed && !virtualParameter.isRequiredNamed) {
                throw InvalidGenerationSourceError(
                  "Parameter must be `required` and named.",
                  element: parameter,
                );
              }
              if (parameter.isOptionalNamed && !virtualParameter.isOptionalNamed) {
                throw InvalidGenerationSourceError(
                  "Parameter must be named.",
                  element: parameter,
                );
              }
              if (parameter.isOptionalPositional && !virtualParameter.isOptionalPositional) {
                throw InvalidGenerationSourceError(
                  "Parameter must be optional and positional.",
                  element: parameter,
                );
              }
              if (parameter.isRequiredPositional && !virtualParameter.isRequiredPositional) {
                throw InvalidGenerationSourceError(
                  "Parameter must be required and positional.",
                  element: parameter,
                );
              }
              if (parameter.isCovariant && !virtualParameter.isCovariant) {
                throw InvalidGenerationSourceError(
                  "Parameter must be covariant.",
                  element: parameter,
                );
              }
              if (parameter.isFinal && !virtualParameter.isFinal) {
                throw InvalidGenerationSourceError(
                  "Parameter must be final.",
                  element: parameter,
                );
              }
            }
          } else {
            throw InvalidGenerationSourceError(
              "Subtype must have a static method named '${virtual.name}'.",
              element: subtype,
              todo: "Add a static method named '${virtual.name}'.",
            );
          }
        }
      }

      /// Name of the generated enum
      final name = "${root.name}${options.postfix}";
      final variantNames = {
        for (final subtype in subtypes)
          subtype:
              // If the name is an acronym, like SQL, make it completely lowercase.
              subtype.name.toUpperCase() == subtype.name
                  ? subtype.name.toLowerCase()
                  // Otherwise, lowercase the first letter to achieve camelCase.
                  : "${subtype.name.toLowerCase().substring(0, 1)}${subtype.name.substring(1)}",
      };
      final hasMembers = virtualFields.isNotEmpty || virtualGetters.isNotEmpty || virtualMethods.isNotEmpty;
      final needsConstructor = hasMembers && virtualFields.any((field) => field.isConst);

      writeln("/// Helper class for [ ${root.name} ].");
      writeln("enum $name {");
      {
        // Declare variants
        bool first = true;
        for (final subtype in subtypes) {
          if (!first) writeln(",");
          first = false;
          writeln("/// Virtual statics for [${subtype.name}].");
          write(variantNames[subtype]);
          if (needsConstructor) {
            write("(");
            {
              for (final virtual in virtualFields.where((virtual) => virtual.isConst)) {
                write("${virtual.name}: ${subtype.name}.${virtual.name}, ");
              }
            }
            write(")");
          }
        }
        writeln(";");

        // Generate the constructor
        if (needsConstructor) {
          write("const $name({");
          {
            for (final virtual in virtualFields.where((virtual) => virtual.isConst)) {
              write("required this.${virtual.name},");
            }
          }
          writeln("});");
          writeln();
        }

        // Generate members
        if (hasMembers) {
          for (final virtual in virtualFields) {
            if (virtual.documentationComment != null) writeln(virtual.documentationComment);
            if (virtual.isConst) {
              writeln("final ${virtual.declaration};");
            } else {
              write("${virtual.type} get ${virtual.name} => switch (this) {");
              {
                for (final subtype in subtypes) {
                  writeln("$name.${variantNames[subtype]} => ${subtype.name}.${virtual.name},");
                }
              }
              writeln("};");
            }
              writeln();
          }

          for (final virtual in virtualGetters) {
            if (virtual.documentationComment != null) writeln(virtual.documentationComment);
            write("${virtual.returnType} get ${virtual.name} => switch (this) {");
            {
              for (final subtype in subtypes) {
                writeln("$name.${variantNames[subtype]} => ${subtype.name}.${virtual.name},");
              }
            }
            writeln("};");
            writeln();
          }

          for (final virtual in virtualMethods) {
            if (virtual.documentationComment != null) writeln(virtual.documentationComment);
            write("${virtual.returnType} ${virtual.name}(");
            final requiredPositional = <ParameterElement>[];
            final optionalPositional = <ParameterElement>[];
            final optionalNamed = <ParameterElement>[];
            final requiredNamed = <ParameterElement>[];

            for (final parameter in virtual.parameters) {
              if (parameter.isRequiredPositional) {
                requiredPositional.add(parameter);
              } else if (parameter.isOptionalPositional) {
                optionalPositional.add(parameter);
              } else if (parameter.isOptionalNamed) {
                optionalNamed.add(parameter);
              } else if (parameter.isRequiredNamed) {
                requiredNamed.add(parameter);
              }
            }

            {
              for (final parameter in requiredPositional) {
                if (parameter.isFinal) write("final ");
                write("${parameter.type} ${parameter.name}, ");
              }
              if (optionalPositional.isNotEmpty) {
                write("[");
                for (final parameter in optionalPositional) {
                  if (parameter.isFinal) write("final ");
                  write(parameter.type);
                  if (parameter.type.nullabilitySuffix == NullabilitySuffix.none) write("?");
                  write(" ${parameter.name}, ");
                }
                write("]");
              }
              if (requiredNamed.isNotEmpty || optionalNamed.isNotEmpty) {
                write("{");
                for (final parameter in requiredNamed) {
                  if (parameter.isFinal) write("final ");
                  write("required ${parameter.type} ${parameter.name}, ");
                }
                for (final parameter in optionalNamed) {
                  if (parameter.isFinal) write("final ");
                  write(parameter.type);
                  if (parameter.type.nullabilitySuffix == NullabilitySuffix.none) write("?");
                  write(" ${parameter.name}, ");
                }
                write("}");
              }
            }
            write(") => switch (this) {");
            {
              for (final subtype in subtypes) {
                writeln("$name.${variantNames[subtype]} => ${subtype.name}.${virtual.name}(");
                {
                  for (final (index, parameter) in virtual.parameters.indexed) {
                    if (parameter.isNamed) {
                      write("${parameter.name}: ");
                    }
                    write(parameter.name);
                    if (parameter.hasDefaultValue) {
                      write(
                        " ?? (${subtype.getMethod(virtual.name)!.parameters[index].defaultValueCode})",
                      );
                    }
                    write(", ");
                  }
                }
                writeln("),");
              }
            }
            writeln("};");
          }
          writeln();
        }

        // Generate the class instance -> enum variant mapper
        writeln("factory $name.fromInstance(${root.name} instance) {");
        {
          write("return switch (instance) {");
          for (final subtype in subtypes) {
            write("${subtype.name}() => ${variantNames[subtype]},");
          }
          writeln("};");
        }
        writeln("}");
      }
      writeln("}");
      writeln();

      // Generate accessor extension on root class (all subtypes can just 'inherit' it)
      writeln("/// Extension for accessing virtual statics on [ $name ].");
      writeln("extension ${name}Ext on ${root.name} {");
      {
        writeln(
          "/// Access the variant of [$name] that represents this class in the _virtual statics_ relationship with [${root.name}].",
        );
        writeln(" $name get virtuals => $name.fromInstance(this);");
      }
      writeln("}");
    }

    return buffer.toString();
  }
}
