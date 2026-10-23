// Driver for running integration tests on the Web:
// flutter drive --driver=test_driver/integration_test.dart \
//   --target=integration_test/<file>.dart -d web-server --browser-name=chrome
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
