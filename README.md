# 빵도장 (BreadStamp)

> 동네 빵집 탐방을 게임처럼 즐기는 iOS 기록 앱

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0+-000000?style=flat&logo=apple&logoColor=white" />
  <img src="https://img.shields.io/badge/Swift-5.9-FA7343?style=flat&logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/SwiftUI-blue?style=flat&logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/SwiftData-purple?style=flat&logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/Architecture-MVVM-green?style=flat" />
  <img src="https://img.shields.io/badge/Dependencies-Zero-orange?style=flat" />
</p>

---

## 프로젝트 소개

**빵도장**은 동네 빵집 탐방을 즐기는 사용자를 위한 게이미피케이션 기록 앱입니다.

단순 리뷰를 넘어 **스탬프 수집**, **빵 도감 완성**, **업적 달성**이라는 성취 요소를 통해 빵집 탐방에 재미를 더합니다. 모든 데이터는 기기 내 로컬 저장되며, 서버 없이 오프라인에서도 동작합니다.

### 핵심 가치
| 가치 | 설명 |
|------|------|
| **기록** | 방문한 빵집과 먹은 빵을 체계적으로 관리 |
| **수집** | 스탬프북과 도감으로 탐방 이력 시각화 |
| **성취** | 업적 배지 시스템으로 지속적인 동기 부여 |

---

## 주요 기능

### 1. 스탬프북 (홈)
- 방문한 빵집을 스탬프 카드 그리드로 표시
- 빵집별 사진 등록 및 즐겨찾기 관리
- 빵집 상세 페이지에서 등록한 빵 목록 확인

### 2. 빵 도감 (컬렉션)
- 먹은 빵을 카테고리별(식빵, 크루아상, 단팥빵, 케이크, 도넛, 베이글, 기타)로 분류
- 빵 이름, 사진, 평점(1~5), 메모 기록
- 카테고리 필터 칩으로 빠른 조회

### 3. 지도
- MapKit 기반 방문 빵집 위치 마커 표시
- 카메라 자동 포지셔닝 (전체 빵집이 보이도록)
- 즐겨찾기 빵집 마커 색상 구분

### 4. 프로필 / 통계
- 방문 빵집 수, 먹은 빵 수, 즐겨찾기 수, 평균 평점
- 카테고리별 빵 비율 프로그레스 바
- 9종 업적 배지 시스템 (탭하면 달성 가이드 표시)

---

## 기술 스택

| 영역 | 기술 | 선택 이유 |
|------|------|-----------|
| UI 프레임워크 | **SwiftUI** | 선언적 UI, Reactive 데이터 바인딩 |
| 데이터 영속화 | **SwiftData** | Apple 네이티브 ORM, @Model/@Query 활용 |
| 아키텍처 | **MVVM** | View-ViewModel 분리로 테스트 용이성 확보 |
| 지도 | **MapKit** | 네이티브 지도, Marker/카메라 포지셔닝 |
| 이미지 | **PhotosUI** | PhotosPicker로 앨범 접근 |
| 외부 의존성 | **없음** | 순수 Apple SDK만 사용 |

---

## 아키텍처

### MVVM 레이어 구조

```mermaid
block-beta
    columns 1
    block:views["Views Layer"]
        A["SwiftUI Views"]
        B["선언적 UI 렌더링"]
    end
    space
    block:viewmodels["ViewModels Layer"]
        C["@Observable ViewModels"]
        D["비즈니스 로직 + 상태 관리"]
    end
    space
    block:services["Services Layer"]
        E["Stateless Services"]
        F["통계 계산 · 업적 판정 · 샘플 데이터"]
    end
    space
    block:models["Models Layer"]
        G["@Model Entities"]
        H["SwiftData 영속화"]
    end

    views --> viewmodels
    viewmodels --> services
    viewmodels --> models

    style views fill:#4A90D9,color:#fff
    style viewmodels fill:#7B68EE,color:#fff
    style services fill:#F5A623,color:#fff
    style models fill:#D0021B,color:#fff
```

### MVVM 데이터 흐름

```mermaid
flowchart LR
    subgraph View["View Layer"]
        direction TB
        V1[SwiftUI View]
        V2["@Query 데이터 구독"]
        V3["@State ViewModel 소유"]
    end

    subgraph VM["ViewModel Layer"]
        direction TB
        VM1["@Observable 클래스"]
        VM2["CRUD 메서드"]
        VM3["UI 상태 관리"]
    end

    subgraph Model["Model Layer"]
        direction TB
        M1["@Model 엔티티"]
        M2["ModelContext"]
        M3["SwiftData 저장소"]
    end

    V1 -->|"사용자 액션"| VM1
    VM2 -->|"insert/delete"| M2
    M2 -->|"persist"| M3
    M3 -->|"@Query 자동 반영"| V2
    V2 -->|"UI 업데이트"| V1

    style View fill:#4A90D9,color:#fff
    style VM fill:#7B68EE,color:#fff
    style Model fill:#C0392B,color:#fff
```

---

## 데이터 모델

### ER 다이어그램

```mermaid
erDiagram
    BAKERY ||--o{ BREAD : "1:N (cascade delete)"
    BAKERY {
        UUID id PK
        String name
        String address
        Double latitude
        Double longitude
        Data imageData "nullable"
        String memo "nullable"
        Bool isFavorite
        Date visitedAt
        Date createdAt
        Date updatedAt
    }
    BREAD {
        UUID id PK
        String name
        BreadCategory category
        Data imageData "nullable, externalStorage"
        Int rating "1~5"
        String memo "nullable"
        Date eatenAt
        Date createdAt
        Date updatedAt
    }
    ACHIEVEMENT {
        String id PK
        String title
        String description
        String iconName
        AchievementRequirement requirement
        Date unlockedAt "nullable"
    }
```

### 빵 카테고리

```mermaid
mindmap
  root((BreadCategory))
    식빵류
      ::icon(🍞)
    크로아상류
      ::icon(🥐)
    단팥빵류
      ::icon(🥮)
    케이크류
      ::icon(🍰)
    도넛류
      ::icon(🍩)
    베이글류
      ::icon(🥯)
    기타
      ::icon(🥖)
```

---

## 화면 흐름

### 탭 네비게이션 구조

```mermaid
flowchart TB
    App["BreadStampApp<br/>@main"]
    App --> MC["ModelContainer<br/>(Bakery, Bread)"]
    MC --> CV["ContentView<br/>TabView"]

    CV --> T1["🏠 스탬프북<br/>HomeView"]
    CV --> T2["📖 도감<br/>CollectionView"]
    CV --> T3["🗺️ 지도<br/>MapTabView"]
    CV --> T4["👤 프로필<br/>ProfileView"]

    T1 --> SC["StampCard Grid<br/>3열 LazyVGrid"]
    SC -->|"NavigationLink"| BD["BakeryDetailView<br/>빵집 상세"]
    T1 -->|"Sheet"| ABS["AddBakerySheet<br/>빵집 추가"]

    BD -->|"Sheet"| ABRS["AddBreadSheet<br/>빵 추가"]
    BD --> BC1["BreadCard List<br/>등록된 빵 목록"]

    T2 --> FC["CategoryFilter<br/>카테고리 칩"]
    T2 --> BC2["BreadCard List<br/>전체 빵 목록"]

    T3 --> MAP["Map + Marker<br/>MapKit 지도"]

    T4 --> STAT["Statistics Cards<br/>통계 대시보드"]
    T4 --> BG["BadgeView Grid<br/>업적 배지"]
    BG -->|"Sheet"| AGS["AchievementGuideSheet<br/>업적 가이드"]

    style App fill:#2D3748,color:#fff
    style CV fill:#4A90D9,color:#fff
    style T1 fill:#3B7DD8,color:#fff
    style T2 fill:#3B7DD8,color:#fff
    style T3 fill:#3B7DD8,color:#fff
    style T4 fill:#3B7DD8,color:#fff
    style ABS fill:#E8940A,color:#fff
    style ABRS fill:#E8940A,color:#fff
    style AGS fill:#E8940A,color:#fff
```

### 빵집 등록 시퀀스

```mermaid
sequenceDiagram
    actor User as 사용자
    participant HV as HomeView
    participant Sheet as AddBakerySheet
    participant VM as BakeryViewModel
    participant MC as ModelContext
    participant SD as SwiftData

    User->>HV: "+" 버튼 탭
    HV->>Sheet: Sheet 표시
    User->>Sheet: 이름, 주소, 사진 입력
    Sheet->>Sheet: PhotosPicker로 사진 선택 (선택사항)
    User->>Sheet: "추가" 버튼 탭
    Sheet->>VM: addBakery(name, address, imageData, ...)
    VM->>MC: context.insert(bakery)
    VM->>MC: context.save()
    MC->>SD: 영속화 저장
    SD-->>HV: @Query 자동 업데이트
    HV-->>User: 새 StampCard 표시
    Sheet->>Sheet: dismiss()
```

### 업적 달성 시퀀스

```mermaid
sequenceDiagram
    actor User as 사용자
    participant PV as ProfileView
    participant SS as StatisticsService
    participant AS as AchievementService
    participant BV as BadgeView

    User->>PV: 프로필 탭 진입
    PV->>SS: calculate(bakeries, breads)
    SS-->>PV: Stats (통계 데이터)
    PV->>AS: checkAchievements(bakeryCount, breadCount, ...)
    AS->>AS: 각 업적 조건 판정
    AS-->>PV: [Achievement] (업데이트된 목록)
    PV->>BV: 배지 그리드 렌더링
    User->>BV: 배지 탭
    BV->>BV: AchievementGuideSheet 표시

    Note over AS: bakeryCount(1) → 첫 발도장!
    Note over AS: breadCount(10) → 빵순이
    Note over AS: allCategories → 빵 박사
    Note over AS: fiveStarBreads(5) → 미식가
```

---

## View-ViewModel 의존성

```mermaid
graph LR
    subgraph Views
        HV[HomeView]
        BDV[BakeryDetailView]
        ABS[AddBakerySheet]
        CV[CollectionView]
        ABRS[AddBreadSheet]
        MTV[MapTabView]
        PV[ProfileView]
    end

    subgraph ViewModels
        BakVM[BakeryViewModel]
        BrdVM[BreadViewModel]
        MapVM[MapViewModel]
        PrfVM[ProfileViewModel]
    end

    subgraph Services
        SS[StatisticsService]
        AS[AchievementService]
        SDS[SampleDataService]
    end

    HV --> BakVM
    BDV --> BakVM
    BDV --> BrdVM
    ABS --> BakVM
    ABRS -.->|"ModelContext 직접 사용"| MC[(SwiftData)]
    MTV -.->|"@Query 직접 사용"| MC
    CV -.->|"@Query 직접 사용"| MC

    PV --> SS
    PV --> AS
    PV --> PrfVM

    style Views fill:#4A90D9,color:#fff
    style ViewModels fill:#7B68EE,color:#fff
    style Services fill:#E8940A,color:#fff
```

---

## 프로젝트 구조

```
BreadStamp/
├── App/
│   ├── BreadStampApp.swift          ← @main, ModelContainer 설정
│   └── ContentView.swift            ← TabView 루트
├── Models/
│   ├── Bakery.swift                 ← @Model 빵집 (1:N → Bread)
│   ├── Bread.swift                  ← @Model 빵 (N:1 → Bakery)
│   ├── BreadCategory.swift          ← 7종 카테고리 enum
│   └── Achievement.swift            ← 업적 모델 + 9종 정의
├── ViewModels/
│   ├── BakeryViewModel.swift        ← 빵집 CRUD + 즐겨찾기
│   ├── BreadViewModel.swift         ← 빵 CRUD
│   ├── MapViewModel.swift           ← 지도 상태 관리
│   └── ProfileViewModel.swift       ← 업적 상태 관리
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift           ← 스탬프북 메인 (3열 그리드)
│   │   ├── BakeryDetailView.swift   ← 빵집 상세 + 빵 목록
│   │   └── AddBakerySheet.swift     ← 빵집 추가 (PhotosPicker)
│   ├── Collection/
│   │   ├── CollectionView.swift     ← 빵 도감 (카테고리 필터)
│   │   └── AddBreadSheet.swift      ← 빵 추가 (평점, 사진)
│   ├── Map/
│   │   └── MapTabView.swift         ← MapKit 지도 + 마커
│   ├── Profile/
│   │   └── ProfileView.swift        ← 통계 + 업적 대시보드
│   └── Components/
│       ├── StampCard.swift          ← 빵집 스탬프 카드
│       ├── BreadCard.swift          ← 빵 카드
│       ├── BadgeView.swift          ← 업적 배지 + 가이드 시트
│       └── EmptyStateView.swift     ← 빈 상태 안내
├── Services/
│   ├── AchievementService.swift     ← 업적 조건 판정 로직
│   ├── LocationManager.swift        ← CLLocationManager 위치 권한 관리
│   ├── StatisticsService.swift      ← 통계 계산 (카테고리, 평점 등)
│   └── SampleDataService.swift      ← 첫 실행 더미 데이터 (서울 5곳)
└── Resources/
    ├── Assets.xcassets/             ← 커스텀 색상 (라이트/다크 대응)
    └── DesignSystem.swift           ← Color, Font, Spacing, Shadow 토큰
```

---

## 구현 포인트

### 1. SwiftData 관계 모델링

```swift
@Model
final class Bakery {
    @Relationship(deleteRule: .cascade, inverse: \Bread.bakery)
    var breads: [Bread] = []
}
```
- `cascade` 삭제 규칙으로 빵집 삭제 시 관련 빵 자동 삭제
- `inverse` 키패스로 양방향 관계 자동 관리

### 2. @Observable 기반 MVVM

```swift
@Observable
final class BakeryViewModel {
    var isLoading = false
    var errorMessage: String?

    func addBakery(name: String, ..., context: ModelContext) {
        let bakery = Bakery(name: name, ...)
        context.insert(bakery)
        try context.save()
    }
}
```
- iOS 17의 `@Observable` 매크로 사용 (ObservableObject 대신)
- View에서 `@State private var viewModel = BakeryViewModel()`으로 소유

### 3. 디자인 시스템 토큰화

```swift
extension Color {
    static let brandPrimary = Color("Primary")    // 시나몬 브라운
    static let brandSecondary = Color("Secondary") // 밀크티
    static let brandAccent = Color("Accent")       // 딸기잼
}

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    // ...
}
```
- 하드코딩 없이 모든 색상/폰트/간격/그림자를 토큰으로 관리
- Asset Catalog로 라이트/다크 모드 자동 대응

### 4. 업적 시스템

```mermaid
flowchart LR
    subgraph 조건타입["AchievementRequirement"]
        BC["bakeryCount(N)<br/>빵집 방문 수"]
        BRC["breadCount(N)<br/>빵 기록 수"]
        AC["allCategories<br/>전 카테고리 수집"]
        FS["fiveStarBreads(N)<br/>5점 빵 수"]
    end

    subgraph 업적["9종 업적"]
        A1["🏪 첫 발도장<br/>빵집 1곳"]
        A2["🗺️ 동네 탐험가<br/>빵집 5곳"]
        A3["🏆 빵집 마스터<br/>빵집 10곳"]
        A4["👑 빵집 정복자<br/>빵집 25곳"]
        A5["🍞 첫 빵 기록<br/>빵 1개"]
        A6["😋 빵순이<br/>빵 10개"]
        A7["🎪 빵 수집가<br/>빵 50개"]
        A8["📚 빵 박사<br/>전 카테고리"]
        A9["⭐ 미식가<br/>5점 빵 5개"]
    end

    BC --> A1 & A2 & A3 & A4
    BRC --> A5 & A6 & A7
    AC --> A8
    FS --> A9

    style 조건타입 fill:#E8940A,color:#fff
    style 업적 fill:#3B7DD8,color:#fff
```

### 5. MapKit 카메라 자동 조정
- 등록된 빵집 좌표를 기반으로 모든 마커가 화면에 보이도록 `MKCoordinateRegion` 자동 계산
- 빵집 1개일 때와 여러 개일 때 분기 처리
- 즐겨찾기 빵집: 빨간 마커 / 일반 빵집: 파란 마커

### 6. PhotosPicker 이미지 등록
- 빵집/빵 등록 시 선택적 사진 첨부
- 사진 미리보기 및 삭제 기능
- 사진 미등록 시 SF Symbol 기본 아이콘 표시

---

## 디자인 시스템

### 컬러 팔레트

```mermaid
block-beta
    columns 5
    P["Primary<br/>#8B5A2B<br/>시나몬 브라운"]:1
    S["Secondary<br/>#D4A574<br/>밀크티"]:1
    A["Accent<br/>#E85A4F<br/>딸기잼"]:1
    BG["Background<br/>#FDF8F3<br/>크림색"]:1
    SF["Surface<br/>#FFFFFF<br/>카드"]:1

    style P fill:#8B5A2B,color:#fff
    style S fill:#D4A574,color:#fff
    style A fill:#E85A4F,color:#fff
    style BG fill:#C9B99A,color:#333,stroke:#8B7355
    style SF fill:#B0A898,color:#333,stroke:#8B7355
```

| 토큰 | 라이트 | 다크 | 용도 |
|------|--------|------|------|
| Primary | `#8B5A2B` | `#C4956A` | 주요 액션 (시나몬 브라운) |
| Secondary | `#D4A574` | `#E8C9A8` | 보조 요소 (밀크티) |
| Accent | `#E85A4F` | `#FF7B6F` | 강조 포인트 (딸기잼) |
| Background | `#FDF8F3` | `#1C1816` | 메인 배경 (크림색) |
| Surface | `#FFFFFF` | `#2A2420` | 카드/시트 |

### 타이포그래피

시스템 폰트 기반 8단계 스케일 (LargeTitle 34pt ~ Caption 12pt)

### 간격 체계

6단계 스페이싱 토큰 (`xs` 4pt ~ `xxl` 32pt)

---

## 앱 실행 흐름

```mermaid
sequenceDiagram
    participant App as BreadStampApp
    participant MC as ModelContainer
    participant SDS as SampleDataService
    participant CV as ContentView
    participant User as 사용자

    App->>MC: ModelContainer 생성<br/>(Bakery, Bread 스키마)
    App->>SDS: insertSampleDataIfNeeded()
    SDS->>SDS: 데이터 존재 여부 확인
    alt 첫 실행
        SDS->>MC: 서울 5개 빵집 + 12개 빵 삽입
    else 이미 데이터 존재
        SDS-->>App: skip
    end
    App->>CV: ContentView 렌더링
    CV->>User: 4개 탭 표시

    Note over CV,User: 🏠 스탬프북 | 📖 도감 | 🗺️ 지도 | 👤 프로필
```

---

## 개발 환경

| 항목 | 버전 |
|------|------|
| Xcode | 16.0+ |
| iOS Deployment Target | 17.0 |
| Swift | 5.9 |
| 프로젝트 생성 | xcodegen |

---

## 빌드 및 실행

```bash
# 프로젝트 클론
git clone https://github.com/ParkSY0919/BreadStamp.git
cd BreadStamp

# Xcode에서 열기
open BreadStamp.xcodeproj

# Cmd + R 로 시뮬레이터 실행
# 첫 실행 시 서울 지역 5개 빵집 + 12개 빵 샘플 데이터가 자동 생성됩니다.
```

---

## Git 컨벤션

| 타입 | 설명 |
|------|------|
| `[Setting/#N]` | 프로젝트 설정 |
| `[Feature/#N]` | 기능 개발 |
| `[Fix/#N]` | 버그 수정 |
| `[Refactor/#N]` | 코드 리팩토링 |
| `[Docs/#N]` | 문서 작성 |

**브랜치 전략**: `main` ← `feature/#이슈번호`, `fix/#이슈번호`

---

## 향후 계획

- [x] 빵집 위치 검색 (MKLocalSearch 주소 자동완성)
- [x] 내 위치 표시 (CLLocationManager 연동)
- [ ] 공유 기능 (통계/배지 이미지 공유)
- [ ] 빵집/빵 검색
- [ ] 다크 모드 완전 대응
- [ ] 위젯 지원

---

## 라이선스

이 프로젝트는 개인 포트폴리오 목적으로 제작되었습니다.
