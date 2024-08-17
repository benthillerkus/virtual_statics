// ignore_for_file: public_member_api_docs

import 'package:virtual_statics/virtual_statics.dart';

part 'example.g.dart';

@VirtualStatics()
sealed class Thing {

}

class Animal extends Thing {}

class Plant extends Thing {}

class ExistentialDread implements Thing {}
