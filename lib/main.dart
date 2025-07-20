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

// メンバー枠構造体
class CourseMember {
  final int originalFrame;
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
      if (_themeMode == ThemeMode.light) _themeMode = ThemeMode.dark;
      else if (_themeMode == ThemeMode.dark) _themeMode = ThemeMode.light;
      else _themeMode = ThemeMode.light;
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
                  Expanded(flex: 1, child: Text('${cm.originalFrame}', overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 2, child: Text('${cm.member['Number']}', overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 3, child: Text('${cm.member['Name']}', overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 1, child: Text('${cm.member['Sex']}' == '2' ? '♀️' : '', textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('${cm.member['WinPointRate']}', overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 1, child: Text('${cm.member['Rank']}', overflow: TextOverflow.ellipsis)),
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
        onItemReorder: (oldItemIndex, oldListIndex, newItemIndex, newListIndex,) {
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
  final List<String> _dataTimeList = ['', '20252', '20251', '20242', '20021'];
  final List<String> _rankList = ['', 'A1', 'A2', 'B1', 'B2'];
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _loadedCount = 0;
  final int _limit = 100;
  final ScrollController _scrollController = ScrollController();
  bool _hasSearched = false;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('少なくとも1つの検索条件を入力してください')));
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
    source = source.where((member) {
      final matchesName =
          _nameController.text.isEmpty ||
              (member['Kana3']?.toString().toLowerCase() ?? '').contains(_nameController.text.toLowerCase());
      final matchesCode =
          _codeController.text.isEmpty ||
              (member['Number']?.toString() ?? '').startsWith(_codeController.text);
      final matchesGender =
          (_selectedGender == null || _selectedGender == '') ||
              member['Sex']?.toString() == _selectedGender;
      final matchesDataTime =
          (_selectedDataTime == null || _selectedDataTime!.isEmpty) || member['DataTime']?.toString() == _selectedDataTime;
      final matchesRank =
          (_selectedRank == null || _selectedRank!.isEmpty) ||
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
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 6),
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
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 6),
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
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 6),
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

// --- 修正! ResultGraphPage（localMembersを渡す/MemberDetailPage呼出部変更） ---
class ResultGraphPage extends StatelessWidget {
  final List<CourseMember> members;
  final List localMembers;
  ResultGraphPage({required this.members, required this.localMembers});
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
                        getTitlesWidget: (value, meta) => Text('${value.toDouble().toStringAsFixed(2)}'),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= members.length) return SizedBox.shrink();
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
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}%'),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= members.length) return SizedBox.shrink();
                          final cm = members[i];
                          final member = cm.member;
                          final number = member['Number'] ?? '';
                          final name = member['Name'] ?? '';
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${i + 1}', style: TextStyle(fontSize: 12)),
                              Text('${cm.originalFrame}:$number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              Text('$name', style: TextStyle(fontSize: 10)),
                            ],
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                            toY: (double.tryParse(members[i].member['WinRate12#${i + 1}']) ?? 0) * 100,
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
                        final winRate = (double.tryParse(member['WinRate12#${group.x + 1}']) ?? 0) * 100;
                        final startCountRaw = member['NumberOfEntries#${group.x + 1}'] ?? '0';
                        final startCount = double.tryParse(startCountRaw.toString())?.toInt() ?? 0;
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

// 期コードを日本語表記に変換（既存プロジェクトのものを利用）
String formatDataTime(String dataTime) {
  if (dataTime.length != 5) return '不正な形式';
  final year = dataTime.substring(0, 4);
  final term = dataTime.substring(4);
  String termLabel;
  switch (term) {
    case '1': termLabel = '前期'; break;
    case '2': termLabel = '後期'; break;
    default: return '不明な期';
  }
  return '$year年$termLabel';
}

// --- 不具合修正！MemberDetailPage（localMembersも受け取る／期切替に対応） ---
class MemberDetailPage extends StatefulWidget {
  final Map<String, dynamic> member;
  final List localMembers;
  MemberDetailPage({required this.member, required this.localMembers});
  @override
  _MemberDetailPageState createState() => _MemberDetailPageState();
}
class _MemberDetailPageState extends State<MemberDetailPage> {
  late String? _selectedDataTime;
  late Map<String, dynamic> _displayMember;
  final List<String> _dataTimeList = ['', '20252', '20251', '20242', '20021'];

  @override
  void initState() {
    super.initState();
    _selectedDataTime = widget.member['DataTime']?.toString() ?? '';
    _displayMember = widget.member;
  }

  void _switchDataTime(String newValue) {
    setState(() {
      _selectedDataTime = newValue;
      _displayMember = widget.localMembers
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (m) => m['Number'] == widget.member['Number'] && m['DataTime'].toString() == newValue,
        orElse: () => _displayMember,
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    final member = _displayMember;
    return Scaffold(
      appBar: AppBar(title: Text('${member['Name']}の詳細')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(children: [
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
                    if (newValue != null) _switchDataTime(newValue);
                  },
                ),
              ]),
              SizedBox(height: 16),
              Image.network(
                member['Photo'] ?? '',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 20),
              // 詳細テーブル1
              Table(
                border: TableBorder.all(),
                children: [
                  TableRow(children: [
                    TableCell(
                      child: Text(' 期  別：${formatDataTime('${member['DataTime']}')}', textAlign: TextAlign.left),
                    ),
                    TableCell(
                      child: Text(' ${member['DataTime']}', textAlign: TextAlign.left),
                    ),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: Text(' 氏  名：${member['Name']}', textAlign: TextAlign.left),
                    ),
                    TableCell(
                      child: Text(' ${member['Kana3']}', textAlign: TextAlign.left),
                    ),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: Text(' 登  番：${member['Number']}', textAlign: TextAlign.left),
                    ),
                    TableCell(child: Text('', textAlign: TextAlign.left)),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: Text(' 勝  率：${member['WinPointRate']}', textAlign: TextAlign.left),
                    ),
                    TableCell(
                      child: Text(' 複勝率：${(double.parse(member['WinRate12']) * 100).toStringAsFixed(2)}%', textAlign: TextAlign.left),
                    ),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: Text(' 1着数：${member['1stPlaceCount']}', textAlign: TextAlign.left),
                    ),
                    TableCell(
                      child: Text(' 優勝数：${member['NumberOfWins']}', textAlign: TextAlign.left),
                    ),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: Text(' 2着数：${member['2ndPlaceCount']}', textAlign: TextAlign.left),
                    ),
                    TableCell(
                      child: Text(' 優出数：${member['NumberOfFinals']}', textAlign: TextAlign.left),
                    ),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: Text(' 平均ST：${member['StartTiming']}', textAlign: TextAlign.left),
                    ),
                    TableCell(
                      child: Text(' 出走数：${member['NumberOfRace']}', textAlign: TextAlign.left),
                    ),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: Text(' 級  別：${member['Rank']} /${member['RankPast1']}/${member['RankPast2']}/${member['RankPast3']}', textAlign: TextAlign.left),
                    ),
                    TableCell(child: Text('', textAlign: TextAlign.left)),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: Text(' 年  齢：${member['Age']}', textAlign: TextAlign.left),
                    ),
                    TableCell(
                      child: Text(' 誕生日：${member['GBirthday']}', textAlign: TextAlign.left),
                    ),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: Text(' 身  長：${member['Height']}cm', textAlign: TextAlign.left),
                    ),
                    TableCell(
                      child: Text(' 血液型：${member['Blood']}', textAlign: TextAlign.left),
                    ),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: Text(' 体  重：${member['Weight']}kg', textAlign: TextAlign.left),
                    ),
                    TableCell(child: Text('', textAlign: TextAlign.left)),
                  ]),
                  TableRow(children: [
                    TableCell(
                      child: Text(' 支  部：${member['Blanch']}', textAlign: TextAlign.left),
                    ),
                    TableCell(
                      child: Text(' 出身地：${member['Birthplace']}', textAlign: TextAlign.left),
                    ),
                  ]),
                ],
              ),
              SizedBox(height: 20),
              // 詳細テーブル2（全カラム省略せず全て展開）
              Table(
                border: TableBorder.all(),
                children: [
                  TableRow(children: [
                    TableCell(child: Text('F', textAlign: TextAlign.center)),
                    TableCell(child: Text('L0', textAlign: TextAlign.center)),
                    TableCell(child: Text('L1', textAlign: TextAlign.center)),
                    TableCell(child: Text('K0', textAlign: TextAlign.center)),
                    TableCell(child: Text('K1', textAlign: TextAlign.center)),
                    TableCell(child: Text('S0', textAlign: TextAlign.center)),
                    TableCell(child: Text('S1', textAlign: TextAlign.center)),
                    TableCell(child: Text('S2', textAlign: TextAlign.center)),
                  ]),
                  TableRow(children: [
                    TableCell(child: Text(member['FCount'].toString(), textAlign: TextAlign.center)),
                    TableCell(child: Text(member['L0Count'].toString(), textAlign: TextAlign.center)),
                    TableCell(child: Text(member['L1Count'].toString(), textAlign: TextAlign.center)),
                    TableCell(child: Text(member['K0Count'].toString(), textAlign: TextAlign.center)),
                    TableCell(child: Text(member['K1Count'].toString(), textAlign: TextAlign.center)),
                    TableCell(child: Text(member['S0Count'].toString(), textAlign: TextAlign.center)),
                    TableCell(child: Text(member['S1Count'].toString(), textAlign: TextAlign.center)),
                    TableCell(child: Text(member['S2Count'].toString(), textAlign: TextAlign.center)),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
