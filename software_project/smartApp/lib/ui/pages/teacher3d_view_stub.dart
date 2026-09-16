import 'package:flutter/material.dart';

import 'teacher3d_view.dart';

Widget buildTeacher3dView(
  String url,
  void Function(Map<String, dynamic> message)? onMessage,
  Teacher3dController? controller,
) {
  return const Center(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'The 3D AI teacher runs in the web app only.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
