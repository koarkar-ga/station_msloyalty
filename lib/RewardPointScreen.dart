import 'package:flutter/material.dart';

class RewardPointScreen extends StatefulWidget {
  const RewardPointScreen({super.key});

  @override
  State<RewardPointScreen> createState() => _RewardPointScreenState();
}

class _RewardPointScreenState extends State<RewardPointScreen> {
  // နမူနာ Member Data
  String memberName = "U Kyaw Kyaw";
  int availablePoints = 5500;

  // နမူနာ Reward Items List
  final List<Map<String, dynamic>> rewardItems = [
    {
      "name": "5000 MMK Fuel",
      "points": 1000,
      "icon": Icons.local_gas_station,
      "color": Colors.orange,
    },
    {"name": "Engine Oil (1L)", "points": 5000, "icon": Icons.build, "color": Colors.blue},
    {"name": "Umbrella", "points": 1500, "icon": Icons.umbrella, "color": Colors.red},
    {"name": "Coffee Mug", "points": 800, "icon": Icons.coffee, "color": Colors.brown},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reward Point Redemption (ပွိုင့်လဲလှယ်ရန်)")),
      body: Row(
        children: [
          // ၁။ ဘယ်ဘက်ခြမ်း - Member Summary
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.blueGrey[900],
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, size: 80, color: Colors.yellow),
                  const SizedBox(height: 20),
                  Text(
                    memberName,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Your Available Points", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 5),
                  Text(
                    "$availablePoints",
                    style: const TextStyle(
                      fontSize: 48,
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 40),
                  const Text(
                    "Redeem your points for gifts or fuel discounts!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),

          // ၂။ ညာဘက်ခြမ်း - Reward Items Selection
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ရရှိနိုင်သော လက်ဆောင်များ",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: rewardItems.length,
                      itemBuilder: (context, index) {
                        final item = rewardItems[index];
                        bool canAfford = availablePoints >= item['points'];

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: InkWell(
                            onTap: canAfford ? () => _showRedeemConfirm(item) : null,
                            child: Opacity(
                              opacity: canAfford ? 1.0 : 0.5,
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(item['icon'], size: 40, color: item['color']),
                                    const SizedBox(height: 10),
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "${item['points']} Points",
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // လဲလှယ်ရန် အတည်ပြုချက် Popup
  void _showRedeemConfirm(Map item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Redemption"),
        content: Text(
          "Are you sure you want to exchange ${item['points']} points for ${item['name']}?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              // ပွိုင့်လျှော့မည့် Logic များကို ဤနေရာတွင် ရေးရန်
              Navigator.pop(context);
            },
            child: const Text("REDEEM NOW"),
          ),
        ],
      ),
    );
  }
}
