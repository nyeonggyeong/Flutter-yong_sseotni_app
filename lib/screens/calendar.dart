import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class CalendarPage extends StatefulWidget {
  final Map<String, dynamic> userData; // 로그인한 유저 데이터

  const CalendarPage({super.key, required this.userData});

  @override
  CalendarPageState createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  // 날짜별 수입/지출 데이터 저장
  Map<DateTime, List<Map<String, dynamic>>> events = {};

  List<String> categories = [
    '카페',
    '외식',
    '교통',
    '문화/취미 생활',
    '생활용품 및 마트, 편의점',
    '쇼핑',
  ];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 선택된 날짜의 이벤트 가져오기
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  // API 호출: 수입/지출 등록
  Future<void> saveMoney(Map<String, dynamic> moneyData) async {
    const apiUrl = 'http://3.36.22.27:8080/Spring-yong_sseotni/api/money/save';

    try {
      final body = moneyData.entries.map((entry) {
        return '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}';
      }).join('&');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }, // key1=value1&key2=value2&key3=value3
        body: body,
      );

      if (response.statusCode == 200) {
        print('Event saved successfully: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장이 완료되었습니다!')),
        );
      } else {
        print('Failed to save event: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error during API call: $e'); // 테스트용
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
                onChanged: (value) {
                  transactionType = value!;
                },
                decoration: const InputDecoration(
                  labelText: '유형',
                ),
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
                decoration: const InputDecoration(
                  labelText: '카테고리',
                ),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                if (amountController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  final moneyData = {
                    'user_idx': widget.userData['user_idx'], // 유저 ID
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

                  // API 호출
                  await saveMoney(moneyData);

                  setState(() {
                    final dateKey = DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                    );
                    if (events[dateKey] == null) {
                      events[dateKey] = [];
                    }
                    events[dateKey]!.add({
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
            selectedDayPredicate: (DateTime day) {
              return isSameDay(selectedDay, day);
            },
            onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
              setState(() {
                this.selectedDay = selectedDay;
                this.focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              isTodayHighlighted: true,
              selectedDecoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.deepPurple, width: 1.0),
              ),
              outsideDecoration: const BoxDecoration(shape: BoxShape.rectangle),
              defaultTextStyle: const TextStyle(color: Colors.black),
              weekendTextStyle: const TextStyle(color: Colors.red),
              selectedTextStyle: const TextStyle(color: Colors.deepPurple),
              markerDecoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              titleTextFormatter: (date, locale) =>
                  DateFormat.yMMMM(locale).format(date),
              formatButtonVisible: false,
              titleTextStyle: const TextStyle(
                fontSize: 20.0,
                color: Colors.black,
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 4.0),
              leftChevronIcon: const Icon(
                Icons.arrow_left,
                size: 30.0,
              ),
              rightChevronIcon: const Icon(
                Icons.arrow_right,
                size: 30.0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _addEventForSelectedDay,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              '수입/지출 추가',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38D39F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 5,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: _getEventsForDay(selectedDay).map((event) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 2.0, horizontal: 8.0),
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            event['category'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                event['description'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Text(
                            '${event['amount']}원',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: event['type'] == '수입'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '지출패턴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: '커뮤니티',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: '할인 혜택',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
