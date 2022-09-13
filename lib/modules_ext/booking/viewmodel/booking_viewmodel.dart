import 'package:flutter/material.dart';

import '../../../models/booking/booking_value.dart';
import '../../../models/booking/staff_booking_model.dart';
import '../../../services/index.dart';

class BookingViewmodel extends ValueNotifier<BookingValue> {
  BookingViewmodel(String? idProduct)
      : super(BookingValue(
          staffs: [],
          selectDate: '',
          listSlotSelect: [],
          isLoadingSlot: true,
          idProduct: idProduct,
        )) {
    getListStaff().then((value) {
      updateSlot(DateTime.now()).then((value) => updateStatusLoading(false));
    });
  }
  void updateStatusLoading(isLoading) {
    value = value.copyWith(isLoadingSlot: isLoading);
  }

  void clear() {
    value = BookingValue(
      staffs: [],
      selectDate: '',
      listSlotSelect: [],
      isLoadingSlot: false,
      idProduct: '',
    );
  }
}

extension BookingViewmodelProperties on BookingViewmodel {
  List<StaffBookingModel>? get staffs => value.staffs;
  List<String>? get listSlotSelect =>
      (value.listSlotSelect?.isNotEmpty ?? false) ? value.listSlotSelect : [];
  String? get selectDate => value.selectDate;
  bool get isLoadingSlot => value.isLoadingSlot;

  set staffs(List<StaffBookingModel>? staffs) {
    value.staffs!.clear();
    value.staffs!.addAll(staffs!);
    value = value.copyWith(staffs: value.staffs);
  }

  set listSlotSelect(List<String>? listSlotSelect) {
    value = value.copyWith(listSlotSelect: listSlotSelect);
  }

  set selectDate(String? selectDate) {
    value = value.copyWith(selectDate: selectDate);
  }
}

extension BookingInteractor on BookingViewmodel {
  Services get _service => Services();
  Future<void> getListStaff() async {
    final listStaff = await _service.api.getListStaff(value.idProduct)!;
    if (listStaff.isNotEmpty) {
      staffs = listStaff as List<StaffBookingModel>;
    }
  }

  Future<void> updateSlot(DateTime date, [int? idStaff]) async {
    updateStatusLoading(true);
    var dateChoose = '${date.year}-${date.month}-${date.day}';
    listSlotSelect!.clear();

    final listSlot = await _service.api.getSlotBooking(
      value.idProduct,
      '$idStaff',
      dateChoose,
    )!;

    if (listSlot.isNotEmpty) {
      listSlotSelect = listSlot;
    }
    updateStatusLoading(false);
  }
}
