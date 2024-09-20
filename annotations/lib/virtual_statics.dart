/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'package:meta/meta_meta.dart';

/// Annotates a `sealed class` to generate virtual statics.
/// 
/// This is done by generating a helper enum with a variant for each subtype of the annotated class.
/// 
/// With the annotation in place, members can be annotated with [Virtual] to make them available on all subtypes.
@Target({TargetKind.classType})
class VirtualStatics {
  /// Annotates that this `sealed class` should have virtual statics.
  /// 
  /// Use the [postfix] parameter to append a postfix to the generated class name.
  /// 
  /// Each member annotated with [Virtual] will be available on all subtypes.
  const VirtualStatics({this.postfix = "s"});

  /// The postfix to append to the generated class name.
  final String postfix;
}

/// Shorthand for [VirtualStatics] with default values.
const virtualStatics = VirtualStatics();

/// Control if a virtual static has to be (or can be) overridden by a subtype.
enum OverridingPolicy {
  /// The virtual static has to be overridden by each subtype.
  mustBeOverridden,
  /// The virtual static can be overridden by each subtype.
  /// If not overridden, the virtual static will be 'inherited' by subtypes (i.e. the subtypes copy or reference the parent's static).
  mayBeOverridden,
  /// The virtual static cannot be overridden by any subtype.
  /// I.e. the virtual static is 'inherited' by subtypes (i.e. the subtypes copy or reference the parent's static).
  mustNotBeOverridden;
}

/// Helper annotation to mark the members on a virtual static.
@Target({TargetKind.field, TargetKind.method, TargetKind.getter})
class Virtual {
  /// Annotate a member on a `sealed class` marked with [VirtualStatics] to prove that the static member is available on all subtypes.
  /// 
  /// Use the [overrides] parameter to control if the virtual static has to be (or can be) overridden by a subtype.
  const Virtual([this.overrides = OverridingPolicy.mustBeOverridden]);

  /// Whether the virtual static has to be overridden by a subtype.
  final OverridingPolicy overrides;
}

/// Shorthand for [Virtual] with default values.
const virtual = Virtual();

/// Shorthand for [Virtual] with [OverridingPolicy.mayBeOverridden].
const defaultVirtual = Virtual(OverridingPolicy.mayBeOverridden);

/// Shorthand for [Virtual] with [OverridingPolicy.cannotBeOverriden].
/// 
/// This is useful for virtual statics that should be available on subtypes, but cannot be overridden by them.
/// I.e. the virtual static is 'inherited' by subtypes (i.e. the subtype copy or reference the parent's static).
const finalVirtual = Virtual(OverridingPolicy.mustNotBeOverridden);
