import 'package:flutter/material.dart';
import '../../models/BookingRequest.dart';
import '../../utils/SizeHelper.dart';

class BookingCard extends StatelessWidget {
  final BookingRequest data;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onView;

  const BookingCard({
    super.key,
    required this.data,
    required this.onAccept,
    required this.onDecline,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    double w(double v) => SizeHelper.byWidth(context, v);
    double h(double v) => SizeHelper.byHeight(context, v);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // white like the mock
        borderRadius: BorderRadius.circular(w(12)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
            blurRadius: h(10),
            offset: Offset(0, h(4)),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(w(16), h(14), w(16), h(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT — name, location, need
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: TextStyle(
                    fontSize: h(12), // use height for font scaling
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2024),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: h(5)),
                Text(
                  data.location,
                  style: TextStyle(
                    fontSize: h(10),
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF000000),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data.need,
                  style: TextStyle(
                    fontSize: h(9),
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF71727A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: w(12)),

          // RIGHT — View + buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(height: h(1)),
              TextButton(
                onPressed: onView,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(w(0), h(0)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFFFF8D29),
                ),
                child: Text(
                  'View',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationThickness: 1.2,
                    decorationColor: const Color(0xFFFF8D29),
                    fontSize: h(9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: h(10)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // DECLINE
                  SizedBox(
                    width: w(110),        // wider so text never wraps
                    height: h(32),
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(w(110), h(32)),
                        padding: EdgeInsets.zero,
                        foregroundColor: const Color(0xFF1F2024),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        backgroundColor: const Color(0xFFFCFEFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(w(6)),
                        ),
                      ),
                      child: Text(
                        'Decline',
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: h(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: w(8)),

                  // ACCEPT
                  SizedBox(
                    width: w(110),
                    height: h(32),
                    child: FilledButton(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        minimumSize: Size(w(110), h(32)),
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFFFF7A2F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(w(6)),
                        ),
                      ),
                      child: Text(
                        'Accept',
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: h(12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
