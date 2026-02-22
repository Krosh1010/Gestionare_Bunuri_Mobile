class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Eroare de server']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Eroare de cache']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Fără conexiune la internet']);
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Eroare de autentificare']);
}

