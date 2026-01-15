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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_ganadero.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
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
      ),
    );
  }
}

class InicioContent extends StatelessWidget {
  const InicioContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Bienvenidos a Ganadería UTC',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 14, 14, 14),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Quiénes somos
          _title('¿Quiénes somos?'),
          _paragraph(
            'Somos un equipo de profesionales apasionados por la innovación en el sector agropecuario. '
            'Nuestra aplicación ha sido desarrollada con el propósito de modernizar y optimizar la gestión '
            'de fincas ganaderas, especialmente aquellas dedicadas a la producción lechera. Trabajamos para '
            'brindar herramientas tecnológicas que permitan un seguimiento detallado del estado de salud, '
            'producción y bienestar de cada animal.',
          ),

          const SizedBox(height: 24),

          // Misión
          _title('Misión'),
          _paragraph(
            'Desarrollar soluciones tecnológicas inteligentes que fortalezcan la gestión de la producción '
            'ganadera, mejoren el bienestar animal y aumenten la rentabilidad mediante herramientas de '
            'monitoreo, análisis predictivo y trazabilidad.',
          ),

          const SizedBox(height: 24),

          // Visión
          _title('Visión'),
          _paragraph(
            'Ser la plataforma líder en Latinoamérica en transformación digital ganadera, reconocida por '
            'su impacto positivo en la eficiencia productiva y el bienestar del sector.',
          ),

          const SizedBox(height: 32),

          // Cuidado de vacas
          _title('Cuidado de las vacas lecheras'),
          const SizedBox(height: 8),

          LayoutBuilder(
            builder: (context, constraints) {
              // Diseño RESPONSIVE
              bool isSmall = constraints.maxWidth < 600;

              return isSmall
                  ? Column(
                    children: [
                      _ImageBlock(
                        imagePath: 'assets/images/vaca1.jpg',
                        title: 'Alimentación adecuada',
                        description:
                            'Una dieta balanceada es esencial para una buena producción lechera.',
                      ),
                      const SizedBox(height: 16),
                      _ImageBlock(
                        imagePath: 'assets/images/vaca3.png',
                        title: 'Espacios limpios',
                        description:
                            'Ambientes higiénicos evitan enfermedades y promueven el bienestar.',
                      ),
                      const SizedBox(height: 16),
                      _ImageBlock(
                        imagePath: 'assets/images/vaca2.png',
                        title: 'Chequeos veterinarios',
                        description:
                            'Controles regulares aseguran la salud y productividad del hato.',
                      ),
                    ],
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ImageBlock(
                          imagePath: 'assets/images/vaca1.jpg',
                          title: 'Alimentación adecuada',
                          description:
                              'Una dieta balanceada es esencial para una buena producción lechera.',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ImageBlock(
                          imagePath: 'assets/images/vaca3.png',
                          title: 'Espacios limpios',
                          description:
                              'Ambientes higiénicos evitan enfermedades y promueven el bienestar.',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ImageBlock(
                          imagePath: 'assets/images/vaca2.png',
                          title: 'Chequeos veterinarios',
                          description:
                              'Controles regulares aseguran la salud y productividad del hato.',
                        ),
                      ),
                    ],
                  );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, color: Color.fromARGB(179, 0, 0, 0)),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const _ImageBlock({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imagePath,
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color.fromARGB(179, 0, 0, 0),
          ),
        ),
      ],
    );
  }
}
