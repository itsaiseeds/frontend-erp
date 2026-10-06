import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/config/app_config_keys.dart';
import 'package:frontend_erp/core/network/api_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('.env.prod loads and yields an absolute https base url', () async {
    await dotenv.load(fileName: AppConfigKeys.ENV_FILE_PROD);

    final String base = ApiConfig.baseUrl;
    debugPrint('resolved baseUrl = "$base"');

    expect(base, isNotEmpty,
        reason: 'empty baseUrl makes Dio fall back to the page origin');
    expect(base.startsWith('https://'), isTrue);
    expect(base, 'https://sai-seeds-preprod.onrender.com');
    expect(base.endsWith('/'), isFalse, reason: 'trailing slash is stripped');
  });

  test('login endpoint composes into the expected absolute URL', () async {
    await dotenv.load(fileName: AppConfigKeys.ENV_FILE_PROD);

    final composed = Uri.parse(ApiConfig.baseUrl)
        .resolve('/android/api/v1/auth/login')
        .toString();
    debugPrint('login URL = $composed');

    expect(composed, 'https://sai-seeds-preprod.onrender.com/android/api/v1/auth/login');
    expect(composed.contains('web.app'), isFalse);
  });
}
