import 'package:flutter/material.dart';
import 'editor.dart';
import 'ar_calibracion.dart';
import 'perfil.dart';
import 'login.dart';
import 'mis_modelos.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_ar/screens/tutorial.dart';

// 1. Cambiamos de StatelessWidget a StatefulWidget para manejar el texto de búsqueda
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // 2. Variable para guardar lo que el usuario escribe
  String _textoBusqueda = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      // --- EL MENÚ LATERAL (DRAWER) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              leading: const Icon(Icons.home, color: Colors.black87),
              title: const Text('Inicio'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.view_in_ar, color: Colors.black87),
              title: const Text('Mis Modelos 3D'),
              onTap: () {
                Navigator.pop(context);
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              tooltip: '',
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
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

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 3. El buscador ahora actualiza el estado cada vez que escribes
            TextField(
              onChanged: (valor) {
                setState(() {
                  _textoBusqueda = valor
                      .toLowerCase(); // Convertimos a minúsculas para una búsqueda más fácil
                });
              },
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

            // --- FEED DINÁMICO CON FILTRADO ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tutoriales')
                    .orderBy('fecha_creacion', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0056B3),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aún no hay tutoriales.\n¡Sube el primero!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    );
                  }

                  // 4. Lógica de Filtrado Local
                  final tutorialesRaw = snapshot.data!.docs;

                  // Filtramos la lista basándonos en lo que escribiste en el buscador
                  final tutorialesFiltrados = tutorialesRaw.where((doc) {
                    final datos = doc.data() as Map<String, dynamic>;
                    final titulo = (datos['titulo'] ?? '')
                        .toString()
                        .toLowerCase();
                    return titulo.contains(_textoBusqueda);
                  }).toList();

                  // Si buscaste algo que no existe
                  if (tutorialesFiltrados.isEmpty) {
                    return Center(
                      child: Text(
                        'No se encontraron resultados para "$_textoBusqueda"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  // Dibujamos solo los tutoriales que pasaron el filtro
                  return ListView.builder(
                    itemCount: tutorialesFiltrados.length,
                    itemBuilder: (context, index) {
                      final datos =
                          tutorialesFiltrados[index].data()
                              as Map<String, dynamic>;
                      final idDocumento = tutorialesFiltrados[index].id;

                      final titulo = datos['titulo'] ?? 'Tutorial FixAR';
                      final duracion =
                          datos['duracion'] ?? 'Tiempo desconocido';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: _buildTutorialCard(
                          context: context,
                          title: titulo,
                          duration: duracion,
                          iconData: Icons.view_in_ar,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TutorialExecutionScreen(
                                  tutorialId: idDocumento,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
