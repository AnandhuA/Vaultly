import 'package:flutter/material.dart';

import '../../data/models/vault_item.dart';

class IconMapper {
  static IconData collection(String icon) {
    return switch (icon) {
      'code' => Icons.code_rounded,
      'work' => Icons.work_outline_rounded,
      'palette' => Icons.palette_outlined,
      'payments' => Icons.payments_outlined,
      'flight' => Icons.flight_takeoff_rounded,
      'restaurant' => Icons.restaurant_menu_rounded,
      _ => Icons.folder_rounded,
    };
  }

  static IconData item(VaultItemType type) {
    return switch (type) {
      VaultItemType.instagram => Icons.camera_alt_outlined,
      VaultItemType.linkedin => Icons.business_center_outlined,
      VaultItemType.youtube => Icons.play_circle_outline_rounded,
      VaultItemType.pdf => Icons.picture_as_pdf_outlined,
      VaultItemType.image || VaultItemType.screenshot => Icons.image_outlined,
      VaultItemType.video => Icons.movie_outlined,
      VaultItemType.note || VaultItemType.text => Icons.notes_rounded,
      VaultItemType.document => Icons.description_outlined,
      VaultItemType.voice => Icons.mic_none_rounded,
      _ => Icons.link_rounded,
    };
  }
}
