// lib/widgets/pedigree_card.dart

import 'package:flutter/material.dart';
import '../providers/pedigree_provider.dart'; // PedigreeNode için

/// Soy ağacındaki her bir kuşu temsil eden kart görünümü (düğüm).
class PedigreeCard extends StatelessWidget {
  final PedigreeNode node;
  final double cardHeight;

  const PedigreeCard({
    Key? key,
    required this.node,
    this.cardHeight = 70.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (node.isBos) {
      // Boş düğümler (bilinmeyen atalar) için şeffaf bir kutu.
      return SizedBox(
        height: cardHeight,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: const Center(
            child: Text(
              'Bilinmiyor',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
                fontSize: 10,
              ),
            ),
          ),
        ),
      );
    }

    // Cinsiyete göre renk ve ikon belirleme
    Color renk = Colors.grey.shade200;
    IconData icon = Icons.pets;
    if (node.cinsiyet == 'Erkek') {
      renk = const Color(0xFFE3F2FD); // Light Blue
      icon = Icons.male;
    } else if (node.cinsiyet == 'Dişi') {
      renk = const Color(0xFFFCE4EC); // Light Pink
      icon = Icons.female;
    }

    return SizedBox(
      height: cardHeight,
      child: Card(
        color: renk,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: Colors.grey.shade400,
            width: 0.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Halka No (Ring Number)
              Row(
                children: [
                  Icon(icon, size: 12, color: Colors.blueGrey.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      node.halkaNo!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blueGrey.shade900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // İsim (Name)
              Text(
                node.isim ?? 'İsimsiz',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              // Seviye (Level) - Debug amaçlı tutulabilir
              // Text(
              //   'Lvl: ${node.level}',
              //   style: TextStyle(fontSize: 8, color: Colors.grey),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}