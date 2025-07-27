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

  MemberSetPage({
    this.onToggleTheme,
    this.themeMode = ThemeMode.system,
    required this.localMembers,
  });

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
              widget.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
            ),
            tooltip: widget.themeMode == ThemeMode.dark ? 'ライトモードに切替' : 'ダークモードに切替',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: DragAndDropLists(
        children: _buildCourseLists(),
        onItemReorder: (oldItemIndex, oldListIndex, newItemIndex, newListIndex) {
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
                localMembers: widget.localMembers,
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

  MemberSearchPage({
    this.initialRank,
    this.initialGender,
    required this.localMembers,
  });

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
  final List<String> _dataTimeList = ['', '20252', '20251', '20021'];
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
      ).showSnackBar(
          SnackBar(content: Text('少なくとも1つの検索条件を入力してください')));
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
    source =
        source.where((member) {
          final matchesName =
              _nameController.text.isEmpty ||
                  (member['Kana3']?.toString().toLowerCase() ?? '').contains(
                    _nameController.text.toLowerCase(),
                  );
          final matchesCode =
              _codeController.text.isEmpty ||
                  (member['Number']?.toString() ?? '').startsWith(
                    _codeController.text,
                  );
          final matchesGender =
              (_selectedGender == null || _selectedGender == '') ||
                  member['Sex']?.toString() == _selectedGender;
          final matchesDataTime =
              (_selectedDataTime == null || _selectedDataTime!.isEmpty) ||
                  member['DataTime']?.toString() == _selectedDataTime;
          final matchesRank =
              (_selectedRank == null || _selectedRank!.isEmpty) ||
                  member['Rank']?.toString() == _selectedRank;
          return matchesName &&
              matchesCode &&
              matchesGender &&
              matchesDataTime &&
              matchesRank;
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
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(flex: 2, child: Text(member['Number'] ?? 'No number')),
                            Expanded(flex: 3, child: Text('${member['Name'] ?? 'No name'}')),
                            Expanded(flex: 1, child: Text(member['Sex'] == '2' ? '♀️' : '')),
                            Expanded(flex: 2, child: Text(member['WinPointRate'] ?? 'No Data')),
                            Expanded(flex: 1, child: Text(member['Rank'] ?? 'No Data', style: TextStyle(fontWeight: (member['Rank'] == 'A1') ? FontWeight.bold : FontWeight.normal))),
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
  final List localMembers;

  ResultGraphPage({required this.members, required this.localMembers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('スタートフォーメーション')),
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
                          return Builder(
                            builder: (context) => InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MemberDetailPage(
                                      member: member,
                                      localMembers: localMembers,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${i + 1}', style: TextStyle(fontSize: 12)),
                                  Text('${cm.originalFrame}:$number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('$name', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
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
                            toY: double.parse(members[i].member['StartTime#${i + 1}']) * -1,
                            color: Colors.transparent,
                            width: 20,
                            borderRadius: BorderRadius.circular(0),
                            rodStackItems: [
                              BarChartRodStackItem(
                                0,
                                double.parse(members[i].member['StartTime#${i + 1}']) * -1,
                                Colors.transparent,
                              ),
                              BarChartRodStackItem(
                                double.parse(members[i].member['StartTime#${i + 1}']) * -1,
                                double.parse(members[i].member['StartTime#${i + 1}']) * -1 + 0.02,
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
                          'Sタイミング: ${startTimeValue}S',

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
                            toY:
                            (double.tryParse(
                              members[i].member['WinRate12#${i + 1}'],
                            ) ?? 0) * 100,
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
                            ) ?? 0) * 100;
                        final startCountRaw =
                            member['NumberOfEntries#${group.x + 1}'] ?? '0';
                        final startCount =
                            double.tryParse(
                              startCountRaw.toString(),
                            )?.toInt() ?? 0;
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


// --- MemberDetailPage（データがなければメッセージで告知） ---
class MemberDetailPage extends StatefulWidget {
  final Map<String, dynamic> member;
  final List localMembers;
  MemberDetailPage({required this.member, required this.localMembers});

  @override
  _MemberDetailPageState createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  String? _selectedDataTime;
  Map<String, dynamic>? _displayMember;
  bool _noData = false;
  final List<String> _dataTimeList = ['', '20252', '20251', '20021'];

  @override
  void initState() {
    super.initState();
    _selectedDataTime = widget.member['DataTime']?.toString() ?? '';
    _displayMember = widget.member;
    _noData = false;
  }

  void _switchDataTime(String newValue) {
    setState(() {
      _selectedDataTime = newValue;
      _displayMember = widget.localMembers
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (m) =>
        m['Number'] == widget.member['Number'] &&
            m['DataTime'].toString() == newValue,
        orElse: () => {},
      );
      _noData = _displayMember == null || _displayMember!.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.member['Name']}の詳細')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Text('期を選択: '),
                  DropdownButton<String>(
                    value: _selectedDataTime,
                    items: _dataTimeList.map((dt) {
                      return DropdownMenuItem(
                        value: dt,
                        child: Text(dt.isEmpty ? '' : formatDataTime(dt)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        _switchDataTime(newValue);
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              _noData
                  ? Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  '選択した期のデータがありません。',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  : Column(
                children: [
                  if (_displayMember?['Photo'] != null && _displayMember?['Photo'].isNotEmpty)
                    Image.network(
                      _displayMember!['Photo'],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  SizedBox(height: 20),
                  // --- 詳細テーブル1 ---
                  Table(
                    border: TableBorder.all(),
                    children: [
                      TableRow(
                        children: [
                          TableCell(
                            child: Text(
                              ' 期  別：${formatDataTime('${_displayMember?['DataTime']}')}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          TableCell(
                            child: Text(
                              ' ${_displayMember?['DataTime'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Text(
                              ' 氏  名：${_displayMember?['Name'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          TableCell(
                            child: Text(
                              ' ${_displayMember?['Kana3'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Text(
                              ' 登  番：${_displayMember?['Number'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          TableCell(child: Text('', textAlign: TextAlign.left)),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Text(
                              ' 勝  率：${_displayMember?['WinPointRate'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          TableCell(
                            child: Text(
                              ' 複勝率：${_displayMember?['WinRate12'] != null ? (double.parse(_displayMember!['WinRate12']) * 100).toStringAsFixed(2) + '%' : ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Text(
                              ' 1着数：${_displayMember?['1stPlaceCount'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          TableCell(
                            child: Text(
                              ' 優勝数：${_displayMember?['NumberOfWins'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Text(
                              ' 2着数：${_displayMember?['2ndPlaceCount'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          TableCell(
                            child: Text(
                              ' 優出数：${_displayMember?['NumberOfFinals'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Text(
                              ' 平均ST：${_displayMember?['StartTiming'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          TableCell(
                            child: Text(
                              ' 出走数：${_displayMember?['NumberOfRace'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Text(
                              ' 級  別：${_displayMember?['Rank'] ?? ''} /${_displayMember?['RankPast1'] ?? ''}/${_displayMember?['RankPast2'] ?? ''}/${_displayMember?['RankPast3'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          TableCell(child: Text('', textAlign: TextAlign.left)),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Text(
                              ' 年  齢：${_displayMember?['Age'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          TableCell(
                            child: Text(
                              ' 誕生日：${_displayMember?['GBirthday'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Text(
                              ' 身  長：${_displayMember?['Height'] ?? ''}cm',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          TableCell(
                            child: Text(
                              ' 血液型：${_displayMember?['Blood'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Text(
                              ' 体  重：${_displayMember?['Weight'] ?? ''}kg',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          TableCell(child: Text('', textAlign: TextAlign.left)),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Text(
                              ' 支  部：${_displayMember?['Blanch'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          TableCell(
                            child: Text(
                              ' 出身地：${_displayMember?['Birthplace'] ?? ''}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // --- 詳細テーブル2（例: F, L0, L1, ... S2） ---
                  Table(
                    border: TableBorder.all(),
                    children: [
                      TableRow(
                        children: [
                          TableCell(child: Text('F', textAlign: TextAlign.center)),
                          TableCell(child: Text('L0', textAlign: TextAlign.center)),
                          TableCell(child: Text('L1', textAlign: TextAlign.center)),
                          TableCell(child: Text('K0', textAlign: TextAlign.center)),
                          TableCell(child: Text('K1', textAlign: TextAlign.center)),
                          TableCell(child: Text('S0', textAlign: TextAlign.center)),
                          TableCell(child: Text('S1', textAlign: TextAlign.center)),
                          TableCell(child: Text('S2', textAlign: TextAlign.center)),
                        ],
                      ),
                      TableRow(
                        children: [
                          // F
                          TableCell(
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    double safeParse(String? value) =>
                                        double.tryParse(value ?? '') ?? 0;
                                    final total =
                                        safeParse(_displayMember?['FalseStart#1']) +
                                            safeParse(_displayMember?['FalseStart#2']) +
                                            safeParse(_displayMember?['FalseStart#3']) +
                                            safeParse(_displayMember?['FalseStart#4']) +
                                            safeParse(_displayMember?['FalseStart#5']) +
                                            safeParse(_displayMember?['FalseStart#6']);

                                    return AlertDialog(
                                      title: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'フライング失格回数',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'このセルはフライングによる失格回数の合計値を示しています。',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '１コース: ${_displayMember?['FalseStart#1'] ?? '0'}',
                                          ),
                                          Text(
                                            '２コース: ${_displayMember?['FalseStart#2'] ?? '0'}',
                                          ),
                                          Text(
                                            '３コース: ${_displayMember?['FalseStart#3'] ?? '0'}',
                                          ),
                                          Text(
                                            '４コース: ${_displayMember?['FalseStart#4'] ?? '0'}',
                                          ),
                                          Text(
                                            '５コース: ${_displayMember?['FalseStart#5'] ?? '0'}',
                                          ),
                                          Text(
                                            '６コース: ${_displayMember?['FalseStart#6'] ?? '0'}',
                                          ),
                                          Divider(height: 20, thickness: 1),
                                          Text(
                                            'コメント：',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'フライングをした選手は、そのレースから除外され、該当艇に関する舟券はすべて返還となります。\n'
                                                'フフライング回数が多くなると、以下のような罰則があります。\n'
                                                ' 1回：30日間の斡旋停止（レース出場停止）\n'
                                                ' 2回：60日間の斡旋停止\n'
                                                ' 3回：90日間の斡旋停止\n'
                                                ' 4回：180日間の斡旋停止や引退勧告\n',
                                            style: TextStyle(
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          child: Text('閉じる'),
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                (() {
                                  double safeParse(String? value) =>
                                      double.tryParse(value ?? '') ?? 0;
                                  final total =
                                      safeParse(_displayMember?['FalseStart#1']) +
                                          safeParse(_displayMember?['FalseStart#2']) +
                                          safeParse(_displayMember?['FalseStart#3']) +
                                          safeParse(_displayMember?['FalseStart#4']) +
                                          safeParse(_displayMember?['FalseStart#5']) +
                                          safeParse(_displayMember?['FalseStart#6']);
                                  if (total == 0) {
                                    return '';
                                  } else {
                                    return '${total.toStringAsFixed(0)}';
                                  }
                                })(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // L0
                          TableCell(
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    double safeParse(String? value) =>
                                        double.tryParse(value ?? '') ?? 0;
                                    final total =
                                        safeParse(
                                          _displayMember?['LateStartNoResponsibility#1'],
                                        ) +
                                            safeParse(
                                              _displayMember?['LateStartNoResponsibility#2'],
                                            ) +
                                            safeParse(
                                              _displayMember?['LateStartNoResponsibility#3'],
                                            ) +
                                            safeParse(
                                              _displayMember?['LateStartNoResponsibility#4'],
                                            ) +
                                            safeParse(
                                              _displayMember?['LateStartNoResponsibility#5'],
                                            ) +
                                            safeParse(
                                              _displayMember?['LateStartNoResponsibility#6'],
                                            );

                                    return AlertDialog(
                                      title: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '選手責任外の出遅れ回数',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'スタートタイミングから1秒以上遅れてスタートラインを通過した場合に適用されます。\n'
                                                'L0は「選手責任外の出遅れ」を示し、例えばエンジントラブルなど選手自身の過失ではない理由で出遅れた場合に使われます',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '１コース: ${_displayMember?['LateStartNoResponsibility#1'] ?? '0'}',
                                          ),
                                          Text(
                                            '２コース: ${_displayMember?['LateStartNoResponsibility#2'] ?? '0'}',
                                          ),
                                          Text(
                                            '３コース: ${_displayMember?['LateStartNoResponsibility#3'] ?? '0'}',
                                          ),
                                          Text(
                                            '４コース: ${_displayMember?['LateStartNoResponsibility#4'] ?? '0'}',
                                          ),
                                          Text(
                                            '５コース: ${_displayMember?['LateStartNoResponsibility#5'] ?? '0'}',
                                          ),
                                          Text(
                                            '６コース: ${_displayMember?['LateStartNoResponsibility#6'] ?? '0'}',
                                          ),
                                          Divider(height: 20, thickness: 1),
                                          Text(
                                            'コメント：',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'L0の場合、事故点は加算されず、勝率や事故率の計算でも出走回数としてカウントされません。\n'
                                                '一方、L1（選手責任の出遅れ）は事故点が加算され、級別審査にも影響します。',
                                            style: TextStyle(
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          child: Text('閉じる'),
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                (() {
                                  double safeParse(String? value) =>
                                      double.tryParse(value ?? '') ?? 0;
                                  final total =
                                      safeParse(
                                        _displayMember?['LateStartNoResponsibility#1'],
                                      ) +
                                          safeParse(
                                            _displayMember?['LateStartNoResponsibility#2'],
                                          ) +
                                          safeParse(
                                            _displayMember?['LateStartNoResponsibility#3'],
                                          ) +
                                          safeParse(
                                            _displayMember?['LateStartNoResponsibility#4'],
                                          ) +
                                          safeParse(
                                            _displayMember?['LateStartNoResponsibility#5'],
                                          ) +
                                          safeParse(
                                            _displayMember?['LateStartNoResponsibility#6'],
                                          );
                                  if (total == 0) {
                                    return '';
                                  } else {
                                    return '${total.toStringAsFixed(0)}';
                                  }
                                })(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // L1
                          TableCell(
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    double safeParse(String? value) =>
                                        double.tryParse(value ?? '') ?? 0;
                                    final total =
                                        safeParse(
                                          _displayMember?['LateStartOnResponsibility#1'],
                                        ) +
                                            safeParse(
                                              _displayMember?['LateStartOnResponsibility#2'],
                                            ) +
                                            safeParse(
                                              _displayMember?['LateStartOnResponsibility#3'],
                                            ) +
                                            safeParse(
                                              _displayMember?['LateStartOnResponsibility#4'],
                                            ) +
                                            safeParse(
                                              _displayMember?['LateStartOnResponsibility#5'],
                                            ) +
                                            safeParse(
                                              _displayMember?['LateStartOnResponsibility#6'],
                                            );

                                    return AlertDialog(
                                      title: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '選手責任による出遅れ回数',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Lとはスタートタイミングから1秒以上遅れてスタートラインを通過した場合に適用されます。\n'
                                                'L0は「選手責任の出遅れ」を示します。',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '１コース: ${_displayMember?['LateStartOnResponsibility#1'] ?? '0'}',
                                          ),
                                          Text(
                                            '２コース: ${_displayMember?['LateStartOnResponsibility#2'] ?? '0'}',
                                          ),
                                          Text(
                                            '３コース: ${_displayMember?['LateStartOnResponsibility#3'] ?? '0'}',
                                          ),
                                          Text(
                                            '４コース: ${_displayMember?['LateStartOnResponsibility#4'] ?? '0'}',
                                          ),
                                          Text(
                                            '５コース: ${_displayMember?['LateStartOnResponsibility#5'] ?? '0'}',
                                          ),
                                          Text(
                                            '６コース: ${_displayMember?['LateStartOnResponsibility#6'] ?? '0'}',
                                          ),
                                          Divider(height: 20, thickness: 1),
                                          Text(
                                            'コメント：',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '「L1」となった場合、その選手はそのレースを欠場扱いとなり、該当艇が絡む舟券は全額返還されます。\n'
                                                'また、選手には事故点が加算され、一定期間レースへの出場停止などの罰則が科されます。',
                                            style: TextStyle(
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          child: Text('閉じる'),
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                (() {
                                  double safeParse(String? value) =>
                                      double.tryParse(value ?? '') ?? 0;
                                  final total =
                                      safeParse(
                                        _displayMember?['LateStartOnResponsibility#1'],
                                      ) +
                                          safeParse(
                                            _displayMember?['LateStartOnResponsibility#2'],
                                          ) +
                                          safeParse(
                                            _displayMember?['LateStartOnResponsibility#3'],
                                          ) +
                                          safeParse(
                                            _displayMember?['LateStartOnResponsibility#4'],
                                          ) +
                                          safeParse(
                                            _displayMember?['LateStartOnResponsibility#5'],
                                          ) +
                                          safeParse(
                                            _displayMember?['LateStartOnResponsibility#6'],
                                          );
                                  if (total == 0) {
                                    return '';
                                  } else {
                                    return '${total.toStringAsFixed(0)}';
                                  }
                                })(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // K0
                          TableCell(
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    double safeParse(String? value) =>
                                        double.tryParse(value ?? '') ?? 0;
                                    final total =
                                        safeParse(
                                          _displayMember?['WithdrawNoResponsibility#1'],
                                        ) +
                                            safeParse(
                                              _displayMember?['WithdrawNoResponsibility#2'],
                                            ) +
                                            safeParse(
                                              _displayMember?['WithdrawNoResponsibility#3'],
                                            ) +
                                            safeParse(
                                              _displayMember?['WithdrawNoResponsibility#4'],
                                            ) +
                                            safeParse(
                                              _displayMember?['WithdrawNoResponsibility#5'],
                                            ) +
                                            safeParse(
                                              _displayMember?['WithdrawNoResponsibility#6'],
                                            );

                                    return AlertDialog(
                                      title: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '選手責任外の事前欠場回数',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '「K0」は選手の責任によらない理由（例：病気や怪我、不可抗力によるトラブルなど）でレースに出場できなくなった場合に使われます。',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '１コース: ${_displayMember?['WithdrawNoResponsibility#1'] ?? '0'}',
                                          ),
                                          Text(
                                            '２コース: ${_displayMember?['WithdrawNoResponsibility#2'] ?? '0'}',
                                          ),
                                          Text(
                                            '３コース: ${_displayMember?['WithdrawNoResponsibility#3'] ?? '0'}',
                                          ),
                                          Text(
                                            '４コース: ${_displayMember?['WithdrawNoResponsibility#4'] ?? '0'}',
                                          ),
                                          Text(
                                            '５コース: ${_displayMember?['WithdrawNoResponsibility#5'] ?? '0'}',
                                          ),
                                          Text(
                                            '６コース: ${_displayMember?['WithdrawNoResponsibility#6'] ?? '0'}',
                                          ),
                                          Divider(height: 20, thickness: 1),
                                          Text(
                                            'コメント：',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'その艇が絡む舟券は全額返還となります。',
                                            style: TextStyle(
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          child: Text('閉じる'),
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                (() {
                                  double safeParse(String? value) =>
                                      double.tryParse(value ?? '') ?? 0;
                                  final total =
                                      safeParse(
                                        _displayMember?['WithdrawNoResponsibility#1'],
                                      ) +
                                          safeParse(
                                            _displayMember?['WithdrawNoResponsibility#2'],
                                          ) +
                                          safeParse(
                                            _displayMember?['WithdrawNoResponsibility#3'],
                                          ) +
                                          safeParse(
                                            _displayMember?['WithdrawNoResponsibility#4'],
                                          ) +
                                          safeParse(
                                            _displayMember?['WithdrawNoResponsibility#5'],
                                          ) +
                                          safeParse(
                                            _displayMember?['WithdrawNoResponsibility#6'],
                                          );
                                  if (total == 0) {
                                    return '';
                                  } else {
                                    return '${total.toStringAsFixed(0)}';
                                  }
                                })(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // K1
                          TableCell(
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    double safeParse(String? value) =>
                                        double.tryParse(value ?? '') ?? 0;
                                    final total =
                                        safeParse(
                                          _displayMember?['WithdrawOnResponsibility#1'],
                                        ) +
                                            safeParse(
                                              _displayMember?['WithdrawOnResponsibility#2'],
                                            ) +
                                            safeParse(
                                              _displayMember?['WithdrawOnResponsibility#3'],
                                            ) +
                                            safeParse(
                                              _displayMember?['WithdrawOnResponsibility#4'],
                                            ) +
                                            safeParse(
                                              _displayMember?['WithdrawOnResponsibility#5'],
                                            ) +
                                            safeParse(
                                              _displayMember?['WithdrawOnResponsibility#6'],
                                            );

                                    return AlertDialog(
                                      title: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '選手責任による事前欠場回数',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '「K」は欠場（レースに出場しないこと）を示し、\n'
                                                '「1」は「選手責任」を表し、選手自身のミスや過失など、選手の責任によってレース前に欠場した場合に使われます。',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '１コース: ${_displayMember?['WithdrawOnResponsibility#1'] ?? '0'}',
                                          ),
                                          Text(
                                            '２コース: ${_displayMember?['WithdrawOnResponsibility#2'] ?? '0'}',
                                          ),
                                          Text(
                                            '３コース: ${_displayMember?['WithdrawOnResponsibility#3'] ?? '0'}',
                                          ),
                                          Text(
                                            '４コース: ${_displayMember?['WithdrawOnResponsibility#4'] ?? '0'}',
                                          ),
                                          Text(
                                            '６コース: ${_displayMember?['WithdrawOnResponsibility#5'] ?? '0'}',
                                          ),
                                          Text(
                                            '６コース: ${_displayMember?['WithdrawOnResponsibility#6'] ?? '0'}',
                                          ),
                                          Divider(height: 20, thickness: 1),
                                          Text(
                                            'コメント：',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'K1が記録されると、その選手には事故点（通常10点）が加算され、事故率や級別審査にも影響します。\n'
                                                'また、K1となった艇が絡む舟券は全額返還されます。',
                                            style: TextStyle(
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          child: Text('閉じる'),
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                (() {
                                  double safeParse(String? value) =>
                                      double.tryParse(value ?? '') ?? 0;
                                  final total =
                                      safeParse(
                                        _displayMember?['WithdrawOnResponsibility#1'],
                                      ) +
                                          safeParse(
                                            _displayMember?['WithdrawOnResponsibility#2'],
                                          ) +
                                          safeParse(
                                            _displayMember?['WithdrawOnResponsibility#3'],
                                          ) +
                                          safeParse(
                                            _displayMember?['WithdrawOnResponsibility#4'],
                                          ) +
                                          safeParse(
                                            _displayMember?['WithdrawOnResponsibility#5'],
                                          ) +
                                          safeParse(
                                            _displayMember?['WithdrawOnResponsibility#6'],
                                          );
                                  if (total == 0) {
                                    return '';
                                  } else {
                                    return '${total.toStringAsFixed(0)}';
                                  }
                                })(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // S0
                          TableCell(
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    double safeParse(String? value) =>
                                        double.tryParse(value ?? '') ?? 0;
                                    final total =
                                        safeParse(
                                          _displayMember?['InvalidNoResponsibility#1'],
                                        ) +
                                            safeParse(
                                              _displayMember?['InvalidNoResponsibility#2'],
                                            ) +
                                            safeParse(
                                              _displayMember?['InvalidNoResponsibility#3'],
                                            ) +
                                            safeParse(
                                              _displayMember?['InvalidNoResponsibility#4'],
                                            ) +
                                            safeParse(
                                              _displayMember?['InvalidNoResponsibility#5'],
                                            ) +
                                            safeParse(
                                              _displayMember?['InvalidNoResponsibility#6'],
                                            );

                                    return AlertDialog(
                                      title: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '選手責任外の失格回数',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '「S」は失格（Disqualification）を示し\n'
                                                '「0」は「選手責任外」を表し、選手の責任によらない理由（例：機械的トラブル、他艇からのもらい事故、不可抗力など）で失格となった場合に使われます',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '１コース: ${_displayMember?['InvalidNoResponsibility#1'] ?? '0'}',
                                          ),
                                          Text(
                                            '２コース: ${_displayMember?['InvalidNoResponsibility#2'] ?? '0'}',
                                          ),
                                          Text(
                                            '３コース: ${_displayMember?['InvalidNoResponsibility#3'] ?? '0'}',
                                          ),
                                          Text(
                                            '４コース: ${_displayMember?['InvalidNoResponsibility#4'] ?? '0'}',
                                          ),
                                          Text(
                                            '５コース: ${_displayMember?['InvalidNoResponsibility#5'] ?? '0'}',
                                          ),
                                          Text(
                                            '６コース: ${_displayMember?['InvalidNoResponsibility#6'] ?? '0'}',
                                          ),
                                          Divider(height: 20, thickness: 1),
                                          Text(
                                            'コメント：',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'この場合、事故点や制裁は加算されません。',
                                            style: TextStyle(
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          child: Text('閉じる'),
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                (() {
                                  double safeParse(String? value) =>
                                      double.tryParse(value ?? '') ?? 0;
                                  final total =
                                      safeParse(
                                        _displayMember?['InvalidNoResponsibility#1'],
                                      ) +
                                          safeParse(
                                            _displayMember?['InvalidNoResponsibility#2'],
                                          ) +
                                          safeParse(
                                            _displayMember?['InvalidNoResponsibility#3'],
                                          ) +
                                          safeParse(
                                            _displayMember?['InvalidNoResponsibility#4'],
                                          ) +
                                          safeParse(
                                            _displayMember?['InvalidNoResponsibility#5'],
                                          ) +
                                          safeParse(
                                            _displayMember?['InvalidNoResponsibility#6'],
                                          );
                                  if (total == 0) {
                                    return '';
                                  } else {
                                    return '${total.toStringAsFixed(0)}';
                                  }
                                })(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // S1
                          TableCell(
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    double safeParse(String? value) =>
                                        double.tryParse(value ?? '') ?? 0;
                                    final total =
                                        safeParse(
                                          _displayMember?['InvalidNoResponsibility#1'],
                                        ) +
                                            safeParse(
                                              _displayMember?['InvalidNoResponsibility#2'],
                                            ) +
                                            safeParse(
                                              _displayMember?['InvalidNoResponsibility#3'],
                                            ) +
                                            safeParse(
                                              _displayMember?['InvalidNoResponsibility#4'],
                                            ) +
                                            safeParse(
                                              _displayMember?['InvalidNoResponsibility#5'],
                                            ) +
                                            safeParse(
                                              _displayMember?['InvalidNoResponsibility#6'],
                                            );

                                    return AlertDialog(
                                      title: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '選手責任による失格回数',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '「S1」は選手自身の過失やミスによって失格となった場合に使われます。\n'
                                                '具体的には、転覆、落水、沈没、周回誤認、危険行為など、選手の責任でレース続行ができなくなった場合が該当します。',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '１コース: ${_displayMember?['InvalidNoResponsibility#1'] ?? '0'}',
                                          ),
                                          Text(
                                            '２コース: ${_displayMember?['InvalidNoResponsibility#2'] ?? '0'}',
                                          ),
                                          Text(
                                            '３コース: ${_displayMember?['InvalidNoResponsibility#3'] ?? '0'}',
                                          ),
                                          Text(
                                            '４コース: ${_displayMember?['InvalidNoResponsibility#4'] ?? '0'}',
                                          ),
                                          Text(
                                            '５コース: ${_displayMember?['InvalidNoResponsibility#5'] ?? '0'}',
                                          ),
                                          Text(
                                            '６コース: ${_displayMember?['InvalidNoResponsibility#6'] ?? '0'}',
                                          ),
                                          Divider(height: 20, thickness: 1),
                                          Text(
                                            'コメント：',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'S1が記録されると、その選手には事故点（通常10点）が加算され、\n'
                                                '事故率や級別審査にも影響します。また、舟券は全額返還されます。',
                                            style: TextStyle(
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          child: Text('閉じる'),
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                (() {
                                  double safeParse(String? value) =>
                                      double.tryParse(value ?? '') ?? 0;
                                  final total =
                                      safeParse(
                                        _displayMember?['InvalidNoResponsibility#1'],
                                      ) +
                                          safeParse(
                                            _displayMember?['InvalidNoResponsibility#2'],
                                          ) +
                                          safeParse(
                                            _displayMember?['InvalidNoResponsibility#3'],
                                          ) +
                                          safeParse(
                                            _displayMember?['InvalidNoResponsibility#4'],
                                          ) +
                                          safeParse(
                                            _displayMember?['InvalidNoResponsibility#5'],
                                          ) +
                                          safeParse(
                                            _displayMember?['InvalidNoResponsibility#6'],
                                          );
                                  if (total == 0) {
                                    return '';
                                  } else {
                                    return '${total.toStringAsFixed(0)}';
                                  }
                                })(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // S2
                          TableCell(
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    double safeParse(String? value) =>
                                        double.tryParse(value ?? '') ?? 0;
                                    final total =
                                        safeParse(
                                          _displayMember?['InvalidOnObstruction#1'],
                                        ) +
                                            safeParse(
                                              _displayMember?['InvalidOnObstruction#2'],
                                            ) +
                                            safeParse(
                                              _displayMember?['InvalidOnObstruction#3'],
                                            ) +
                                            safeParse(
                                              _displayMember?['InvalidOnObstruction#4'],
                                            ) +
                                            safeParse(
                                              _displayMember?['InvalidOnObstruction#5'],
                                            ) +
                                            safeParse(
                                              _displayMember?['InvalidOnObstruction#6'],
                                            );

                                    return AlertDialog(
                                      title: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '選手責任による妨害失格回数',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '他艇を妨害したことによる選手責任の失格に該当します。\n'
                                                'S2が記録されると、その選手には事故点が15点加算されます。\n'
                                                'S2による失格の場合、舟券の全額返還は行われません。',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '合計: ${total == 0 ? 'なし' : total.toStringAsFixed(0)}',
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '1コース: ${_displayMember?['InvalidOnObstruction#1'] ?? '0'}',
                                          ),
                                          Text(
                                            '２コース: ${_displayMember?['InvalidOnObstruction#2'] ?? '0'}',
                                          ),
                                          Text(
                                            '３コース: ${_displayMember?['InvalidOnObstruction#3'] ?? '0'}',
                                          ),
                                          Text(
                                            '４コース: ${_displayMember?['InvalidOnObstruction#4'] ?? '0'}',
                                          ),
                                          Text(
                                            '５コース: ${_displayMember?['InvalidOnObstruction#5'] ?? '0'}',
                                          ),
                                          Text(
                                            '６コース: ${_displayMember?['InvalidOnObstruction#6'] ?? '0'}',
                                          ),
                                          Divider(height: 20, thickness: 1),
                                          Text(
                                            'コメント：',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'S2は、事故点も重くペナルティが大きい失格です。',
                                            style: TextStyle(
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          child: Text('閉じる'),
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                (() {
                                  double safeParse(String? value) =>
                                      double.tryParse(value ?? '') ?? 0;
                                  final total =
                                      safeParse(
                                        _displayMember?['InvalidOnObstruction#1'],
                                      ) +
                                          safeParse(
                                            _displayMember?['InvalidOnObstruction#2'],
                                          ) +
                                          safeParse(
                                            _displayMember?['InvalidOnObstruction#3'],
                                          ) +
                                          safeParse(
                                            _displayMember?['InvalidOnObstruction#4'],
                                          ) +
                                          safeParse(
                                            _displayMember?['InvalidOnObstruction#5'],
                                          ) +
                                          safeParse(
                                            _displayMember?['InvalidOnObstruction#6'],
                                          );
                                  if (total == 0) {
                                    return '';
                                  } else {
                                    return '${total.toStringAsFixed(0)}';
                                  }
                                })(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  //
                  //
                  Text('コース別複勝率(%)'),
                  Container(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        titlesData: FlTitlesData(
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
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
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}');
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        maxY: 100,
                        barGroups: [
                          for (int i = 1; i <= 6; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY:
                                  double.parse(_displayMember?['WinRate12#$i']) *
                                      100,
                                  color: Colors.indigo.withOpacity(0.9),
                                  width: 20,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ],
                            ),
                        ],
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.white,
                            // 古いバージョンはこちら
                            // getTooltipColor: (_) => Colors.white, // 背景色
                            tooltipMargin: 0,
                            // tooltipBorderRadius: BorderRadius.circular(8),
                            tooltipRoundedRadius: 8,
                            // 代わりにこちらを使用
                            tooltipPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final course = group.x;
                              final winRate = rod.toY.toStringAsFixed(1);

                              // 進入回数を整数で表示
                              final entriesRaw =
                                  _displayMember?['NumberOfEntries#$course'] ?? '0';
                              final entries =
                                  double.tryParse(entriesRaw.toString())?.toInt() ??
                                      0;

                              return BarTooltipItem(
                                'コース: $course\n'
                                    '複勝率: $winRate%\n'
                                    '進入回数: ${entries}回',
                                const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  //
                  //
                  Text('コース別１、２、３着回数'),
                  SizedBox(height: 8),
                  // --- 凡例を追加 ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // ここを追加
                    children: [
                      _LegendItem(color: Colors.indigo, label: '1着'),
                      SizedBox(width: 16),
                      _LegendItem(color: Colors.blue, label: '2着'),
                      SizedBox(width: 16),
                      _LegendItem(color: Colors.lightBlueAccent, label: '3着'),
                    ],
                  ),
                  Container(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        titlesData: FlTitlesData(
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42.0,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}回');
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}');
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        maxY: 50,
                        barGroups: [
                          for (int i = 1; i <= 6; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY:
                                  double.parse(_displayMember?['1stPlace#$i']) +
                                      double.parse(_displayMember?['2ndPlace#$i']) +
                                      double.parse(_displayMember?['3rdPlace#$i']),
                                  width: 20,
                                  borderRadius: BorderRadius.circular(5),
                                  rodStackItems: [
                                    BarChartRodStackItem(
                                      0,
                                      double.parse(_displayMember?['1stPlace#$i']),
                                      Colors.indigo, // 1着
                                    ),
                                    BarChartRodStackItem(
                                      double.parse(_displayMember?['1stPlace#$i']),
                                      double.parse(_displayMember?['1stPlace#$i']) +
                                          double.parse(
                                            _displayMember?['2ndPlace#$i'],
                                          ),
                                      Colors.lightBlue, // 2着
                                    ),
                                    BarChartRodStackItem(
                                      double.parse(_displayMember?['1stPlace#$i']) +
                                          double.parse(
                                            _displayMember?['2ndPlace#$i'],
                                          ),
                                      double.parse(_displayMember?['1stPlace#$i']) +
                                          double.parse(
                                            _displayMember?['2ndPlace#$i'],
                                          ) +
                                          double.parse(
                                            _displayMember?['3rdPlace#$i'],
                                          ),
                                      Colors.lightBlueAccent, // 3着
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.white,
                            // 古いバージョンはこちら
                            // getTooltipColor: (_) => Colors.white, // 背景色
                            tooltipMargin: 0,
                            // tooltipBorderRadius: BorderRadius.circular(8),
                            tooltipRoundedRadius: 8,
                            // 代わりにこちらを使用
                            tooltipPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final course = group.x;
                              final place123 = rod.toY.toStringAsFixed(0);

                              // 進入回数を整数で表示
                              final entriesRaw =
                                  _displayMember?['NumberOfEntries#$course'] ?? '0';
                              final entries =
                                  double.tryParse(entriesRaw.toString())?.toInt() ??
                                      0;

                              return BarTooltipItem(
                                'コース: $course\n'
                                    '123着: ${place123}回\n'
                                    '進入回数: ${entries}回',
                                const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  //
                  //              Text('スタートタイミング/コース'),
                  Text('スタートタイミング/コース'),
                  SizedBox(height: 8),
                  Container(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        titlesData: FlTitlesData(
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42.0,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toDouble().toStringAsFixed(2)}',
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}');
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        maxY: 0,
                        minY: -0.4,
                        barGroups: [
                          for (int i = 1; i <= 6; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY:
                                  double.parse(_displayMember?['StartTime#$i']) *
                                      -1,
                                  color: Colors.transparent,
                                  width: 20,
                                  borderRadius: BorderRadius.circular(0),
                                  rodStackItems: [
                                    BarChartRodStackItem(
                                      0,
                                      double.parse(_displayMember?['StartTime#$i']) *
                                          -1,
                                      Colors.transparent,
                                    ),
                                    BarChartRodStackItem(
                                      double.parse(_displayMember?['StartTime#$i']) *
                                          -1,
                                      double.parse(_displayMember?['StartTime#$i']) *
                                          -1 +
                                          0.02,
                                      Colors.red,
                                    ),
                                  ],
                                ),
                              ],
                              // showingTooltipIndicators: [0], // これでツールチップが有効
                            ),
                        ],
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.white,
                            // 古いバージョンはこちら
                            // getTooltipColor: (_) => Colors.white, // 背景色
                            tooltipMargin: -120,
                            // tooltipBorderRadius: BorderRadius.circular(8),
                            tooltipRoundedRadius: 8,
                            // 代わりにこちらを使用
                            tooltipPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final course = group.x;
                              final startTime = rod.toY.toStringAsFixed(2);

                              // 進入回数を整数で表示
                              final entriesRaw =
                                  _displayMember?['NumberOfEntries#$course'] ?? '0';
                              final entries =
                                  double.tryParse(entriesRaw.toString())?.toInt() ??
                                      0;

                              return BarTooltipItem(
                                'コース: $course\n'
                                    'Sタイム: $startTime\n'
                                    '進入回数: ${entries}回',
                                const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  height: 1.4,
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
            ],
          ),
        ),
      ),
    );
  }
}
//
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black12),
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }
}
// 期コードを日本語表記に変換する関数
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
