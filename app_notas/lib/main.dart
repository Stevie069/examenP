import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Nueva librería
import 'dart:convert';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MainScreen(),
  ));
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // ⚠️⚠️ PON TU IP REAL AQUÍ (La misma de antes: 10.134.123.31) ⚠️⚠️
  final String serverIP = '10.134.123.31'; 
  
  // Variables UI
  String _resultadoPrediccion = "--";
  List<dynamic> _historial = [];

  // Controladores
  final _studyCtrl = TextEditingController();
  final _attendCtrl = TextEditingController();
  final _sleepCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pedirHistorial(); // Cargar historial al iniciar
  }

  // --- FUNCIÓN 1: PREDECIR (Cliente envía POST al Servidor) ---
  Future<void> _enviarPrediccion() async {
    setState(() { _resultadoPrediccion = "⏳"; });

    try {
      final url = Uri.parse('http://$serverIP:5000/predict');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "study": _studyCtrl.text,
          "attendance": _attendCtrl.text,
          "sleep": _sleepCtrl.text
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _resultadoPrediccion = data['score'].toString();
        });
        // Actualizar historial automáticamente
        _pedirHistorial(); 
      } else {
        setState(() { _resultadoPrediccion = "Err"; });
      }
    } catch (e) {
      print("❌ Error Conexión: $e");
      setState(() { _resultadoPrediccion = "Sin Red"; });
    }
  }

  // --- FUNCIÓN 2: HISTORIAL (Cliente envía GET al Servidor) ---
  Future<void> _pedirHistorial() async {
    try {
      final url = Uri.parse('http://$serverIP:5000/history');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _historial = data;
        });
      }
    } catch (e) {
      print("❌ Error Historial: $e");
    }
  }

  // --- INTERFAZ (IGUAL QUE ANTES) ---
  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildPredictionScreen(),
      _buildHistoryScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? "🔮 Cliente IA" : "📜 Servidor DB"),
        backgroundColor: Colors.deepPurple,
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() { 
            _currentIndex = index; 
            if(index == 1) _pedirHistorial();
          });
        },
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.cloud_upload), label: "Predecir"),
          BottomNavigationBarItem(icon: Icon(Icons.storage), label: "Historial"),
        ],
      ),
    );
  }

  Widget _buildPredictionScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _inputField("Horas de Estudio", Icons.book, _studyCtrl),
                  const SizedBox(height: 15),
                  _inputField("Asistencia (%)", Icons.school, _attendCtrl),
                  const SizedBox(height: 15),
                  _inputField("Horas de Sueño", Icons.bed, _sleepCtrl),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _enviarPrediccion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple, 
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50)
                    ),
                    child: const Text("ENVIAR AL SERVIDOR"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text("Respuesta del Servidor:", style: TextStyle(color: Colors.grey)),
          Text(_resultadoPrediccion, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        ],
      ),
    );
  }

  Widget _inputField(String label, IconData icon, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildHistoryScreen() {
    if (_historial.isEmpty) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      itemCount: _historial.length,
      padding: const EdgeInsets.all(10),
      itemBuilder: (context, index) {
        final item = _historial[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.deepPurple[100],
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item['score'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 16),
                  ),
                ),
              ),
            ),
            title: Text("Nota: ${item['score']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Estudio: ${item['study']}h | Asist: ${item['attendance']}%"),
            trailing: Text(item['date'].toString().split(' ')[1]),
          ),
        );
      },
    );
  }
}