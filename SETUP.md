# 감정 잔향 전시 POC - Setup Guide

## 📋 시스템 구성

이 프로젝트는 3가지 컴포넌트로 구성되어 있습니다:

1. **API Server** (Dart) - REST API 서버
2. **Web Dashboard** (Flutter Web) - 데이터 시각화 대시보드
3. **Mobile App** (Flutter Mobile) - 카메라 기반 코너 추적

---

## 🚀 실행 방법

### 1️⃣ API Server 실행

터미널에서 다음 명령어로 서버를 시작합니다:

```bash
dart run bin/server.dart
```

또는 특정 포트로 실행:

```bash
dart run bin/server.dart 8080
```

✅ 서버가 실행되면 다음과 같은 로그가 표시됩니다:
```
✅ API Server running on http://0.0.0.0:8080
```

**사용 가능한 엔드포인트:**
- `POST /api/staytime` - 모바일에서 시간 데이터 수신
- `GET /api/staytime` - 모든 디바이스 데이터 조회
- `GET /api/staytime/:deviceId` - 특정 디바이스 데이터 조회
- `GET /health` - 서버 상태 확인

---

### 2️⃣ Web Dashboard 실행

새 터미널 창에서:

```bash
flutter run -d chrome
```

또는 특정 브라우저로:

```bash
flutter run -d edge
```

✅ 대시보드가 열리면 2초마다 자동으로 데이터를 갱신합니다.

---

### 3️⃣ Mobile App 실행

**중요: 모바일 앱 설정**

1. `lib/services/api_service.dart` 파일을 열고 `baseUrl`을 수정합니다:

```dart
ApiService({
  this.baseUrl = 'http://YOUR_COMPUTER_IP:8080',  // <-- 여기 수정!
  this.deviceId = 'mobile_01',
});
```

2. 컴퓨터의 IP 주소 찾기:
   - **macOS**: `ifconfig | grep "inet " | grep -v 127.0.0.1`
   - **Windows**: `ipconfig`
   - 예: `192.168.0.10`

3. 모바일 디바이스가 **같은 Wi-Fi 네트워크**에 연결되어 있는지 확인

4. 앱 실행:

```bash
# Android
flutter run

# iOS
flutter run -d ios

# 또는 특정 디바이스 선택
flutter devices
flutter run -d <device-id>
```

---

## 📱 Mobile App 사용법

### 🎯 픽셀 기반 모션 감지 (자동)

앱은 기본적으로 **자동 모션 감지 모드**로 시작됩니다:

1. 앱이 시작되면 카메라가 자동으로 초기화됩니다
2. 화면이 4개 구역으로 나뉘어 있습니다:
   - Top Left (왼쪽 위)
   - Top Right (오른쪽 위)
   - Bottom Left (왼쪽 아래)
   - Bottom Right (오른쪽 아래)

3. 각 코너를 **탭**하면 해당 영역의 시간이 추적됩니다
4. 다른 코너를 탭하면 자동으로 전환됩니다
5. 하단에서 실시간으로 각 코너의 누적 시간을 확인할 수 있습니다

### 작동 방식

**픽셀 기반 모션 감지:**
1. 카메라 프레임의 픽셀 변화를 감지
2. 이전 프레임과 비교하여 차이 계산
3. 화면을 4개 구역으로 나누어 각 영역의 모션 측정
4. 가장 많이 움직인 영역을 자동 추적
5. 해당 코너가 **초록색**으로 하이라이트됨

**장점:**
- ✅ ML Kit 불필요 (가벼움)
- ✅ 모든 디바이스에서 작동
- ✅ 오류 없음
- ✅ 빠른 처리 속도

### 모드 전환

**자동 모션 감지** (기본):
- 움직임이 있는 영역을 자동으로 감지
- 초록색으로 영역 하이라이트
- 상태 표시: `AUTO` (초록색)

**수동 모드**:
- 화면의 코너를 직접 탭하여 추적
- 상태 표시: `MANUAL` (주황색)
- 상단 ✨ 버튼으로 전환

### 버튼 기능

- **✨/👆 Auto/Manual**: 자동 감지 ↔ 수동 모드 전환
- **🔄 Refresh**: 모든 시간을 0으로 리셋
- **📤 Send**: 즉시 데이터를 서버로 전송

### 자동 데이터 전송

- **5초마다** 자동으로 서버에 데이터 전송

---

## 🔍 테스트 시나리오

### 전체 시스템 테스트

1. **서버 시작**
   ```bash
   dart run bin/server.dart
   ```

2. **웹 대시보드 열기** (새 터미널)
   ```bash
   flutter run -d chrome
   ```

3. **모바일 앱 실행** (새 터미널)
   ```bash
   flutter run
   ```

4. **테스트 진행**
   - Mobile: Top Left를 탭하고 5초 대기
   - Web: Top Left 구역의 시간이 증가하는지 확인
   - Mobile: Top Right를 탭하고 10초 대기
   - Web: Top Right 구역의 시간이 증가하는지 확인

---

## 🛠️ 문제 해결

### 모바일에서 서버에 연결 안됨

1. 방화벽 확인:
   ```bash
   # macOS 방화벽 설정 확인
   # System Preferences > Security & Privacy > Firewall
   ```

2. 같은 Wi-Fi 네트워크 확인
   - 컴퓨터와 모바일이 같은 네트워크에 있어야 합니다

3. IP 주소 확인:
   ```bash
   # 현재 IP 확인
   ifconfig | grep "inet "
   ```

4. 서버가 실행 중인지 확인:
   ```bash
   curl http://localhost:8080/health
   ```

### Web Dashboard에 데이터가 안 보임

1. 서버가 실행 중인지 확인
2. 브라우저 콘솔에서 에러 확인 (F12)
3. 모바일에서 데이터를 전송했는지 확인

---

## 📁 프로젝트 구조

```
lib/
├── features/
│   ├── api/
│   │   ├── api_server.dart      # REST API 서버
│   │   └── data_store.dart      # 인메모리 데이터 저장소
│   ├── dashboard/
│   │   └── dashboard_screen.dart # 웹 대시보드 UI
│   └── detection/
│       └── time_tracker.dart     # 시간 추적 서비스
├── screens/
│   └── camera_screen.dart        # 모바일 카메라 화면
├── services/
│   ├── api_service.dart          # API 통신 서비스
│   └── camera_service.dart       # 카메라 서비스
├── shared/
│   ├── models/
│   │   └── stay_data.dart        # 데이터 모델
│   └── utils/
│       └── logger.dart           # 로깅 유틸
└── main.dart                     # 앱 진입점

bin/
└── server.dart                   # 서버 진입점
```

---

## ✅ 구현된 기능

- [x] **Motion Detection**: 픽셀 기반 모션 감지 (ML Kit 불필요)
- [x] **자동 코너 판정**: 움직임 기반 자동 코너 추적
- [x] **실시간 시각화**: 웹 대시보드에서 실시간 업데이트
- [x] **수동/자동 모드**: 테스트와 실제 사용 간 전환 가능
- [x] **경량화**: 외부 ML 라이브러리 의존성 제거

## 🔮 향후 개발 예정

- [ ] **멀티 사람 감지**: 여러 사람 동시 추적
- [ ] **멀티 디바이스 지원**: 여러 카메라 동시 사용
- [ ] **데이터 영속성**: 파일 또는 DB에 데이터 저장
- [ ] **고급 시각화**: 차트 및 히트맵
- [ ] **감지 정확도 향상**: 더 정교한 포즈 감지 알고리즘

---

## 📊 API 사양

### POST /api/staytime

**Request:**
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

**Response:**
```json
{
  "status": "ok"
}
```

### GET /api/staytime

**Response:**
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

© 2025 예승님 — 감정 잔향 전시 POC
