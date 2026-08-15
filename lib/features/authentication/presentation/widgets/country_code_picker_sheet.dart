import 'package:flutter/material.dart';
import 'package:workaxis/core/constants/app_radius.dart';
import 'package:workaxis/core/constants/app_spacing.dart';
import 'package:workaxis/core/models/country_code.dart';
import 'package:workaxis/core/theme/app_colors.dart';
import 'package:workaxis/core/widgets/app_text_field.dart';

class CountryCodePickerSheet extends StatefulWidget {
  const CountryCodePickerSheet({
    required this.selectedCountry,
    super.key,
  });

  final CountryCode selectedCountry;

  static Future<CountryCode?> show({
    required BuildContext context,
    required CountryCode selectedCountry,
  }) {
    return showModalBottomSheet<CountryCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) =>
          CountryCodePickerSheet(selectedCountry: selectedCountry),
    );
  }

  @override
  State<CountryCodePickerSheet> createState() => _CountryCodePickerSheetState();
}

class _CountryCodePickerSheetState extends State<CountryCodePickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = CountryCode.supportedCountries.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.dialCode.contains(q) ||
          c.code.toLowerCase().contains(q);
    }).toList();

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginCompact,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: AppRadius.borderFull,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Select Country / Region',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Search Field
                AppTextField(
                  hintText: 'Search country or dialing code...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Countries List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No countries match "$_searchQuery".',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: AppColors.outlineVariant,
                          ),
                          itemBuilder: (context, index) {
                            final country = filtered[index];
                            final isSelected =
                                country.code == widget.selectedCountry.code &&
                                    country.dialCode ==
                                        widget.selectedCountry.dialCode;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              leading: Text(
                                country.flag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(
                                country.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    country.dialCode,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    const Icon(
                                      Icons.check_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).pop(country);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
