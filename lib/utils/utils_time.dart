part of 'utils.dart';

class _UtilsTime {
  DateTime getDateOnly([DateTime date]) {
    date = date ?? DateTime.now();
    return date.subtract(Duration(
        hours: date.hour,
        minutes: date.minute,
        seconds: date.second,
        milliseconds: date.millisecond,
        microseconds: date.microsecond));
  }

  DateTime setDate(DateTime date, DateTime newDate) =>
      DateTime(newDate.year, newDate.month, newDate.day, date.minute, date.second, date.millisecond, date.microsecond);

  DateTime setTime(DateTime date, int hours, int minutes, [int seconds, int milliseconds, int microseconds]) =>
      DateTime(date.year, date.month, date.day, hours, minutes, seconds ?? date.second,
          milliseconds ?? date.millisecond, microseconds ?? date.microsecond);

  String getFormattedDateByWords(DateTime date,
      {final yesterday = 'Yesterday', final today = 'Today', final tomorrow = 'Tomorrow'}) {
    date = getDateOnly(date);
    const singleDay = const Duration(days: 1);

    final dateNow = getDateOnly(DateTime.now());
    final dateYesterday = dateNow.subtract(singleDay);
    final dateTomorrow = dateNow.add(singleDay);

    var title = getFormattedDate(date);
    if (date == dateYesterday) {
      title = yesterday;
    } else if (date == dateTomorrow) {
      title = tomorrow;
    } else if (date == dateNow) {
      title = today;
    }

    return title;
  }

  String getFormattedDateTimeByWords(DateTime date,
          {final yesterday = 'Yesterday', final today = 'Today', final tomorrow = 'Tomorrow'}) =>
      '${getFormattedDateByWords(date, yesterday: yesterday, today: today, tomorrow: tomorrow)} ${getFormattedTime(date)}';

  String getFormattedTime(DateTime date) => '${date.hour}:${date.minute}';

  String getFormattedDate(DateTime date) => '${date.month} / ${date.day} / ${date.year}';
}
