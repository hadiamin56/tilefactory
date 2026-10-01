class MarketPrice {
  final String produceName;
  final double pricePerKg;
  final double changePercent; // positive = up, negative = down

  const MarketPrice({
    required this.produceName,
    required this.pricePerKg,
    required this.changePercent,
  });
}
