enum BookingServiceCategory {
  women('Women'),
  hairColor('Hair Color'),
  men('Men'),
  kids('Kids'),
  addOns('Add-Ons'),
  specialEventWedding('Special Event / Wedding');

  const BookingServiceCategory(this.label);

  final String label;
}

class BookingServiceCatalogEntry {
  const BookingServiceCatalogEntry({
    required this.category,
    required this.name,
  });

  final BookingServiceCategory category;
  final String name;
}

const List<BookingServiceCatalogEntry> bookingServiceCatalog =
    <BookingServiceCatalogEntry>[
  BookingServiceCatalogEntry(category: BookingServiceCategory.women, name: 'Women\'s Haircut'),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.women,
    name: 'Shampoo, Haircut & Style',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.women,
    name: 'Trim / Maintenance Cut',
  ),
  BookingServiceCatalogEntry(category: BookingServiceCategory.women, name: 'Layered Haircut'),
  BookingServiceCatalogEntry(category: BookingServiceCategory.women, name: 'Long Haircut'),
  BookingServiceCatalogEntry(category: BookingServiceCategory.women, name: 'Bob / Lob Haircut'),
  BookingServiceCatalogEntry(category: BookingServiceCategory.women, name: 'Curly Haircut'),
  BookingServiceCatalogEntry(category: BookingServiceCategory.women, name: 'Bang Trim'),
  BookingServiceCatalogEntry(category: BookingServiceCategory.women, name: 'Blowout & Style'),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.women,
    name: 'Special Event Styling',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.women,
    name: 'Bridal / Wedding Hair',
  ),
  BookingServiceCatalogEntry(category: BookingServiceCategory.hairColor, name: 'Highlights'),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.hairColor,
    name: 'Partial Highlights',
  ),
  BookingServiceCatalogEntry(category: BookingServiceCategory.hairColor, name: 'Baby Lights'),
  BookingServiceCatalogEntry(category: BookingServiceCategory.hairColor, name: 'Balayage'),
  BookingServiceCatalogEntry(category: BookingServiceCategory.hairColor, name: 'Root Retouch'),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.hairColor,
    name: 'All Over Color',
  ),
  BookingServiceCatalogEntry(category: BookingServiceCategory.hairColor, name: 'Toner / Gloss'),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.hairColor,
    name: 'Color Correction',
  ),
  BookingServiceCatalogEntry(category: BookingServiceCategory.men, name: 'Men\'s Haircut'),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.men,
    name: 'Haircut + Beard Trim',
  ),
  BookingServiceCatalogEntry(category: BookingServiceCategory.men, name: 'Buzz Cut'),
  BookingServiceCatalogEntry(category: BookingServiceCategory.men, name: 'Fade / Taper Cut'),
  BookingServiceCatalogEntry(category: BookingServiceCategory.men, name: 'Beard Trim'),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.men,
    name: 'Eyebrow Cleanup',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.men,
    name: 'Scalp Treatment',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.kids,
    name: 'Kids Haircut – Boys',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.kids,
    name: 'Kids Haircut – Girls',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.kids,
    name: 'Kids Shampoo + Cut',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.kids,
    name: 'First Haircut Package',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.kids,
    name: 'Braids / Simple Styling',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.addOns,
    name: 'Deep Conditioning Treatment',
  ),
  BookingServiceCatalogEntry(category: BookingServiceCategory.addOns, name: 'Toner / Gloss'),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.addOns,
    name: 'Extra Styling Time',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.addOns,
    name: 'Hot Tool Styling',
  ),
  BookingServiceCatalogEntry(category: BookingServiceCategory.addOns, name: 'Hair Tinsel'),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.addOns,
    name: 'Scalp Treatment',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.addOns,
    name: 'Eyebrow Cleanup',
  ),
  BookingServiceCatalogEntry(category: BookingServiceCategory.addOns, name: 'Beard Trim'),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.addOns,
    name: 'Extension Blend Style',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.specialEventWedding,
    name: 'Bridal Trial',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.specialEventWedding,
    name: 'Bridal Hair Styling',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.specialEventWedding,
    name: 'Bridesmaid Styling',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.specialEventWedding,
    name: 'Flower Girl Styling',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.specialEventWedding,
    name: 'Event Hair Styling',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.specialEventWedding,
    name: 'Glam Waves / Hollywood Waves',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.specialEventWedding,
    name: 'Updo Styling',
  ),
  BookingServiceCatalogEntry(
    category: BookingServiceCategory.specialEventWedding,
    name: 'On-Location Bridal Package',
  ),
];

final Map<String, BookingServiceCategory> bookingServiceCategoryByName =
    <String, BookingServiceCategory>{
  for (final entry in bookingServiceCatalog) entry.name.toLowerCase(): entry.category,
};

final Map<BookingServiceCategory, List<String>> bookingServiceNamesByCategory =
    <BookingServiceCategory, List<String>>{
  for (final category in BookingServiceCategory.values)
    category: bookingServiceCatalog
        .where((entry) => entry.category == category)
        .map((entry) => entry.name)
        .toList(growable: false),
};