import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/theme/colors/colors_extension.dart';
import 'package:expense_tracker/core/theme/text/app_text_style.dart';

class AuthAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Function()? onBack;
  final bool showBack;
  const AuthAppBarWidget({super.key, this.title, this.onBack, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: false,
      title: title != null
          ? Text(
              title ?? "",
              style: AppTextStyle.s20_w500(color: context.colors.black),
            )
          : null,
      backgroundColor: Colors.transparent,
      leading: Offstage(
        offstage: !showBack,
        child: InkWell(
          onTap: onBack ?? AutoRouter.of(context).pop,
          child: Icon(
            Icons.arrow_back,
            size: 30,
            color: context.colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(65);
}
