import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'main.dart';

class MyInAppBrowser extends InAppBrowser {
  MyInAppBrowser(
      {int? windowId, UnmodifiableListView<UserScript>? initialUserScripts})
      : super(windowId: windowId, initialUserScripts: initialUserScripts);

  @override
  Future onBrowserCreated() async {
    print("\n\nBrowser Created!\n\n");
  }

  @override
  Future onLoadStart(url) async {}

  @override
  Future onLoadStop(url) async {
    pullToRefreshController?.endRefreshing();
  }

  @override
  Future<PermissionResponse> onPermissionRequest(request) async {
    return PermissionResponse(
        resources: request.resources, action: PermissionResponseAction.GRANT);
  }

  @override
  void onLoadError(url, code, message) {
    pullToRefreshController?.endRefreshing();
  }

  @override
  void onProgressChanged(progress) {
    if (progress == 100) {
      pullToRefreshController?.endRefreshing();
    }
  }

  @override
  void onExit() {
    print("\n\nBrowser closed!\n\n");
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      NavigationAction navigationAction) async {
    print("\n\nOverride ${navigationAction.request.url}\n\n");

    // Check if the platform is macOS
    if (Platform.isMacOS) {
      // Handle the URL navigation without opening a new window
      await webViewController?.loadUrl(
        urlRequest: navigationAction.request,
      );
      return NavigationActionPolicy.CANCEL;
    }

    // For other platforms, allow normal navigation behavior
    return NavigationActionPolicy.ALLOW;
  }
}

class InAppBrowserExampleScreen extends StatefulWidget {
  final MyInAppBrowser browser = new MyInAppBrowser();

  @override
  _InAppBrowserExampleScreenState createState() =>
      new _InAppBrowserExampleScreenState();
}

class _InAppBrowserExampleScreenState extends State<InAppBrowserExampleScreen> {
  PullToRefreshController? pullToRefreshController;
  final List<String> urls = [
    'https://www.google.com',
    'https://www.facebook.com',
    'https://www.openai.com',
    'https://www.flutter.dev',
  ];

  int _currentIndex = 0;

  void _loadUrl(int index) async {
    await widget.browser.openUrlRequest(
      urlRequest: URLRequest(
        url: WebUri(Uri.parse(urls[index]).toString()),
    ),
    );


  }

  @override
  void initState() {
    super.initState();

    pullToRefreshController = kIsWeb ||
            ![TargetPlatform.iOS, TargetPlatform.android]
                .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.black,
            ),
            onRefresh: () async {
              if (Platform.isAndroid) {
                widget.browser.webViewController?.reload();
              } else if (Platform.isIOS) {
                widget.browser.webViewController?.loadUrl(
                    urlRequest: URLRequest(
                        url: await widget.browser.webViewController?.getUrl()));
              }
            },
          );
    widget.browser.pullToRefreshController = pullToRefreshController;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(
          "InAppBrowser",
        )),
        //drawer: myDrawer(context: context),
        body: Container(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _loadUrl(index);
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home,color: Colors.black,),
            label: 'Google',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.link,color: Colors.black,),
            label: 'Example',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.language,color: Colors.black,),
            label: 'OpenAI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.code,color: Colors.black,),
            label: 'Flutter',
          ),
        ],
      ),
    );
  }
}
