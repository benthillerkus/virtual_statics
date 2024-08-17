sealed class Sealed {}

class A extends Sealed {}

class B extends Sealed {}

class C extends Sealed {}

void foo(Sealed sealed) {
  final _ = switch (sealed) {
    A() => throw UnimplementedError(),
    B() => throw UnimplementedError(),
    C() => throw UnimplementedError(),
    I() => throw UnimplementedError(),
  };
}

interface class I implements Sealed {}

