import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:virtual_statics/virtual_statics.dart';

class VirtualStaticsGenerator extends Generator {
  const VirtualStaticsGenerator();

  static const TypeChecker _annotationChecker = TypeChecker.fromRuntime(VirtualStatics);

  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) {
    final potentialRoots = library.annotatedWith(_annotationChecker);
    if (potentialRoots.isEmpty) return null;

    final roots = [
      for (final AnnotatedElement(:annotation, :element) in potentialRoots)
        if (element case final ClassElement element when element.isSealed)
          (element, annotation.read("flattenHierarchy").boolValue)
        else
          throw InvalidGenerationSourceError(
            "VirtualStatics can only be used on sealed classes.",
            element: element,
            todo: switch (element) { ClassElement() => "Make the class sealed.", _ => "Remove the annotation." },
          ),
    ];

    /// Build a type hierarchy for all classes in the library
    final hierarchy = <ClassElement, List<ClassElement>>{for (final (root, _) in roots) root: []};

    for (final element in library.classes) {
      for (final MapEntry(key: root, value: subtyes) in hierarchy.entries) {
        if (element.supertype == root.thisType ||
            element.interfaces.contains(root.thisType) ||
            element.mixins.contains(root.thisType)) {
          subtyes.add(element);
        }
      }
    }

    final buffer = StringBuffer();

    for (final MapEntry(key: root, value: subtypes) in hierarchy.entries) {
      if (subtypes.isEmpty) {
        throw InvalidGenerationSourceError(
          "Sealed class must have at least one subtype.",
          element: root,
          todo: "Extend or implement the sealed class.",
        );
      }
      buffer.writeln("enum ${root.name}Kind {");
      bool first = true;
      for (final subtype in subtypes) {
        if (!first) buffer.writeln(",");
        first = false;
        buffer.write("  ");
        buffer.write(subtype.name.toLowerCase().substring(0, 1));
        buffer.write(subtype.name.substring(1));
      }
      buffer.writeln(";");
      buffer.writeln("}");
    }

    return buffer.toString();
  }
}
