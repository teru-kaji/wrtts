import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fl_chart/fl_chart.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final membersJson = await rootBundle.loadString('assets/members.json');
  final List membersList = jsonDecode(membersJson);
  runApp(MyApp(localMembers: membersList));
}

// 枠情報を持つメンバー構造体
class CourseMember {
  final int originalFrame; // 元の枠番号（1〜6）
  final Map<String, dynamic> member;

  CourseMember({required this.originalFrame, required this.member});
}

class MyApp extends StatefulWidget {
  final List localMembers;

  MyApp({required this.localMembers});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleThemeMode() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Member Search App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(backgroundColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(backgroundColor: Colors.blue[700]),
      ),
      themeMode: _themeMode,
      home: MemberSetPage(
        onToggleTheme: _toggleThemeMode,
        themeMode: _themeMode,
        localMembers: widget.localMembers,
      ),
    );
  }
}

class MemberSetPage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final ThemeMode themeMode;
  final List localMembers;

  MemberSetPage({this.onToggleTheme, this.themeMode = ThemeMode.system, required this.localMembers});

  @override
  _MemberSetPageState createState() => _MemberSetPageState();
}

class _MemberSetPageState extends State<MemberSetPage> {
  List<CourseMember?> courseMembers = List.filled(6, null);
  String? _lastSelectedRank = '';
  String? _lastSelectedGender = '';

  void _showMemberSearchPage(int courseIndex) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MemberSearchPage(
          initialRank: _lastSelectedRank,
          initialGender: _lastSelectedGender,
          localMembers: widget.localMembers,
        ),
      ),
    );

    if (result != null && result['member'] != null) {
      setState(() {
        courseMembers[courseIndex] = CourseMember(
          originalFrame: courseIndex + 1,
          member: result['member'],
        );
        _lastSelectedRank = result['selectedRank'];
        _lastSelectedGender = result['selectedGender'];
      });
    }
  }

  List<DragAndDropList> _buildCourseLists() {
    return List.generate(6, (index) {
      final cm = courseMembers[index];
      return DragAndDropList(
        header: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0),
          child: Text(
            '${index + 1}コース',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        children: [
          DragAndDropItem(
            child: ListTile(
              title: cm == null
                  ? Text('未選択')
                  : Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${cm.originalFrame}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${cm.member['Number']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${cm.member['Name']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${cm.member['Sex']}' == '2' ? '♀️' : '',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${cm.member['WinPointRate']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${cm.member['Rank']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              onTap: () => _showMemberSearchPage(index),
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('メンバーセット'),
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip:
            widget.themeMode == ThemeMode.dark ? 'ライトモードに切替' : 'ダークモードに切替',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: DragAndDropLists(
        children: _buildCourseLists(),
        onItemReorder: (
            oldItemIndex,
            oldListIndex,
            newItemIndex,
            newListIndex,
            ) {
          setState(() {
            final moved = courseMembers[oldListIndex];
            courseMembers[oldListIndex] = courseMembers[newListIndex];
            courseMembers[newListIndex] = moved;
          });
        },
        onListReorder: (oldListIndex, newListIndex) {},
        listPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        itemDecorationWhileDragging: BoxDecoration(
          color: Colors.blue[100],
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        listDivider: null,
      ),
      floatingActionButton: ElevatedButton(
        onPressed: courseMembers.every((m) => m != null)
            ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultGraphPage(
                members: courseMembers.cast<CourseMember>(),
              ),
            ),
          );
        }
            : null,
        child: Text('決定'),
      ),
    );
  }
}

class MemberSearchPage extends StatefulWidget {
  final String? initialRank;
  final String? initialGender;
  final List localMembers;

  MemberSearchPage({this.initialRank, this.initialGender, required this.localMembers});

  @override
  _MemberSearchPageState createState() => _MemberSearchPageState();
}

class _MemberSearchPageState extends State<MemberSearchPage> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedGender;
  String? _selectedDataTime = '20252';
  String? _selectedRank;

  final List<Map<String, String>> _genderList = [
    {'label': '', 'value': ''},
    {'label': '男性', 'value': '1'},
    {'label': '女性', 'value': '2'},
  ];
  final List<String> _dataTimeList = ['', '20252', '20251', '20242', '20021'];
  final List<String> _rankList = ['', 'A1', 'A2', 'B1', 'B2'];

  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _loadedCount = 0;
  final int _limit = 100;
  final ScrollController _scrollController = ScrollController();
  bool _hasSearched = false; // 初期ローディング表示制御用

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGender ?? '';
    _selectedRank = widget.initialRank ?? '';
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreMembers();
    }
  }

  void _searchMembers() async {
    if (_nameController.text.isEmpty &&
        _codeController.text.isEmpty &&
        (_selectedGender == null || _selectedGender == '') &&
        (_selectedDataTime == null || _selectedDataTime!.isEmpty) &&
        (_selectedRank == null || _selectedRank!.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('少なくとも1つの検索条件を入力してください')));
      return;
    }

    setState(() {
      _members = [];
      _loadedCount = 0;
      _hasMore = true;
      _hasSearched = true;
    });
    await _fetchMoreMembers();
  }

  Future<void> _fetchMoreMembers() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    List<Map<String, dynamic>> source = widget.localMembers.cast<Map<String, dynamic>>();

    // 検索条件でフィルタ
    source = source.where((member) {
      final matchesName = _nameController.text.isEmpty ||
          (member['Kana3']?.toString().toLowerCase() ?? '').contains(_nameController.text.toLowerCase());
      final matchesCode = _codeController.text.isEmpty ||
          (member['Number']?.toString() ?? '').startsWith(_codeController.text);
      final matchesGender = (_selectedGender == null || _selectedGender == '') ||
          member['Sex']?.toString() == _selectedGender;
      final matchesDataTime = (_selectedDataTime == null || _selectedDataTime!.isEmpty) ||
          member['DataTime']?.toString() == _selectedDataTime;
      final matchesRank = (_selectedRank == null || _selectedRank!.isEmpty) ||
          member['Rank']?.toString() == _selectedRank;
      return matchesName && matchesCode && matchesGender && matchesDataTime && matchesRank;
    }).toList();

    final next = source.skip(_members.length).take(_limit).toList();

    setState(() {
      if (next.length < _limit) _hasMore = false;
      _members.addAll(next);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('選手検索'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _codeController,
                    decoration: InputDecoration(labelText: '登録番号'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: '氏名（ひらがな）'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: '期',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 6,
                        ),
                        isDense: true,
                      ),
                      value: _selectedDataTime,
                      items: _dataTimeList.map((dt) {
                        return DropdownMenuItem(
                          value: dt,
                          child: Text(dt.isEmpty ? '' : formatDataTime(dt)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDataTime = value;
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: '級別',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 6,
                        ),
                        isDense: true,
                      ),
                      value: _selectedRank,
                      items: _rankList.map((rank) {
                        return DropdownMenuItem(
                          value: rank,
                          child: Text(rank),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRank = value;
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: '性別',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 6,
                        ),
                        isDense: true,
                      ),
                      value: _selectedGender,
                      items: _genderList.map((gender) {
                        return DropdownMenuItem(
                          value: gender['value'],
                          child: Text(gender['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 100,
                height: 40,
                child: ElevatedButton(
                  onPressed: _searchMembers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: Size(60, 32),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    textStyle: TextStyle(fontSize: 14),
                  ),
                  child: Text('検索'),
                ),
              ),
            ),
            Container(
              height: 500,
              child: _hasSearched
                  ? ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: _members.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _members.length) {
                    final member = _members[index];
                    return Card(
                      elevation: 2,
                      margin:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(member['Number'] ?? 'No number'),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('${member['Name'] ?? 'No name'}'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(member['Sex'] == '2' ? '♀️' : ''),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(member['WinPointRate'] ?? 'No Data'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                member['Rank'] ?? 'No Data',
                                style: TextStyle(
                                  fontWeight: (member['Rank'] == 'A1')
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).pop({
                            'member': member,
                            'selectedRank': _selectedRank,
                            'selectedGender': _selectedGender,
                          });
                        },
                      ),
                    );
                  } else {
                    // 検索後のみローディングインジケータを表示
                    return Center(child: CircularProgressIndicator());
                  }
                },
              )
                  : Center(child: Text('検索条件を入力し、検索ボタンを押してください')),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                child: Text('閉じる'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultGraphPage extends StatelessWidget {
  final List<CourseMember> members;

  ResultGraphPage({required this.members});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('グラフ表示')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16),
            Text('スタートタイミング'),
            Container(
              height: 250,
              padding: EdgeInsets.symmetric(horizontal: 5.0),
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42.0,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toDouble().toStringAsFixed(2)}');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= members.length)
                            return SizedBox.shrink();
                          final cm = members[i];
                          final member = cm.member;
                          final number = member['Number'] ?? '';
                          final name = member['Name'] ?? '';
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${i + 1}', style: TextStyle(fontSize: 12)),
                              Text(
                                '${cm.originalFrame}:$number',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('$name', style: TextStyle(fontSize: 10)),
                            ],
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minY: -0.4,
                  maxY: 0,
                  barGroups: [
                    for (int i = 0; i < 6; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: double.parse(
                              members[i].member['StartTime#${i + 1}'],
                            ) *
                                -1,
                            color: Colors.transparent,
                            width: 20,
                            borderRadius: BorderRadius.circular(0),
                            rodStackItems: [
                              BarChartRodStackItem(
                                0,
                                double.parse(
                                  members[i].member['StartTime#${i + 1}'],
                                ) *
                                    -1,
                                Colors.transparent,
                              ),
                              BarChartRodStackItem(
                                double.parse(
                                  members[i].member['StartTime#${i + 1}'],
                                ) *
                                    -1,
                                double.parse(
                                  members[i]
                                      .member['StartTime#${i + 1}'],
                                ) *
                                    -1 +
                                    0.02,
                                Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      tooltipPadding: EdgeInsets.all(8),
                      tooltipMargin: -70,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final startTimeValue = rod.toY.abs().toStringAsFixed(2);
                        return BarTooltipItem(
                          '$startTimeValue',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text('複勝率（１着または２着の確率）'),
            Container(
              height: 300,
              padding: EdgeInsets.symmetric(horizontal: 5.0),
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42.0,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= members.length)
                            return SizedBox.shrink();
                          final cm = members[i];
                          final member = cm.member;
                          final number = member['Number'] ?? '';
                          final name = member['Name'] ?? '';
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${i + 1}', style: TextStyle(fontSize: 12)),
                              Text(
                                '${cm.originalFrame}:$number',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('$name', style: TextStyle(fontSize: 10)),
                            ],
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                  maxY: 100,
                  barGroups: [
                    for (int i = 0; i < 6; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (double.tryParse(
                              members[i].member['WinRate12#${i + 1}'],
                            ) ??
                                0) *
                                100,
                            color: Colors.indigo,
                            width: 20,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ],
                      ),
                  ],
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      tooltipPadding: EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final member = members[group.x].member;
                        final winRate =
                            (double.tryParse(
                              member['WinRate12#${group.x + 1}'],
                            ) ??
                                0) *
                                100;
                        final startCountRaw =
                            member['NumberOfEntries#${group.x + 1}'] ?? '0';
                        final startCount =
                            double.tryParse(
                              startCountRaw.toString(),
                            )?.toInt() ??
                                0;
                        return BarTooltipItem(
                          '複勝率: ${winRate.toStringAsFixed(1)}%\n進入回数: $startCount回',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 期コードを日本語表記に変換
String formatDataTime(String dataTime) {
  if (dataTime.length != 5) return '不正な形式';

  final year = dataTime.substring(0, 4);
  final term = dataTime.substring(4);

  String termLabel;
  switch (term) {
    case '1':
      termLabel = '前期';
      break;
    case '2':
      termLabel = '後期';
      break;
    default:
      return '不明な期';
  }

  return '$year年$termLabel';
}
