class SensitiveDetector {
  static final List<RegExp> _patterns = [
    // AWS Access Key
    RegExp(r'AKIA[0-9A-Z]{16}'),
    // GitHub tokens
    RegExp(r'gh[ps]_[A-Za-z0-9_]{36,}'),
    // SSH private key
    RegExp(r'-----BEGIN (?:RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'),
    // JWT
    RegExp(r'eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
    // Generic secret patterns (key: value or key=value)
    RegExp(r'(?:password|passwd|api_key|apikey|secret|token|access_token|private_key)\s*[:=]\s*\S+', caseSensitive: false),
    // Database connection strings with credentials
    RegExp(r'(?:mysql|postgres|postgresql|mongodb|redis)://[^:]+:[^@]+@', caseSensitive: false),
  ];

  /// Returns true if the content matches any known sensitive pattern.
  static bool isSensitive(String content) {
    for (final pattern in _patterns) {
      if (pattern.hasMatch(content)) return true;
    }
    return false;
  }
}
