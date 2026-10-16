import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../utils/country.dart';

Future<Country?> showCountryPicker(
  BuildContext context, {
  required Country selected,
}) => showModalBottomSheet<Country>(
  context: context,
  isScrollControlled: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    maxChildSize: 0.9,
    builder: (context, controller) => ListView.separated(
      controller: controller,
      itemCount: Country.all.length,
      separatorBuilder: (_, _) => const Divider(indent: 20, endIndent: 20),
      itemBuilder: (context, i) {
        final country = Country.all[i];
        final isSelected = country == selected;
        return ListTile(
          minTileHeight: 52,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Text(country.name, style: AppTextStyles.bodyLarge),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                country.dialCode,
                style: AppTextStyles.mono(
                  size: 14,
                  color: AppColors.ink2,
                  letterSpacing: 0,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 12),
                const Icon(Icons.check, size: 20),
              ],
            ],
          ),
          onTap: () => Navigator.of(context).pop(country),
        );
      },
    ),
  ),
);
