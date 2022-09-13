import 'package:myfatoorah_flutter/utils/MFCountry.dart';

class MFUtils {
  static MFCountry getMFCountryByCountryCode(String? code) {
    switch (code) {
      case 'KW':
        return MFCountry.KUWAIT;
      case 'SA':
        return MFCountry.SAUDI_ARABIA;
      case 'BH':
        return MFCountry.BAHRAIN;
      case 'AR':
        return MFCountry.UNITED_ARAB_EMIRATES;
      case 'QA':
        return MFCountry.QATAR;
      case 'OM':
        return MFCountry.OMAN;
      case 'JO':
        return MFCountry.JORDAN;
      case 'EG':
        return MFCountry.EGYPT;
      default:
        return MFCountry.KUWAIT;
    }
  }
}