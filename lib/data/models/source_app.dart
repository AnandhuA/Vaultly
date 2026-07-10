enum SourceApp {
  instagram,
  linkedin,
  youtube,
  browser,
  whatsapp,
  telegram,
  unknown,
}

extension SourceAppLabel on SourceApp {
  String get label {
    return switch (this) {
      SourceApp.instagram => 'Instagram',
      SourceApp.linkedin => 'LinkedIn',
      SourceApp.youtube => 'YouTube',
      SourceApp.browser => 'Website',
      SourceApp.whatsapp => 'WhatsApp',
      SourceApp.telegram => 'Telegram',
      SourceApp.unknown => 'Unknown',
    };
  }
}
