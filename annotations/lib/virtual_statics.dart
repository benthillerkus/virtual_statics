/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class VirtualStatics {
  const VirtualStatics({this.postfix = "s", this.flattenHierarchy = false});

  /// The postfix to append to the generated class name.
  final String postfix;

  /// Whether subtypes that themselves are annotated with [VirtualStatics] should have their
  /// subtypes ("the grandchildren") be also included in the enum for this class.
  final bool flattenHierarchy;
}

/// Shorthand for [VirtualStatics] with default values.
const virtualStatics = VirtualStatics();


enum OverridingPolicy {
  hasToBeOverridden,
  inherits,
  cannotBeOverridden;
}

@Target({TargetKind.field, TargetKind.method, TargetKind.getter})
class Virtual {
  const Virtual([this.overrides = OverridingPolicy.hasToBeOverridden]);

  /// Whether the virtual static has to be overridden by a subtype.
  ///
  /// If `false`, the virtual static will be 'inherited' by subtypes (i.e. the subtype copy or reference the parent's static),
  /// and can be overridden if desired.
  final OverridingPolicy overrides;
}

/// Shorthand for [Virtual] with default values.
const virtual = Virtual();

/// Shorthand for [Virtual] with [OverridingPolicy.inherits].
const defaultVirtual = Virtual(OverridingPolicy.inherits);

/// Shorthand for [Virtual] with [OverridingPolicy.cannotBeOverriden].
/// 
/// This is useful for virtual statics that should be available on subtypes, but cannot be overridden by them.
/// I.e. the virtual static is 'inherited' by subtypes (i.e. the subtype copy or reference the parent's static).
const finalVirtual = Virtual(OverridingPolicy.cannotBeOverridden);
