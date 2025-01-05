import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_yong_sseotni/screens/community.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class CalendarPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CalendarPage({super.key, required this.userData});

  @override
  CalendarPageState createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  Map<DateTime, List<Map<String, dynamic>>> events = {};

  final List<String> categories = [
    '카페',
    '외식',
    '교통',
    '문화/취미 생활',
    '생활용품 및 마트, 편의점',
    '쇼핑',
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CommunityPage(userIdx: widget.userData['user_idx']),
        ),
      );
    }
  }

  Future<void> saveMoney(Map<String, dynamic> moneyData) async {
    const apiUrl = 'http://3.36.22.27:8080/Spring-yong_sseotni/api/money/save';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: moneyData.entries
            .map((entry) =>
                '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
            .join('&'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장이 완료되었습니다!')),
        );
      }
    } catch (e) {
      print('Error during API call: $e');
    }
  }

  void _addEventForSelectedDay() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String transactionType = '수입';
    String selectedCategory = categories.first;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('수입/지출 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: transactionType,
                items: ['수입', '지출']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => transactionType = value!,
                decoration: const InputDecoration(labelText: '유형'),
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) => selectedCategory = value!,
                decoration: const InputDecoration(labelText: '카테고리'),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '금액',
                  hintText: '금액을 입력하세요',
                ),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명',
                  hintText: '지출/수입 상세 설명',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                if (amountController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  final moneyData = {
                    'user_idx': widget.userData['user_idx'],
                    'money_when': DateFormat('yyyy-MM-dd').format(selectedDay),
                    'money_type': selectedCategory,
                    'money_where': descriptionController.text,
                    'money_in': transactionType == '수입'
                        ? int.parse(amountController.text)
                        : 0,
                    'money_out': transactionType == '지출'
                        ? int.parse(amountController.text)
                        : 0,
                  };

                  await saveMoney(moneyData);

                  setState(() {
                    final dateKey = DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                    );
                    events.putIfAbsent(dateKey, () => []).add({
                      'type': transactionType,
                      'amount': int.parse(amountController.text),
                      'description': descriptionController.text,
                      'category': selectedCategory,
                    });
                  });

                  Navigator.of(context).pop();
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchMonthlyEvents() async {
    const apiUrl =
        'http://3.36.22.27:8080/Spring-yong_sseotni/api/money/getMonthlyMoneyList';
    try {
      final userIdx = widget.userData['user_idx'];
      final url =
          '$apiUrl?user_idx=$userIdx&year=${focusedDay.year}&month=${focusedDay.month}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          events.clear();
          for (var event in decodedData) {
            final eventDate = DateTime.tryParse(event['money_when'] ?? '');
            if (eventDate != null) {
              final keyDate =
                  DateTime(eventDate.year, eventDate.month, eventDate.day);
              events.putIfAbsent(keyDate, () => []).add({
                'type': event['money_in'] > 0 ? '수입' : '지출',
                'amount': int.tryParse(event['money']?.toString() ?? '0') ?? 0,
                'description': event['money_where'] ?? '알 수 없음',
                'category': event['money_type'] ?? '기타',
              });
            }
          }
        });
      }
    } catch (e) {
      print('Error fetching monthly events: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMonthlyEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('캘린더 - ${widget.userData['user_nick']}님'),
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2023, 1, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });
            },
            onPageChanged: (newFocusedDay) {
              setState(() => focusedDay = newFocusedDay);
              fetchMonthlyEvents();
            },
            eventLoader: (day) =>
                events[DateTime(day.year, day.month, day.day)] ?? [],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _addEventForSelectedDay,
            icon: const Icon(Icons.add),
            label: const Text('수입/지출 추가'),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: (events[DateTime(
                        selectedDay.year,
                        selectedDay.month,
                        selectedDay.day,
                      )] ??
                      [])
                  .map((event) => ListTile(
                        title: Text(event['category']),
                        subtitle: Text(event['description']),
                        trailing: Text(
                          '${event['amount']}원',
                          style: TextStyle(
                            color: event['type'] == '수입'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '지출패턴'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: '커뮤니티'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_offer), label: '할인 혜택'),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
