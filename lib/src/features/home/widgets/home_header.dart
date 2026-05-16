import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../household/household.dart';
import 'home_formatters.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.household,
    required this.displayName,
    required this.onMembers,
    required this.onSelected,
  });

  final Household household;
  final String displayName;
  final VoidCallback onMembers;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 52, 16, 18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: FtColors.surfaceAlt,
            foregroundColor: FtColors.ink,
            child: Text(
              initialsOf(displayName),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  household.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 17,
                        color: FtColors.ink,
                      ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onMembers,
            child: SizedBox(
              width: 74,
              height: 30,
              child: Stack(
                children: [
                  for (var i = 0; i < household.members.take(3).length; i++)
                    Positioned(
                      left: i * 20,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: parseColor(
                          household.members[i].color,
                        ),
                        foregroundColor: Colors.white,
                        child: Text(
                          initialsOf(household.members[i].displayName),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: onSelected,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'insights', child: Text('Insight')),
              PopupMenuItem(value: 'goals', child: Text('Tujuan')),
              PopupMenuItem(value: 'investments', child: Text('Investasi')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'accounts', child: Text('Akun')),
              PopupMenuItem(value: 'cards', child: Text('Kartu kredit')),
              PopupMenuItem(value: 'incomes', child: Text('Pemasukan')),
              PopupMenuItem(value: 'categories', child: Text('Kategori')),
              PopupMenuItem(value: 'members', child: Text('Anggota')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'export', child: Text('Ekspor data')),
              PopupMenuItem(value: 'signout', child: Text('Keluar')),
            ],
          ),
        ],
      ),
    );
  }
}
