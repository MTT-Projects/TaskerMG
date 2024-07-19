import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class PopUpDialog extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  final List<Widget>? buttons;
  final Widget? content;

  PopUpDialog({
    required this.title,
    required this.text,
    required this.icon,
    this.buttons,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, size: 24),
          SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          if (content != null) ...[
            SizedBox(height: 16),
            content!,
          ],
        ],
      ),
      actions: buttons ??
          [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
    );
  }
}


class PopUpButtons {
  static List<Widget> yesNo(BuildContext context, VoidCallback onYes) {
    return [
      TextButton(
        onPressed: onYes,
        child: Text('Sí'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('No'),
      ),
    ];
  }

  static List<Widget> saveCancel(BuildContext context, VoidCallback onSave) {
    return [
      TextButton(
        onPressed: onSave,
        child: Text('Guardar'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('Cancelar'),
      ),
    ];
  }

  static List<Widget> deleteCancel(BuildContext context, VoidCallback onDelete) {
    return [
      TextButton(
        onPressed: onDelete,
        child: Text('Borrar'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('Cancelar'),
      ),
    ];
  }

  static List<Widget> exitCancel(BuildContext context, VoidCallback onExit) {
    return [
      TextButton(
        onPressed: onExit,
        child: Text('Salir'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('Cancelar'),
      ),
    ];
  }

  //ok button
  static List<Widget> okButton(BuildContext context) {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('OK'),
      ),
    ];
  }
}


class PopupDialog {
  static void show({
    required BuildContext context,
    required String title,
    required String text,
    required IconData icon,
    required List<Widget> buttons,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(text),
          actions: buttons,
        );
      },
    );
  }
}

