import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generator.dart';

/// Entry point for the virtual_statics builder as defined in `build.yaml`.
Builder virtualStaticsBuilder(BuilderOptions options) =>
    SharedPartBuilder(const [VirtualStaticsGenerator()], 'virtual_statics');
