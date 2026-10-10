import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/civit_models.dart';
import '../models/hf_models.dart';
import '../models/omdb_models.dart';
import '../services/civarchive_api.dart';
import '../services/civitai_api.dart';
import '../services/huggingface_api.dart';
import '../services/openmodeldb_api.dart';

enum LoadStatus { idle, loading, success, failed }

class CivitAiBrowserStore extends ChangeNotifier {
  final CivitAiApi api;
  LoadStatus status = LoadStatus.idle;
  List<CivitModel> models = [];
  String? errorMessage;
  String query = '';
  CivitModelType type = CivitModelType.all;
  CivitSort sort = CivitSort.mostDownloaded;
  CivitPeriod period = CivitPeriod.allTime;
  bool nsfw = false;
  String? _nextCursor;
  bool _loadingMore = false;

  CivitAiBrowserStore(this.api);

  int _searchSeq = 0;

  bool get canLoadMore => _nextCursor != null && !_loadingMore;

  Future<void> search() async {
    final seq = ++_searchSeq;
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final page = await api.getModels(
        query: query,
        type: type,
        sort: sort,
        period: period,
        nsfw: nsfw,
      );
      if (seq != _searchSeq) return;
      models = page.items;
      _nextCursor = page.nextCursor;
      status = LoadStatus.success;
    } catch (e) {
      if (seq != _searchSeq) return;
      status = LoadStatus.failed;
      errorMessage = '$e';
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_nextCursor == null || _loadingMore) return;
    _loadingMore = true;
    try {
      final page = await api.getModels(
        query: query,
        type: type,
        sort: sort,
        period: period,
        nsfw: nsfw,
        cursor: _nextCursor,
      );
      models = [...models, ...page.items];
      _nextCursor = page.nextCursor;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  void setQuery(String value) {
    query = value;
  }

  void setType(CivitModelType value) {
    type = value;
    search();
  }

  void setSort(CivitSort value) {
    sort = value;
    search();
  }

  void setPeriod(CivitPeriod value) {
    period = value;
    search();
  }

  void setNsfw(bool value) {
    nsfw = value;
    search();
  }
}

class HuggingFaceBrowserStore extends ChangeNotifier {
  final HuggingFaceApi api;
  LoadStatus status = LoadStatus.idle;
  List<HuggingFaceModel> models = [];
  List<HuggingFaceFile> files = [];
  HuggingFaceModel? selected;
  String? errorMessage;
  String query = '';

  HuggingFaceBrowserStore(this.api);

  int _searchSeq = 0;
  int _selectSeq = 0;

  Future<void> search() async {
    final seq = ++_searchSeq;
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await api.searchModels(query: query);
      if (seq != _searchSeq) return;
      models = result;
      status = LoadStatus.success;
    } catch (e) {
      if (seq != _searchSeq) return;
      status = LoadStatus.failed;
      errorMessage = '$e';
    }
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
  }

  Future<void> selectModel(HuggingFaceModel model) async {
    final seq = ++_selectSeq;
    selected = model;
    files = [];
    status = LoadStatus.loading;
    notifyListeners();
    try {
      final result = await api.listFiles(model.id);
      if (seq != _selectSeq) return;
      files = result;
      status = LoadStatus.success;
    } catch (e) {
      if (seq != _selectSeq) return;
      status = LoadStatus.failed;
      errorMessage = '$e';
    }
    notifyListeners();
  }
}

class OpenModelDbBrowserStore extends ChangeNotifier {
  final OpenModelDbApi api;
  LoadStatus status = LoadStatus.idle;
  List<OpenModelDbModel> models = [];
  String? errorMessage;
  String query = '';
  String? tagFilter;

  OpenModelDbBrowserStore(this.api);

  List<OpenModelDbModel> get filtered => models.where((m) {
    if (tagFilter != null && !m.tags.contains(tagFilter)) return false;
    if (query.isNotEmpty &&
        !m.name.toLowerCase().contains(query.toLowerCase())) {
      return false;
    }
    return true;
  }).toList();

  List<String> get allTags =>
      models.expand((m) => m.tags).toSet().toList()..sort();

  Future<void> load() async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      models = await api.getModels();
      status = LoadStatus.success;
    } catch (e) {
      status = LoadStatus.failed;
      errorMessage = '$e';
    }
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setTagFilter(String? tag) {
    tagFilter = tag;
    notifyListeners();
  }
}

class CivArchiveBrowserStore extends ChangeNotifier {
  final CivArchiveApi api;
  LoadStatus status = LoadStatus.idle;
  List<CivitModel> models = [];
  String? errorMessage;
  String query = '';
  int page = 1;

  CivArchiveBrowserStore(this.api);

  Future<void> search() async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      models = await api.getModels(query: query, page: page);
      status = LoadStatus.success;
    } catch (e) {
      status = LoadStatus.failed;
      errorMessage = '$e';
    }
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
  }

  void setPage(int value) {
    page = value;
    search();
  }
}
