# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

StepByStep (ステップバイステップ) is an iOS task management app that enforces single-task focus by breaking tasks into 5 actionable steps using AI.

## Build Commands

```bash
# Build the project
xcodebuild -project ios/stepbystep/stepbystep.xcodeproj -scheme stepbystep -configuration Debug build

# Run on simulator
xcodebuild -project ios/stepbystep/stepbystep.xcodeproj -scheme stepbystep -destination 'platform=iOS Simulator,name=iPhone 15' run

# Run tests
xcodebuild test -project ios/stepbystep/stepbystep.xcodeproj -scheme stepbystep -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean build
xcodebuild clean -project ios/stepbystep/stepbystep.xcodeproj -scheme stepbystep
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