import 'package:flutter/material.dart';
import 'services/ai_tip_service.dart';

class TestAiTipPage extends StatefulWidget {
  const TestAiTipPage({super.key});

  @override
  State<TestAiTipPage> createState() => _TestAiTipPageState();
}

class _TestAiTipPageState extends State<TestAiTipPage> {
  Map<String, dynamic>? result;
  bool loading = false;

  Future<void> runTest() async {
    setState(() => loading = true);

    final ai = AiTipService();
    final tips = await ai.getItemTips(
      itemName: "Gardenia Butterscotch Loaf",
      category: "Bakery",
      expDays: -5,
      weatherLevel: "red",
    );

    setState(() {
      result = tips;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Tip Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: runTest,
              child: const Text("Run AI Tip Test"),
            ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            if (!loading && result != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    result.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
