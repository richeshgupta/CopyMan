# Security Policy

## Supported Versions

CopyMan is currently in active development. We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 2.1.x   | :white_check_mark: |
| 2.0.x   | :white_check_mark: |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Security Considerations

### Clipboard Data Handling

CopyMan captures and stores clipboard content locally on your device. Please be aware:

- **Sensitive Data**: Any text you copy will be stored in CopyMan's history, including passwords, API keys, or confidential information
- **Local Storage**: All clipboard data is stored in a local SQLite database at `~/.local/share/copyman/copyman.db`
- **No Cloud Sync**: Version 1.x-2.x stores data locally only—no network transmission or cloud backup
- **Persistence**: Clipboard history persists across restarts until manually deleted or auto-cleanup removes it

### Password Manager Exclusions

CopyMan includes built-in exclusions for common password managers to prevent accidental capture of credentials:

**Pre-configured exclusions:**
- 1Password
- Bitwarden
- LastPass
- KeePass / KeePassXC
- Dashlane
- Enpass
- NordPass
- RoboForm

**Customization:**
- You can add or remove app exclusions via Settings > App Exclusions
- Exclusions work by detecting the foreground application name (Linux: xdotool/xprop)
- If app detection fails, clipboard capture proceeds (fail-safe behavior)

### Data Storage

**Database Location:**
- Linux: `~/.local/share/copyman/copyman.db`
- macOS: `~/Library/Application Support/copyman/copyman.db`
- Windows: `%APPDATA%\copyman\copyman.db`

**Database Security:**
- SQLite database is stored in plaintext (no encryption in v1.x-2.x)
- Accessible only to the user account that runs CopyMan
- Standard file permissions apply (readable/writable by owner only)

**Recommendations:**
- Ensure your user account is password-protected
- Use full-disk encryption (LUKS, FileVault, BitLocker) for additional protection
- Regularly review and clear sensitive items from history
- Enable auto-cleanup (Settings > General > TTL) to automatically remove old items

### Future Security Features (Phase 3+)

Planned for future releases:
- End-to-end encryption (E2EE) for cross-device sync
- Zero-knowledge relay server
- Database encryption at rest
- Biometric authentication
- Self-hosted sync options

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in CopyMan, please report it responsibly:

### How to Report

**Please DO NOT:**
- Open a public GitHub issue for security vulnerabilities
- Discuss the vulnerability publicly before it is patched

**Instead:**
1. Email: [rgrichesh45@gmail.com](mailto:rgrichesh45@gmail.com)
2. Subject line: "CopyMan Security Vulnerability"
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Affected versions
   - Potential impact
   - Any suggested fixes (optional)

### Response Timeline

- **Initial Response**: Within 48 hours of report
- **Triage**: Within 7 days (assess severity and impact)
- **Fix Development**: Depends on severity
  - Critical: Within 7 days
  - High: Within 14 days
  - Medium: Within 30 days
  - Low: Next release cycle
- **Public Disclosure**: After patch is released and users have time to update

### Credit

We will credit security researchers who report valid vulnerabilities (unless they prefer to remain anonymous) in:
- CHANGELOG.md
- Security advisories
- Release notes

## Security Best Practices for Users

1. **Review Exclusions**: Verify password managers and sensitive apps are in the exclusion list (Settings > App Exclusions)
2. **Enable Auto-Cleanup**: Set a reasonable TTL (Time To Live) for clipboard items to auto-delete old entries
3. **Pin Sparingly**: Only pin items you trust to remain in history indefinitely
4. **Manual Cleanup**: Regularly delete sensitive items manually (right-click > Delete)
5. **Secure Your Device**: Use strong account passwords and enable full-disk encryption
6. **Keep Updated**: Install security updates promptly when released
7. **Audit History**: Periodically review your clipboard history for sensitive data leaks

## Known Limitations

- **No Encryption**: v1.x-2.x databases are stored in plaintext
- **App Detection Reliability**: Linux app detection may fail on Wayland or certain window managers (clipboard capture proceeds anyway)
- **No Remote Wipe**: If your device is lost/stolen, clipboard data remains accessible until manually deleted
- **Clipboard Injection**: CopyMan uses system clipboard APIs and is subject to any vulnerabilities in those APIs

## Compliance

- **GDPR**: CopyMan stores data locally—users control their own data
- **Data Retention**: Configurable via history limits and TTL settings
- **Right to Deletion**: Users can delete any/all clipboard items at will
- **No Analytics**: CopyMan does not collect telemetry or usage statistics

## Questions?

For non-security questions about data handling, please open a GitHub Discussion:
https://github.com/richeshgupta/CopyMan/discussions
