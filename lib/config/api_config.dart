/// Centralized API configuration for the Sindomon app.
///
/// All API calls across the app build their endpoints from [apiBaseUrl].
/// Change the backend server here — nothing else in the codebase needs to move.
///
/// The base URL can also be overridden per build without touching code, which
/// is the Flutter-native substitute for `.env` files (this project has none):
///
///   flutter build windows --dart-define=API_BASE_URL=https://staging.example.com
///
/// The override must be an `https://` URL without a trailing slash (the app
/// rejects non-https values at startup — see `main.dart` — and a trailing
/// slash would produce `//` in every `$apiBaseUrl/api/v1/...` endpoint).
///
/// Keep the production default below in sync with the deployed backend.
const String apiBaseUrl = String.fromEnvironment(
  "API_BASE_URL",
  defaultValue: "https://sindomon.cml-indonesia.com",
);
