/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

class VirtualStatics {
  const VirtualStatics({this.postfix = "s", this.flattenHierarchy = false});

  final String postfix;
  final bool flattenHierarchy;
}

/// Shorthand for [VirtualStatics] with default values.
const virtualStatics = VirtualStatics();

class Virtual {
  const Virtual();
}

/// Shorthand for [Virtual] with default values.
const virtual = Virtual();
