import 'package:equatable/equatable.dart';

/// A dialling country for the phone sign-in picker.
class Country extends Equatable {
  const Country(this.isoCode, this.shortName, this.name, this.dialCode);

  final String isoCode;
  final String shortName;
  final String name;
  final String dialCode;

  String get label => '$shortName $dialCode';

  @override
  List<Object?> get props => [isoCode, dialCode];

  static const uganda = Country('UG', 'UG', 'Uganda', '+256');

  /// Uganda plus where most remote owners live. "Any country works":
  /// the list only seeds the picker; the number is sent as E.164.
  static const all = [
    uganda,
    Country('KE', 'KE', 'Kenya', '+254'),
    Country('TZ', 'TZ', 'Tanzania', '+255'),
    Country('RW', 'RW', 'Rwanda', '+250'),
    Country('SS', 'SS', 'South Sudan', '+211'),
    Country('GB', 'UK', 'United Kingdom', '+44'),
    Country('IE', 'IE', 'Ireland', '+353'),
    Country('US', 'US', 'United States', '+1'),
    Country('CA', 'CA', 'Canada', '+1'),
    Country('AE', 'AE', 'United Arab Emirates', '+971'),
    Country('SA', 'SA', 'Saudi Arabia', '+966'),
    Country('QA', 'QA', 'Qatar', '+974'),
    Country('ZA', 'ZA', 'South Africa', '+27'),
    Country('DE', 'DE', 'Germany', '+49'),
    Country('NL', 'NL', 'Netherlands', '+31'),
    Country('SE', 'SE', 'Sweden', '+46'),
    Country('NO', 'NO', 'Norway', '+47'),
    Country('DK', 'DK', 'Denmark', '+45'),
    Country('BE', 'BE', 'Belgium', '+32'),
    Country('FR', 'FR', 'France', '+33'),
    Country('IT', 'IT', 'Italy', '+39'),
    Country('AU', 'AU', 'Australia', '+61'),
    Country('IN', 'IN', 'India', '+91'),
    Country('CN', 'CN', 'China', '+86'),
  ];

  /// The country for [isoCode] (e.g. from the device locale), else Uganda.
  static Country fromIso(String? isoCode) => all.firstWhere(
    (c) => c.isoCode == isoCode?.toUpperCase(),
    orElse: () => uganda,
  );
}
