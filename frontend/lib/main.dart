import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const AirbnbApp());

class AirbnbApp extends StatelessWidget {
  const AirbnbApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pinkAccent),
      home: const PricePredictor(),
    );
  }
}

class PricePredictor extends StatefulWidget {
  const PricePredictor({super.key});

  @override
  // FIX 1: Changed return type to State<PricePredictor> to avoid "Private type in public API" error
  State<PricePredictor> createState() => _PricePredictorState();
}

class _PricePredictorState extends State<PricePredictor> {
  final _formKey = GlobalKey<FormState>();

  String selectedBorough = 'Westminster'; // Default value
  String selectedRoom = 'Entire home/apt';
  final TextEditingController _nightsController =
      TextEditingController(text: '1');
  final TextEditingController _availabilityController =
      TextEditingController(text: '30');
  final TextEditingController _hostListingsController =
      TextEditingController(text: '1');

  // FIX 2: Removed unused _boroughController to clear the warning

  String prediction = "£0.00";
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
        Uri.parse('http://localhost:8000/predict'),
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
          prediction = "£${data['predicted_price']}";
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
    bool isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
          title: const Text("London Airbnb Predictor"), centerTitle: true),
      body: Center(
        child: Container(
          // FIX 3: maxWidth must be inside BoxConstraints
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 900 : 500,
          ),
          padding: const EdgeInsets.all(24.0),
          child: isDesktop
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _buildFormSection()),
                  const SizedBox(width: 30),
                  Expanded(flex: 2, child: _buildResultSection()),
                ])
              : SingleChildScrollView(
                  child: Column(children: [
                  _buildFormSection(),
                  const SizedBox(height: 24),
                  _buildResultSection(),
                ])),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Form(
      key: _formKey,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Listing Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text("Neighbourhood",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Autocomplete<String>(
                initialValue: const TextEditingValue(text: 'Westminster'),
                optionsBuilder: (textValue) => boroughs.where((s) =>
                    s.toLowerCase().contains(textValue.text.toLowerCase())),
                onSelected: (selection) => selectedBorough = selection,
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                        hintText: "Search Borough...",
                        suffixIcon: Icon(Icons.search)),
                    validator: (value) {
                      if (!boroughs.contains(value))
                        return "Select a valid London Borough";
                      selectedBorough = value!;
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text("Room Type",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: selectedRoom,
                items: [
                  'Entire home/apt',
                  'Private room',
                  'Hotel room',
                  'Shared room'
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => selectedRoom = v!),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: _buildValidatedField(
                          "Min Nights (1-30)", _nightsController, 1, 30)),
                  const SizedBox(width: 15),
                  Expanded(
                      child: _buildValidatedField("Host Listings (1-500)",
                          _hostListingsController, 1, 500)),
                ],
              ),
              const SizedBox(height: 20),
              _buildValidatedField("Yearly Availability (0-365)",
                  _availabilityController, 0, 365),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidatedField(
      String label, TextEditingController controller, int min, int max) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        int? val = int.tryParse(value ?? '');
        if (val == null || val < min || val > max) return "Range $min - $max";
        return null;
      },
    );
  }

  Widget _buildResultSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showWarning)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange)),
            child: const Text(
                "⚠️ London's 90-Day Rule: Stays over 90 days in Entire Homes may require a license.",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: Colors.pinkAccent,
              borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              const Text("ESTIMATED PRICE",
                  style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold)),
              FittedBox(
                  child: Text(prediction,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                          fontWeight: FontWeight.bold))),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : getPrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.pinkAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("PREDICT NOW",
                        style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ],
    );
  }
}
