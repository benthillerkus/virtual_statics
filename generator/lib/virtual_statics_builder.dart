/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generator.dart';


Builder virtualStaticsBuilder(BuilderOptions options) =>
    SharedPartBuilder(const [VirtualStaticsGenerator()], 'virtual_statics');
