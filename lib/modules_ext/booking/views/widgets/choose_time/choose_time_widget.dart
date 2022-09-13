import 'package:flutter/material.dart';

import '../../../../../common/constants.dart';
import 'choose_time_constants.dart';

class ChooseTimeWidget extends StatefulWidget {
  final DateTime? selectDate;
  final List<DateTime>? listSlotTime;
  final int paddingTime;
  final DateTime? initValue;
  final ValueChanged<DateTime>? onChooseTime;

  const ChooseTimeWidget({
    Key? key,
    this.initValue,
    this.selectDate,
    this.paddingTime = 60,
    this.onChooseTime,
    this.listSlotTime,
  })  : assert(
          paddingTime >= 1 && paddingTime <= 60,
          ' 1 <= paddingTime <= 60',
        ),
        super(key: key);

  @override
  State<ChooseTimeWidget> createState() => _ChooseTimeWidgetState();
}

class _ChooseTimeWidgetState extends State<ChooseTimeWidget> {
  DateTime? get _endTime =>
      widget.listSlotTime != null && widget.listSlotTime!.isNotEmpty
          ? widget.listSlotTime?.last
          : null;
  final listTitle = <Widget>[];
  DateTime? _timeSelect;

  List<Widget> _renderTime() {
    final listWidget = <Widget>[];
    final currentTime = DateTime.now();
    for (var j = 0;
        j < ChooseTimeConstants.defineLimitTime(context).length;
        j++) {
      final listSlots = <DateTime>[];
      final blockTimeCurrent = ChooseTimeConstants.defineLimitTime(context)[j];
      var listLost = widget.listSlotTime as List;

      for (var i = 0; i < listLost.length; i++) {
        final slot = widget.listSlotTime![i];
        if (blockTimeCurrent['timeStart'] <= slot.hour &&
            blockTimeCurrent['timeEnd'] >= slot.hour &&
            currentTime.isBefore(slot)) {
          listSlots.add(slot);
        }
      }

      listWidget.add(
        Expanded(
          child: Column(
            children: List.generate(
              listSlots.length,
              (index) => _buildButtonTime(listSlots[index]),
            ),
          ),
        ),
      );
    }

    return listWidget;
  }

  @override
  void didUpdateWidget(ChooseTimeWidget oldWidget) {
    if (oldWidget.selectDate != widget.selectDate ||
        widget.initValue != oldWidget.initValue ||
        ((widget.listSlotTime?.length ?? 0) !=
            (oldWidget.listSlotTime?.length ?? 0))) {
      _timeSelect = widget.initValue;
      setState(() {});
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _timeSelect = widget.initValue ?? DateTime.now();
    Future.delayed(Duration.zero, () {
      if (_endTime != null && _endTime is DateTime) {
        ChooseTimeConstants.defineLimitTime(context).last['timeEnd'] =
            _endTime!.hour;
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = isIos ? 350.0 : 250.0;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          _renderListTitle(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _renderTime(),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _renderListTitle() {
    final List lstTitle = <Widget>[];
    for (var item in ChooseTimeConstants.defineLimitTime(context)) {
      lstTitle.add(Expanded(
          child: Text(
        item['title'],
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      )));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: lstTitle as List<Widget>,
    );
  }

  Widget _buildButtonTime(DateTime time) {
    return TextButton(
      style: TextButton.styleFrom(
        primary: time == _timeSelect
            ? Theme.of(context).primaryColor
            : Theme.of(context).colorScheme.secondary,
        onSurface: time == _timeSelect
            ? Colors.white
            : Theme.of(context).buttonTheme.colorScheme!.onPrimary,
      ),
      onPressed: () {
        widget.onChooseTime?.call(time);
        setState(() {
          _timeSelect = time;
        });
      },
      child: Text(DateTimeUtils.getTimeBooking(time)),
    );
  }
}
