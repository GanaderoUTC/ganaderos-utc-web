import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el enlace")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),

      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45), // transparencia
      ),

      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),

          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// CONTENIDO
                  if (isMobile)
                    Column(
                      children: [
                        _info(),
                        const SizedBox(height: 6),
                        _contact(),
                        const SizedBox(height: 6),
                        _social(context),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [_info(), _contact(), _social(context)],
                    ),

                  const SizedBox(height: 6),

                  const Divider(color: Colors.white24),

                  const SizedBox(height: 4),

                  const Text(
                    "© 2025 UTC GEN APP - Todos los derechos reservados",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _info() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "UTC GEN APP",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          "Sistema de gestión ganadera.",
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _contact() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Contacto",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          "Latacunga - Ecuador",
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _social(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.facebook, color: Colors.white, size: 18),
          onPressed:
              () => _openUrl(
                context,
                "https://www.facebook.com/universidadtecnicadecotopaxi/",
              ),
        ),

        IconButton(
          icon: const Icon(
            Icons.alternate_email,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => _openUrl(context, "https://x.com/utcCotopaxi"),
        ),

        IconButton(
          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
          onPressed:
              () =>
                  _openUrl(context, "https://www.instagram.com/utc_cotopaxi/"),
        ),
      ],
    );
  }
}
