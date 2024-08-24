/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class VirtualStatics {
  const VirtualStatics({this.postfix = "s", this.flattenHierarchy = false});

  final String postfix;
  final bool flattenHierarchy;
}

/// Shorthand for [VirtualStatics] with default values.
const virtualStatics = VirtualStatics();

@Target({TargetKind.field, TargetKind.method})
class Virtual {
  const Virtual();
}

/// Shorthand for [Virtual] with default values.
const virtual = Virtual();
