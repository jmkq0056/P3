# HueScript Architecture & Flow

This document explains how HueScript works from a simple text script all the way to changing physical Philips Hue lights. 

## 🔄 The Complete Flow

```
HueScript Text → Lexer → Parser → AST → Interpreter → LightService → HueBridgeService → Hue Bridge → Physical Lights
```

## 📝 Example Script Journey

Let's follow this simple script:
```huescript
lights color "#FF0000";
light 1 brightness 75;
wait 2 seconds;
lights off;
```

## 🏗️ Architecture Overview

### 1. **Lexer Phase** - Breaking Down Text
**File:** `main/java/com/soft/p4/hueScriptLanguage/lexer/Lexer.java`
- **Role:** Converts raw script text into tokens (keywords, numbers, strings)
- **Input:** `"lights color \"#FF0000\";"`
- **Output:** `[LIGHTS, COLOR, STRING("#FF0000"), SEMICOLON]`
- **Token Types:** Defined in `lexer/TokenType.java` (LIGHTS, COLOR, BRIGHTNESS, etc.)

### 2. **Parser Phase** - Creating Structure  
**File:** `main/java/com/soft/p4/hueScriptLanguage/parser/HueScriptParser.java`
- **Role:** Converts tokens into an Abstract Syntax Tree (AST)
- **Strategy Pattern:** Uses different parsers for different commands
- **Key Strategy Files:**
  - `parser/strategy/all/LightsCommandParserStrategy.java` - Handles "lights" commands
  - `parser/strategy/single/LightCommandParserStrategy.java` - Handles "light ID" commands  
  - `parser/strategy/all/BrightnessCommandParserStrategy.java` - Handles brightness
  - `parser/strategy/all/WaitCommandParserStrategy.java` - Handles delays

### 3. **AST Nodes** - Structured Commands
**Base:** `main/java/com/soft/p4/hueScriptLanguage/ast/`
- **ScriptNode.java** - Root of the entire script tree
- **Command.java** - Base interface for all commands

**Individual Commands:** `ast/command/all/`
- **LightCommand.java** - Turn lights on/off 
- **ColorCommand.java** - Change light colors
- **BrightnessCommand.java** - Adjust brightness levels
- **WaitCommand.java** - Pause execution
- **TransitionCommand.java** - Smooth color transitions  
- **RepeatCommand.java** - Loop commands
- **SceneCommand.java** - Grouped command sequences
- **VariableInvocationCommand.java** - Use stored variables

**Group Commands:** `ast/command/group/`
- **GroupDefineCommand.java** - Create light groups
- **GroupLightCommand.java** - Control group power
- **GroupColorCommand.java** - Set group colors
- **GroupBrightnessCommand.java** - Set group brightness
- **GroupTransitionCommand.java** - Group color transitions

### 4. **Interpreter Phase** - Executing Commands
**File:** `main/java/com/soft/p4/hueScriptLanguage/interpreter/HueScriptInterpreter.java`
- **Role:** Visits each AST node and executes the corresponding action
- **Pattern:** Implements Visitor pattern to traverse the AST
- **State Management:** Tracks variables, scenes, groups between executions  
- **Execution Flow:**
  1. Receives AST from parser
  2. Visits each command node
  3. Translates commands to LightService calls
  4. Manages timing (waits, transitions)
  5. Provides execution feedback

### 5. **Service Layer** - Light Control Abstraction
**File:** `main/java/com/soft/p4/service/LightService.java`
- **Role:** High-level API for light operations
- **Key Methods:**
  - `setLightsState(boolean)` - All lights on/off
  - `setLightState(String lightId, boolean)` - Single light on/off
  - `setColor(String hexColor)` - All lights color
  - `setLightColor(String lightId, String hexColor)` - Single light color
  - `setBrightness(int)` - All lights brightness 
  - `transitionColor(from, to, duration)` - Smooth color changes

### 6. **Bridge Communication** - Hardware Interface
**File:** `main/java/com/soft/p4/service/HueBridgeService.java`
- **Role:** Direct communication with Philips Hue Bridge via REST API
- **Responsibilities:**
  - Converts colors from hex to Hue's XY color space
  - Manages bridge IP and API key configuration
  - Handles HTTP requests to bridge endpoints
  - Error handling and connection testing
- **Key Endpoints:**
  - `/groups/0/action` - Control all lights
  - `/lights/{id}/state` - Control individual lights
  - Bridge uses JSON payloads: `{"on": true, "bri": 254, "xy": [0.3, 0.3]}`

### 7. **Web Interface** - User Interaction
**File:** `main/java/com/soft/p4/controller/ScriptController.java`
- **Role:** REST API endpoints for script execution
- **Key Endpoints:**
  - `POST /api/scripts/execute` - Run script synchronously
  - `POST /api/scripts/execute-stream` - Run with real-time logs
  - `GET /api/scripts/logs` - Stream execution progress
- **Features:** Error handling, connection testing, state management

## 🔍 Detailed Example Flow

### Script: `lights color "#FF0000";`

1. **Lexer Input:** `"lights color \"#FF0000\";"`
2. **Lexer Output:** `[LIGHTS, COLOR, STRING("#FF0000"), SEMICOLON]`
3. **Parser:** `LightsCommandParserStrategy` creates `ColorCommand("#FF0000")`
4. **Interpreter:** Visits `ColorCommand`, calls `lightService.setColor("#FF0000")`
5. **LightService:** Calls `hueBridgeService.setAllLightsColor("#FF0000")`
6. **HueBridgeService:** 
   - Converts `#FF0000` to XY coordinates `[0.701, 0.299]`
   - Sends HTTP PUT to `http://bridge-ip/api/key/groups/0/action`
   - JSON body: `{"on": true, "xy": [0.701, 0.299]}`
7. **Hue Bridge:** Receives JSON, forwards to all connected lights
8. **Physical Lights:** Change to red color

## 🎯 Design Patterns in Detail

### 1. **Strategy Pattern** – Used in the Parser
**What it does:**
Each command type (e.g. `lights`, `light 1`, `wait`, `repeat`) has its own parser strategy class.

**Why:**
Makes the parser modular — easy to add new commands without changing core logic.

**Example:**
- `LightsCommandParserStrategy.java` parses `lights color "red";`
- `WaitCommandParserStrategy.java` parses `wait 2 seconds;`
- `RepeatCommandParserStrategy.java` parses `repeat 3 times { ... }`

**Benefit:**
Cleaner code, open for extension, easy to maintain.

**Key Files:**
- `parser/strategy/CommandParserStrategy.java` (interface)
- `parser/strategy/all/LightsCommandParserStrategy.java`
- `parser/strategy/single/LightCommandParserStrategy.java`
- `parser/strategy/group/GroupCommandParserStrategy.java`

### 2. **Visitor Pattern** – Used in the Interpreter
**What it does:**
Interpreter walks the AST and visits each command node to execute actions.

**Why:**
Separates execution logic from the AST structure.

**Example:**
- Visiting `ColorCommand` → calls `lightService.setColor()`
- Visiting `WaitCommand` → delays script execution
- Visiting `RepeatCommand` → loops through child commands

**Benefit:**
Keeps logic decoupled from structure. Makes adding new command types easier.

**Key Files:**
- `ast/NodeVisitor.java` (interface)
- `interpreter/HueScriptInterpreter.java` (implements visitor)
- All command classes in `ast/command/` implement `accept(NodeVisitor)`

### 3. **Command Pattern** – Used for Each Script Action
**What it does:**
Each line in the script is turned into a command object (e.g., `ColorCommand`, `WaitCommand`, `RepeatCommand`).

**Why:**
Encapsulates script actions as standalone objects.

**Example:**
- A `BrightnessCommand` object holds data like target light and brightness value
- A `TransitionCommand` stores from/to colors and duration
- Commands can be stored in variables, scenes, and groups

**Benefit:**
Flexible execution, testable commands, reusable in scenes and groups.

**Key Files:**
- `ast/command/Command.java` (base interface)
- `ast/command/all/ColorCommand.java`
- `ast/command/all/BrightnessCommand.java`
- `ast/command/group/GroupColorCommand.java`

### 4. **Service Layer Pattern** – Used for Hardware Abstraction
**What it does:**
Splits backend into logic (`LightService`) and hardware (`HueBridgeService`).

**Why:**
Keeps business logic separate from low-level REST calls.

**Example:**
- `LightService.setColor()` → handles validation and calls bridge
- `HueBridgeService.setAllLightsColor()` → sends HTTP requests
- Bridge service converts hex colors to Hue's XY color space

**Benefit:**
Easier to test, maintain, and extend (e.g., swap Philips Hue with another system).

**Key Files:**
- `service/LightService.java` (high-level operations)
- `service/HueBridgeService.java` (hardware communication)

## 🧩 File Organization

```
src/main/java/com/soft/p4/
├── hueScriptLanguage/           # Core language implementation
│   ├── lexer/                   # Text → Tokens
│   │   ├── Lexer.java          
│   │   ├── Token.java
│   │   └── TokenType.java
│   ├── parser/                  # Tokens → AST
│   │   ├── HueScriptParser.java
│   │   ├── ParserContext.java
│   │   └── strategy/            # Command-specific parsers
│   ├── ast/                     # AST node definitions  
│   │   ├── Node.java
│   │   ├── ScriptNode.java
│   │   └── command/             # Command implementations
│   ├── interpreter/             # AST → Actions
│   │   └── HueScriptInterpreter.java
│   └── exception/               # Error handling
├── service/                     # Hardware abstraction
│   ├── LightService.java        # High-level light control
│   └── HueBridgeService.java    # Low-level bridge communication
└── controller/                  # Web API
    └── ScriptController.java    # REST endpoints
```

## 🎨 Supported Language Features

### Basic Commands
- `lights on/off` - Control all lights
- `light 1 on/off` - Control specific light
- `lights color "#FF0000"` - Set color (hex or names like "red")
- `lights brightness 75` - Set brightness (0-100)

### Advanced Features  
- `wait 2 seconds` - Pause execution
- `repeat 3 times { ... }` - Loop commands
- `transition "#FF0000" to "#00FF00" for 5 seconds` - Smooth color changes
- `var myColor = "#FF0000"` - Store values for reuse
- `define myScene { ... }` - Create reusable command sequences
- `group livingRoom = "1,2,3"` - Create light groups

### Time Units
- Milliseconds: `ms`, `millisecond`, `milliseconds`
- Seconds: `sec`, `second`, `seconds`  
- Minutes: `min`, `minute`, `minutes`
- Hours: `hr`, `hour`, `hours`

This architecture ensures clean separation of concerns, making the system maintainable and extensible while providing a smooth path from simple script text to physical light changes. 