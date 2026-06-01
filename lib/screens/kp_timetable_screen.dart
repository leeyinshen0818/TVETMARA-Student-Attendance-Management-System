import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/kp_timetable_service.dart';

class KpTimetableScreen extends StatefulWidget {
  final AppUser kpUser;

  const KpTimetableScreen({super.key, required this.kpUser});

  @override
  State<KpTimetableScreen> createState() => _KpTimetableScreenState();
}

class _KpTimetableScreenState extends State<KpTimetableScreen> {
  late KpTimetableService _service;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = KpTimetableService(currentKpOops: widget.kpUser);
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_service.isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xff1a73e8)),
        ),
      );
    }

    // Mengambil semua slot untuk dipaparkan dalam bentuk jadual baris demi baris
    // (Anda boleh menapis senarai ini menggunakan _searchController.text sekiranya perlu)
    final allSlots = _service.availableSections.expand((section) {
      // Mengumpulkan semua slot daripada kombinasi hari (1-5) dan period (1-8) sebagai sandaran data
      final List<TimetableSlot> slots = [];
      final List<String> days = ['ISNIN', 'SELASA', 'RABU', 'KHAMIS', 'JUMAAT'];
      for (var day in days) {
        for (var period = 1; period <= 8; period++) {
          slots.addAll(_service.getFilteredSlotsForCell(day, period));
        }
      }
      return slots;
    }).toSet().toList(); // Memastikan slot adalah unik

    return Container(
      color: const Color(0xfff8fafc), // Latar belakang aplikasi web yang bersih
      width: double.infinity,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Jadual Program',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff202124),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            // 1. TOP ROW: Summary Cards Block
            _buildSummaryCards(allSlots.length),
            const SizedBox(height: 20),

            // 2. MIDDLE ROW: Unified Filters Section
            _buildFiltersCard(),
            const SizedBox(height: 24),

            // 3. BOTTOM SECTION: Official Timetable Slots Table
            _buildOfficialTimetableTable(allSlots),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 1. Blok Ringkasan Metrik (3-Column Summary Cards)
  Widget _buildSummaryCards(int totalSlotsCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Menggunakan GridView berasaskan nisbah lebar untuk susun atur responsif
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: constraints.maxWidth > 600 ? 3 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth > 600 ? 3.5 : 4,
          children: [
            _buildMetricCard('TOTAL SLOTS', totalSlotsCount.toString(), Colors.blue.shade700),
            _buildMetricCard('REPLACEMENT', '0', Colors.orange.shade700),
            _buildMetricCard('SECTION', _service.availableSections.length.toString(), Colors.purple.shade700),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffdadce0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xff70757a),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff202124),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Kad Penapis Bersepadu (Filters Section)
  Widget _buildFiltersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffdadce0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Penapis
          Row(
            children: [
              const Icon(Icons.tune, color: Color(0xff1a73e8), size: 20),
              const SizedBox(width: 8),
              const Spacer(),
              Text(
                'Program: ${_service.currentKpOops.programId ?? 'N/A'}',
                style: const TextStyle(fontSize: 13, color: Color(0xff5f6368), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xfff1f3f4), height: 1),
          ),
          // Baris Input Penapis (Responsif)
          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 750;
              return isDesktop
                  ? Row(
                      children: [
                        Expanded(child: _buildCourseDropdown()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSectionDropdown()),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: _buildSearchBar()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildCourseDropdown(),
                        const SizedBox(height: 12),
                        _buildSectionDropdown(),
                        const SizedBox(height: 12),
                        _buildSearchBar(),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kursus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff5f6368))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xffdadce0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: 'SEMUA KURSUS',
              items: const [
                DropdownMenuItem(value: 'SEMUA KURSUS', child: Text('SEMUA KURSUS')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Seksyen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff5f6368))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xffdadce0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _service.selectedSection,
              dropdownColor: Colors.white,
              items: _service.availableSections.map((String section) {
                return DropdownMenuItem<String>(
                  value: section,
                  child: Text(section),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  _service.changeSection(val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Carian Pantas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff5f6368))),
        const SizedBox(height: 6),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Kod, subjek, bilik',
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xffa0a0a0)),
            prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xff5f6368)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffdadce0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffdadce0)),
            ),
          ),
          onChanged: (value) {
            setState(() {}); // Mengemas kini UI berdasarkan penapis teks semata-mata
          },
        ),
      ],
    );
  }

  /// 3. Jadual Slot Jadual Waktu Rasmi (Official Timetable Slots Table)
  /// 3. Jadual Slot Jadual Waktu Rasmi (Official Timetable Slots Table)
  Widget _buildOfficialTimetableTable(List<TimetableSlot> slots) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffdadce0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            spreadRadius: 2,
            blurRadius: 8,
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Pengepala Biru Gelap
          Container(
            color: const Color(0xff0f2027),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JADUAL WAKTU SEMESTER SESI 2025/2026',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'PAPARAN SLOT JADUAL',
                  style: TextStyle(
                    color: Color(0xff94a3b8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // PERBETULAN LEBAR: Menggunakan LayoutBuilder & SizedBox untuk memenuhi ruang desktop sepenuhnya
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  // Memaksa lebar jadual mengikut saiz maksimum skrin desktop/parent widget
                  width: constraints.maxWidth > 1000 ? constraints.maxWidth : 1100,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xfff5f5f0)),
                    dataRowMaxHeight: 75,
                    dataRowMinHeight: 65,
                    // Memberi ruang spacing yang sekata antara lajur secara automatik
                    columnSpacing: constraints.maxWidth > 1000 ? null : 24,
                    columns: const [
                      DataColumn(label: Text('NO.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('KOD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('NAMA KURSUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('SEKSYEN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('PROGRAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('CAPACITY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('HARI / MASA LOKASI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('JENIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                    rows: slots.isEmpty
                        ? [
                            const DataRow(cells: [
                              DataCell(Text('-')),
                              DataCell(Text('Tiada Data')),
                              DataCell(Text('Sila ubah suai tetapan penapis')),
                              DataCell(Text('-')),
                              DataCell(Text('-')),
                              DataCell(Text('-')),
                              DataCell(Text('-')),
                              DataCell(Text('-')),
                            ])
                          ]
                        : List.generate(slots.length, (index) {
                            final slot = slots[index];
                            return DataRow(
                              cells: [
                                DataCell(Text('${index + 1}', style: const TextStyle(color: Color(0xff5f6368)))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffe6f4ea),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      slot.subjectCode,
                                      style: const TextStyle(
                                        color: Color(0xff137333),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text('Kursus ${slot.subjectCode}', style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(Text(slot.section)),
                                DataCell(Text(_service.currentKpOops.programId ?? 'N/A')),
                                const DataCell(Text('30')),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('JUMAAT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                        const Text('15:00 - 17:00', style: TextStyle(color: Color(0xff5f6368), fontSize: 11)),
                                        Text(
                                          slot.room.isNotEmpty ? slot.room : 'N/A',
                                          style: const TextStyle(color: Color(0xff1a73e8), fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xfff1f3f4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xffdadce0)),
                                    ),
                                    child: const Text('Teori/Amali', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xff5f6368))),
                                  ),
                                ),
                              ],
                            );
                          }),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}