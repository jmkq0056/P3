// Hue Script Editor core functionality

// CodeMirror configuration
const editor = CodeMirror.fromTextArea(document.getElementById('scriptEditor'), {
    mode: "javascript",
    theme: "dracula",
    lineNumbers: true,
    indentUnit: 2,
    tabSize: 2,
    autoCloseBrackets: false,
    matchBrackets: false,
    lineWrapping: false,
    foldGutter: false,
    gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
    extraKeys: {
        "Ctrl-Space": "autocomplete",
        "Tab": function (cm) {
            if (cm.somethingSelected()) {
                cm.indentSelection("add");
            } else {
                cm.replaceSelection("  ", "end");
            }
        }
    },
});

// Default editor content
editor.setValue(`// Hue Script Editor
// Type your commands below or use the snippets on the right

// Quick Examples:
// lights on;          - Turn on all lights
// brightness 75;      - Set brightness to 75%
// lights color "red"; - Set color to red
// wait 2 sec;         - Wait for 2 seconds

`);

// Global state
let isDarkMode = true;
let isExecuting = false;
let statusIndicator = null;
let currentEditingScript = null; // Tracks current editing session

// Predefined script templates
const scriptTemplates = {
    'simple-cycle': `// Simple On/Off Cycle
// Basic light cycling with brightness variation

brightness 100;
lights on;

repeat 5 times {
  wait 3 sec;
  brightness 100;
  wait 1 sec;
  brightness 30;
  wait 1 sec;
}

lights off;
`,
    'party-mode': `// Party Mode Script
// Dynamic light show with rapid color changes

brightness 100;
lights on;

// Fast color cycling
repeat 30 seconds {
  lights color "red";
  wait 500 ms;
  lights color "blue";
  wait 500 ms;
  lights color "green";
  wait 500 ms;
  lights color "purple";
  wait 500 ms;
}

// Smooth transitions
transition "red" to "blue" over 3 seconds;
wait 1 sec;
transition "blue" to "green" over 3 seconds;
wait 1 sec;
transition "green" to "purple" over 3 seconds;
wait 1 sec;

// Strobe sequence
repeat 10 times {
  lights on;
  wait 200 ms;
  lights off;
  wait 200 ms;
}

// End state
lights on;
brightness 50;
lights color "warm";
`,
    'relax-mode': `// Relaxation Mode
// Calming atmosphere with gentle transitions

// Initial warm setting
brightness 60;
lights color "warm";
wait 3 sec;

// Breathing effect
repeat 5 times {
  brightness 70;
  wait 4 sec;
  brightness 40;
  wait 4 sec;
}

// Color progression
transition "warm" to "cool" over 10 seconds;
wait 5 sec;
transition "cool" to "#6495ED" over 10 seconds; // Cornflower Blue
wait 5 sec;
transition "#6495ED" to "#9370DB" over 10 seconds; // Medium Purple
wait 5 sec;

// Final state
transition "#9370DB" to "warm" over 10 seconds;
brightness 30;
`,
    'group-control': `// Group Control Example
// Multi-room lighting coordination

// Define light groups
define group livingRoom [1, 2, 3]; // Living room lights
define group kitchen [4, 5];       // Kitchen lights
define group bedroom [6, 7, 8];    // Bedroom lights

// Initialize each group
group livingRoom on;
group livingRoom color "warm";
group livingRoom brightness 80;

group kitchen on;
group kitchen color "cool";
group kitchen brightness 100;

group bedroom on;
group bedroom color "#6495ED"; // Cornflower Blue
group bedroom brightness 50;

wait 5 sec;

// Synchronized transitions
group livingRoom transition "warm" to "red" over 3 seconds;
group kitchen transition "cool" to "blue" over 3 seconds;
group bedroom transition "#6495ED" to "purple" over 3 seconds;

wait 5 sec;

// Wave effect across rooms
// Living room
group livingRoom brightness 100;
wait 500 ms;
group livingRoom brightness 30;

// Kitchen
wait 500 ms;
group kitchen brightness 100;
wait 500 ms;
group kitchen brightness 30;

// Bedroom
wait 500 ms;
group bedroom brightness 100;
wait 500 ms;
group bedroom brightness 30;

wait 3 sec;

// Sync all groups
group livingRoom brightness 100;
group kitchen brightness 100;
group bedroom brightness 100;
wait 2 sec;

// Sequential on/off pattern
repeat 3 times {
  group livingRoom off;
  wait 1 sec;
  group livingRoom on;
  group kitchen off;
  wait 1 sec;
  group kitchen on;
  group bedroom off;
  wait 1 sec;
  group bedroom on;
}

// Reset to comfortable state
group livingRoom color "warm";
`,
    'scenes-example': `// Scene Definition Example
// Define and use reusable lighting scenes

// Define Movie Mode scene
define scene movieMode {
  brightness 30;
  lights color "warm";
  light 1 brightness 20; // Accent light dimmer than others
  light 2 brightness 40; // Main light slightly brighter
}

// Define Evening Relax scene
define scene eveningRelax {
  brightness 60;
  lights color "#FF9966"; // Warm orange
  
  // Create a gentle breathing effect
  repeat 3 times {
    brightness 70;
    wait 4 sec;
    brightness 50;
    wait 4 sec;
  }
}

// Define Energize scene
define scene energize {
  brightness 100;
  lights color "cool";
  
  // Quick brightness pulses for energy
  repeat 5 times {
    brightness 100;
    wait 300 ms;
    brightness 80;
    wait 300 ms;
  }
}

// Main script - Activate each scene with transitions between them
scene movieMode;
wait 5 sec;

// Transition to evening relax
transition "warm" to "#FF9966" over 3 seconds;
brightness 60;
wait 1 sec;
scene eveningRelax;
wait 3 sec;

// Transition to energize
transition "#FF9966" to "cool" over 3 seconds;
wait 1 sec;
scene energize;
wait 3 sec;

// Return to movie mode to end
transition "cool" to "warm" over 3 seconds;
wait 1 sec;
scene movieMode;
`
};

// Autocomplete suggestions
const commands = [
    { text: "lights on;", displayText: "lights on - Turn on lights" },
    { text: "lights off;", displayText: "lights off - Turn off lights" },
    { text: "brightness ", displayText: "brightness [0-100] - Set brightness level" },
    { text: "lights color ", displayText: "lights color \"[color]\" - Set light color" },
    { text: "wait ", displayText: "wait [time] [unit] - Pause execution" },
    { text: "transition ", displayText: "transition \"[color1]\" to \"[color2]\" over [time] [unit]" },
    { text: "repeat ", displayText: "repeat [number] times { ... } - Loop commands" },
    { text: "repeat for ", displayText: "repeat for [number] [unit] { ... } - Time-based loop" },
    { text: "var ", displayText: "var [name] = \"[color]\"; - Define a color variable" },
    { text: "define scene ", displayText: "define scene [name] { ... } - Define a reusable scene" },
    { text: "scene ", displayText: "scene [name]; - Invoke a defined scene" }
];

const timeUnits = [
    { text: "sec", displayText: "sec - Seconds" },
    { text: "seconds", displayText: "seconds - Seconds" },
    { text: "min", displayText: "min - Minutes" },
    { text: "minutes", displayText: "minutes - Minutes" },
    { text: "ms", displayText: "ms - Milliseconds" },
    { text: "milliseconds", displayText: "milliseconds - Milliseconds" },
    { text: "hr", displayText: "hr - Hours" },
    { text: "hours", displayText: "hours - Hours" }
];

const colorNames = [
    { text: "\"red\"", displayText: "red - #FF0000" },
    { text: "\"green\"", displayText: "green - #00FF00" },
    { text: "\"blue\"", displayText: "blue - #0000FF" },
    { text: "\"yellow\"", displayText: "yellow - #FFFF00" },
    { text: "\"orange\"", displayText: "orange - #FFA500" },
    { text: "\"purple\"", displayText: "purple - #800080" },
    { text: "\"pink\"", displayText: "pink - #FFC0CB" },
    { text: "\"white\"", displayText: "white - #FFFFFF" },
    { text: "\"warm\"", displayText: "warm - #FF9900 (Warm white)" },
    { text: "\"cool\"", displayText: "cool - #F5F5DC (Cool white)" }
];

// Initialize application
$(document).ready(function () {
    // Ensure editing indicator is hidden on page load
    $('#editing-indicator').hide().removeClass('show');

    initStatusIndicator();
    addConsoleResizeButton();
    applyTheme(isDarkMode);
    setupAutoComplete();
    setupLanguageDocsModalFix();

    // Check if we're editing a script from the dashboard
    checkForEditingScript();

    // Add Ctrl+S save functionality
    $(document).on('keydown', function (e) {
        if ((e.ctrlKey || e.metaKey) && e.key === 's') {
            e.preventDefault();
            if (currentEditingScript) {
                // Show update script modal
                showUpdateScriptModal();
            } else {
                // Show save new script modal
                $('#saveScriptModal').modal('show');
            }
        }
    });

    // Theme toggle
    $('#themeSwitch').change(function () {
        isDarkMode = $(this).prop('checked');
        applyTheme(isDarkMode);
    });

    // Code insertion from examples
    $('.code-example .insert-btn').on('click', function (e) {
        e.stopPropagation();
        const code = $(this).closest('.code-example').data('code');
        insertCodeAtCursor(code);
    });

    // Color swatch selection
    $('.color-swatch').on('click', function () {
        const color = $(this).data('color');
        const colorCode = `lights color "${color}";`;
        insertCodeAtCursor(colorCode);
    });

    // Custom color picker
    $('#useColorBtn').on('click', function () {
        const colorValue = $('#colorPicker').val().toUpperCase();
        const colorCode = `lights color "${colorValue}";`;
        insertCodeAtCursor(colorCode);
    });

    // Script execution
    $('#runScriptBtn').on('click', function () {
        runScript();
    });

    // Light controls
    $('#turnOnLightsBtn').on('click', function () {
        turnOnLights();
    });

    $('#turnOffLightsBtn').on('click', function () {
        turnOffLights();
    });

    // Emergency stop
    $('#emergencyStopBtn').on('click', function () {
        emergencyStop();
    });

    // Console management
    $('#clearConsoleBtn').on('click', function () {
        $('#outputConsole').html('// Console cleared');
    });

    // Editor management
    $('#clearEditorBtn').on('click', function () {
        if (confirm('Are you sure you want to clear the editor? All unsaved changes will be lost.')) {
            editor.setValue('// Type your commands below\n\n');
            editor.focus();
        }
    });

    $('#formatCodeBtn').on('click', function () {
        formatCode();
    });

    // Top save button handler
    $('#topSaveBtn').on('click', function () {
        if (currentEditingScript) {
            showUpdateScriptModal();
        } else {
            $('#saveScriptModal').modal('show');
        }
    });

    $('#confirmSaveBtn').on('click', function () {
        const scriptName = $('#scriptName').val().trim();

        if (!scriptName) {
            showNotification('Please enter a script name', 'error');
            return;
        }

        const scriptContent = editor.getValue();
        if (!scriptContent.trim()) {
            showNotification('Cannot save empty script', 'error');
            return;
        }

        saveScript(scriptName, scriptContent, '');
        $('#saveScriptModal').modal('hide');
        $('#scriptName').val('');
        showNotification(`Script "${scriptName}" saved successfully!`, 'success');
    });

    $('#loadScriptBtn').on('click', function () {
        loadSavedScriptsList();
        $('#loadScriptModal').modal('show');
    });

    // Save (New) button handler - always saves as new script (using event delegation)
    $(document).on('click', '#saveScriptBtn', function (e) {
        e.preventDefault();
        e.stopPropagation();
        console.log('Save (New) button clicked!'); // Debug log
        $('#saveScriptModal').modal('show');
    });

    // Template loading handler
    $(document).on('click', '.load-template', function () {
        const templateName = $(this).data('template');
        console.log('Loading template:', templateName);

        if (scriptTemplates[templateName]) {
            if (editor.getValue().trim() !== '' &&
                !confirm('This will replace the current script content. Continue?')) {
                return;
            }
            editor.setValue(scriptTemplates[templateName]);
            editor.focus();
            showNotification(`Template "${templateName}" loaded!`, 'info');
        } else {
            console.error('Template not found:', templateName);
            alert(`Template "${templateName}" not found. Please check the console for details.`);
        }
    });

    checkConnectionStatus();

    // Editor keyboard shortcuts
    editor.setOption('extraKeys', {
        'Ctrl-Enter': function () { runScript(); },
        'Ctrl-L': function () { $('#loadScriptBtn').click(); return false; },
        'Ctrl-Space': function (cm) { cm.showHint({ hint: hueScriptHint }); },
        'Escape': function () { if (isExecuting) emergencyStop(); }
    });

    // Window resize handler
    $(window).resize(function () {
        editor.refresh();
    });

    // Auto-save timer
    setInterval(function () {
        if (editor.getValue().trim() !== '') {
            localStorage.setItem('autoSavedScript', editor.getValue());
            localStorage.setItem('autoSaveTime', new Date().toISOString());
        }
    }, 30000);

    checkForAutoSavedScript();

    // Interpreter state reset
    $('#resetStateBtn').on('click', function () {
        if (confirm('Are you sure you want to reset the interpreter state? This will clear all variables and scenes.')) {
            resetInterpreterState();
        }
    });

    // Initialize Bootstrap tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Documentation modal handler - removed duplicate (handled in setupLanguageDocsModalFix)

    $('#printDocsBtn').on('click', function () {
        window.print();
    });
});

// Create connection status indicator
function initStatusIndicator() {
    statusIndicator = $('<div id="statusIndicator" class="status-indicator"></div>');
    $('body').append(statusIndicator);
    updateConnectionStatus(false);
}

// Check Hue Bridge connection
function checkConnectionStatus() {
    $.ajax({
        url: '/api/scripts/test-connection',
        type: 'GET',
        success: function (response) {
            updateConnectionStatus(response.connected);
            if (response.connected) {
                $('#connectionStatus').html('<i class="fas fa-circle text-success me-2"></i>Connected').removeClass('text-danger').addClass('text-success');
                $('#bridgeIpAddress').text(response.bridgeIp || 'Unknown');
            } else {
                $('#connectionStatus').html('<i class="fas fa-circle text-danger me-2"></i>Disconnected').removeClass('text-success').addClass('text-danger');
                showNotification('Not connected to Hue Bridge. Check network settings.', 'warning');
            }
        },
        error: function () {
            updateConnectionStatus(false);
            $('#connectionStatus').html('<i class="fas fa-circle text-danger me-2"></i>Error').removeClass('text-success').addClass('text-danger');
        }
    });
}

// Update connection status display
function updateConnectionStatus(connected) {
    if (connected) {
        statusIndicator.removeClass('disconnected').addClass('connected');
        statusIndicator.attr('title', 'Connected to Hue Bridge');
    } else {
        statusIndicator.removeClass('connected').addClass('disconnected');
        statusIndicator.attr('title', 'Not connected to Hue Bridge');
    }
}

// Setup autocomplete system
function setupAutoComplete() {
    CodeMirror.registerHelper("hint", "hueScript", hueScriptHint);
}

// Context-aware autocomplete suggestions
function hueScriptHint(editor) {
    const cursor = editor.getCursor();
    const line = editor.getLine(cursor.line);
    const lineText = line.slice(0, cursor.ch);

    let result = [];
    const lastWord = /[a-zA-Z0-9_]+$/.exec(lineText);
    const lastWordText = lastWord ? lastWord[0].toLowerCase() : '';

    // Context-sensitive filtering
    if (lineText.includes('color')) {
        result = colorNames.filter(item =>
            !lastWordText || item.text.toLowerCase().includes(lastWordText));
    } else if (lineText.includes('wait') || lineText.includes('over') || lineText.includes('for')) {
        if (/\d+\s*$/.test(lineText)) {
            result = timeUnits.filter(item =>
                !lastWordText || item.text.toLowerCase().includes(lastWordText));
        }
    } else {
        result = commands.filter(item =>
            !lastWordText || item.text.toLowerCase().includes(lastWordText));
    }

    return {
        list: result,
        from: lastWord ? CodeMirror.Pos(cursor.line, lineText.length - lastWordText.length) : cursor,
        to: cursor
    };
}

// Console expand/collapse functionality
function addConsoleResizeButton() {
    const $consoleHeader = $('.console-card .card-header');
    const $resizeIcon = $('<i class="fas fa-expand console-resize-toggle" title="Expand Console"></i>');

    $consoleHeader.append($resizeIcon);

    $resizeIcon.on('click', function () {
        const $consoleCard = $('.console-card');
        $consoleCard.toggleClass('expanded');

        if ($consoleCard.hasClass('expanded')) {
            $(this).removeClass('fa-expand').addClass('fa-compress').attr('title', 'Collapse Console');
            $('body').css('overflow', 'hidden');
        } else {
            $(this).removeClass('fa-compress').addClass('fa-expand').attr('title', 'Expand Console');
            $('body').css('overflow', '');
        }

        setTimeout(() => editor.refresh(), 300);
    });

    // ESC key closes expanded console
    $(document).keydown(function (e) {
        if (e.key === "Escape" && $('.console-card').hasClass('expanded')) {
            $resizeIcon.click();
        }
    });
}

// Theme switching
function applyTheme(isDark) {
    const body = document.body;

    if (isDark) {
        body.classList.add('dark-mode');
        body.classList.remove('light-mode');
        editor.setOption('theme', 'dracula');
    } else {
        body.classList.remove('dark-mode');
        body.classList.add('light-mode');
        editor.setOption('theme', 'eclipse');
    }

    setTimeout(() => editor.refresh(), 100);
}

// Insert code at cursor with visual feedback
function insertCodeAtCursor(code) {
    const doc = editor.getDoc();
    const cursor = doc.getCursor();
    const line = doc.getLine(cursor.line);
    const needsNewline = line.trim() !== '';

    if (needsNewline) {
        if (cursor.ch === line.length) {
            code = '\n' + code;
        } else {
            code = code;
        }
    }

    doc.replaceRange(code, cursor);
    editor.focus();

    // Brief highlight animation
    const currentPos = editor.getCursor();
    const startPos = {
        line: currentPos.line - (code.split('\n').length - 1),
        ch: cursor.ch
    };

    const marker = editor.markText(startPos, currentPos, {
        className: 'inserted-code-highlight'
    });

    setTimeout(() => {
        marker.clear();
    }, 1000);
}

// Code formatting with indentation
function formatCode() {
    const content = editor.getValue();
    const lines = content.split('\n');
    let formattedLines = [];
    let indentLevel = 0;

    lines.forEach(line => {
        let trimmedLine = line.trim();

        if (trimmedLine.startsWith('}')) {
            indentLevel = Math.max(0, indentLevel - 1);
        }

        if (trimmedLine.length > 0) {
            formattedLines.push('  '.repeat(indentLevel) + trimmedLine);
        } else {
            formattedLines.push('');
        }

        if (trimmedLine.endsWith('{')) {
            indentLevel++;
        }
    });

    editor.setValue(formattedLines.join('\n'));
    showNotification('Code formatted', 'info');
}

// Script execution dispatcher
function runScript() {
    const scriptContent = editor.getValue().trim();
    if (!scriptContent) {
        $('#outputConsole').html('// Error: Script cannot be empty.');
        showNotification('Script cannot be empty', 'error');
        return;
    }

    if (typeof EventSource !== 'undefined') {
        runScriptRealTime(scriptContent);
    } else {
        runScriptTraditional(scriptContent);
    }
}

function runScriptRealTime(scriptContent) {
    // UI state updates
    isExecuting = true;
    $('#outputConsole').html('// Starting script execution...\n').addClass('streaming');
    $('#runScriptBtn')
        .prop('disabled', true)
        .html('<i class="fas fa-spinner fa-spin me-2"></i>Running...')
        .addClass('btn-running');

    // Visual execution indicator
    $('.navbar-status-light').addClass('active');

    // Live execution indicator
    const indicator = $('<div class="real-time-indicator">🔴 Live execution</div>');
    $('#outputConsole').before(indicator);

    // Start streaming execution
    $.ajax({
        url: '/api/scripts/execute-stream',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ scriptContent: scriptContent }),
        success: function (response) {
            if (response.success && response.connectionId) {
                // SSE connection for real-time logs
                const eventSource = new EventSource(`/api/scripts/logs?connectionId=${response.connectionId}`);

                eventSource.onopen = function () {
                    console.log('Connected to real-time log stream');
                    indicator.html('🟢 Connected - Live execution');
                };

                eventSource.addEventListener('connected', function (event) {
                    $('#outputConsole').html(event.data + '\n');
                });

                eventSource.addEventListener('log', function (event) {
                    try {
                        const data = JSON.parse(event.data);
                        const formattedMessage = formatConsoleOutput(data.message);

                        // Animated log entry
                        const logEntry = $('<span class="log-entry"></span>').html(formattedMessage + '\n');
                        $('#outputConsole').append(logEntry);

                        // Auto-scroll with animation
                        const console = document.getElementById('outputConsole');
                        $(console).animate({
                            scrollTop: console.scrollHeight
                        }, 200);

                    } catch (e) {
                        console.error('Error parsing log data:', e);
                    }
                });

                eventSource.addEventListener('complete', function (event) {
                    try {
                        const data = JSON.parse(event.data);
                        const formattedMessage = formatConsoleOutput(data.message);

                        // Final log entry
                        const logEntry = $('<span class="log-entry"></span>').html(formattedMessage + '\n');
                        $('#outputConsole').append(logEntry);

                        // Auto-scroll to bottom
                        const console = document.getElementById('outputConsole');
                        $(console).animate({
                            scrollTop: console.scrollHeight
                        }, 200);

                        // Reset UI state
                        isExecuting = false;
                        $('#runScriptBtn')
                            .prop('disabled', false)
                            .html('<i class="fas fa-play me-2"></i>Run Script')
                            .removeClass('btn-running');

                        $('#outputConsole').removeClass('streaming');
                        indicator.addClass('disconnected').html('✅ Execution completed');

                        // Cleanup indicator
                        setTimeout(() => indicator.fadeOut(500, () => indicator.remove()), 2000);

                        // Completion notification
                        if (data.message.includes('✅')) {
                            showNotification('Script executed successfully', 'success');
                        } else {
                            showNotification('Script executed with errors', 'warning');
                        }

                        // Remove status indicators
                        $('.navbar-status-light').removeClass('active');

                    } catch (e) {
                        console.error('Error parsing completion data:', e);
                    }

                    eventSource.close();
                });

                eventSource.onerror = function (event) {
                    console.error('SSE connection error:', event);
                    $('#outputConsole').append('// Connection error occurred\n').removeClass('streaming');

                    // Reset UI state
                    isExecuting = false;
                    $('#runScriptBtn')
                        .prop('disabled', false)
                        .html('<i class="fas fa-play me-2"></i>Run Script')
                        .removeClass('btn-running');

                    indicator.addClass('disconnected').html('❌ Connection lost');

                    // Cleanup indicator
                    setTimeout(() => indicator.fadeOut(500, () => indicator.remove()), 3000);

                    showNotification('Connection error during script execution', 'error');
                    $('.navbar-status-light').removeClass('active');
                    eventSource.close();
                };

            } else {
                // Handle connection failure
                $('#outputConsole').html('// Error: ' + (response.error || 'Failed to start script execution')).removeClass('streaming');

                // Reset UI state
                isExecuting = false;
                $('#runScriptBtn')
                    .prop('disabled', false)
                    .html('<i class="fas fa-play me-2"></i>Run Script')
                    .removeClass('btn-running');

                indicator.addClass('disconnected').html('❌ Failed to start');

                // Cleanup indicator
                setTimeout(() => indicator.fadeOut(500, () => indicator.remove()), 3000);

                showNotification('Failed to start script execution', 'error');
                $('.navbar-status-light').removeClass('active');
            }
        },
        error: function (xhr) {
            $('#outputConsole').html('// Error: ' + (xhr.responseText || 'Failed to start script execution')).removeClass('streaming');

            // Reset UI state
            isExecuting = false;
            $('#runScriptBtn')
                .prop('disabled', false)
                .html('<i class="fas fa-play me-2"></i>Run Script')
                .removeClass('btn-running');

            indicator.addClass('disconnected').html('❌ Connection failed');

            // Cleanup indicator
            setTimeout(() => indicator.fadeOut(500, () => indicator.remove()), 3000);

            showNotification('Failed to start script execution', 'error');
            $('.navbar-status-light').removeClass('active');
        }
    });
}

function runScriptTraditional(scriptContent) {
    // UI state updates
    isExecuting = true;
    $('#outputConsole').html('// Running script...');
    $('#runScriptBtn')
        .prop('disabled', true)
        .html('<i class="fas fa-spinner fa-spin me-2"></i>Running...')
        .addClass('btn-running');

    // Visual execution indicator
    $('.navbar-status-light').addClass('active');

    $.ajax({
        url: '/api/scripts/execute',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ scriptContent: scriptContent }),
        success: function (response) {
            // Format and display output
            let outputHtml = formatConsoleOutput(response.log || '// Script executed successfully.');
            $('#outputConsole').html(outputHtml);

            // Auto-scroll to bottom
            const console = document.getElementById('outputConsole');
            console.scrollTop = console.scrollHeight;

            // Reset UI state
            isExecuting = false;
            $('#runScriptBtn')
                .prop('disabled', false)
                .html('<i class="fas fa-play me-2"></i>Run Script')
                .removeClass('btn-running');

            // Execution result notification
            if (response.success) {
                showNotification('Script executed successfully', 'success');
            } else {
                showNotification('Script executed with errors', 'warning');
            }
        },
        error: function (xhr) {
            $('#outputConsole').html('// Error: ' + (xhr.responseText || 'Failed to execute script.'));

            // Reset UI state
            isExecuting = false;
            $('#runScriptBtn')
                .prop('disabled', false)
                .html('<i class="fas fa-play me-2"></i>Run Script')
                .removeClass('btn-running');

            showNotification('Failed to execute script', 'error');
        },
        complete: function () {
            // Remove status indicators
            $('.navbar-status-light').removeClass('active');
        }
    });
}

// Console output formatting with syntax highlighting
function formatConsoleOutput(output) {
    if (!output) return '';

    // Apply color coding to emojis and keywords
    return output
        .replace(/✅/g, '<span class="console-success">✅</span>')
        .replace(/❌/g, '<span class="console-error">❌</span>')
        .replace(/⛔/g, '<span class="console-warning">⛔</span>')
        .replace(/⏱️/g, '<span class="console-info">⏱️</span>')
        .replace(/💡/g, '<span class="console-light">💡</span>')
        .replace(/🔄/g, '<span class="console-repeat">🔄</span>')
        .replace(/🎨/g, '<span class="console-color">🎨</span>')
        .replace(/🌈/g, '<span class="console-transition">🌈</span>')
        .replace(/📋/g, '<span class="console-scene">📋</span>')
        .replace(/(\b(error|failed|failure)\b)/gi, '<span class="console-error">$1</span>')
        .replace(/(\b(success|successful|completed)\b)/gi, '<span class="console-success">$1</span>')
        .replace(/(\b(warning|cancelled|stopped)\b)/gi, '<span class="console-warning">$1</span>')
        .replace(/(\/\/.*)/g, '<span class="console-comment">$1</span>');
}

// Quick light control - turn on
function turnOnLights() {
    // Loading state
    $('#turnOnLightsBtn').prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i>');

    $.ajax({
        url: '/api/test/lights-on',
        type: 'GET',
        success: function (response) {
            if (response.success) {
                $('#outputConsole').append('\n// 💡 All lights turned ON');
                showNotification('Lights turned ON', 'success');

                // Visual feedback
                $('.navbar-status-light').addClass('active');
                setTimeout(() => {
                    $('.navbar-status-light').removeClass('active');
                }, 2000);
            } else {
                $('#outputConsole').append('\n// ❌ Failed to turn lights on: ' + response.error);
                showNotification('Failed to turn lights ON', 'error');
            }
        },
        error: function () {
            $('#outputConsole').append('\n// ❌ Error communicating with bridge');
            showNotification('Error communicating with bridge', 'error');
        },
        complete: function () {
            // Reset button
            $('#turnOnLightsBtn').prop('disabled', false).html('<i class="fas fa-lightbulb me-2"></i>Lights ON');
        }
    });
}

// Quick light control - turn off
function turnOffLights() {
    // Loading state
    $('#turnOffLightsBtn').prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i>');

    $.ajax({
        url: '/api/test/lights-off',
        type: 'GET',
        success: function (response) {
            if (response.success) {
                $('#outputConsole').append('\n// 💡 All lights turned OFF');
                showNotification('Lights turned OFF', 'success');

                // Visual feedback
                $('.navbar-status-light').removeClass('active');
            } else {
                $('#outputConsole').append('\n// ❌ Failed to turn lights off: ' + response.error);
                showNotification('Failed to turn lights OFF', 'error');
            }
        },
        error: function () {
            $('#outputConsole').append('\n// ❌ Error communicating with bridge');
            showNotification('Error communicating with bridge', 'error');
        },
        complete: function () {
            // Reset button
            $('#turnOffLightsBtn').prop('disabled', false).html('<i class="fas fa-lightbulb-slash me-2"></i>Lights OFF');
        }
    });
}

// Emergency stop with retry logic
function emergencyStop() {
    // Audio alert if available
    try {
        const audio = new Audio('/sounds/alert.mp3');
        audio.play();
    } catch (e) {
        // Audio not available
    }

    // Visual emergency state
    $('body').addClass('emergency');
    setTimeout(() => $('body').removeClass('emergency'), 1000);

    // Block UI during stop
    showLoadingOverlay('EMERGENCY STOP IN PROGRESS');

    // Retry mechanism for reliability
    let stopAttempts = 0;
    const maxAttempts = 3;

    function attemptStop() {
        stopAttempts++;

        $.ajax({
            url: '/api/test/emergency-stop',
            type: 'GET',
            timeout: 3000,
            success: function (response) {
                if (response.success) {
                    $('#outputConsole').html('// ⚠️ EMERGENCY STOP ACTIVATED\n// ' + response.message);
                    showNotification('Emergency Stop Activated - Lights Preserved', 'warning');

                    // Reset execution state
                    isExecuting = false;
                    $('#runScriptBtn')
                        .prop('disabled', false)
                        .html('<i class="fas fa-play me-2"></i>Run Script')
                        .removeClass('btn-running');

                    hideLoadingOverlay();
                } else {
                    $('#outputConsole').html('// ❌ Emergency stop failed: ' + response.error);
                    showNotification('Emergency Stop Failed', 'danger');

                    // Retry if attempts remaining
                    if (stopAttempts < maxAttempts) {
                        setTimeout(attemptStop, 500);
                    } else {
                        hideLoadingOverlay();
                    }
                }
            },
            error: function (xhr) {
                $('#outputConsole').html('// ❌ Error activating emergency stop: ' + xhr.responseText);
                showNotification('Emergency Stop Failed', 'danger');

                // Retry if attempts remaining
                if (stopAttempts < maxAttempts) {
                    setTimeout(attemptStop, 500);
                } else {
                    hideLoadingOverlay();
                }
            }
        });
    }

    // Start retry sequence
    attemptStop();
}

// Loading overlay display
function showLoadingOverlay(message) {
    // Create overlay if needed
    if ($('#loadingOverlay').length === 0) {
        $('body').append(`
            <div id="loadingOverlay">
                <div class="overlay-content">
                    <div class="spinner-border text-light" role="status"></div>
                    <div id="overlayMessage">${message}</div>
                </div>
            </div>
        `);
    } else {
        $('#overlayMessage').text(message);
        $('#loadingOverlay').show();
    }
}

// Hide loading overlay
function hideLoadingOverlay() {
    $('#loadingOverlay').hide();
}

// Persist script to localStorage
function saveScript(name, content, description = '') {
    const savedScripts = getSavedScripts();
    const timestamp = new Date().toISOString();

    savedScripts[name] = {
        content: content,
        description: description,
        timestamp: timestamp
    };

    localStorage.setItem('hueScripts', JSON.stringify(savedScripts));
}

// Retrieve saved scripts
function getSavedScripts() {
    const scripts = localStorage.getItem('hueScripts');
    return scripts ? JSON.parse(scripts) : {};
}

// Populate saved scripts modal
function loadSavedScriptsList() {
    const savedScripts = getSavedScripts();
    const scriptsList = $('#savedScriptsList');
    scriptsList.empty();

    const scriptNames = Object.keys(savedScripts);

    if (scriptNames.length === 0) {
        $('#noSavedScripts').show();
        return;
    }

    $('#noSavedScripts').hide();

    scriptNames.forEach(name => {
        const script = savedScripts[name];
        const date = new Date(script.timestamp).toLocaleString();

        const scriptItem = $(`
            <a href="#" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center" data-script-name="${name}">
                <div>
                    <div class="fw-bold">${name}</div>
                    <small class="text-muted">Saved on ${date}</small>
                </div>
                <div class="script-actions">
                    <button class="btn btn-sm btn-outline-secondary edit-script me-1" title="Rename"
                            data-script-name="${name}">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-danger delete-script" title="Delete"
                            data-script-name="${name}">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </a>
        `);

        scriptsList.append(scriptItem);
    });

    // Script selection event
    $('.list-group-item').on('click', function (e) {
        if (!$(e.target).closest('.script-actions').length) {
            const scriptName = $(this).data('script-name');
            loadScript(scriptName);
            $('#loadScriptModal').modal('hide');
        }
    });

    // Script deletion event
    $('.delete-script').on('click', function (e) {
        e.preventDefault();
        e.stopPropagation();

        const scriptName = $(this).data('script-name');
        if (confirm(`Are you sure you want to delete "${scriptName}"?`)) {
            deleteScript(scriptName);
            $(this).closest('.list-group-item').remove();

            if ($('#savedScriptsList .list-group-item').length === 0) {
                $('#noSavedScripts').show();
            }
        }
    });

    // Script rename event
    $('.edit-script').on('click', function (e) {
        e.preventDefault();
        e.stopPropagation();

        const scriptName = $(this).data('script-name');
        const newName = prompt('Enter new name for this script:', scriptName);

        if (newName && newName.trim() !== '' && newName !== scriptName) {
            renameScript(scriptName, newName);
            loadSavedScriptsList();
        }
    });
}

// Rename a saved script
function renameScript(oldName, newName) {
    const savedScripts = getSavedScripts();
    if (savedScripts[oldName]) {
        savedScripts[newName] = savedScripts[oldName];
        delete savedScripts[oldName];
        localStorage.setItem('hueScripts', JSON.stringify(savedScripts));
        showNotification(`Script renamed to "${newName}"`, 'info');
    }
}

// Load a script into the editor
function loadScript(name) {
    const savedScripts = getSavedScripts();
    if (savedScripts[name]) {
        editor.setValue(savedScripts[name].content);
        editor.focus();
        showNotification(`Script "${name}" loaded!`, 'success');
    }
}

// Delete a saved script
function deleteScript(name) {
    const savedScripts = getSavedScripts();
    if (savedScripts[name]) {
        delete savedScripts[name];
        localStorage.setItem('hueScripts', JSON.stringify(savedScripts));
        showNotification(`Script "${name}" deleted`, 'info');
    }
}

// Check for auto-saved script
function checkForAutoSavedScript() {
    const autoSavedScript = localStorage.getItem('autoSavedScript');
    const autoSaveTime = localStorage.getItem('autoSaveTime');

    if (autoSavedScript && autoSaveTime) {
        const timeAgo = timeSince(new Date(autoSaveTime));

        // Only show recovery option if editor is empty
        if (editor.getValue().trim() === '') {
            const restoreBtn = $(`
                <div class="auto-save-recovery">
                    <div class="alert alert-info alert-dismissible fade show" role="alert">
                        <i class="fas fa-history me-2"></i>
                        Found an auto-saved script from ${timeAgo} ago.
                        <button type="button" id="restoreAutoSaveBtn" class="btn btn-sm btn-primary ms-3">Restore</button>
                        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                    </div>
                </div>
            `);

            $('.editor-card').prepend(restoreBtn);

            $('#restoreAutoSaveBtn').on('click', function () {
                editor.setValue(autoSavedScript);
                $('.auto-save-recovery').alert('close');
            });
        }
    }
}

// Format time since a given date
function timeSince(date) {
    const seconds = Math.floor((new Date() - date) / 1000);
    let interval = Math.floor(seconds / 31536000);

    if (interval > 1) return interval + " years";
    interval = Math.floor(seconds / 2592000);
    if (interval > 1) return interval + " months";
    interval = Math.floor(seconds / 86400);
    if (interval > 1) return interval + " days";
    interval = Math.floor(seconds / 3600);
    if (interval > 1) return interval + " hours";
    interval = Math.floor(seconds / 60);
    if (interval > 1) return interval + " minutes";
    return Math.floor(seconds) + " seconds";
}

// Show a notification with enhanced styling and animations
function showNotification(message, type = 'info') {
    // Map type to icon and color
    const icons = {
        'success': 'fas fa-check-circle',
        'error': 'fas fa-exclamation-circle',
        'warning': 'fas fa-exclamation-triangle',
        'info': 'fas fa-info-circle'
    };

    // Remove any existing notifications
    $('.notification').remove();

    // Create notification element with icon
    const notification = $(`
        <div class="notification notification-${type} animate__animated animate__fadeInRight">
            <div class="notification-icon">
                <i class="${icons[type] || 'fas fa-info-circle'}"></i>
            </div>
            <div class="notification-content">
                ${message}
            </div>
            <button type="button" class="notification-close">
                <i class="fas fa-times"></i>
            </button>
        </div>
    `);

    // Add to body
    $('body').append(notification);

    // Handle close button
    notification.find('.notification-close').on('click', function () {
        notification.addClass('animate__fadeOutRight');
        setTimeout(() => {
            notification.remove();
        }, 500);
    });

    // Auto-dismiss after 4 seconds
    setTimeout(() => {
        notification.addClass('animate__fadeOutRight');
        setTimeout(() => {
            notification.remove();
        }, 500);
    }, 4000);
}

// Reset interpreter state
function resetInterpreterState() {
    $('#outputConsole').html('// Resetting interpreter state...');

    $.ajax({
        url: '/api/scripts/reset-state',
        type: 'POST',
        success: function (response) {
            if (response.success) {
                $('#outputConsole').html('// ✅ Interpreter state reset successfully.\n// All variables and scenes have been cleared.');
                showNotification('Interpreter state reset successfully', 'success');
            } else {
                $('#outputConsole').html('// ❌ Failed to reset interpreter state: ' + response.message);
                showNotification('Failed to reset state', 'error');
            }
        },
        error: function (xhr) {
            $('#outputConsole').html('// ❌ Error resetting interpreter state: ' + xhr.responseText);
            showNotification('Failed to reset state', 'error');
        }
    });
}

// Add an animated help tour
function startHelperTour() {
    const tour = new Shepherd.Tour({
        useModalOverlay: true,
        defaultStepOptions: {
            cancelIcon: {
                enabled: true
            },
            classes: 'shepherd-theme-custom',
            scrollTo: true
        }
    });

    tour.addStep({
        id: 'welcome',
        title: 'Welcome to the Hue Script Editor',
        text: 'This tour will help you get familiar with the editor features',
        buttons: [
            {
                action: tour.cancel,
                classes: 'shepherd-button-secondary',
                text: 'Skip Tour'
            },
            {
                action: tour.next,
                classes: 'shepherd-button-primary',
                text: 'Next'
            }
        ]
    });

    tour.addStep({
        id: 'editor',
        title: 'Script Editor',
        text: 'This is where you write your Hue Script. Type commands or use the snippets on the right.',
        attachTo: {
            element: '.editor-card',
            on: 'bottom'
        },
        buttons: [
            {
                action: tour.back,
                classes: 'shepherd-button-secondary',
                text: 'Back'
            },
            {
                action: tour.next,
                classes: 'shepherd-button-primary',
                text: 'Next'
            }
        ]
    });

    tour.addStep({
        id: 'commands',
        title: 'Command Library',
        text: 'Browse available commands, code examples, and templates to get started quickly.',
        attachTo: {
            element: '#commandsAccordion',
            on: 'left'
        },
        buttons: [
            {
                action: tour.back,
                classes: 'shepherd-button-secondary',
                text: 'Back'
            },
            {
                action: tour.next,
                classes: 'shepherd-button-primary',
                text: 'Next'
            }
        ]
    });

    tour.addStep({
        id: 'run-script',
        title: 'Run Your Script',
        text: 'Click this button to execute your script and control your Hue lights.',
        attachTo: {
            element: '#runScriptBtn',
            on: 'top'
        },
        buttons: [
            {
                action: tour.back,
                classes: 'shepherd-button-secondary',
                text: 'Back'
            },
            {
                action: tour.next,
                classes: 'shepherd-button-primary',
                text: 'Next'
            }
        ]
    });

    tour.addStep({
        id: 'lights-controls',
        title: 'Quick Light Controls',
        text: 'Quickly turn all lights on or off with these buttons.',
        attachTo: {
            element: '.light-control-buttons',
            on: 'bottom'
        },
        buttons: [
            {
                action: tour.back,
                classes: 'shepherd-button-secondary',
                text: 'Back'
            },
            {
                action: tour.next,
                classes: 'shepherd-button-primary',
                text: 'Next'
            }
        ]
    });

    tour.addStep({
        id: 'emergency',
        title: 'Emergency Stop',
        text: 'If something goes wrong, hit the Emergency Stop button to reset all lights.',
        attachTo: {
            element: '#emergencyStopBtn',
            on: 'bottom'
        },
        buttons: [
            {
                action: tour.back,
                classes: 'shepherd-button-secondary',
                text: 'Back'
            },
            {
                action: tour.next,
                classes: 'shepherd-button-primary',
                text: 'Next'
            }
        ]
    });

    tour.addStep({
        id: 'console',
        title: 'Output Console',
        text: 'See the results of your script execution here.',
        attachTo: {
            element: '.console-card',
            on: 'top'
        },
        buttons: [
            {
                action: tour.back,
                classes: 'shepherd-button-secondary',
                text: 'Back'
            },
            {
                action: tour.complete,
                classes: 'shepherd-button-primary',
                text: 'Finish Tour'
            }
        ]
    });

    tour.start();
}

// Start tour when help button is clicked
$(document).on('click', '#helpTourBtn', function () {
    startHelperTour();
});

// Helpful keyboard shortcuts visualization
function showKeyboardShortcuts() {
    const shortcutsModal = new bootstrap.Modal(document.getElementById('keyboardShortcutsModal'));
    shortcutsModal.show();
}

// Enable keyboard shortcuts display when ? key is pressed
$(document).keydown(function (e) {
    if (e.key === '?' && !$(e.target).is('input, textarea')) {
        showKeyboardShortcuts();
    }
});

// Add analytics tracking for UI actions
function trackEvent(category, action, label) {
    // This is a placeholder for analytics tracking
    // In a production environment, this could send data to an analytics service
    console.log(`Analytics Event: ${category} - ${action} - ${label}`);
}

// Share script via URL
function shareScript() {
    const scriptContent = editor.getValue();
    if (!scriptContent.trim()) {
        showNotification('Cannot share empty script', 'error');
        return;
    }

    // Encode script content to base64 for URL sharing
    const encodedScript = btoa(encodeURIComponent(scriptContent));
    const shareUrl = `${window.location.origin}${window.location.pathname}?script=${encodedScript}`;

    // Create a temporary input to copy the URL
    const tempInput = document.createElement('input');
    document.body.appendChild(tempInput);
    tempInput.value = shareUrl;
    tempInput.select();
    document.execCommand('copy');
    document.body.removeChild(tempInput);

    showNotification('Share URL copied to clipboard!', 'success');
}

// Check for shared script in URL
function checkForSharedScript() {
    const urlParams = new URLSearchParams(window.location.search);
    const sharedScript = urlParams.get('script');

    if (sharedScript) {
        try {
            const decodedScript = decodeURIComponent(atob(sharedScript));

            // Only offer to load if the editor is empty or there's existing content
            if (editor.getValue().trim() !== '') {
                if (confirm('Load the shared script? This will replace your current code.')) {
                    editor.setValue(decodedScript);
                    showNotification('Shared script loaded!', 'info');
                }
            } else {
                editor.setValue(decodedScript);
                showNotification('Shared script loaded!', 'info');
            }

            // Remove the parameter from URL without refreshing
            window.history.replaceState({}, document.title, window.location.pathname);
        } catch (e) {
            console.error('Error loading shared script:', e);
        }
    }
}

// Initialize pulse animation for status indicator
function initPulseAnimation() {
    // Check if the element exists before trying to use it
    const pulseContainer = document.getElementById('pulseContainer');
    if (!pulseContainer) {
        console.warn('Pulse container not found, skipping animation');
        return;
    }

    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    let radius = 0;
    let alpha = 1;
    let expanding = true;

    canvas.width = 30;
    canvas.height = 30;
    pulseContainer.appendChild(canvas);

    function drawPulse() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Outer pulse ring
        ctx.beginPath();
        ctx.arc(15, 15, radius, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(46, 204, 113, ${alpha})`;
        ctx.fill();

        // Inner status dot
        ctx.beginPath();
        ctx.arc(15, 15, 5, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(46, 204, 113, 1)';
        ctx.fill();

        if (expanding) {
            radius += 0.3;
            alpha -= 0.02;

            if (radius >= 15) {
                expanding = false;
                radius = 15;
                alpha = 0;
            }
        } else {
            radius = 5;
            alpha = 1;
            expanding = true;
        }

        requestAnimationFrame(drawPulse);
    }

    drawPulse();
}

// Additional component initialization
$(document).ready(function () {
    // Load shared scripts from URL
    checkForSharedScript();

    // Start pulse animation
    initPulseAnimation();

    // Share functionality
    $('#shareScriptBtn').on('click', function () {
        shareScript();
    });

    // Shortcuts modal
    $('#keyboardShortcutsBtn').on('click', function () {
        showKeyboardShortcuts();
    });

    // Editor change tracking
    editor.on('change', function () {
        trackEvent('Editor', 'CodeChanged', 'Script modified');
    });

    // Button interaction tracking
    $('button').on('click', function () {
        const buttonId = this.id || this.className || 'unnamed-button';
        // Only track named buttons to reduce console spam
        if (this.id) {
            trackEvent('UI', 'ButtonClick', buttonId);
        }
    });
});

// Language docs modal styling fixes
function setupLanguageDocsModalFix() {
    const modalElement = document.getElementById('languageDocsModal');

    // Modal show event handler
    $('#languageDocsModal').on('shown.bs.modal', function () {
        fixLanguageDocsTableStyling();
    });

    // Modal hide event handler to fix focus issues
    $('#languageDocsModal').on('hidden.bs.modal', function () {
        // Remove aria-hidden to prevent focus conflicts
        $(this).removeAttr('aria-hidden');

        // Clean up any Bootstrap modal instances
        try {
            const modalInstance = bootstrap.Modal.getInstance(modalElement);
            if (modalInstance) {
                modalInstance.dispose();
            }
        } catch (e) {
            console.warn('Error disposing modal instance:', e);
        }

        // Ensure focus returns to the button that opened the modal
        setTimeout(() => {
            $('#languageDocsBtn').focus();
        }, 150);
    });

    // Documentation button handler
    $('#languageDocsBtn').on('click', function (e) {
        e.preventDefault();
        e.stopPropagation();

        // Check if modal is already open to prevent conflicts
        if ($(modalElement).hasClass('show')) {
            console.warn('Modal is already open, ignoring click');
            return;
        }

        // Dispose of any existing modal instance
        try {
            const existingInstance = bootstrap.Modal.getInstance(modalElement);
            if (existingInstance) {
                existingInstance.dispose();
            }
        } catch (e) {
            console.warn('Error disposing existing modal instance:', e);
        }

        // Remove any existing aria-hidden attribute before showing
        $(modalElement).removeAttr('aria-hidden');

        var languageDocsModal = new bootstrap.Modal(modalElement, {
            backdrop: true,
            keyboard: true,
            focus: true
        });

        languageDocsModal.show();

        // Apply styling fixes
        setTimeout(fixLanguageDocsTableStyling, 100);
    });
}

// Dark mode table styling
function fixLanguageDocsTableStyling() {
    if (isDarkMode) {
        // Apply dark theme to documentation tables
        $('#languageDocsModal table').addClass('table table-striped table-hover');
        $('#languageDocsModal th').addClass('bg-primary text-white');
        $('#languageDocsModal td').addClass('align-middle');
    }
}

// Script editing session management
function checkForEditingScript() {
    // Hide indicator initially
    $('#editing-indicator').hide().removeClass('show');

    const editingData = localStorage.getItem('editingScript');
    if (editingData) {
        try {
            const scriptData = JSON.parse(editingData);
            if (scriptData.isEditing) {
                // Load script content
                editor.setValue(scriptData.content);

                // Store editing session
                currentEditingScript = {
                    name: scriptData.name,
                    originalContent: scriptData.content,
                    description: scriptData.description
                };

                // Update page title
                document.title = `P4 Hue Script Editor - Editing: ${scriptData.name}`;

                // Show editing indicator
                $('#editing-script-name').text(scriptData.name);
                $('#editing-indicator').addClass('show').fadeIn(300);

                // Auto-hide indicator
                setTimeout(() => {
                    $('#editing-indicator').fadeOut(500);
                }, 4000);

                // Configure save button for editing
                $('#topSaveBtn')
                    .show()
                    .addClass('editing')
                    .attr('title', 'Save Changes (Ctrl+S)')
                    .find('span').text('Save Changes');

                // Update card save button
                $('#saveScriptBtn').addClass('btn-warning').removeClass('btn-outline-primary');

                // Clear session data
                localStorage.removeItem('editingScript');
            }
        } catch (e) {
            console.error('Error parsing editing script data:', e);
            localStorage.removeItem('editingScript');
        }
    } else {
        // Hide save button when not editing
        $('#topSaveBtn').hide();
    }
}

// Show update script modal for existing scripts
function showUpdateScriptModal() {
    if (!currentEditingScript) {
        $('#saveScriptModal').modal('show');
        return;
    }

    // Create update modal
    const updateModal = $(`
        <div class="modal fade" id="updateScriptModal" tabindex="-1" aria-labelledby="updateScriptModalLabel" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="updateScriptModalLabel">
                            <i class="fas fa-save me-2"></i>Update Script
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label for="updateScriptName" class="form-label">Script Name</label>
                            <input type="text" class="form-control" id="updateScriptName" value="${currentEditingScript.name}">
                        </div>
                        <div class="mb-3">
                            <label for="updateScriptDescription" class="form-label">Description (Optional)</label>
                            <textarea class="form-control" id="updateScriptDescription" rows="2" placeholder="Brief description of what this script does">${currentEditingScript.description}</textarea>
                        </div>
                        <div class="form-check mb-3">
                            <input class="form-check-input" type="checkbox" id="saveAsNewScript">
                            <label class="form-check-label" for="saveAsNewScript">
                                Save as new script (keep original)
                            </label>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="button" class="btn btn-primary" id="confirmUpdateBtn">
                            <i class="fas fa-save me-2"></i>Save Changes
                        </button>
                    </div>
                </div>
            </div>
        </div>
    `);

    // Remove existing modal
    $('#updateScriptModal').remove();

    // Show modal
    $('body').append(updateModal);
    $('#updateScriptModal').modal('show');

    // Save button handler
    $('#confirmUpdateBtn').on('click', function () {
        const newName = $('#updateScriptName').val().trim();
        const newDescription = $('#updateScriptDescription').val().trim();
        const saveAsNew = $('#saveAsNewScript').prop('checked');
        const currentContent = editor.getValue();

        if (!newName) {
            showNotification('Please enter a script name', 'error');
            return;
        }

        if (saveAsNew) {
            // Create new script
            saveScript(newName, currentContent, newDescription);
            showNotification(`Script saved as "${newName}"`, 'success');
        } else {
            // Update existing
            updateExistingScript(currentEditingScript.name, newName, currentContent, newDescription);
            showNotification(`Script "${newName}" updated successfully`, 'success');

            // Update session info
            currentEditingScript.name = newName;
            currentEditingScript.description = newDescription;
            currentEditingScript.originalContent = currentContent;

            // Update page title
            document.title = `P4 Hue Script Editor - Editing: ${newName}`;

            // Update indicator
            $('#editing-script-name').text(newName);

            // Maintain save button state
            $('#topSaveBtn')
                .show()
                .addClass('editing')
                .attr('title', 'Save Changes (Ctrl+S)')
                .find('span').text('Save Changes');
        }

        $('#updateScriptModal').modal('hide');
    });

    // Modal cleanup
    $('#updateScriptModal').on('hidden.bs.modal', function () {
        $(this).remove();
    });
}

// Update existing script data
function updateExistingScript(oldName, newName, content, description = '') {
    const savedScripts = getSavedScripts();

    // Remove old entry if renamed
    if (oldName !== newName && savedScripts[oldName]) {
        delete savedScripts[oldName];
    }

    // Save updated data
    savedScripts[newName] = {
        content: content,
        description: description,
        timestamp: new Date().toISOString()
    };

    localStorage.setItem('hueScripts', JSON.stringify(savedScripts));
}