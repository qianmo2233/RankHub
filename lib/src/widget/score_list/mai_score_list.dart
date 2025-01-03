import 'package:flutter/material.dart';
import 'package:rank_hub/src/model/maimai/song_score.dart';
import 'package:rank_hub/src/provider/lx_mai_provider.dart';
import 'package:rank_hub/src/view/maimai/lx_mai_record_card.dart';

class LxMaiScoreList extends StatefulWidget {
  final String searchQuery;
  final ScrollController scrollController;

  const LxMaiScoreList(
      {super.key, required this.searchQuery, required this.scrollController});

  @override
  State createState() => _LxMaiScoreListState();
}

class _LxMaiScoreListState extends State<LxMaiScoreList> {
  List<SongScore> scores = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  List<SongScore> filteredScores = [];

  @override
  void initState() {
    super.initState();
    fetchRecords();
  }

  @override
  void dispose() {
    scores.clear();
    filteredScores.clear();
    super.dispose();
  }

  void filterSearchResults(String query) {
    // 如果查询为空，显示所有歌曲
    if (query.isEmpty) {
      setState(() {
        filteredScores = scores;
      });
      return;
    }
  }

  Future<void> fetchRecords({bool froce = false}) async {
    if (hasError) {
      isLoading = true;
    }
    try {
      final fetchedSongs = await LxMaiProvider(context: context).lxApiService.getRecordList(forceRefresh: froce);
      setState(() {
        scores = fetchedSongs;
        isLoading = false;
        hasError = false;
        errorMessage = '';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Failed to load songs: $e';
      });
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    filteredScores = widget.searchQuery.isEmpty
        ? scores
        : scores
            .where((song) => song.songName!
                .toLowerCase()
                .contains(widget.searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Failed to load records',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(errorMessage),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {fetchRecords(froce: true);},
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ))
              : filteredScores.isEmpty
                  ? const Center(
                      child: Text(
                        'No records found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {fetchRecords(froce: true);},
                      child: ListView.builder(
                        controller: widget.scrollController,
                        itemCount: filteredScores.length,
                        itemBuilder: (context, index) {
                          return LxMaiRecordCard(
                              recordData: filteredScores[index]);
                        },
                      ),
                    ),
    );
  }
}