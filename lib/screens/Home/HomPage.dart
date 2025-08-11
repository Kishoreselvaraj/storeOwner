import 'package:flutter/material.dart';
import '../ProductListPage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black),
                  children: [
                    TextSpan(text: "Sell your products and\n"),
                    TextSpan(text: "Get Clients in "),
                    TextSpan(
                        text: "One",
                        style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Find Clients & Sell Products in One Tap",
                style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 32),
              _RoundedCard(
                title: "Add Products",
                subtitle: "Sell you products",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListPage()));
                },
              ),
              const SizedBox(height: 16),
              _RoundedCard(
                title: "View Booking",
                subtitle: "View List for Product bookings",
                onTap: () {},
              ),
              const SizedBox(height: 34),
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "You'll get:",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        _BenefitRow(text: "Trusted Customers"),
                        _BenefitRow(text: "Branding your shop"),
                        _BenefitRow(text: "Chat directly with your client and electrician"),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10, right: 14,
                    child: Icon(Icons.star, color: Colors.orange, size: 24),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _RoundedCard({required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.withOpacity(0.05),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, color: Colors.orange, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;
  const _BenefitRow({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(Icons.star, color: Colors.orange[600], size: 17),
        const SizedBox(width: 7),
        Flexible(child: Text(
          text,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        )),
      ],
    ),
  );
}
