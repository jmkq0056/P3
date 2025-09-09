# FOCUZ Health Tracking App

FOCUZ is a complete health tracking application with voice commands and AI-powered food analysis capabilities.

## Voice + AI Features Setup

### 1. Create API Keys

#### OpenAI API Key
1. Go to [OpenAI API](https://platform.openai.com/)
2. Create an account or log in
3. Navigate to API Keys section
4. Generate a new API key
5. Copy the key to your `.env` file (see below)

#### Wit.ai API Key
1. Go to [Wit.ai](https://wit.ai)
2. Create an account or log in with Facebook
3. Create a new app
4. Configure intents and entities for:
   - `log_water` (with amount in ml/l/oz)
   - `log_weight` (with weight in kg/lbs)
   - `log_sleep` (with duration and quality)
   - `log_training` (with type and duration)
   - `log_meal` (with name and calories)
5. Copy the Server Access Token to your `.env` file

### 2. Set Up Environment Variables
Create a `.env` file in the root of your project with the following:

```
# OpenAI API Key - Required for meal image analysis
OPENAI_API_KEY=your_openai_api_key_here

# Wit.ai API Key - Required for intent detection
WIT_AI_API_KEY=your_wit_ai_api_key_here
```

### 3. Voice Recognition Model Setup (Vosk)
1. Download a small model from [Vosk Models](https://alphacephei.com/vosk/models)
2. Extract and place the model files into `assets/vosk_model/` directory
3. The model should contain files like `am`, `conf`, `graph.fst`, etc.

### 4. Prepare Animation Assets
1. Download the following Lottie animations:
   - [Voice Animation](https://lottiefiles.com/animations/voice-recognition-NBQGjiGCkp) → Save as `assets/lottie/voice_animation.json`
   - [Loading Animation](https://lottiefiles.com/animations/loading-IeqDrxk1HS) → Save as `assets/lottie/loading_animation.json`

### 5. Install Dependencies
Run the following command to install all dependencies:

```bash
flutter pub get
```

## Usage

### Voice Commands
Use the microphone button to activate voice commands like:
- "Add 500 ml water"
- "Log my weight at 78.3"
- "Slept for 6 hours"
- "Add 20 minutes of running"
- "Log meal pasta with 650 calories"

### AI Food Analysis
1. Go to the Meals tab
2. Use the camera or gallery button to take/select a photo of food
3. The AI will analyze the image and estimate:
   - Food name
   - Calories
   - Protein, carbs, and fat content
4. Review and add to your meal log

## Development Notes

### Required Permissions
- Camera (for food photos)
- Microphone (for voice commands)
- Internet (for API calls)

### Data Privacy
- All voice processing happens locally with Vosk
- Food images are sent to OpenAI's servers for analysis
- No data is permanently stored outside your device

## Troubleshooting

If you encounter issues with voice or AI features:

1. Check internet connection
2. Verify API keys in .env file
3. Ensure the Vosk model is correctly placed
4. Check microphone/camera permissions
5. Restart the app

For more help, contact support@focuz-app.com
# FOCUZ
# FOCUZ
