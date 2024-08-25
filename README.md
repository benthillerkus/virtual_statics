<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

# virtual statics (not really)

Overwrite static fields on sealed classes in Dart (using a generated companion enum).

## Getting started

First you'll need to add the `virtual_statics` package to your dependencies. 
Because this package is currently dependant on code generation(hopefully I'll be able to adopt macros in the future),
you'll also need to add the `virtual_statics_builder` and `build_runner` packages to your dev_dependencies.

```shell
dart pub add virtual_statics dev:virtual_statics_builder dev:build_runner
```

## Usage

Prepare your file by adding the necessary annotations and part directives. 
Then run `build_runner` to generate the code.

```shell

```dart
// myfile.dart

// Import the package
import 'package:virtual_statics/virtual_statics.dart';

// Add a part directive to the file
// Replace 'myfile' with the name of the file you're working on.
// The generated code will then be placed in 'myfile.g.dart'
part 'myfile.g.dart';

// Add the @VirtualStatics annotation to the sealed class
@virtualStatics
sealed class Animal {

  // Add the @virtual annotation to a static field that should be available in all subclasses
  @virtual
  static const dbId = 0;
}

// Make sure there is atleast one subclass
sealed class Dog extends Animal {
  // And implement the method you've marked as virtual
  // Note how you don't need to add any annotations to the subclass
  // (this is mostly because I can't use the @override annotation...)
  static const dbId = 1;
}
```

```shell
dart run build_runner build
```

If you get any errors, you may have forgotten to implement a method required by `@virtual` or have put an annotation in the wrong place.
In that case, just fix the error and retry.

## Design

You can annotate a `sealed class` with `@virtualStatics` and a static field on that class with `@virtual`.
If that class is extended or implemented by atleast one subclass, the package will generate an enum with the same name as the sealed class and a variant for each subclass.

The name of the enum can be customized by the `postFix` parameter of the `@virtualStatics` annotation.

The generated enum will have a factory method that takes an instance of a subclass of our root sealed class and returns the corresponding variant of the enum.
Additionally an extension on the root sealed class is generated that provides a `.virtuals` getter on each instance of the sealed class to access the enum variant.

Static fields, getters and methods on the root sealed class annotated with `@virtual` need to be available in all subclasses.
This can happen by either the user implementing them on each subclass (the builder will check for this)
or by the user using the `@defaultVirtual` or `@finalVirtual` annotation instead of `@virtual`,
which enable the implementation on the root sealed class to be _inherited_.

`static const` fields can be turned into fields on the enum, through the const constructor of the enum.
Everything else will be dispatched through a getter with a big `switch` expression on the enum that calls the corresponding method on the subclass. This works because `sealed classes` guarantee exhaustivity.

Default values for optional method parameters will not be copied from the implementation on the root sealed class, instead the type of the argument will be made optional.
This means that the implementation of a method on a subclass can have different default values than the method on the root sealed class.

## Additional information

If you run into more serious issues, please open an issue on the [GitHub repository](https://github.com/benthillerkus/virtual_statics).

## Development

First clone the repository and navigate to the root directory of the project.

If you are using VSCode, you can use the workspace I've already set up in [virtual_statics.code-workspace](./virtual_statics.code-workspace). If not, you'll have to wrangle with more subfolders, but if you're coming from a Java background, you should feel right at home.

This monorepo is managed using [melos](https://pub.dev/packages/melos).
Install the `melos` cli globally using:

```shell
dart pub global activate melos
```

Then run `melos bootstrap` to install all dependencies and resolve the interdependencies between the local packages.

In the future, I hope I can adopt pub _workspaces_ instead, but right now melos is the most ergonomic
solution for managing multiple packages.

### Architecture

The project is divided into 3 packages:

1. `virtual_statics` - The package that users will import into their libraries. It provides just the annotations. If I can get rid of having to use a seperate package for generation, I'll move all logic into this package.
2. `virtual_statics_builder` - The package that actually generates the code.
3. `example` - A playground / test environment.

## Acknowledgements

Yamen Abdulrahman for his [guide to writing custom build_runners](https://medium.com/@yamen.abd98/code-generator-using-flutter-source-gen-build-runner-9cc1fe0e2ff2)
