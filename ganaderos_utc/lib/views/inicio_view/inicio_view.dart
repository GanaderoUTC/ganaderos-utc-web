import 'package:flutter/material.dart';
import '../../widgets/footer.dart';
import '../../widgets/navbar.dart';
import '../../widgets/sidebar.dart';

class InicioView extends StatelessWidget {
  const InicioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      drawer: const Sidebar(),
      body: Stack(
        children: [
          // ✅ Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo_ganadero.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ✅ Overlay oscuro suave para lectura
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.28)),
          ),

          // ✅ Contenido scroll
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: const InicioContent(),
                ),
              ),
              const Footer(),
            ],
          ),
        ],
      ),
    );
  }
}

class InicioContent extends StatelessWidget {
  const InicioContent({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;
    final isTablet = w >= 700 && w < 1100;

    final maxWidth = isMobile ? double.infinity : 1100.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          children: [
            _HeroSection(isMobile: isMobile),
            const SizedBox(height: 18),

            // ✅ Cards institucionales: Quiénes somos / Misión / Visión
            _InfoCardsRow(isMobile: isMobile, isTablet: isTablet),
            const SizedBox(height: 18),

            // ✅ Sección cuidados con 3 tarjetas imagen
            const _SectionTitle(
              title: "Cuidado de vacas lecheras",
              subtitle:
                  "Buenas prácticas para mejorar bienestar animal, salud y productividad del hato.",
            ),
            const SizedBox(height: 12),
            _CareCards(isMobile: isMobile, isTablet: isTablet),

            const SizedBox(height: 18),

            // ✅ Beneficios del sistema
            const _SectionTitle(
              title: "¿Qué aporta la plataforma?",
              subtitle:
                  "Funciones pensadas para el control, registro y consulta de información ganadera.",
            ),
            const SizedBox(height: 12),
            _BenefitsGrid(isMobile: isMobile, isTablet: isTablet),

            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

/* ------------------------- HERO ------------------------- */

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  const _HeroSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 18 : 26,
        horizontal: isMobile ? 16 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.agriculture,
                  size: isMobile ? 34 : 40,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ganadería UTC",
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 30,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E2A35),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Plataforma de gestión ganadera enfocada en control, registro y consulta para producción lechera.",
                      style: TextStyle(
                        fontSize: isMobile ? 13.5 : 16,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _HeroButton(
                icon: Icons.business,
                label: "Haciendas",
                onTap: () => Navigator.pushNamed(context, '/companies'),
                isPrimary: true,
              ),
              _HeroButton(
                icon: Icons.monitor_outlined,
                label: "Estadísticas",
                onTap: () => Navigator.pushNamed(context, '/stats'),
                isPrimary: false,
              ),
              _HeroButton(
                icon: Icons.health_and_safety,
                label: "Salud Animal General",
                onTap: () => Navigator.pushNamed(context, '/checkup'),
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HeroButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.green[700] : Colors.teal[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/* ------------------------- INFO CARDS ------------------------- */

class _InfoCardsRow extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  const _InfoCardsRow({required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _InfoCardData(
        title: "¿Quiénes somos?",
        icon: Icons.groups,
        text:
            "Somos un equipo enfocado en innovación agropecuaria. Esta aplicación moderniza la gestión de fincas lecheras con herramientas de registro y consulta.",
      ),
      _InfoCardData(
        title: "Misión",
        icon: Icons.flag,
        text:
            "Desarrollar soluciones tecnológicas que fortalezcan la gestión ganadera y el bienestar animal mediante monitoreo, control y trazabilidad.",
      ),
      _InfoCardData(
        title: "Visión",
        icon: Icons.public,
        text:
            "Ser una plataforma referente en transformación digital ganadera en Latinoamérica, aportando eficiencia y mejor toma de decisiones.",
      ),
    ];

    if (isMobile) {
      return Column(
        children:
            items
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InfoCard(item: e),
                  ),
                )
                .toList(),
      );
    }

    return Row(
      children:
          items
              .map(
                (e) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _InfoCard(item: e),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _InfoCardData {
  final String title;
  final IconData icon;
  final String text;
  const _InfoCardData({
    required this.title,
    required this.icon,
    required this.text,
  });
}

class _InfoCard extends StatelessWidget {
  final _InfoCardData item;
  const _InfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: Colors.green[800]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2A35),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.text,
                  style: const TextStyle(
                    fontSize: 13.8,
                    color: Colors.black54,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------- SECTION TITLE ------------------------- */

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2A35),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.25),
          ),
        ],
      ),
    );
  }
}

/* ------------------------- CARE CARDS ------------------------- */

class _CareCards extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  const _CareCards({required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final cards = const [
      _ImageCardData(
        imagePath: 'assets/images/vaca3.png',
        title: 'Alimentación adecuada',
        description:
            'Una dieta balanceada contribuye a una producción constante y mejora el rendimiento.',
      ),
      _ImageCardData(
        imagePath: 'assets/images/vaca3.png',
        title: 'Espacios limpios',
        description:
            'Ambientes higiénicos disminuyen riesgos y favorecen el bienestar del ganado.',
      ),
      _ImageCardData(
        imagePath: 'assets/images/vaca3.png',
        title: 'Chequeos veterinarios',
        description:
            'Controles regulares permiten detectar y tratar problemas a tiempo.',
      ),
    ];

    if (isMobile) {
      return Column(
        children:
            cards
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ImageCard(item: c),
                  ),
                )
                .toList(),
      );
    }

    return Row(
      children:
          cards
              .map(
                (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _ImageCard(item: c),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _ImageCardData {
  final String imagePath;
  final String title;
  final String description;
  const _ImageCardData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class _ImageCard extends StatelessWidget {
  final _ImageCardData item;
  const _ImageCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(item.imagePath, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 16 : 17,
              color: const Color(0xFF1E2A35),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.25),
          ),
        ],
      ),
    );
  }
}

/* ------------------------- BENEFITS GRID (FIX OVERFLOW) ------------------------- */

class _BenefitsGrid extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  const _BenefitsGrid({required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _BenefitData(
        icon: Icons.assignment,
        title: "Registro organizado",
        text:
            "Guarda información de ganado, peso, salud, vacunas y recolección.",
      ),
      _BenefitData(
        icon: Icons.search,
        title: "Consulta rápida",
        text: "Acceso inmediato a reportes y datos por empresa o por animal.",
      ),
      _BenefitData(
        icon: Icons.security,
        title: "Acceso controlado",
        text: "Roles de usuario para administrar y proteger la información.",
      ),
      _BenefitData(
        icon: Icons.insights,
        title: "Mejor decisión",
        text: "Visualiza datos clave que apoyan decisiones productivas.",
      ),
    ];

    int crossAxisCount = 4;
    if (isMobile) {
      crossAxisCount = 1;
    } else if (isTablet) {
      crossAxisCount = 2;
    }

    // ✅ IMPORTANTE:
    // Ratio más pequeño => más altura.
    // Desktop antes 2.15 era MUY bajo para algunos tamaños (te daba ~95px).
    final double ratio = isMobile ? 3.3 : (isTablet ? 2.2 : 1.65);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: ratio,
      ),
      itemBuilder: (_, i) => _BenefitCard(item: items[i]),
    );
  }
}

class _BenefitData {
  final IconData icon;
  final String title;
  final String text;
  const _BenefitData({
    required this.icon,
    required this.title,
    required this.text,
  });
}

class _BenefitCard extends StatelessWidget {
  final _BenefitData item;
  const _BenefitCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final bool compactWidth = c.maxWidth < 320;

        // ✅ Cuando el Grid te da poca altura, reducimos todo.
        final bool tinyHeight = c.maxHeight < 120;

        final double pad = tinyHeight ? 10 : 14;
        final double iconPad = tinyHeight ? 8 : 10;
        final double gap1 = tinyHeight ? 8 : 12;
        final double gap2 = tinyHeight ? 2 : 4;
        final double gap3 = tinyHeight ? 4 : 6;
        final double iconSize = tinyHeight ? 20 : 24;

        return Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child:
              compactWidth
                  ? _compactContent(
                    tinyHeight: tinyHeight,
                    iconPad: iconPad,
                    iconSize: iconSize,
                    gap1: gap1,
                    gap2: gap2,
                  )
                  : _rowContent(
                    tinyHeight: tinyHeight,
                    iconPad: iconPad,
                    iconSize: iconSize,
                    gap1: gap1,
                    gap2: gap2,
                    gap3: gap3,
                  ),
        );
      },
    );
  }

  Widget _rowContent({
    required bool tinyHeight,
    required double iconPad,
    required double iconSize,
    required double gap1,
    required double gap2,
    required double gap3,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(iconPad),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.icon, size: iconSize, color: Colors.teal[800]),
        ),
        SizedBox(width: gap1),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // ✅ clave
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: tinyHeight ? 13.5 : 14.5,
                  color: const Color(0xFF1E2A35),
                ),
              ),
              SizedBox(height: gap2),
              Text(
                item.text,
                maxLines: tinyHeight ? 1 : 2, // ✅ menos líneas si no hay alto
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: tinyHeight ? 12.3 : 13.2,
                  color: Colors.black54,
                  height: 1.15,
                ),
              ),
              SizedBox(height: gap3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compactContent({
    required bool tinyHeight,
    required double iconPad,
    required double iconSize,
    required double gap1,
    required double gap2,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min, // ✅ clave
      children: [
        Container(
          padding: EdgeInsets.all(iconPad),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.icon, size: iconSize, color: Colors.teal[800]),
        ),
        SizedBox(height: gap1),
        Text(
          item.title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: tinyHeight ? 13.5 : 14.5,
            color: const Color(0xFF1E2A35),
          ),
        ),
        SizedBox(height: gap2),
        Text(
          item.text,
          textAlign: TextAlign.center,
          maxLines: tinyHeight ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: tinyHeight ? 12.3 : 13.2,
            color: Colors.black54,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}
