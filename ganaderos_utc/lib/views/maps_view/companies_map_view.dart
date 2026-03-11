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

  List<_CompanyMapItem> companies = [];

  // Centro aproximado de Ecuador
  static const LatLng ecuadorCenter = LatLng(-1.8312, -78.1834);

  /// Coordenadas referenciales de ciudades/parroquias del Ecuador
  static final Map<String, LatLng> _ecuadorLocations = {
    // Provincias / ciudades principales
    'quito': const LatLng(-0.1807, -78.4678),
    'guayaquil': const LatLng(-2.1700, -79.9224),
    'cuenca': const LatLng(-2.9001, -79.0059),
    'latacunga': const LatLng(-0.9352, -78.6155),
    'ambato': const LatLng(-1.2491, -78.6167),
    'riobamba': const LatLng(-1.6636, -78.6546),
    'loja': const LatLng(-3.9931, -79.2042),
    'ibarra': const LatLng(0.3517, -78.1223),
    'santo domingo': const LatLng(-0.2531, -79.1754),
    'quevedo': const LatLng(-1.0286, -79.4635),
    'portoviejo': const LatLng(-1.0546, -80.4545),
    'machala': const LatLng(-3.2581, -79.9554),
    'esmeraldas': const LatLng(0.9682, -79.6517),
    'babahoyo': const LatLng(-1.8022, -79.5344),
    'tena': const LatLng(-0.9938, -77.8129),
    'puyo': const LatLng(-1.4920, -78.0026),
    'nueva loja': const LatLng(0.0847, -76.8828),

    // Cotopaxi / UTC / zonas útiles para tu proyecto
    'salache': const LatLng(-0.9917, -78.6167),
    'mulalo': const LatLng(-0.9170, -78.6970),
    'tanicuchi': const LatLng(-0.9315, -78.7174),
    'pastocalle': const LatLng(-0.8500, -78.6333),
    'saquisili': const LatLng(-0.8399, -78.6670),
    'pujili': const LatLng(-0.9575, -78.6963),
    'pangua': const LatLng(-1.0953, -79.2260),
    'la mana': const LatLng(-0.9409, -79.2219),
    'sigchos': const LatLng(-0.6992, -78.9037),
    'salcedo': const LatLng(-1.0455, -78.5906),

    // Algunas parroquias o sectores frecuentes
    'guaytacama': const LatLng(-0.9066, -78.6437),
    'poalo': const LatLng(-0.9169, -78.5618),
    'belisario quevedo': const LatLng(-0.9810, -78.6200),
    'alaquez': const LatLng(-0.9794, -78.6686),
    'toacaso': const LatLng(-0.7758, -78.7538),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _normalize(String? text) {
    if (text == null) return '';
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  LatLng? _resolveLocation(Company c) {
    // 1) Si ya tiene coordenadas reales, usar esas
    if (c.lat != null && c.lng != null) {
      return LatLng(c.lat!, c.lng!);
    }

    // 2) Buscar por city
    final cityKey = _normalize(c.city);
    if (cityKey.isNotEmpty && _ecuadorLocations.containsKey(cityKey)) {
      return _ecuadorLocations[cityKey];
    }

    // 3) Buscar por parish
    final parishKey = _normalize(c.parish);
    if (parishKey.isNotEmpty && _ecuadorLocations.containsKey(parishKey)) {
      return _ecuadorLocations[parishKey];
    }

    // 4) Si no hay coincidencia, null
    return null;
  }

  String _buildLocationLabel(Company c) {
    if ((c.city ?? '').trim().isNotEmpty &&
        (c.parish ?? '').trim().isNotEmpty) {
      return '${c.city}, ${c.parish}';
    }
    if ((c.city ?? '').trim().isNotEmpty) return c.city!;
    if ((c.parish ?? '').trim().isNotEmpty) return c.parish!;
    return 'Ubicación no especificada';
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final all = await _repo.getAll();

      final resolved =
          all
              .map((c) {
                final point = _resolveLocation(c);
                if (point == null) return null;

                return _CompanyMapItem(
                  company: c,
                  point: point,
                  isApproximate: !(c.lat != null && c.lng != null),
                );
              })
              .whereType<_CompanyMapItem>()
              .toList();

      setState(() {
        companies = resolved;
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFE3F2FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
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
        child: Text(
          'No hay empresas con coordenadas o ubicaciones válidas de Ecuador.',
        ),
      );
    }

    final markers =
        companies.map((item) {
          return Marker(
            width: 46,
            height: 46,
            point: item.point,
            child: GestureDetector(
              onTap: () => _showCompanyPopup(item),
              child: Icon(
                Icons.location_on,
                size: 46,
                color: item.isApproximate ? Colors.orange : Colors.red,
              ),
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

  void _showCompanyPopup(_CompanyMapItem item) {
    final c = item.company;

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
                    _infoRow('Ciudad', c.city ?? '-'),
                    _infoRow('Parroquia', c.parish ?? '-'),
                    _infoRow('Ubicación usada', _buildLocationLabel(c)),
                    _infoRow(
                      'Coordenadas',
                      '${item.point.latitude.toStringAsFixed(6)}, ${item.point.longitude.toStringAsFixed(6)}',
                    ),
                    _infoRow(
                      'Tipo',
                      item.isApproximate
                          ? 'Referencia aproximada de Ecuador'
                          : 'Coordenada registrada',
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await MapsLauncher.open(
                            item.point.latitude,
                            item.point.longitude,
                          );
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
          width: 110,
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

class _CompanyMapItem {
  final Company company;
  final LatLng point;
  final bool isApproximate;

  _CompanyMapItem({
    required this.company,
    required this.point,
    required this.isApproximate,
  });
}
