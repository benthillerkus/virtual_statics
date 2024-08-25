// ignore_for_file: public_member_api_docs

import 'package:virtual_statics/virtual_statics.dart';

part 'example.g.dart';

@VirtualStatics(flattenHierarchy: true)
sealed class Thing {
  /// The database ID for this thing.
  @virtual
  static const dbId = 0;
}

class Animal extends Thing {
  static const dbId = 1;
}

class Plant extends Thing {
  static const dbId = 2;

  static int dbIdPlus(int other, {int another = -9, required int justAnother}) => dbId + other + another;}

class ExistentialDread implements Thing {
  static const dbId = 3;
}

@VirtualStatics()
sealed class Television extends Thing {
  static const dbId = 4;

  /// The price of the television.
  @virtual
  static double price = double.negativeInfinity;

  @virtual
  static void a([int b = 0]) {}
}

class CRT extends Television {
  static double price = 100.0;

  static void a([int b = 0]) {}

}

class LCD extends Television {
  static double price = 200.0;

  static void a([int b = 2]) {}
}

void asdf() {
  final dread = ExistentialDread();
  dread.virtuals;
}

@VirtualStatics(postfix: "es")
sealed class Postfix {
  /// The length of the postfix.
  @virtual
  static int get length => 0;
}

class S extends Postfix {
  static int get length => 1;

}

class Kind extends Postfix {
  static int get length => 4;

}

// You heard it here first: a type is a thing.
class Type extends Thing implements Postfix {
  static const dbId = 5;

  static int get length => 5;
}
