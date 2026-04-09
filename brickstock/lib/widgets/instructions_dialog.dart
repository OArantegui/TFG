import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InstructionsDialog extends StatelessWidget {
  final List<String> urls;

  const InstructionsDialog({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manuales disponibles', style: TextStyle(fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: double.maxFinite,
        // Usamos shrinkWrap para que el popup se adapte al número de manuales
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: urls.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final url = urls[index];
            
            // Recortamos la URL. Dividimos por '/' y nos quedamos con la última parte.
            // Ej: https://.../6218872.pdf -> 6218872.pdf
            final fileName = url.split('/').last;

            return ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
              title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
              contentPadding: EdgeInsets.zero,
              onTap: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}