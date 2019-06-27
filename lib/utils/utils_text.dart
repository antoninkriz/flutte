part of 'utils.dart';

class _UtilsText {
  Color colorForBalance<T>(num val,
      {Color positive = Colors.lightGreen, Color negative = Colors.red, Color zero = Colors.white}) {
    if (val > 0)
      return positive;
    else if (val < 0)
      return negative;
    else
      return zero;
  }
}
