import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';



class QRCode extends StatelessWidget {
  final String qrCodeUrl;

  const QRCode({Key? key, required this.qrCodeUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code'),
      ),
      body: Center(                                                                                                                  
        child: qrCodeUrl.isNotEmpty
            ? SvgPicture.network(
                qrCodeUrl,
                width: 200,
                height: 200,
                placeholderBuilder: (context) => const CircularProgressIndicator(),
              )
            : const Text('No QR Code Available'),
      ),
    );
  }
}
