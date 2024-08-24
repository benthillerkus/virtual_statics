// ignore_for_file: public_member_api_docs

import 'package:virtual_statics/virtual_statics.dart';

part 'example.g.dart';

@VirtualStatics(flattenHierarchy: true)
sealed class Thing {
  /// The database ID for this thing.
  @virtual
  static const dbId = 0;

  @virtual
  static void doSomething() {}
}

class Animal extends Thing {
  static const dbId = 1;

  static void doSomething() {}
}

class Plant extends Thing {
  static const dbId = 2;

  static void doSomething() {}
}

class ExistentialDread implements Thing {
  static const dbId = 3;

  static void doSomething() {}
}

@VirtualStatics()
sealed class Television extends Thing {
  static const dbId = 4;

  static void doSomething() {}

  /// The price of the television.
  @virtual
  static double price = double.negativeInfinity;
}

class CRT extends Television {
  static double price = 100.0;
}

class LCD extends Television {
  static double price = 200.0;
}

void asdf() {
  final dread = ExistentialDread();
  dread.virtuals;
}

@VirtualStatics(postfix: "es")
sealed class Postfix {}

class S extends Postfix {}

class Kind extends Postfix {}

// You heard it here first: a type is a thing.
class Type extends Thing implements Postfix {
  static const dbId = 5;

  static void doSomething() {}
}
