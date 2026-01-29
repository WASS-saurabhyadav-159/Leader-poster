import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/colors.dart';
import '../../constants/app_colors.dart';
import 'onboarding.dart';

class Footer extends StatelessWidget {
  final int _pageCount;
  final int _currentPage;
  final void Function() onNext;

  const Footer(this._pageCount, this._currentPage, this.onNext, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (_currentPage == _pageCount - 1) {
      children.add(
        OnboardingButton(
          "LETS START",
          onNext,
        ),
      );
    } else {
      children.add(
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Selector(_pageCount - 1, _currentPage),
              SvgPicture.asset("assets/arrow-right.svg")
            ],
          ),
        ),
      );
      children.add(
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // soft shadow
                blurRadius: 6,
                offset: const Offset(0, 3), // vertical shadow
              ),
            ],
            borderRadius: BorderRadius.circular(8), // match button shape
          ),
          child: OnboardingButton("NEXT", onNext),
        ),
      );

    }

    return Container(
        color: AppColors.accentOrange,
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      );
  }
}

class Selector extends StatelessWidget {
  final int _pageCount;
  final int _currentPage;

  const Selector(this._pageCount, this._currentPage, {super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    for (int i = 0; i < _pageCount; i++) {
      Color borderColor = i != _currentPage
          ? SharedColors.selectorBorderColor
          : SharedColors.primaryLight;
      Color bodyColor =
          i != _currentPage ? SharedColors.primary : SharedColors.primaryLight;
      children.add(Container(
        width: 8.0,
        height: 8.0,
        decoration: BoxDecoration(
            color: bodyColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor)),
      ));
      children.add(const SizedBox(
        width: 4.0,
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class LastFooter extends StatelessWidget {
  const LastFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
