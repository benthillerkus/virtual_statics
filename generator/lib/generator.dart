import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:virtual_statics/virtual_statics.dart';

extension VirtualStaticsExt on VirtualStatics {
  static VirtualStatics fromAnnotation(ConstantReader annotation) => VirtualStatics(
        postfix: annotation.read("postfix").stringValue,
        flattenHierarchy: annotation.read("flattenHierarchy").boolValue,
      );
}

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
          (element, VirtualStaticsExt.fromAnnotation(annotation))
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
      if (subtypes.isEmpty) {
        throw InvalidGenerationSourceError(
          "Sealed class must have at least one subtype.",
          element: root,
          todo: "Extend or implement the sealed class.",
        );
      }

      write("/// Helper class for [");
      write(root.name);
      writeln("].");
      write("enum ");
      write(root.name);
      write(options.postfix);
      writeln(" {");
      bool first = true;
      for (final subtype in subtypes) {
        if (!first) writeln(",");
        first = false;
        write("/// Virtual statics for [");
        write(subtype.name);
        writeln("].");
        write(subtype.name.toLowerCase().substring(0, 1));
        write(subtype.name.substring(1));
      }
      writeln(";");
      writeln("}");
    }

    return buffer.toString();
  }
}
