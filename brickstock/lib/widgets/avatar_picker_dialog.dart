import 'package:flutter/material.dart';

class AvatarPickerDialog extends StatelessWidget {
  final Function(String) onAvatarSelected;
  
  // Lista de tus avatares
  final List<String> avatars = [
    'assets/avatars/lego_1.png',
    'assets/avatars/lego_2.png',
    'assets/avatars/lego_3.png',
    'assets/avatars/lego_4.png',
  ];

  AvatarPickerDialog({Key? key, required this.onAvatarSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Elige tu Avatar de Lego'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: avatars.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                onAvatarSelected(avatars[index]);
                Navigator.pop(context);
              },
              child: CircleAvatar(
                backgroundImage: AssetImage(avatars[index]),
                backgroundColor: Colors.grey[200],
              ),
            );
          },
        ),
      ),
    );
  }
}