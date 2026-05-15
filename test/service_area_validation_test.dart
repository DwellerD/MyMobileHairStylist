import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_hair_salon/features/customer/booking/domain/service_area_validation.dart';

void main() {
  test('normalizeServiceAreaPostalCode trims ZIP+4 to the launch ZIP', () {
    expect(normalizeServiceAreaPostalCode('84005-1234'), '84005');
    expect(normalizeServiceAreaPostalCode(' 84005 '), '84005');
  });

  test('resolveServiceAreaStatus treats supported ZIPs as serviceable', () {
    expect(
      resolveServiceAreaStatus(
        postalCode: '84005',
        storedStatus: 'out_of_area',
      ),
      'serviceable',
    );
  });

  test('resolveServiceAreaStatus keeps unsupported ZIPs out of area', () {
    expect(
      resolveServiceAreaStatus(postalCode: '99999', storedStatus: 'serviceable'),
      'out_of_area',
    );
  });
}