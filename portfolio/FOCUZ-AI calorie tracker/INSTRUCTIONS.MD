# Claude Sonnet 3.7 Instructions — FOCUZ Health Tracker App

## Objective

Code the entire **UI/UX** layer of the FOCUZ Health Tracker App using **Flutter for iOS**, optimized for a **single user**, with **Font Awesome icons**, **Lottie animations**, and local storage using Hive or Isar.

Do not include backend logic, just structure, UI/UX, transitions, and animation placeholders. Avoid unnecessary boilerplate or redundant widgets.

---

## Folder Structure (Minimalist)

```plaintext
lib/
├── main.dart
├── app.dart                     # App initialization and theme
├── core/
│   ├── constants.dart           # Colors, dimensions, text styles
│   └── assets.dart              # Font Awesome + Lottie paths
├── widgets/                     # Shared animated components
├── features/
│   ├── splash/
│   │   └── splash_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── training/
│   │   ├── training_screen.dart
│   │   └── training_form.dart
│   ├── meals/
│   │   ├── meals_screen.dart
│   │   └── meal_form.dart
│   ├── water_can/
│   │   └── water_can_screen.dart
│   ├── sleep/
│   │   └── sleep_screen.dart
│   ├── weight/
│   │   └── weight_screen.dart
│   ├── steps/
│   │   └── steps_screen.dart
│   └── settings/
│       └── settings_screen.dart
```

---

## Core UI Requirements

### Splash Screen

* Use `assets/logo/logo.png`
* Text: `FOCUZ` (centered, bold)
* Optional background Lottie (subtle particles)
* Transition to dashboard with `Navigator.pushReplacement`

### Navigation

* Custom animated **BottomNavigationBar**
* Font Awesome icons for 5 tabs: Dashboard, Training, Meals, Metrics, Settings

### Global Theme

* Dark theme by default
* Toggle between light/dark (animated)
* Font: System or bundled Google Font

---

## Page-by-Page UI Components

### Dashboard

* Animated cards for:

  * Steps (animated ring)
  * Calories (animated pie)
  * Water (wave progress)
  * Sleep (hours)
  * Weight (latest + trend arrow)
* Use `AnimatedContainer`, `Hero`, or `AnimatedSwitcher`

### Training

* List of sessions: title, kcal, date, video icon (Font Awesome)
* Add/Edit form:

  * Text input, dropdown, attach video button
  * Lottie animation by training type

### Meals

* Tabs: Today, Add Meal, Custom Meals
* Manual input form: name, kcal, portion
* API Search (search button only — no logic)
* Animated calorie ring progress

### Water & Cans

* Buttons: +250ml, +500ml, +1L (water)
* Add can (dropdown with Font Awesome drink icons)
* Animated wave meter or fill bar

### Sleep

* Log sleep duration (picker)
* Quality: 1–5 star selector
* History chart placeholder

### Weight

* Input current weight (slider)
* Line chart with milestone animation placeholder

### Steps

* Read from Apple Health (logic excluded)
* Animated circular progress
* Bar chart: 7-day steps

### Settings

* Theme toggle (animated preview)
* Language selector (Danish/English)
* Halal filter (switch)
* Reset app (confirm with Lottie)
* Trigger to preload assets (Font Awesome, Lottie)

---

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
  font_awesome_flutter:
  lottie:
  hive:
  path_provider:
  flutter_svg:
  animations:
  provider:
```

---

## Assets (Placeholders)

* `assets/logo/logo.png`
* `assets/icons/*.svg`
* `assets/lottie/*.json`

---

## Development Notes

* Use mock/dummy data where needed
* Separate logic from UI — only placeholders and visual structure
* No backend, no auth, no networking
* Write all screens with `StatelessWidget` or minimal `StatefulWidget`
* Keep code modular and reusable

---

## Deliverables from Claude

1. All Flutter files for UI described above
2. Preconfigured splash screen with navigation
3. Animated bottom navigation and tab views
4. Clean, documented, build-ready layout (no logic needed)

---

## End
