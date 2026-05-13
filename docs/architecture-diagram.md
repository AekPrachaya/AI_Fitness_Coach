# ภาพที่ 3.1 ภาพรวมสถาปัตยกรรมระบบ FormAI (Layer Diagram)

```mermaid
graph TB
    subgraph L1["🖥️  Presentation Layer — UI Screens & Widgets"]
        direction LR
        S1[SplashScreen\nWelcomeScreen]
        S2[OnboardingScreens\nPersonalInfo / Goal / Level / Equipment]
        S3[AuthScreens\nLogin / Register]
        S4[HomeScreen\nDashboard]
        S5[WorkoutSessionScreen\nLive Camera + Overlay]
        S6[WorkoutSummaryScreen\nStats & Score]
        W1[Shared Widgets\nAppButton / AppCard / AppTextField / AppBadge]
    end

    subgraph L2["⚙️  State Management Layer — Riverpod"]
        direction LR
        P1[routerProvider\nGoRouter]
        P2[userProfileProvider\nHive ↔ UserProfile]
        P3[workoutSessionNotifierProvider\nWorkoutSessionNotifier\nState Machine: idle→tracking→finished]
        P4[poseDetectionServiceProvider\nPoseDetectionService]
    end

    subgraph L3["🧠  Business Logic Layer — Services & Analyzers"]
        direction TB
        subgraph Analyzers["Exercise Analyzers"]
            A1[SquatAnalyzer\nknee angle\ndown 100° / up 160°]
            A2[PushUpAnalyzer\nelbow angle\ndown 90° / up 160°]
            A3[DeadliftAnalyzer\nhip angle\ndown 80° / up 160°]
            A4[BicepCurlAnalyzer\nelbow angle\ndown 50° / up 150°]
        end
        SVC1[ExerciseAnalyzer\nfactory dispatch by exerciseId]
        SVC2[RepCounter\nState Machine:\nwaitingDown → down → rep++]
        SVC3[AngleCalculator\natan2 vector angle\nfor 3 landmarks]
        SVC4[FormResult\nscore + feedback\nThai language]
    end

    subgraph L4["💾  Data Layer — Models & Local Storage"]
        direction LR
        M1[UserProfile\nname / age / gender\nheight / weight / goal / level / equipment]
        M2[Workout\nid / name / muscleGroup\ndifficulty / instructions / commonMistakes]
        M3[SessionData\nworkoutId / durationSeconds\ntotalReps / avgFormScore / estimatedCalories]
        M4[WorkoutSessionState\ncurrentSet / repCount\njointAngle / formResult / poses]
        DB1[(Hive Box\nboxUserProfile)]
        DB2[(Hive Box\nboxSessionHistory)]
        DB3[(Hive Box\nboxProgressData)]
        JSON1[workouts.json\nExercise metadata]
    end

    subgraph L5["📱  Platform / Device Layer"]
        direction LR
        HW1[Camera Plugin\ncamera: ^0.10.0\nCameraImage stream]
        HW2[Google ML Kit\ngoogle_mlkit_pose_detection\n33 PoseLandmarks per frame]
        HW3[Permission Handler\ncamera permission\nruntime request]
        HW4[Path Provider\nHive storage path\nfile system]
    end

    %% Connections between layers
    L1 -->|"user actions\nGoRouter navigation"| L2
    L2 -->|"process frame\nstartSession / endSession"| L3
    L2 <-->|"read / write\nprofile & history"| L4
    L3 -->|"FormResult\nrep count\njoint angle"| L2
    L3 -->|"PoseLandmark data"| L4
    L4 <-->|"persist / load\nHive boxes"| L5
    L5 -->|"CameraImage\nframes"| L2
    HW1 -->|"raw frames\nYUV / BGRA8888"| HW2
    HW2 -->|"List<Pose>\nlandmarks + likelihood"| P4

    %% Styling
    classDef layer1 fill:#1a237e,stroke:#3949ab,color:#fff
    classDef layer2 fill:#1b5e20,stroke:#388e3c,color:#fff
    classDef layer3 fill:#4a148c,stroke:#7b1fa2,color:#fff
    classDef layer4 fill:#bf360c,stroke:#e64a19,color:#fff
    classDef layer5 fill:#263238,stroke:#546e7a,color:#fff
    classDef db fill:#e65100,stroke:#bf360c,color:#fff

    class S1,S2,S3,S4,S5,S6,W1 layer1
    class P1,P2,P3,P4 layer2
    class A1,A2,A3,A4,SVC1,SVC2,SVC3,SVC4 layer3
    class M1,M2,M3,M4,JSON1 layer4
    class DB1,DB2,DB3 db
    class HW1,HW2,HW3,HW4 layer5
```

---

## คำอธิบายแต่ละ Layer

| Layer | ชื่อ | เทคโนโลยี | หน้าที่ |
|-------|------|-----------|---------|
| **L1** | Presentation | Flutter Widgets, Material 3 | แสดงผล UI, รับ input จากผู้ใช้ |
| **L2** | State Management | Riverpod, GoRouter | จัดการ state และ navigation |
| **L3** | Business Logic | Dart classes | วิเคราะห์ท่าออกกำลังกาย, นับ rep, คำนวณมุม |
| **L4** | Data | Hive, JSON | เก็บข้อมูลผู้ใช้และประวัติการออกกำลังกาย |
| **L5** | Platform/Device | ML Kit, Camera Plugin | ประมวลผล pose detection จาก camera |

---

## Data Flow: การประมวลผล 1 frame

```
Camera Hardware
    │  CameraImage (YUV/BGRA8888)
    ▼
PoseDetectionService
    │  InputImage → ML Kit
    │  List<Pose> (33 landmarks × x,y,z,likelihood)
    ▼
WorkoutSessionNotifier.processFrame()
    │
    ├─► AngleCalculator.calculateAngle(hip, knee, ankle)
    │       └─► jointAngle: double
    │
    ├─► ExerciseAnalyzer.analyze(pose, angle)
    │       └─► FormResult(score, feedback)
    │
    └─► RepCounter.update(angle)
            └─► bool repCompleted
                    │
                    ▼
            WorkoutSessionState (updated)
                    │
                    ▼
            WorkoutSessionScreen re-renders
```
