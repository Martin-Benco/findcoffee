import 'lib/core/utils.dart';

void main() {
  print('=== Test formátovania vzdialenosti ===');
  
  // Test pre vzdialenosti menej ako 1 km
  print('Test pre vzdialenosti < 1 km:');
  print('0.1 km -> ${AppUtils.formatDistance(0.1)}'); // Očakávané: 100 m
  print('0.5 km -> ${AppUtils.formatDistance(0.5)}'); // Očakávané: 500 m
  print('0.85 km -> ${AppUtils.formatDistance(0.85)}'); // Očakávané: 850 m
  print('0.999 km -> ${AppUtils.formatDistance(0.999)}'); // Očakávané: 999 m
  
  print('\nTest pre vzdialenosti 1-2 km:');
  print('1.0 km -> ${AppUtils.formatDistance(1.0)}'); // Očakávané: 1.0 km
  print('1.2 km -> ${AppUtils.formatDistance(1.2)}'); // Očakávané: 1.2 km
  print('1.5 km -> ${AppUtils.formatDistance(1.5)}'); // Očakávané: 1.5 km
  print('1.9 km -> ${AppUtils.formatDistance(1.9)}'); // Očakávané: 1.9 km
  print('2.0 km -> ${AppUtils.formatDistance(2.0)}'); // Očakávané: 2.0 km
  
  print('\nTest pre vzdialenosti > 2 km:');
  print('2.1 km -> ${AppUtils.formatDistance(2.1)}'); // Očakávané: 2 km
  print('2.5 km -> ${AppUtils.formatDistance(2.5)}'); // Očakávané: 3 km
  print('3.0 km -> ${AppUtils.formatDistance(3.0)}'); // Očakávané: 3 km
  print('5.0 km -> ${AppUtils.formatDistance(5.0)}'); // Očakávané: 5 km
  print('10.0 km -> ${AppUtils.formatDistance(10.0)}'); // Očakávané: 10 km
  
  print('\n=== Test dokončený ===');
} 