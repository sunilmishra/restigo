import 'api_exception_test.dart' as api_exception_test;
import 'auth_interceptor_test.dart' as auth_interceptor_test;
import 'credential_store_test.dart' as credential_store_test;
import 'restigo_client_test.dart' as restigo_client_test;
import 'secure_storage_test.dart' as secure_storage_test;
import 'token_manager_test.dart' as token_manager_test;

void main() {
  api_exception_test.main();
  auth_interceptor_test.main();
  credential_store_test.main();
  restigo_client_test.main();
  secure_storage_test.main();
  token_manager_test.main();
}
