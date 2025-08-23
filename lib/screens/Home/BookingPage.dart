// ignore: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/BookingRequest.dart';
import '../../components/Home/BookingCard.dart';
import '../../components/Home/ProductsAppBar.dart';
import '../../utils/SizeHelper.dart'; // ← add this

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late final List<BookingRequest> _items;

  @override
  void initState() {
    super.initState();
    final List list = jsonDecode(sampleJson) as List;
    _items = list.map((e) => BookingRequest.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    double w(double v) => SizeHelper.byWidth(context, v);
    double h(double v) => SizeHelper.byHeight(context, v);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: ProductsAppBar(
        title: 'Booking',
        totalResults: _items.length,
        onBack: () => Navigator.pop(context),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: h(4)),
              child: const SectionLabel(text: 'TOP CUSTOMERS'),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: w(16), vertical: h(8)),
            sliver: SliverList.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => SizedBox(height: h(12)),
              itemBuilder: (context, i) => BookingCard(
                data: _items[i],
                onAccept: () => _snack(context, 'Accepted ${_items[i].name}'),
                onDecline: () => _snack(context, 'Declined ${_items[i].name}'),
                onView: () => _snack(context, 'Viewing ${_items[i].name}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext c, String msg) {
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    double w(double v) => SizeHelper.byWidth(context, v);
    double h(double v) => SizeHelper.byHeight(context, v);

    return Padding(
      padding: EdgeInsets.fromLTRB(w(20), h(8), w(20), h(4)),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8F9098),
        ),
      ),
    );
  }
}


const sampleJson = '''
[
  {
    "id": "1",
    "name": "Ashok Selvaraj",
    "location": "Coimbatore, TN",
    "need": "Need an 2 Fan",
    "topCustomer": true
  },
  {
    "id": "2",
    "name": "Sanjay B",
    "location": "Tiruppur, TN",
    "need": "Need an 3 Tube light",
    "topCustomer": true
  },
  {
    "id": "3",
    "name": "Tamilslevan",
    "location": "Salem, TN",
    "need": "Need an 4 Invertor",
    "topCustomer": true
  },
  {
    "id": "4",
    "name": "Kishore",
    "location": "Erode, TN",
    "need": "Need an 3 Tube light",
    "topCustomer": true
  },
  {
    "id": "5",
    "name": "Kannan",
    "location": "Madurai, TN",
    "need": "Need an 3 Tube light",
    "topCustomer": true
  },
  {
    "id": "6",
    "name": "Ravi Kumar",
    "location": "Chennai, TN",
    "need": "Need an 1 Ceiling Fan",
    "topCustomer": false
  }
]
''';
