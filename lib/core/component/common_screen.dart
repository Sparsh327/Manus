import 'package:flutter/material.dart';
import 'package:quickui/quickui.dart';

class CommonScreen extends StatelessWidget {
  final bool? showLoader;
  final bool? resize;
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final double? horizontalPadding;
  final double? verticalPadding;
  final Color? bgColor;
  final Widget? floatingActionButton;

  const CommonScreen({
    super.key,
    this.showLoader = false,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.horizontalPadding,
    this.verticalPadding,
    this.bgColor,
    this.resize,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: bgColor ?? Colors.white,
          resizeToAvoidBottomInset: resize ?? true,
          extendBodyBehindAppBar: true,
          appBar: appBar,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: SafeArea(
              child: Padding_(
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                child: child,
              ),
            ),
          ),
        ),
        Visibility(
          visible: showLoader ?? false,
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }
}
