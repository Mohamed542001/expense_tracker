import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/bloc/device_cubit/device_cubit.dart';
import 'package:expense_tracker/core/constants/input_field_style/custom_input_decoration.dart';
import 'package:expense_tracker/core/theme/colors/colors_extension.dart';
import 'package:expense_tracker/core/theme/text/app_text_style.dart';

class GenericTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final bool autoFocus;
  final int? max;
  final EdgeInsets? margin;
  final EdgeInsets? contentPadding;
  final TextInputType type;
  final TextInputAction action;
  final BorderRadius? radius;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final Function()? onTab;
  final Color? enableBorderColor;
  final Color? focusBorderColor;
  final Color? fillColor;
  final Color? hintColor;
  final Color? textColor;
  final int? maxLength;
  final TextAlign? textAlign;
  final Function(String? value) validate;
  final FieldTypes fieldTypes;
  final Function()? onSubmit;
  final Function(String)? onChange;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autoValidateMode;
  final String? fontFamily;
  final TextDirection? textDirection;

  const GenericTextField(
      {super.key,
      this.label,
      this.hint,
      required this.fieldTypes,
      this.controller,
      this.focusNode,
      this.margin,
      this.textAlign,
      this.autoFocus = false,
      this.contentPadding,
      this.inputFormatters,
      required this.type,
      this.onTab,
      this.radius,
      this.max,
      this.maxLength,
      this.suffixWidget,
      this.prefixWidget,
      this.textColor,
      this.fillColor,
      this.hintColor,
      this.prefixIcon,
      this.suffixIcon,
      this.onChange,
      this.textDirection,
      this.fontFamily,
      this.autoValidateMode,
      this.onSubmit,
      required this.action,
      this.enableBorderColor,
      this.focusBorderColor,
      required this.validate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(0),
      child: Visibility(
        visible: fieldTypes == FieldTypes.clickable,
        replacement: buildFormFiled(context),
        child: buildClickableView(context),
      ),
    );
  }

  Widget buildClickableView(BuildContext context) {
    return InkWell(
      onTap: onTab,
      child: AbsorbPointer(
        absorbing: true,
        child: buildFormFiled(context),
      ),
    );
  }

  Widget buildFormFiled(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      textInputAction: action,
      enableSuggestions: false,
      autocorrect: false,
      autofocus: autoFocus,
      focusNode: focusNode,
      textDirection: textDirection,
      autovalidateMode: autoValidateMode ?? AutovalidateMode.onUserInteraction,
      inputFormatters: inputFormatters ??
          [
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength), //n is maximum number of characters you want in textfield
          ],
      enabled: fieldTypes != FieldTypes.disable,
      autofillHints: getAutoFillHints(type),
      maxLines: fieldTypes == FieldTypes.chat
          ? null
          : fieldTypes == FieldTypes.rich
              ? max
              : 1,
      obscureText: fieldTypes == FieldTypes.password,
      readOnly: fieldTypes == FieldTypes.readonly,
      onEditingComplete: onSubmit,
      onChanged: onChange,
      validator: (value) => validate(value),
      textAlign: textAlign ?? TextAlign.start,
      style: AppTextStyle.s14_w400(color: textColor ?? context.colors.black).copyWith(fontFamily: fontFamily),
      decoration: CustomInputDecoration(
        labelTxt: label,
        hint: hint,
        prefIcon: prefixIcon,
        sufIcon: suffixIcon,
        enableColor: enableBorderColor,
        focsColor: focusBorderColor,
        customFillColor: fillColor,
        padding: contentPadding,
        hintColor: hintColor,
        borderRadius: radius,
        lang: context.watch<DeviceCubit>().state.model.locale.languageCode,
      ),
    );
  }

  List<String> getAutoFillHints(TextInputType inputType) {
    if (inputType == TextInputType.emailAddress) {
      return [AutofillHints.email];
    } else if (inputType == TextInputType.datetime) {
      return [AutofillHints.birthday];
    } else if (inputType == TextInputType.phone) {
      return [AutofillHints.telephoneNumber];
    } else if (inputType == TextInputType.url) {
      return [AutofillHints.url];
    }
    return [AutofillHints.name, AutofillHints.username];
  }
}

enum FieldTypes { normal, clickable, readonly, chat, password, rich, disable }
