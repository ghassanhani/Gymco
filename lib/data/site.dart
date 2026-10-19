import 'package:url_launcher/url_launcher.dart';

/// gymcoapp.com, served from site/ in this repo.
const siteUrl = 'https://gymcoapp.com';

Future<void> openSite(String path) => launchUrl(Uri.parse('$siteUrl/$path/'), mode: LaunchMode.externalApplication);
