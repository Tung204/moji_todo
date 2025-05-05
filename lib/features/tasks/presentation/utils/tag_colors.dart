import 'package:flutter/material.dart';

class TagColors {
  static final Map<String, Map<String, Color>> tagColorMap = {
    'Design': {
      'background': Colors.blue[50]!,
      'text': Colors.blue,
    },
    'Work': {
      'background': Colors.pink[50]!,
      'text': Colors.pink,
    },
    'Productive': {
      'background': Colors.green[50]!,
      'text': Colors.green,
    },
    'Personal': {
      'background': Colors.orange[50]!,
      'text': Colors.orange,
    },
    'Study': {
      'background': Colors.purple[50]!,
      'text': Colors.purple,
    },
    // Thêm các tag khác nếu cần
  };

  static Map<String, Color> getTagColors(String tag) {
    return tagColorMap[tag] ?? {
      'background': Colors.grey[200]!,
      'text': Colors.grey,
    };
  }
}