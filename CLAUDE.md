# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

3D 효과가 있는 인터랙티브 포켓몬 카드를 표시하는 Flutter 애플리케이션입니다. 마우스 이동이나 터치 제스처에 반응하여 카드가 3D로 기울어지며, PokeAPI를 통해 랜덤 포켓몬 데이터를 가져옵니다. Web, iOS, Android 플랫폼을 모두 지원합니다.

**웹 데모**: https://origogi.github.io/flutter-pokemon-3d-card/

## 개발 명령어

### 실행
```bash
# 개발 서버 실행 (플랫폼별)
flutter run -d chrome        # 웹
flutter run -d macos         # macOS
flutter run                  # 연결된 디바이스

# 특정 플랫폼 빌드
flutter build web
flutter build ios
flutter build apk
flutter build appbundle
```

### 린트 및 분석
```bash
# 코드 정적 분석
flutter analyze

# 포맷팅
flutter format .
flutter format lib/
```

### 의존성 관리
```bash
# 패키지 설치
flutter pub get

# 패키지 업데이트
flutter pub upgrade

# 캐시 정리
flutter clean
```

## 아키텍처

### 상태 관리
- **Riverpod** (hooks_riverpod ^2.6.1)을 사용한 상태 관리
- `StateNotifierProvider`를 통해 포켓몬 정보 상태를 관리
- `AsyncValue`를 사용하여 loading/data/error 상태를 처리

### 레이어 구조
```
lib/
├── data/               # 데이터 레이어
│   └── pokemon_repository.dart  # PokeAPI HTTP 통신
├── domain/             # 도메인 레이어
│   └── pokemon_info.dart        # 포켓몬 데이터 모델
├── view/               # 프레젠테이션 레이어
│   ├── home.dart               # 메인 화면 (MaterialApp)
│   ├── tilt_card.dart          # 3D 틸트 카드 위젯
│   ├── pokemon_info_provider.dart  # 포켓몬 상태 관리
│   ├── random_button.dart      # 랜덤 포켓몬 버튼
│   ├── background_blur.dart    # 배경 블러 효과
│   └── github_link.dart        # GitHub 링크 (웹 전용)
└── util/               # 유틸리티
    └── platform_checker*.dart   # 플랫폼별 조건부 import
```

### 핵심 컴포넌트

**TiltCard (lib/view/tilt_card.dart)**
- `HookConsumerWidget`을 사용한 3D 틸트 효과 구현
- `useState`로 tiltX, tiltY 상태 관리
- `useAnimationController`로 리셋 애니메이션 처리
- 플랫폼별 입력 처리:
  - 데스크톱/웹: `MouseRegion`으로 마우스 호버 감지
  - 모바일: `GestureDetector`로 팬 제스처 감지
- `Matrix4` 3D 변환을 통한 카드 회전 효과
- 동적 그레어(glare) 효과: 틸트 각도에 따라 하이라이트 위치와 투명도 변경

**PokemonInfoNotifier (lib/view/pokemon_info_provider.dart)**
- `StateNotifier<AsyncValue<PokemonInfo>>`로 구현
- Repository를 주입받아 포켓몬 데이터 fetch
- 초기화 시 자동으로 랜덤 포켓몬 로드

**PokemonRepository (lib/data/pokemon_repository.dart)**
- PokeAPI (https://pokeapi.co/api/v2/pokemon/) 사용
- 1-1025 범위의 랜덤 포켓몬 ID 생성
- HTTP 통신 및 JSON 파싱 처리

**플랫폼 체커 (lib/util/platform_checker.dart)**
- Conditional imports 패턴 사용
- `dart:html` 사용 가능 여부로 웹/모바일 구분
- `platform_checker_web.dart`, `platform_checker_mobile.dart`, `platform_checker_stub.dart`로 분리

### 주요 기술 스택
- **상태 관리**: Riverpod + Flutter Hooks
- **HTTP 통신**: http ^1.1.0
- **폰트**: Silkscreen (assets/fonts/)
- **리소스**: SVG (flutter_svg), GIF 로딩 인디케이터
- **플랫폼 지원**: Web, iOS, Android

## 코드 스타일 및 규칙

- `flutter_lints` 패키지 기반 린트 규칙 적용
- `analysis_options.yaml`에서 `depend_on_referenced_packages` 경고 무시 설정
- Riverpod provider는 파일 최하단에 global로 선언
- 위젯은 가능한 한 const 생성자 사용
- Flutter Hooks 사용 시 `useCallback`, `useMemoized`로 최적화

## 개발 팁

### 3D 틸트 효과 조정
- `tilt_card.dart:41-42`에서 tiltX, tiltY 계산 로직 수정
- `smoothing` 상수(0.2)로 보간 속도 조절
- `clamp` 값으로 최대 기울기 제한 (-8.0 ~ 8.0)

### 새로운 포켓몬 속성 추가
1. `domain/pokemon_info.dart`에 필드 추가
2. `fromJson` 팩토리에서 JSON 매핑
3. `view/tilt_card.dart`의 `PokemonInfoLabels`에서 UI 표시

### 플랫폼별 조건부 렌더링
```dart
if (kIsWeb) ... // flutter/foundation.dart
PlatformChecker.isMobile // 커스텀 플랫폼 체커
```

## TODO
- Gyro 센서 조정 (README TODO 항목)

## 참고
- 원본 CodePen 참고: https://codepen.io/andrewmillen/full/jOLELeo
- PokeAPI 문서: https://pokeapi.co/docs/v2
