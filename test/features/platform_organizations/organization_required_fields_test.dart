import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/features/platform_organizations/presentation/widgets/organization_form/organization_form_state.dart';

void main() {
  group('organization required fields', () {
    late OrganizationFormState form;

    setUp(() => form = OrganizationFormState());
    tearDown(() => form.dispose());

    void fillRequired() {
      form.name.text = 'Acme Retail';
      form.address.text = '12 Market Road, Pune';
      form.contactName.text = 'Priya Shah';
      form.contactPhone.text = '+91 98765 43210';
    }

    test('edit requires the headquarters address, contact name and phone', () {
      form.name.text = 'Acme Retail';

      final errors = form.validate(
        missingNameMessage: 'Name is required.',
        requiresContactDetails: true,
      );

      expect(errors.address, 'Enter the headquarters address.');
      expect(errors.contactName, 'Enter the contact person name.');
      expect(errors.phone, 'Enter the contact phone number.');
      expect(errors.hasErrors, isTrue);
    });

    test('a complete organization passes the same rule', () {
      fillRequired();

      final errors = form.validate(
        missingNameMessage: 'Name is required.',
        requiresContactDetails: true,
      );

      expect(errors.hasErrors, isFalse);
    });

    test('the rule stays off unless asked for', () {
      form.name.text = 'Legacy Co';

      final errors = form.validate(missingNameMessage: 'Name is required.');

      expect(errors.hasErrors, isFalse);
    });

    test('an invalid phone is still rejected when the rule is on', () {
      fillRequired();
      form.contactPhone.text = '12345';

      final errors = form.validate(
        missingNameMessage: 'Name is required.',
        requiresContactDetails: true,
      );

      expect(errors.phone, isNotNull);
      expect(errors.phone, isNot('Enter the contact phone number.'));
    });
  });
}
