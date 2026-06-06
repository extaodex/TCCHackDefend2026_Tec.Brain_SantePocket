/// Permission service for desktop — no special permissions needed.
/// On Windows, TCP/UDP socket binding may be blocked by the firewall.
class PermissionService {
  static Future<bool> requestAllPermissions() async {
    // Desktop platforms don't need runtime permission requests.
    return true;
  }

  static Future<bool> hasStoragePermission() async {
    return true;
  }
}
