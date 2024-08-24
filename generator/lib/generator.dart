import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
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
          } else {
            throw InvalidGenerationSourceError(
              "Subtype must have a static const field named '${virtual.name}'.",
              element: subtype,
              todo: "Add a static const field named '${virtual.name}'.",
            );
          }
        }

        for (final virtual in virtualMethods) {
          if (subtype.getMethod(virtual.name) case final MethodElement method) {
            if (method.isStatic) continue;
            throw InvalidGenerationSourceError(
              "Method must be static.",
              element: method,
            );
          }
          throw InvalidGenerationSourceError(
            "Subtype must have a static method named '${virtual.name}'.",
            element: subtype,
            todo: "Add a static method named '${virtual.name}'.",
          );
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
      final hasMembers = virtualFields.isNotEmpty || virtualMethods.isNotEmpty;
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
