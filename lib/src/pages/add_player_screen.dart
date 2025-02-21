import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rank_hub/src/pages/add_lx_mai_screen.dart';
import 'package:rank_hub/src/pages/add_moe_md_screen.dart';
import 'package:rank_hub/src/provider/moe_md_provider.dart';

class AddPlayerScreen extends StatefulWidget {
  const AddPlayerScreen({super.key});

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                '添加玩家数据到 RankHub',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const Center(
              child: Text('将你的游玩数据集中一处，随时查看'),
            ),
            const SizedBox(height: 64),
            const Text('支持的来源'),
            const SizedBox(
              height: 8,
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddLxMaiScreen(),
                ),
              );
              },
              leading: CachedNetworkImage(
                imageUrl: 'https://maimai.lxns.net/favicon.webp',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                fadeInDuration:
                    const Duration(milliseconds: 500), // Fade-in duration
                placeholder: (context, url) => Transform.scale(
                  scale: 0.4,
                  child: const CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.image_not_supported,
                  size: 16,
                ),
              ),
              title: const Text('落雪咖啡屋'),
              subtitle: const Text('maimai.lxns.net'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMoeMdScreen(provider: MoeMdProvider()),
                ),
              );
              },
              leading: CachedNetworkImage(
                imageUrl: 'https://musedash.moe/img/icons/android-chrome-512x512.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                fadeInDuration:
                    const Duration(milliseconds: 500), // Fade-in duration
                placeholder: (context, url) => Transform.scale(
                  scale: 0.4,
                  child: const CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.image_not_supported,
                  size: 16,
                ),
              ),
              title: const Text('MuseDash.moe'),
              subtitle: const Text('musedash.moe'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
