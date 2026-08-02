void main() {
  final Set<String> cats = {};
  final products = [
    {'category': ''},
    {'category': 'Fruit'},
    {'category': 'Vegetables/菜枼'},
    {'category': 'All'},
    {'category': 'Fruit'},
  ];
  
  for (var p in products) {
    if (p['category']!.isNotEmpty) cats.add(p['category']!);
  }
  
  cats.removeAll({'Leafy Greens', 'Root Vegetables', 'Herbs', 'All'});
  
  final sorted = cats.toList()..sort();
  final dynamicCategories = ['All', ...sorted];
  
  print('dynamicCategories: $dynamicCategories');
  
  String value = 'All';
  int matches = dynamicCategories.where((c) => c == value).length;
  print('Matches for "$value": $matches');
}
