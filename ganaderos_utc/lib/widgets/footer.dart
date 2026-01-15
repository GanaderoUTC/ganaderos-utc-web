import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyleHeader = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14, // un poco más pequeño
    );
    final textStyleBody = const TextStyle(color: Colors.white, fontSize: 12);
    final linkStyle = const TextStyle(
      color: Colors.white,
      decoration: TextDecoration.underline,
      fontSize: 12,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 24, 240, 89),
            Color.fromARGB(255, 11, 166, 3),
            Color.fromARGB(255, 1, 236, 115),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;

              Widget content =
                  isSmallScreen
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoApp(textStyleHeader, textStyleBody),
                          const SizedBox(height: 16),
                          _contact(textStyleHeader, textStyleBody),
                          const SizedBox(height: 16),
                          _socialLinks(linkStyle, textStyleHeader),
                        ],
                      )
                      : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _infoApp(textStyleHeader, textStyleBody),
                          ),
                          Expanded(
                            flex: 3,
                            child: _contact(textStyleHeader, textStyleBody),
                          ),
                          Expanded(
                            flex: 3,
                            child: _socialLinks(linkStyle, textStyleHeader),
                          ),
                        ],
                      );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  content,
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 8),
                  const Text(
                    '© 2025 UTC GEN APP - Todos los derechos reservados',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _infoApp(TextStyle headerStyle, TextStyle bodyStyle) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UTC GEN APP', style: headerStyle),
          const SizedBox(height: 6),
          Text(
            'Aplicación de monitoreo y control de datos para la gestión inteligente de información.',
            style: bodyStyle,
          ),
        ],
      ),
    );
  }

  Widget _contact(TextStyle headerStyle, TextStyle bodyStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contacto', style: headerStyle),
          const SizedBox(height: 6),
          Text(
            'Email: comunicacion.institucional@utc.edu.ec',
            style: bodyStyle,
          ),
          Text('Tel: (593) 03 2252205 / 2252307 / 2252346', style: bodyStyle),
          Text(
            'Dirección: Av. Simón Rodríguez s/n, Barrio El Ejido, Latacunga - Ecuador.',
            style: bodyStyle,
          ),
        ],
      ),
    );
  }

  Widget _socialLinks(TextStyle linkStyle, TextStyle headerStyle) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Síguenos', style: headerStyle),
          const SizedBox(height: 6),
          _socialLinkRow(
            icon: Icons.facebook,
            label: 'Facebook',
            url: 'https://www.facebook.com/universidadtecnicadecotopaxi/',
            linkStyle: linkStyle,
          ),
          const SizedBox(height: 6),
          _socialLinkRow(
            icon: Icons.alternate_email, // icono más genérico para Twitter
            label: 'Twitter',
            url: 'https://x.com/utcCotopaxi',
            linkStyle: linkStyle,
          ),
          const SizedBox(height: 6),
          _socialLinkRow(
            icon: Icons.camera_alt,
            label: 'Instagram',
            url: 'https://www.instagram.com/utc_cotopaxi/',
            linkStyle: linkStyle,
          ),
        ],
      ),
    );
  }

  Widget _socialLinkRow({
    required IconData icon,
    required String label,
    required String url,
    required TextStyle linkStyle,
  }) {
    return InkWell(
      onTap: () => _openUrl(url),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: linkStyle),
        ],
      ),
    );
  }
}
