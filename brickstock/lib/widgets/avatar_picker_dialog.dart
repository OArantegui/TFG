import 'package:flutter/material.dart';

class AvatarPickerDialog extends StatelessWidget {
  final Function(String) onAvatarSelected;

  // Lista de avatares
  final List<String> avatars = [
    'assets/avatars/avatar-harrypoter.jpg',
    'assets/avatars/avatar-ironman.jpg',
    'assets/avatars/avatar-vader.jpg',
    'assets/avatars/avatar-lambo.jpg',
    'assets/avatars/lego-default.jpg',
  ];

  AvatarPickerDialog({Key? key, required this.onAvatarSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Elige tu Avatar'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600, // Ancho máximo
          maxHeight: 500, // Alto máximo para que no se estire de más
        ),
        child: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 110,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: avatars.length, // Lista de avatares
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
