class BookingRequest {
  final String id;
  final String name;
  final String location;
  final String need;
  final bool topCustomer;

  BookingRequest({
    required this.id,
    required this.name,
    required this.location,
    required this.need,
    required this.topCustomer,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> m) => BookingRequest(
        id: m['id'],
        name: m['name'],
        location: m['location'],
        need: m['need'],
        topCustomer: m['topCustomer'] ?? false,
      );
}