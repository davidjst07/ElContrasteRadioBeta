import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.radio),
        title: const Text('El Contraste App'),
        actions: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Text('21:55', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                'EN VIVO',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Image.asset('assets/logoradio.png', height: 100),
            _NowplayingWidget(),
            const SizedBox(height: 24),
            Row(
              children: [
                _TabButton(text: "Radio", selected: true),
                _TabButton(text: "Noticias", selected: false),
                _TabButton(text: "Deportes", selected: false),
              ],
            ),
            const SizedBox(height: 10),
            _ProgrammingWidget(),
          ],
        ),
      ),
    );
  }
}

class _NowplayingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color.fromARGB(255, 7, 38, 65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.radio, size: 60, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              'El Contraste Radio',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border),
                SizedBox(width: 32),
                Icon(Icons.play_circle_fill, size: 48, color: Colors.white70),
                SizedBox(width: 32),
                Icon(Icons.share),
              ],
            ),
            Slider(value: 0.75, onChanged: (_) {}, min: 0, max: 1),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool selected;

  const _TabButton({required this.text, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 36,
          alignment: Alignment.center,
          margin: EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? Color.fromARGB(255, 42, 76, 156)
                : Color(0xFF2A86C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _ProgrammingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Programación',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Card(
          color: Color.fromARGB(255, 42, 76, 156),
          child: ListTile(
            leading: Icon(Icons.person, color: Colors.greenAccent),
            title: Text('DJ Carlos', style: TextStyle(color: Colors.white)),
            subtitle: Text('Éxitos de los 80s y 90s'),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('EN VIVO', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
        SizedBox(height: 12),
        Text('Próximo: 18:00', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Música Tropical con DJ María'),
      ],
    );
  }
}
