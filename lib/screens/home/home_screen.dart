import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../models/app_model.dart';
import '../../modules/dynamic_layout/index.dart';
import '../../services/index.dart';
import '../../widgets/home/index.dart';
import '../../widgets/home/wrap_status_bar.dart';
import '../base_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen();

  @override
  State<StatefulWidget> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends BaseScreen<HomeScreen> {
  // @override
  // bool get wantKeepAlive => true;

  @override
  void dispose() {
    printLog('[Home] dispose');
    super.dispose();
  }

  @override
  void initState() {
    printLog('[Home] initState');
    super.initState();
  }

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    /// init dynamic link
    if (!kIsWeb) {
      Services().firebase.initDynamicLinkService(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    printLog('[Home] build');
    return Selector<AppModel, Tuple2<AppConfig?, String>>(
      selector: (_, model) => Tuple2(model.appConfig, model.langCode),
      builder: (_, value, child) {
        var appConfig = value.item1;
        var langCode = value.item2;

        if (appConfig == null) {
          return kLoadingWidget(context);
        }

        var isStickyHeader = appConfig.settings.stickyHeader;
        final horizontalLayoutList =
            List.from(appConfig.jsonData['HorizonLayout']);
        final isShowAppbar = horizontalLayoutList.isNotEmpty &&
            horizontalLayoutList.first['layout'] == 'logo';
        return Scaffold(
          backgroundColor: Theme.of(context).backgroundColor,
          body: Stack(
            children: <Widget>[
              if (appConfig.background != null)
                isStickyHeader
                    ? SafeArea(
                        child: HomeBackground(config: appConfig.background),
                      )
                    : HomeBackground(config: appConfig.background),
              HomeLayout(
                isPinAppBar: isStickyHeader,
                isShowAppbar: isShowAppbar,
                showNewAppBar:
                    appConfig.appBar?.shouldShowOn(RouteList.home) ?? false,
                configs: appConfig.jsonData,
                key: Key(langCode),
              ),
              if (ServerConfig().isBuilder) const WrapStatusBar(),
            ],
          ),
        );
      },
    );
  }
}
