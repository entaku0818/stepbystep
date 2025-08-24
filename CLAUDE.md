# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

StepByStep (ステップバイステップ) is an iOS task management app that enforces single-task focus by breaking tasks into 5 actionable steps using AI.

## Build Commands

```bash
# 利用可能なシミュレーターを確認
xcrun simctl list devices available | grep -E "iPhone|iPad"

# Build the project (正しいプロジェクト名とスキーム名を使用)
xcodebuild -project ios/stepbystep/TaskSteps.xcodeproj -scheme stepbystep -configuration Debug build

# Run on simulator (自動検出したiPhoneシミュレーターを使用)
SIMULATOR=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed -E 's/.*\(([A-Z0-9-]+)\).*/\1/')
xcodebuild -project ios/stepbystep/TaskSteps.xcodeproj -scheme stepbystep -destination "platform=iOS Simulator,id=$SIMULATOR" run

# Run tests
xcodebuild test -project ios/stepbystep/TaskSteps.xcodeproj -scheme stepbystep -destination "platform=iOS Simulator,id=$SIMULATOR"

# Clean build
xcodebuild clean -project ios/stepbystep/TaskSteps.xcodeproj -scheme stepbystep
```

## Important: Build Verification

**コード変更後は必ずビルドとテストを実行してください:**

1. **ビルド確認**: 大きな変更を行った後は必ず `xcodebuild` でビルドエラーがないことを確認
2. **テスト実行**: 機能追加・修正後はテストを実行して既存機能が壊れていないことを確認
3. **型チェック**: Swift の型チェックエラーが発生した場合は、複雑な式を小さなコンポーネントに分割
4. **シミュレーター**: 実行前に `xcrun simctl list devices available` で利用可能なシミュレーターを確認

```bash
# 簡易ビルドチェック（エラーがないか確認、シミュレーター自動検出）
cd /Users/entaku/repository/stepbystep/ios/stepbystep
SIMULATOR=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed -E 's/.*\(([A-Z0-9-]+)\).*/\1/')
xcodebuild -project TaskSteps.xcodeproj -scheme stepbystep -configuration Debug -sdk iphonesimulator -destination "id=$SIMULATOR" build
```

## Architecture

### Technology Stack
- **Language**: Swift 5.0
- **Framework**: SwiftUI
- **Minimum iOS**: 18.4
- **Bundle ID**: com.entaku.stepbystep
- **Development Team**: 4YZQY4C47E

### Core Design Principles
1. **Single Task Focus**: Only one active task at a time
2. **Forced Sequential Execution**: Cannot skip steps or work on multiple tasks
3. **AI-Powered Task Splitting**: Automatically breaks tasks into 5 concrete steps
4. **Minimal UI**: Show only the current step to maintain focus

### Planned Architecture
- **Task Input Screen**: Simple text input with AI integration
- **Step Execution Screen**: Shows only current step with completion checkbox
- **Progress Screen**: Visual progress bar and completion animation
- **Data Storage**: Local iOS storage (CoreData or UserDefaults)
- **AI Integration**: OpenAI API for task decomposition

### Key Features to Implement
1. Task registration (one at a time)
2. AI task splitting into 5 steps
3. Step-by-step execution view
4. Progress tracking
5. Time tracking per step
6. Completion animations
7. Daily AI usage limits (3 splits/day for free version)

## Important Notes

- The project currently has basic iOS scaffolding but no implemented features
- Comprehensive Japanese documentation exists in `/docs` folder outlining full concept
- Originally planned for React Native but implemented in SwiftUI
- Focus on extreme simplicity - avoid feature creep
- Target users: People with ADHD or focus challenges

## Memories
- to memorize