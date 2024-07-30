import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MailService {
  // static const String _host = 'smtp.mailersend.net';
  // static const int _port = 587;
  // static const String _username = 'MS_UiddCV@trial-vywj2lpykk1l7oqz.mlsender.net';
  // static const String _password = 'pYLnSKZdFQ6kuVSC';

  static final String _host = dotenv.env['MAIL_HOST'] ?? '';
  static final int _port = int.parse(dotenv.env['MAIL_PORT'] ?? '');
  static final String _username = dotenv.env['MAIL_USERNAME'] ?? '';
  static final String _password = dotenv.env['MAIL_PASSWORD'] ?? '';

  static Future<void> sendMail({
    required String to,
    required String subject,
    required String code,
  }) async {
    final smtpServer = SmtpServer(
      _host,
      port: _port,
      username: _username,
      password: _password,
    );

    final message = Message()
      ..from = Address(_username, 'Mtt Projects')
      ..recipients.add(to)
      ..subject = subject
      ..html = _buildEmailHtml(code);

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent. \n${e.toString()}');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }

  static String _buildEmailHtml(String code) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body {
          font-family: Arial, sans-serif;
          background-color: #f4f4f4;
          margin: 0;
          padding: 0;
        }
        .container {
          max-width: 600px;
          margin: 50px auto;
          background-color: #fff;
          padding: 20px;
          box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
          border-radius: 8px;
        }
        .header {
          text-align: center;
          margin-bottom: 20px;
        }
        .header img {
          max-width: 150px;
        }
        .content {
          text-align: center;
        }
        .content h1 {
          color: #333;
        }
        .content p {
          color: #666;
        }
        .code {
          display: inline-block;
          margin: 20px 0;
          padding: 10px 20px;
          background-color: #efefef;
          border-radius: 4px;
          font-size: 24px;
          letter-spacing: 4px;
        }
        .footer {
          text-align: center;
          margin-top: 30px;
          color: #999;
          font-size: 12px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <img src="https://raw.githubusercontent.com/Matiw172/matiw172.github.io/main/images/MTT_Logo_complet.png" alt="Company Logo">
        </div>
        <div class="content">
          <h1>Código de Verificación</h1>
          <p>¡Bienvenido a TaskerMG! Para completar tu registro, por favor ingresa el siguiente código de verificación:</p>
          <div class="code">$code</div>
          <p>Si no solicitaste este código, por favor ignora este correo.</p>
        </div>
        <div class="footer">
          <p>© 2024 MTT Projects. Todos los derechos reservados.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }
}
