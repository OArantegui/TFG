import 'package:flutter/material.dart';

class AvatarPickerDialog extends StatelessWidget {
  final Function(String) onAvatarSelected;
  
  // Lista de tus avatares
  final List<String> avatars = [
    'assets/avatars/avatar-harrypoter.jpg',
    'assets/avatars/avatar-ironman.jpg',
    'assets/avatars/avatar-vader.jpg',
    'assets/avatars/avatar-lambo.jpg',
    'assets/avatars/lego-default.jpg',
  ];

  AvatarPickerDialog({Key? key, required this.onAvatarSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Elige tu Avatar'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600, // Ancho máximo (tamaño típico de un móvil grande)
          maxHeight: 500, // Alto máximo para que no se estire de más
        ),
        // 2. Aquí dentro pones tu GridView o la lista que ya tenías
        child: SizedBox(
          width: double.maxFinite, // Ayuda a que el Grid no se encoja a 0
          child: GridView.builder(
            shrinkWrap: true, // Importante para que no de error de tamaño infinito
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 110, 
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: avatars.length, // Tu lista de avatares
            itemBuilder: (context, index) {
              final avatarPath = avatars[index];
              return GestureDetector(
                onTap: () {
                  onAvatarSelected(avatarPath);
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(avatarPath),
                  backgroundColor: Colors.transparent,
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}