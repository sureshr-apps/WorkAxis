import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/app/theme/app_theme.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/assets/data/sql_connect_assets_repository.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';
import 'package:workaxis/features/assets/presentation/widgets/employee_asset_card.dart';

import '../../helpers/access_fixtures.dart';
import '../../helpers/fake_data_gateway.dart';

const _pendingAsset = EmployeeAsset(
  id: 'asset-1',
  organizationId: 'org-acme',
  branchId: 'br-01',
  branchName: 'Downtown Flagship',
  employeeId: 'user-emp-01',
  employeeName: 'Sarah Connor',
  name: 'Work phone',
  category: 'Device',
  assetTag: 'WA-001',
  status: AssetStatus.assigned,
  acknowledgementRequired: true,
  acknowledgementStatus: AssetAcknowledgementStatus.pending,
);

void main() {
  group('employee asset acknowledgment', () {
    test('maps the server result and sends only the asset id', () async {
      final gateway = FakeDataGateway()
        ..respond('AcknowledgeMyEmployeeAsset', {
          'employeeAsset': {
            'id': 'asset-1',
            'organizationId': 'org-acme',
            'branchId': 'br-01',
            'branchName': 'Downtown Flagship',
            'employeeId': 'user-emp-01',
            'employeeName': 'Sarah Connor',
            'name': 'Work phone',
            'category': 'Device',
            'assetTag': 'WA-001',
            'status': 'assigned',
            'acknowledgementRequired': true,
            'acknowledgementStatus': 'acknowledged',
          },
        });
      final repository = SqlConnectAssetsRepository(gateway: gateway);

      final acknowledged = await repository.acknowledgeAsset(
        access: employeeAccess(),
        assetId: 'asset-1',
      );

      expect(gateway.singleVarsOf('AcknowledgeMyEmployeeAsset'), {
        'assetId': 'asset-1',
      });
      expect(
        acknowledged.acknowledgementStatus,
        AssetAcknowledgementStatus.acknowledged,
      );
    });

    test(
      'rejects acknowledgment attempts from manager sessions locally',
      () async {
        final repository = SqlConnectAssetsRepository(
          gateway: FakeDataGateway(),
        );

        await expectLater(
          repository.acknowledgeAsset(
            access: branchManagerAccess(),
            assetId: 'asset-1',
          ),
          throwsA(isA<AccessDeniedException>()),
        );
      },
    );

    testWidgets('employee sees a receipt confirmation action', (tester) async {
      var acknowledged = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 280,
                child: EmployeeAssetCard(
                  asset: _pendingAsset,
                  canEdit: false,
                  canAcknowledge: true,
                  onAcknowledge: () => acknowledged = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Acknowledge receipt'), findsOneWidget);
      await tester.tap(find.text('Acknowledge receipt'));
      await tester.pump();
      expect(acknowledged, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('manager sees pending state without an acknowledgment action', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 280,
                child: EmployeeAssetCard(
                  asset: _pendingAsset,
                  canEdit: true,
                  onEdit: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Awaiting employee acknowledgment'), findsOneWidget);
      expect(find.text('Acknowledge receipt'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
