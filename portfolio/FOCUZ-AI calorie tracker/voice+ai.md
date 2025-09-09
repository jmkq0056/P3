# Voice Automation + OpenAI Image-to-Meal Integration (FOCUZ App)

## Overview

This document outlines the implementation strategy for **voice automation** and **AI-powered food image analysis** in the FOCUZ health tracking app. The system uses a **free online AI service for intent detection** and **OpenAI GPT-4 Turbo Vision API** for estimating calories and nutritional values from food images.

---

## 1. Voice Command Automation (Free, Online Intent Detection)

### Tools:

* **Vosk** – Offline Speech-to-Text Engine (Free, on-device)
* **Wit.ai** – Free online AI platform for intent detection (by Meta)

### Architecture:

```plaintext
User Speaks → Vosk (STT) → Text → Wit.ai (Intent) → Dart Function Trigger
```

### Wit.ai Features:

* Free forever (with Meta account)
* Supports natural English input
* Hosted in the cloud (no server required)
* Provides parsed intents and extracted entities

### Sample Commands:

* “Add 500 ml water”
* “Log my weight at 78.3”
* “Slept for 6 hours”
* “Add 2 cans of Pepsi Max”

### Sample Wit.ai Response:

```json
{
  "intent": {
    "name": "log_water"
  },
  "entities": {
    "amount": 500
  }
}
```

### Dart Handling Example:

```dart
if (intent == 'log_water') {
  final amount = entities['amount'];
  logWater(amount);
}
```

### Setup Steps:

1. Create app in [wit.ai](https://wit.ai)
2. Add training samples with intents like `log_water`, `log_weight`, etc.
3. Integrate HTTP POST in Flutter to send user text and receive structured intent

---

## 2. Image-to-Meal Conversion (OpenAI Vision)

### Tool:

* **GPT-4 Turbo with Vision (OpenAI API)**

### Purpose:

* Upload a photo of a meal
* AI recognizes food items and estimates:

  * Total calories (kcal)
  * Macronutrients (protein, fat, carbohydrates in grams)
  * Meal name (if identifiable)

### API Input:

```json
{
  "image": "<base64-encoded image>",
  "prompt": "Identify the food and return JSON with name, estimated kcal, protein (g), fat (g), carbs (g)."
}
```

### Expected Output:

```json
{
  "food": "Grilled chicken with brown rice and broccoli",
  "kcal": 460,
  "protein_g": 38,
  "fat_g": 12,
  "carbs_g": 42
}
```

### Estimated Cost:

* GPT-4 Turbo Vision API: \$0.01–\$0.02 per image (as of 2024)

### Integration Strategy:

* Take photo via camera or gallery
* Encode image to base64
* Send to OpenAI with minimal prompt
* Extract response
* Auto-fill new meal log with estimated data

### Flutter Hook:

```dart
final response = await openAiClient.analyzeImage(base64Image);
logMeal(response.food, response.kcal, response.protein, response.fat, response.carbs);
```

---

## Workflow Summary

### Voice Commands:

* STT with Vosk
* Online NLP with Wit.ai
* Trigger Flutter logic by intent name

### Meal Photo to Nutrition:

* Use GPT-4 Turbo API
* Return structured nutrition data
* Auto-fill meal tracker

---

## Future Enhancements

* Add fallback to OpenFoodFacts if GPT image fails
* Context memory for smart updates (e.g. "change last weight")
* On-device fallback intent parser (Snips NLU or similar)

---

## End of Voice + AI Integration Plan
