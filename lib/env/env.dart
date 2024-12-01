import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: "RazerKey")
  static final String razerKey = _Env.razerKey;
  @EnviedField(varName: "SecretKey")
  static final String secretKey = _Env.secretKey;
}
