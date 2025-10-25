# ☕️ 감정 잔향 전시 POC — Product Requirements Document (v0.2, Integrated)

> **프로젝트명:** 감정 잔향 전시 POC  
> **작성자:** 예승님  
> **작성일:** 2025-10-25  
> **목표:**  
> Flutter mobile 카메라를 사용해 전시장 내 인원 위치를 감지하고,  
> 머무른 시간을 Flutter Web의 내장 서버로 전송 및 시각화하는 오프라인 실험형 POC 시스템.

---

## 🧭 1️⃣ 개요

이 프로젝트는 **AI 카메라 감지 + 시간 추적 + 대시보드 시각화**를  
모두 Flutter 환경 내에서 수행하는 실험용 POC이다.  
외부 서버(FastAPI 등)는 사용하지 않으며,  
Flutter Web이 자체적으로 REST API 서버 역할을 한다.

---

## 🧩 2️⃣ 시스템 구성 요약

```
[Flutter Mobile App]
 ├─ 카메라 기반 사람 감지 (TFLite/MediaPipe)
 ├─ 코너별 머무름 시간 계산
 └─ Flutter Web(localhost)로 데이터 전송

[Flutter Web Dashboard]
 ├─ dart:io 기반 HTTP 서버 (REST API)
 ├─ POST 요청 수신 및 In-memory 저장
 ├─ 대시보드 실시간 시각화
```

---

## ⚙️ 3️⃣ 기능 요구사항

| ID | 기능명 | 설명 | 우선순위 |
|----|---------|------|-----------|
| F-01 | 카메라 감지 | Mobile에서 프레임 단위로 사람 감지 | ★★★★★ |
| F-02 | 코너 판정 | 프레임을 4분면으로 나누고 좌표 기반 판정 | ★★★★★ |
| F-03 | 시간 누적 | 특정 코너 유지 시 타이머 누적 | ★★★★☆ |
| F-04 | 데이터 전송 | Flutter Web 서버로 REST POST 전송 | ★★★★☆ |
| F-05 | 데이터 수신 | Flutter Web이 POST 수신 및 저장 | ★★★★☆ |
| F-06 | 시각화 | Web Dashboard에서 실시간 업데이트 | ★★★★☆ |

---

## 🧠 4️⃣ 데이터 구조

### POST `/api/staytime`
```json
{
  "device_id": "mobile_01",
  "corner_times": {
    "top-left": 20,
    "top-right": 15,
    "bottom-left": 0,
    "bottom-right": 10
  }
}
```

### GET `/api/staytime`
```json
{
  "mobile_01": {
    "top-left": 20,
    "top-right": 15,
    "bottom-left": 0,
    "bottom-right": 10
  }
}
```

---

## 🧱 5️⃣ Flutter Web 구조

```
lib/
 ├── main.dart              // entrypoint + 서버 실행
 ├── api_server.dart        // dart:io 기반 REST 서버
 ├── dashboard_screen.dart  // 대시보드 UI
 ├── data_store.dart        // In-memory 저장소
 ├── models/stay_data.dart  // 모델 정의
 └── utils/logger.dart      // 로깅
```

---

## 💻 6️⃣ Flutter Web 서버 코드 예시

```dart
import 'dart:convert';
import 'dart:io';

final Map<String, Map<String, int>> stayData = {};

Future<void> startApiServer() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print("✅ Flutter Web API running on http://0.0.0.0:8080");

  await for (HttpRequest req in server) {
    if (req.method == 'POST' && req.uri.path == '/api/staytime') {
      final body = await utf8.decoder.bind(req).join();
      final data = jsonDecode(body);
      stayData[data["device_id"]] = Map<String, int>.from(data["corner_times"]);
      req.response
        ..statusCode = 200
        ..write(jsonEncode({"status": "ok"}))
        ..close();
    } else if (req.method == 'GET' && req.uri.path == '/api/staytime') {
      req.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(stayData))
        ..close();
    } else {
      req.response
        ..statusCode = 404
        ..write('Not Found')
        ..close();
    }
  }
}
```

---

## 📱 7️⃣ Flutter Mobile (데이터 전송)

```dart
Future<void> sendStayData(Map<String, int> cornerTimes) async {
  final url = Uri.parse("http://192.168.0.10:8080/api/staytime");
  final body = jsonEncode({
    "device_id": "mobile_01",
    "corner_times": cornerTimes,
  });
  await http.post(url, headers: {"Content-Type": "application/json"}, body: body);
}
```

---

## 📊 8️⃣ Flutter Web 대시보드

```dart
class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> cornerTimes = {};

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 2), (_) => refreshData());
  }

  Future<void> refreshData() async {
    final res = await http.get(Uri.parse('http://0.0.0.0:8080/api/staytime'));
    final data = jsonDecode(res.body);
    setState(() => cornerTimes = data["mobile_01"] ?? {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.count(
        crossAxisCount: 2,
        children: cornerTimes.entries.map((e) {
          return Card(
            child: Center(
              child: Text(
                "${e.key}\n${e.value}s",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

---

## ⚡️ 9️⃣ 실행 순서

1. Flutter Web 실행  
   ```bash
   flutter run -d chrome
   ```
   - `main()`에서 `startApiServer()` 호출  
   - 콘솔에 `API running` 로그 확인  

2. Flutter Mobile 실행  
   - 동일 Wi-Fi 연결  
   - `POST http://<web-ip>:8080/api/staytime` 호출  

3. Web Dashboard 자동 갱신  

---

## ✅ 10️⃣ 검증 항목

| 항목 | 목표 |
|------|------|
| 감지 정확도 | 80% 이상 |
| 타이머 정확도 | ±2초 오차 |
| 통신 안정성 | Wi-Fi 내 100% |
| 반응속도 | 2초 이내 |

---

## 🧩 11️⃣ Feature-Based 구조 지침

```
lib/
  features/
    detection/      // 카메라 감지 및 시간 계산
    api/            // 서버 통신 로직
    dashboard/      // 웹 UI
  shared/
    utils/          // 공통 로깅, 상수
    models/         // 데이터 모델
main.dart
```

---

## 🧠 12️⃣ 개발 원칙

- **명확성:** “왜/무엇을 만드는지”를 항상 인지  
- **단계적 개발:** 감지 → 통신 → 시각화 순으로 진행  
- **의존성 최소화:** 외부 서버 없이 완전 로컬 작동  
- **반복 개선:** 테스트 → 개선 → 재배포  
- **가벼운 UI:** 실험용 구조로 단순한 형태 유지  

---

## 🧾 13️⃣ 결론

| 구성요소 | 선택 |
|-----------|------|
| 서버 | Flutter Web 내장 REST |
| 감지 | Flutter Mobile (Camera + TFLite) |
| 데이터 저장 | In-memory Map |
| 통신 | HTTP (동일 Wi-Fi) |
| 대시보드 | Flutter Web UI |
| 아키텍처 | Feature-based |

---

© 2025 예승님 — 감정 잔향 전시 POC
