import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

void main() => runApp(const AirbnbApp());

class AirbnbApp extends StatelessWidget {
  const AirbnbApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF5A5F), // Official Airbnb Rausch
        textTheme: google_fonts.GoogleFonts.interTextTheme(),
      ),
      home: const PricePredictor(),
    );
  }
}

class PricePredictor extends StatefulWidget {
  const PricePredictor({super.key});
  @override
  State<PricePredictor> createState() => _PricePredictorState();
}

class _PricePredictorState extends State<PricePredictor> {
  final _formKey = GlobalKey<FormState>();

  String selectedBorough = 'Westminster';
  String selectedRoom = 'Entire home/apt';
  final TextEditingController _nightsController =
      TextEditingController(text: '1');
  final TextEditingController _availabilityController =
      TextEditingController(text: '30');
  final TextEditingController _hostListingsController =
      TextEditingController(text: '1');

  String prediction = "£0";
  bool isLoading = false;
  bool showWarning = false;

  final List<String> boroughs = [
    'Barking and Dagenham',
    'Barnet',
    'Bexley',
    'Brent',
    'Bromley',
    'Camden',
    'City of London',
    'Croydon',
    'Ealing',
    'Enfield',
    'Greenwich',
    'Hackney',
    'Hammersmith and Fulham',
    'Haringey',
    'Harrow',
    'Havering',
    'Hillingdon',
    'Hounslow',
    'Islington',
    'Kensington and Chelsea',
    'Kingston upon Thames',
    'Lambeth',
    'Lewisham',
    'Merton',
    'Newham',
    'Redbridge',
    'Richmond upon Thames',
    'Southwark',
    'Sutton',
    'Tower Hamlets',
    'Waltham Forest',
    'Wandsworth',
    'Westminster'
  ];

  Future<void> getPrediction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://airbnb-london-app.onrender.com/predict'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "neighbourhood": selectedBorough,
          "room_type": selectedRoom,
          "minimum_nights": int.parse(_nightsController.text),
          "availability_365": int.parse(_availabilityController.text),
          "host_listings_count": int.parse(_hostListingsController.text),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          prediction = "£${data['predicted_price'].toStringAsFixed(0)}";
          showWarning = data['is_90_day_warning'] ?? false;
        });
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 950;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 800),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildInputSection()),
                            const SizedBox(width: 80),
                            Expanded(flex: 2, child: _buildResultCard()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildInputSection(),
                            const SizedBox(height: 40),
                            _buildResultCard(),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFFFF5A5F), size: 36),
          const SizedBox(width: 8),
          Text(
            "airbnb london",
            style: google_fonts.GoogleFonts.poppins(
              color: const Color(0xFFFF5A5F),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const Spacer(),
          Text(
            "For the Hosts",
            style: google_fonts.GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 24),
          const Icon(Icons.language, size: 20, color: Colors.black54),
          const SizedBox(width: 24),
          const Icon(Icons.account_circle, size: 32, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // THE NEW LARGE HEADLINE
          Text(
            "Find the Best Price for your Airbnb",
            style: google_fonts.GoogleFonts.inter(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Predict your earnings",
            style: google_fonts.GoogleFonts.inter(
              fontSize: 29,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF5A5F),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Price your Airbnb perfectly with no worries of over or under-pricing.",
            style: TextStyle(
                color: const Color.fromARGB(255, 67, 64, 63),
                fontSize: 15,
                height: 1.5),
          ),
          const SizedBox(height: 29),

          _inputLabel("NEIGHBOURHOOD"),
          Autocomplete<String>(
            initialValue: const TextEditingValue(text: 'Westminster'),
            optionsBuilder: (text) => boroughs.where(
                (s) => s.toLowerCase().contains(text.text.toLowerCase())),
            onSelected: (s) => selectedBorough = s,
            fieldViewBuilder: (context, ctrl, node, onSubmit) => TextFormField(
              controller: ctrl,
              focusNode: node,
              style: const TextStyle(fontWeight: FontWeight.w500),
              decoration: _inputDecoration("Search boroughs..."),
              validator: (v) =>
                  boroughs.contains(v) ? null : "Select a valid borough",
            ),
          ),
          const SizedBox(height: 32),

          _inputLabel("ROOM TYPE"),
          DropdownButtonFormField<String>(
            value: selectedRoom,
            icon: const Icon(Icons.keyboard_arrow_down),
            decoration: _inputDecoration(""),
            items: [
              'Entire home/apt',
              'Private room',
              'Hotel room',
              'Shared room'
            ]
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e,
                        style: const TextStyle(fontWeight: FontWeight.w500))))
                .toList(),
            onChanged: (v) => setState(() => selectedRoom = v!),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                  child: _buildValidatedInput(
                      "MIN NIGHTS", _nightsController, 1, 30)),
              const SizedBox(width: 24),
              Expanded(
                  child: _buildValidatedInput(
                      "HOST LISTINGS", _hostListingsController, 1, 500)),
            ],
          ),
          const SizedBox(height: 32),
          _buildValidatedInput(
              "YEARLY AVAILABILITY (DAYS)", _availabilityController, 0, 365),

          const SizedBox(height: 20),
          Text(
            "The machine learning model powering this app analyzes thousands of London listings to provide accurate predictions.",
            style: TextStyle(
                color: const Color.fromARGB(255, 184, 84, 59),
                fontSize: 14,
                height: 1.5),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 50,
              offset: const Offset(0, 20))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("ESTIMATED REVENUE",
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 11)),
          const SizedBox(height: 12),
          FittedBox(
            child: Text(prediction,
                style: const TextStyle(
                    fontSize: 84,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -3)),
          ),
          const Text("per night",
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 40),
          if (showWarning) _warningBox(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: isLoading ? null : getPrediction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A5F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Evaluate the Best Price",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Text(
            "Results are estimates based on the specific details you provided.",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade500, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _warningBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF8F1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade100)),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
              child: Text(
                  "90-day rule: Entire homes in London are restricted to 90 nights per year.",
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _inputLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.black54,
                letterSpacing: 1.1)),
      );

  Widget _buildValidatedInput(
      String label, TextEditingController ctrl, int min, int max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputLabel(label),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: _inputDecoration(""),
          validator: (v) {
            int? val = int.tryParse(v ?? '');
            if (val == null || val < min || val > max) return "$min-$max";
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black, width: 1.5)),
        errorStyle: const TextStyle(fontWeight: FontWeight.bold),
      );
}
