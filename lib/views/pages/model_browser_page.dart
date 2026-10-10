import 'package:flutter/material.dart';

import '../widgets/page_scaffold.dart';
import 'model_browser/civarchive_browser.dart';
import 'model_browser/civitai_browser.dart';
import 'model_browser/huggingface_browser.dart';
import 'model_browser/openmodeldb_browser.dart';

class ModelBrowserPage extends StatelessWidget {
  const ModelBrowserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: PageScaffold(
        title: 'Model Browser',
        headerExtra: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'CivitAI'),
            Tab(text: 'CivArchive'),
            Tab(text: 'HuggingFace'),
            Tab(text: 'OpenModelDB'),
          ],
        ),
        child: const TabBarView(
          children: [
            CivitAiBrowserView(),
            CivArchiveBrowserView(),
            HuggingFaceBrowserView(),
            OpenModelDbBrowserView(),
          ],
        ),
      ),
    );
  }
}
