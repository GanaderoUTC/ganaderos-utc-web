import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:ganaderos_utc/repositories/company_repository.dart';
import '../../models/company_models.dart';
import '../../utils/maps_launcher.dart';

class CompaniesMapView extends StatefulWidget {
  const CompaniesMapView({super.key});

  @override
  State<CompaniesMapView> createState() => _CompaniesMapViewState();
}

class _CompaniesMapViewState extends State<CompaniesMapView> {
  final CompanyRepository _repo = CompanyRepository();

  bool loading = true;
  String? error;

  List<Company> companies = [];

  // Centro aproximado de Ecuador
  static const LatLng ecuadorCenter = LatLng(-1.8312, -78.1834);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final all = await _repo.getAll();

      // Solo empresas con coordenadas
      final withCoords =
          all.where((c) => c.lat != null && c.lng != null).toList();

      setState(() {
        companies = withCoords;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudieron cargar empresas: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // ✅ Fondo verde + azul suave
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F5E9), // verde muy suave
              Color(0xFFE3F2FD), // azul muy suave
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // ✅ Barra superior interna de la vista
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Regresar al inicio',
                    icon: const Icon(Icons.home),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/inicio',
                        (_) => false,
                      );
                    },
                  ),

                  const Expanded(
                    child: Center(
                      child: Text(
                        'Mapa de Haciendas (Ecuador)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Recargar',
                  ),
                ],
              ),
            ),

            // contenido
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(error!, textAlign: TextAlign.center),
        ),
      );
    }

    if (companies.isEmpty) {
      return const Center(
        child: Text('No hay empresas con coordenadas (lat/lng).'),
      );
    }

    final markers =
        companies.map((c) {
          return Marker(
            width: 46,
            height: 46,
            point: LatLng(c.lat!, c.lng!),
            child: GestureDetector(
              onTap: () => _showCompanyPopup(c),
              child: const Icon(Icons.location_on, size: 46),
            ),
          );
        }).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: ecuadorCenter,
            initialZoom: 7,
            maxZoom: 18,
            minZoom: 5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.utc.gen.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }

  void _showCompanyPopup(Company c) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  runSpacing: 10,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.companyName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(),
                    _infoRow('Parroquia', c.parish ?? '-'),
                    _infoRow(
                      'Coordenadas',
                      '${c.lat?.toStringAsFixed(6)}, ${c.lng?.toStringAsFixed(6)}',
                    ),

                    const SizedBox(height: 6),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await MapsLauncher.open(c.lat!, c.lng!);
                          if (!ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No se pudo abrir Google Maps'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.map),
                        label: const Text('Abrir en Google Maps'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
