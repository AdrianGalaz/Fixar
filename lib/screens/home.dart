import 'package:flutter/material.dart';
import 'editor.dart';
import 'ar_calibracion.dart';
import 'perfil.dart'; // Importamos la nueva pantalla
import 'login.dart'; // Importamos el login para poder cerrar sesión
import 'mis_modelos.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      // --- MAGIA 1: EL MENÚ LATERAL (DRAWER) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cabecera del menú
            // Opciones del menú
            ListTile(
              leading: const Icon(Icons.home, color: Colors.black87),
              title: const Text('Inicio'),
              onTap: () => Navigator.pop(context), // Cierra el menú
            ),
            ListTile(
              leading: const Icon(Icons.view_in_ar, color: Colors.black87),
              title: const Text('Mis Modelos 3D'),
              onTap: () {
                Navigator.pop(context); // Cierra el menú lateral
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MisModelos()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black87),
              title: const Text('Configuración'),
              onTap: () {},
            ),
            const Divider(), // Línea separadora
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                // Navega de regreso al Login y borra el historial de pantallas
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),

      // Barra superior
      // Barra superior
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        // --- AQUÍ QUITAMOS EL MENSAJE GRIS ---
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              tooltip: '', // Al dejar esto vacío, ya no sale el cuadro gris
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Esto abre el menú lateral
              },
            );
          },
        ),

        // ------------------------------------
        title: const Text(
          'FixAR',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              color: Colors.black,
              size: 28,
            ),
            // Le quitamos también el tooltip al botón de perfil por si acaso
            tooltip: '',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Perfil()),
              );
            },
          ),
        ],
      ),

      // ... EL RESTO DEL CÓDIGO DEL BODY SE QUEDA EXACTAMENTE IGUAL ...
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar Tutoriales',
                hintStyle: const TextStyle(color: Colors.grey),
                suffixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildTutorialCard(
                    context: context,
                    title: 'Cambio de Foco',
                    duration: '5 Minutos',
                    iconData: Icons.lightbulb_outline,
                  ),
                  const SizedBox(height: 20),
                  _buildTutorialCard(
                    context: context,
                    title: 'Cubo Rubik 3x3 (Cruz Blanca)',
                    duration: '5 Minutos',
                    iconData: Icons.grid_on,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditorScreen()),
          );
        },
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Subir Modelo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTutorialCard({
    required BuildContext context,
    required String title,
    required String duration,
    required IconData iconData,
  }) {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: Icon(iconData, size: 60, color: Colors.grey.shade600),
              ),
              Container(
                width: double.infinity,
                color: const Color(0xFF0056B3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
