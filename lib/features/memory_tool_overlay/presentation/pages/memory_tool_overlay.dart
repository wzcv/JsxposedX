import 'package:JsxposedX/common/pages/toast.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MemoryToolOverlay extends HookConsumerWidget {
  const MemoryToolOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: (){
        ToastMessage.show("msg");
      }, child: const Text("1312")),
    );
  }
}
