# 🧮 Simple Calculator App

A modern, fully-featured calculator app built with **Flutter**.  
Supports both **basic arithmetic** and **scientific operations**, along with helpful usability features like theme toggling, calculation history, memory functions, haptic/audio feedback, and undo/redo support.

---

## 🚀 Features

### ✅ Core Functionality
- Basic arithmetic: `+`, `-`, `×`, `÷`
- Scientific functions: `sin`, `cos`, `tan`, `log`, `ln`, `√x`, `x²`, `x!`
- Expression parser with support for parentheses and decimals
- Accurate expression evaluation with error handling

### 🧠 Memory Buttons
- `MC`: Clear memory
- `MR`: Recall memory value
- `M+`: Add current result to memory
- `M-`: Subtract current result from memory

### 💾 History Panel
- Saves up to 20 previous calculations
- Tap to re-insert a previous expression
- Slide-up popup with Clear option

### 🌓 Theme + UI
- Toggle between **light** and **dark** modes
- Responsive design for **mobile** and **web**
- Long press on result to **copy** to clipboard
- Undo / Redo expression changes
- Live preview of result before evaluation
- Smooth slide animation when switching between basic and scientific modes

### 🔉 Feedback
- Button click **sound**
- Optional **haptic feedback**
- Animated button press effect

---

## 🛠 How to Run on Android Emulator

### ✅ Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Android Studio with emulator configured **OR** VS Code with AVD setup
- Android SDK (usually included with Android Studio)

---

### 📦 Step-by-Step

```bash
# 1. Clone the project
git clone https://github.com/your-username/simple-calculator.git
cd simple-calculator

# 2. Get dependencies
flutter pub get

# 3. Launch Android emulator (if not already running)
flutter emulators --launch <emulator_id>

# 4. Run the app
flutter run
```

NOTE: README.md written by ChatGPT 4o.
