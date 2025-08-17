import 'package:flutter/material.dart';
import '../../utils/SizeHelper.dart';


class HomePage extends StatelessWidget {
  final VoidCallback onAddProduct;

  const HomePage({
    super.key,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeHelper.byWidth(context, 18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: SizeHelper.byHeight(context, 28)),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
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
              SizedBox(height: SizeHelper.byHeight(context, 8)),
              const Text(
                "Find Clients & Sell Products in One Tap",
                style: TextStyle(
                    color: Color(0xFF71727A),
                    fontSize: 14,
                    fontWeight: FontWeight.w400),
              ),
              SizedBox(height: SizeHelper.byHeight(context, 32)),
              _RoundedCard(
                title: "Add Products",
                subtitle: "Sell you products",
                onTap: () {onAddProduct();},
              ),
              SizedBox(height: SizeHelper.byHeight(context, 16)),
              _RoundedCard(
                title: "View Booking",
                subtitle: "View List for Product bookings",
                onTap: () {},
              ),
              SizedBox(height: SizeHelper.byHeight(context, 34)),
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF2E8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "You'll get:",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF1F2024),
                          ),
                        ),
                        SizedBox(height: SizeHelper.byHeight(context, 10)),
                        const _BenefitRow(text: "Trusted Customers"),
                        const _BenefitRow(text: "Branding your shop"),
                        const _BenefitRow(text: "Chat directly with your client and electrician"),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: SizeHelper.byWidth(context, 32),
                      height: SizeHelper.byHeight(context, 32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF8D29),
                      ),
                      child: const Center(
                        child: Icon(Icons.star, color: Colors.white, size: 18),
                      ),
                    ),
                  )
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
      color: Color(0xFFFFF2E8),
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
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Color(0xFF1F2024),
                    ),
                  ),
                  SizedBox(height: SizeHelper.byHeight(context, 4)),
                  Text(subtitle,
                    style: const TextStyle(color: Color(0xFF71727A), fontSize: 12, fontWeight: FontWeight.w400 ),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF8F9098), size: 32),
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
    padding: EdgeInsets.symmetric(vertical: SizeHelper.byHeight(context, 2)),
    child: Row(
      children: [
        Icon(Icons.star, color: Color(0xFFFF8D29), size: 17),
        SizedBox(width: SizeHelper.byWidth(context, 7)),
        Flexible(child: Text(
          text,
          style: const TextStyle(fontSize: 15, color: Color(0xFF71727A)),
        )),
      ],
    ),
  );
}
