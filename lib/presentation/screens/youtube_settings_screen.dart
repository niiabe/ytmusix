import 'package:flutter/material.dart';
import '../../service/auth_service.dart';
import 'login_screen.dart';

class YoutubeSettingsScreen extends StatefulWidget {
  const YoutubeSettingsScreen({super.key});

  @override
  State<YoutubeSettingsScreen> createState() => _YoutubeSettingsScreenState();
}

class _YoutubeSettingsScreenState extends State<YoutubeSettingsScreen> {
  final _authService = AuthService();
  bool _hasCookies = false;

  @override
  void initState() {
    super.initState();
    _checkCookies();
  }

  Future<void> _checkCookies() async {
    final has = await _authService.hasCookies();
    setState(() => _hasCookies = has);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _buildPageHeader(context),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLoginStatus(),
                  const SizedBox(height: 24),
                  _buildLoginButton(),
                  if (_hasCookies) ...[
                    const SizedBox(height: 12),
                    _buildLogoutButton(),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Login cookies are saved locally to your device and are used to fetch your private playlists, recommendations, and library content.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF191919),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'YouTube Account',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildLoginStatus() {
    return Row(
      children: [
        Icon(
          _hasCookies ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: _hasCookies ? Colors.greenAccent : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(
          _hasCookies ? 'Logged in' : 'Not logged in',
          style: TextStyle(
            color: _hasCookies ? Colors.greenAccent : Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          if (result == true) {
            await _checkCookies();
          }
        },
        icon: const Icon(Icons.login_rounded),
        label: const Text('Login with Google'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await _authService.clearCookies();
          await _checkCookies();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: BorderSide(color: Colors.white.withAlpha(18)),
          backgroundColor: Colors.white.withAlpha(10),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('Logout'),
      ),
    );
  }
}
