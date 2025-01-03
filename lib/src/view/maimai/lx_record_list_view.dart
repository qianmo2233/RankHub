import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rank_hub/src/model/mai_types.dart';
import 'package:rank_hub/src/view/maimai/lx_mai_record_card.dart';
import 'package:rank_hub/src/provider/lx_mai_provider.dart';
import 'package:rank_hub/src/viewmodel/maimai/lx_record_list_vm.dart';

class LxMaiRecordList extends StatelessWidget {
  const LxMaiRecordList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => RecordListViewModel(LxMaiProvider(context: ctx), context)
        ..fetchRecords(),
      child: Consumer<RecordListViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
              extendBody: true,
              body: Builder(
                builder: (ctx) {
                  if (viewModel.isLoading && viewModel.scores.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (viewModel.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Failed to load records',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              viewModel.errorMessage,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  viewModel.fetchRecords(force: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (viewModel.filteredScores.isEmpty) {
                    return const Center(
                      child: Text(
                        'No records found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    edgeOffset: 176,
                    onRefresh: () => viewModel.fetchRecords(force: true),
                    child: GridView.builder(
                      controller: viewModel.scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 600, // 每个项目的最大宽度
                        crossAxisSpacing: 8, // 网格之间的横向间距
                        mainAxisSpacing: 8, // 网格之间的纵向间距
                        childAspectRatio: 1.8,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 176),
                      itemCount: viewModel.filteredScores.length,
                      itemBuilder: (context, index) {
                        return LxMaiRecordCard(
                          recordData: viewModel.filteredScores[index],
                        );
                      },
                    ),
                  );
                },
              ),
              bottomNavigationBar: SafeArea(
                child: _RankFilterBar(
                  isVisible: viewModel.isVisible,
                  searchController: viewModel.searchController,
                  focusNode: viewModel.focusNode,
                  viewModel: viewModel,
                ),
              ));
        },
      ),
    );
  }
}

class _RankFilterBar extends StatelessWidget {
  final bool isVisible;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final RecordListViewModel viewModel;

  const _RankFilterBar({
    required this.isVisible,
    required this.searchController,
    required this.focusNode,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isVisible ? 144.0 : 0,
        child: ClipRRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: BottomAppBar(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withOpacity(0.9),
                    surfaceTintColor: Colors.transparent,
                    child: OverflowBox(
                      maxHeight: 144,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  fillColor: Colors.transparent,
                                  labelText: "搜索歌曲",
                                  hintText: "支持 ID, 曲名, 艺术家, 别名 查找",
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                            ),
                            SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                        onPressed: viewModel.resetFilter,
                                        child: Row(children: [
                                          Icon(Icons.refresh),
                                          SizedBox(
                                            width: 4,
                                          ),
                                          Text('重置过滤条件')
                                        ])),
                                    ActionChip(
                                      onPressed: viewModel.openLevelMultiSelectDialog,
                                      label: Row(
                                        children: [
                                          Text(viewModel.getLevelIndexText()),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_drop_down)
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Row(
                                        children: [
                                          Text("分类"),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_drop_down)
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Row(
                                        children: [
                                          Text("版本"),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                    ActionChip(
                                      onPressed:
                                          viewModel.openDateRangePickerDialog,
                                      label: Row(
                                        children: [
                                          Text(viewModel.getDateRangeText()),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_drop_down)
                                        ],
                                      ),
                                    ),
                                    ActionChip(
                                      onPressed: viewModel
                                          .openLevelValueRangeSliderDialog,
                                      label: Row(
                                        children: [
                                          Text(viewModel
                                              .getLevelValueRangeText()),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_drop_down)
                                        ],
                                      ),
                                    ),
                                    ActionChip(
                                      onPressed: viewModel.openFCTypeMultiSelectDialog,
                                      label: Row(
                                        children: [
                                          Text(viewModel.getFCTypeText()),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_drop_down)
                                        ],
                                      ),
                                    ),
                                    ActionChip(
                                      onPressed: viewModel.openFSTypeMultiSelectDialog,
                                      label: Row(
                                        children: [
                                          Text(viewModel.getFSTypeText()),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_drop_down)
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Row(
                                        children: [
                                          Text("谱面类型"),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_drop_down)
                                        ],
                                      ),
                                    ),
                                  ],
                                )),
                          ],
                        ),
                      ),
                    )))));
  }
}

class LevelValueRangeSliderDialog extends StatefulWidget {
  final RangeValues initialRange;

  const LevelValueRangeSliderDialog({
    super.key,
    required this.initialRange,
  });

  @override
  State<LevelValueRangeSliderDialog> createState() =>
      _LevelValueRangeSliderDialogState();
}

class _LevelValueRangeSliderDialogState
    extends State<LevelValueRangeSliderDialog> {
  late RangeValues _currentRange;

  @override
  void initState() {
    super.initState();
    _currentRange = widget.initialRange;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Text('选择谱面定数范围'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8, // 设置宽度为屏幕宽度的80%
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 32),
              Text(
                  '当前范围: ${_currentRange.start.toStringAsFixed(1)} - ${_currentRange.end.toStringAsFixed(1)}'),
              RangeSlider(
                values: _currentRange,
                min: 1.0,
                max: 15.0,
                divisions: 140,
                labels: RangeLabels(
                  _currentRange.start.toStringAsFixed(1),
                  _currentRange.end.toStringAsFixed(1),
                ),
                onChanged: (RangeValues newRange) {
                  setState(() {
                    _currentRange = newRange;
                  });
                },
              ),
            ],
          )),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_currentRange);
              },
              child: const Text('OK'),
            ),
          ],
        );
  }
}

class LevelMultiSelectDialog extends StatefulWidget {
  final List<LevelIndex> initialSelected;

  const LevelMultiSelectDialog({
    super.key,
    required this.initialSelected,
  });

  @override
  State<LevelMultiSelectDialog> createState() => _LevelMultiSelectDialogState();
}

class _LevelMultiSelectDialogState extends State<LevelMultiSelectDialog> {
  late List<LevelIndex> _selectedLevels;

  @override
  void initState() {
    super.initState();
    _selectedLevels = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择谱面难度'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: ListView(
          shrinkWrap: true,
          children: LevelIndex.values.map((level) {
            return CheckboxListTile(
              title: Text(level.label),
              value: _selectedLevels.contains(level),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedLevels.add(level);
                  } else {
                    _selectedLevels.remove(level);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedLevels);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class FCTypeMultiSelectDialog extends StatefulWidget {
  final List<FCType> initialSelected;

  const FCTypeMultiSelectDialog({
    super.key,
    required this.initialSelected,
  });

  @override
  State<FCTypeMultiSelectDialog> createState() => _FCTypeMultiSelectDialogState();
}

class _FCTypeMultiSelectDialogState extends State<FCTypeMultiSelectDialog> {
  late List<FCType> _selectedLevels;

  @override
  void initState() {
    super.initState();
    _selectedLevels = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择 FC 类型'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: ListView(
          shrinkWrap: true,
          children: FCType.values.map((fcType) {
            return CheckboxListTile(
              title: Text(fcType.label),
              value: _selectedLevels.contains(fcType),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedLevels.add(fcType);
                  } else {
                    _selectedLevels.remove(fcType);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedLevels);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}



class FSTypeMultiSelectDialog extends StatefulWidget {
  final List<FSType> initialSelected;

  const FSTypeMultiSelectDialog({
    super.key,
    required this.initialSelected,
  });

  @override
  State<FSTypeMultiSelectDialog> createState() => _FSTypeMultiSelectDialogState();
}

class _FSTypeMultiSelectDialogState extends State<FSTypeMultiSelectDialog> {
  late List<FSType> _selectedLevels;

  @override
  void initState() {
    super.initState();
    _selectedLevels = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择 FS 类型'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: ListView(
          shrinkWrap: true,
          children: FSType.values.map((fsType) {
            return CheckboxListTile(
              title: Text(fsType.label),
              value: _selectedLevels.contains(fsType),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedLevels.add(fsType);
                  } else {
                    _selectedLevels.remove(fsType);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedLevels);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}