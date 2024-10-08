// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// VirtualStaticsGenerator
// **************************************************************************

/// Helper class for [Thing].
enum Things {
  /// Virtual statics for [Animal].
  animal(
    dbId: Animal.dbId,
    mayBeOverriden: Animal.mayBeOverriden,
    mustNotBeOverriden: Thing.mustNotBeOverriden,
  ),

  /// Virtual statics for [Plant].
  plant(
    dbId: Plant.dbId,
    mayBeOverriden: Thing.mayBeOverriden,
    mustNotBeOverriden: Thing.mustNotBeOverriden,
  ),

  /// Virtual statics for [ExistentialDread].
  existentialDread(
    dbId: ExistentialDread.dbId,
    mayBeOverriden: Thing.mayBeOverriden,
    mustNotBeOverriden: Thing.mustNotBeOverriden,
  ),

  /// Virtual statics for [Television].
  television(
    dbId: Television.dbId,
    mayBeOverriden: Thing.mayBeOverriden,
    mustNotBeOverriden: Thing.mustNotBeOverriden,
  ),

  /// Virtual statics for [Type].
  type(
    dbId: Type.dbId,
    mayBeOverriden: Thing.mayBeOverriden,
    mustNotBeOverriden: Thing.mustNotBeOverriden,
  );

  const Things({
    required this.dbId,
    required this.mayBeOverriden,
    required this.mustNotBeOverriden,
  });

  /// The database ID for this thing.
  final int dbId;

  final int mayBeOverriden;

  final int mustNotBeOverriden;

  factory Things.fromInstance(Thing instance) {
    return switch (instance) {
      Animal() => animal,
      Plant() => plant,
      ExistentialDread() => existentialDread,
      Television() => television,
      Type() => type,
    };
  }
}

/// Extension for accessing virtual statics on [Things].
extension ThingsExt on Thing {
  /// Access the variant of [Things] that represents this class in the _virtual statics_ relationship with [Thing].
  Things get virtuals => Things.fromInstance(this);
}

/// Helper class for [Television].
enum Televisions {
  /// Virtual statics for [CRT].
  crt,

  /// Virtual statics for [LCD].
  lcd;

  /// The price of the television.
  double get price => switch (this) {
        Televisions.crt => CRT.price,
        Televisions.lcd => LCD.price,
      };

  void a([
    int? b,
  ]) =>
      switch (this) {
        Televisions.crt => CRT.a(
            b ?? (0),
          ),
        Televisions.lcd => LCD.a(
            b ?? (2),
          ),
      };

  factory Televisions.fromInstance(Television instance) {
    return switch (instance) {
      CRT() => crt,
      LCD() => lcd,
    };
  }
}

/// Extension for accessing virtual statics on [Televisions].
extension TelevisionsExt on Television {
  /// Access the variant of [Televisions] that represents this class in the _virtual statics_ relationship with [Television].
  Televisions get virtuals => Televisions.fromInstance(this);
}

/// Helper class for [Postfix].
enum Postfixes {
  /// Virtual statics for [NoPostfix].
  noPostfix,

  /// Virtual statics for [S].
  s,

  /// Virtual statics for [Kind].
  kind,

  /// Virtual statics for [Type].
  type;

  /// The length of the postfix.
  int get length => switch (this) {
        Postfixes.noPostfix => Postfix.length,
        Postfixes.s => S.length,
        Postfixes.kind => Kind.length,
        Postfixes.type => Type.length,
      };

  (bool, bool?) myFunction(
    String positional, {
    Object? namedOptional,
    dynamic namedOptionalDynamic,
  }) =>
      switch (this) {
        Postfixes.noPostfix => Postfix.myFunction(
            positional,
            namedOptional: namedOptional,
            namedOptionalDynamic: namedOptionalDynamic,
          ),
        Postfixes.s => S.myFunction(
            positional,
            namedOptional: namedOptional,
            namedOptionalDynamic: namedOptionalDynamic,
          ),
        Postfixes.kind => Postfix.myFunction(
            positional,
            namedOptional: namedOptional,
            namedOptionalDynamic: namedOptionalDynamic,
          ),
        Postfixes.type => Postfix.myFunction(
            positional,
            namedOptional: namedOptional,
            namedOptionalDynamic: namedOptionalDynamic,
          ),
      };

  factory Postfixes.fromInstance(Postfix instance) {
    return switch (instance) {
      NoPostfix() => noPostfix,
      S() => s,
      Kind() => kind,
      Type() => type,
    };
  }
}

/// Extension for accessing virtual statics on [Postfixes].
extension PostfixesExt on Postfix {
  /// Access the variant of [Postfixes] that represents this class in the _virtual statics_ relationship with [Postfix].
  Postfixes get virtuals => Postfixes.fromInstance(this);
}
