/**
 * Hue Dashboard - Interactive lighting control interface
 * Core dashboard functionality and light management
 */

// Dashboard initialization
$(document).ready(function () {
    // Theme preference detection
    const prefersDarkMode = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    const savedTheme = localStorage.getItem('dashboardTheme');

    if (savedTheme) {
        setTheme(savedTheme === 'dark');
    } else {
        setTheme(prefersDarkMode);
    }

    // User interaction tracking to prevent UI override during active use
    window.userInteractionState = {
        isInteractingWithColor: false,
        isInteractingWithBrightness: false,
        lastInteractionTime: 0,
        interactionCooldown: 5000 // 5 seconds after interaction before allowing updates
    };

    // CodeMirror setup
    window.scriptEditor = CodeMirror.fromTextArea(document.getElementById('script-editor'), {
        mode: "javascript",
        theme: isDarkMode() ? "dracula" : "default",
        lineNumbers: true,
        lineWrapping: true,
        tabSize: 2,
        indentUnit: 2
    });

    // Script selection tracking
    window.currentSelectedScript = null;

    // Connection status check
    $('.connection-status').addClass('loading');
    $('#bridge-status').text('Checking...').removeClass('text-success text-danger').addClass('text-warning');

    setTimeout(function () {
        refreshStatus();
    }, 100);

    // Auto-refresh setup with less aggressive default
    if (localStorage.getItem('autoRefresh') !== 'false') {
        let interval = parseInt(localStorage.getItem('refreshInterval')) || 30000; // Default to 30 seconds instead of 10
        window.statusInterval = setInterval(refreshStatus, interval);
        $('#autoRefreshSwitch').prop('checked', true);
    } else {
        $('#autoRefreshSwitch').prop('checked', false);
    }

    // Bootstrap initialization
    $('[data-bs-toggle="tooltip"]').tooltip();
    $('[data-bs-toggle="popover"]').popover();

    loadSavedScripts();

    // Sidebar toggle
    $('#sidebar-toggle').click(function () {
        $('.sidebar').toggleClass('collapsed');
        $(this).find('i').toggleClass('fa-chevron-left fa-chevron-right');
    });

    // Theme toggle
    $('#theme-toggle, #darkModeSwitch').click(function () {
        const isDark = !isDarkMode();
        setTheme(isDark);
        localStorage.setItem('dashboardTheme', isDark ? 'dark' : 'light');

        window.scriptEditor.setOption('theme', isDark ? 'dracula' : 'default');
    });

    // Navigation handling
    $('.nav-item').click(function (e) {
        e.preventDefault();
        const targetPage = $(this).data('page');

        $('.nav-item').removeClass('active');
        $(this).addClass('active');

        $('.content-page').removeClass('active');
        $('#' + targetPage).addClass('active');

        $('#page-title').text($(this).find('span').text());
    });

    // Light power controls
    $('#light-power').click(function () {
        const currentState = $(this).hasClass('on');
        const newState = !currentState;

        setLightState(newState);
    });

    $('#all-lights-on').click(function () {
        setLightState(true);
    });

    $('#all-lights-off').click(function () {
        setLightState(false);
    });

    // Brightness control with interaction tracking
    $('#brightness-slider').on('input', function () {
        window.userInteractionState.isInteractingWithBrightness = true;
        window.userInteractionState.lastInteractionTime = Date.now();

        const brightness = $(this).val();
        $('#brightness-percentage').text(brightness + '%');

        updateSliderBackground($(this), brightness);
    });

    $('#brightness-slider').on('change', function () {
        const brightness = parseInt($(this).val());
        setBrightness(brightness);

        // Allow refresh updates after a delay
        setTimeout(() => {
            window.userInteractionState.isInteractingWithBrightness = false;
        }, window.userInteractionState.interactionCooldown);
    });

    $('.brightness-preset').click(function () {
        const brightnessValue = $(this).data('value');
        $('#brightness-slider').val(brightnessValue).trigger('input').trigger('change');
    });

    // Color selection with interaction tracking
    $('#color-picker').on('change', function () {
        window.userInteractionState.isInteractingWithColor = true;
        window.userInteractionState.lastInteractionTime = Date.now();

        const colorValue = $(this).val();
        $('#color-preview').css('background-color', colorValue);
        updateRGBFromHex(colorValue);
        setColor(colorValue);

        // Allow refresh updates after a delay
        setTimeout(() => {
            window.userInteractionState.isInteractingWithColor = false;
        }, window.userInteractionState.interactionCooldown);
    });

    // Advanced color controls with interaction tracking
    $('#apply-custom-color').click(function () {
        window.userInteractionState.isInteractingWithColor = true;
        window.userInteractionState.lastInteractionTime = Date.now();

        const hexValue = $('#hex-input').val();
        if (hexValue && isValidHex(hexValue)) {
            const normalizedHex = normalizeHex(hexValue);
            $('#color-preview').css('background-color', normalizedHex);
            $('#color-picker').val(normalizedHex);
            setColor(normalizedHex);
        } else {
            // Try RGB values
            const r = parseInt($('#rgb-r').val()) || 0;
            const g = parseInt($('#rgb-g').val()) || 0;
            const b = parseInt($('#rgb-b').val()) || 0;

            const hexFromRGB = rgbToHex(r, g, b);
            $('#color-preview').css('background-color', hexFromRGB);
            $('#color-picker').val(hexFromRGB);
            $('#hex-input').val(hexFromRGB);
            setColor(hexFromRGB);
        }

        // Allow refresh updates after a delay
        setTimeout(() => {
            window.userInteractionState.isInteractingWithColor = false;
        }, window.userInteractionState.interactionCooldown);
    });

    // Track RGB input interactions
    $('#rgb-r, #rgb-g, #rgb-b').on('input', function () {
        window.userInteractionState.isInteractingWithColor = true;
        window.userInteractionState.lastInteractionTime = Date.now();

        const r = parseInt($('#rgb-r').val()) || 0;
        const g = parseInt($('#rgb-g').val()) || 0;
        const b = parseInt($('#rgb-b').val()) || 0;

        const hexValue = rgbToHex(r, g, b);
        $('#hex-input').val(hexValue);
        $('#color-preview').css('background-color', hexValue);
    });

    // Track hex input interactions
    $('#hex-input').on('input', function () {
        window.userInteractionState.isInteractingWithColor = true;
        window.userInteractionState.lastInteractionTime = Date.now();

        const hexValue = $(this).val();
        if (isValidHex(hexValue)) {
            const normalizedHex = normalizeHex(hexValue);
            updateRGBFromHex(normalizedHex);
            $('#color-preview').css('background-color', normalizedHex);
        }
    });

    $('.color-preset').click(function () {
        window.userInteractionState.isInteractingWithColor = true;
        window.userInteractionState.lastInteractionTime = Date.now();

        const colorValue = $(this).data('color');
        $('#color-picker').val(colorValue).trigger('change');

        // Allow refresh updates after a delay
        setTimeout(() => {
            window.userInteractionState.isInteractingWithColor = false;
        }, window.userInteractionState.interactionCooldown);
    });

    // Quick actions
    $('.quick-action-btn').click(function () {
        const action = $(this).data('action');
        executeQuickAction(action);
    });

    // Status refresh
    $('#refresh-status').click(function () {
        refreshStatus();
    });

    $('#autoRefreshSwitch').change(function () {
        const enabled = $(this).prop('checked');
        localStorage.setItem('autoRefresh', enabled);

        if (enabled) {
            const interval = parseInt($('#refreshInterval').val()) || 10000;
            window.statusInterval = setInterval(refreshStatus, interval);
        } else {
            clearInterval(window.statusInterval);
        }
    });

    $('#refreshInterval').change(function () {
        const interval = parseInt($(this).val());
        localStorage.setItem('refreshInterval', interval);

        if ($('#autoRefreshSwitch').prop('checked')) {
            clearInterval(window.statusInterval);
            window.statusInterval = setInterval(refreshStatus, interval);
        }
    });

    // Script execution
    $('#run-script').click(function () {
        runScript(window.scriptEditor.getValue());
    });

    $('#clear-script').click(function () {
        window.scriptEditor.setValue('');
    });

    $('#clear-console').click(function () {
        $('#console-output').html('// Console cleared');
    });

    // Script saving
    $('#save-script-btn').click(function () {
        $('#saveScriptModal').modal('show');
    });

    $('#confirmSaveBtn').click(function () {
        const scriptName = $('#scriptName').val().trim();
        const scriptDescription = $('#scriptDescription').val().trim();
        const scriptContent = window.scriptEditor.getValue();

        if (!scriptName) {
            showNotification('Please enter a script name', 'error');
            return;
        }

        saveScript(scriptName, scriptContent, scriptDescription);
        $('#saveScriptModal').modal('hide');
    });

    // Template loading
    $('.load-template').click(function () {
        const templateName = $(this).closest('.template-item').data('template');
        loadTemplate(templateName, window.scriptEditor);
    });

    $('.activate-scene').click(function () {
        const sceneName = $(this).closest('.scene-item').data('scene');
        activateScene(sceneName);
    });

    // Connection and emergency controls
    $('#test-connection').click(function () {
        testConnection();
    });

    $('#emergency-stop').click(function () {
        emergencyStop();
    });

    // UI initialization
    updateSliderBackground($('#brightness-slider'), $('#brightness-slider').val());

    // Saved scripts console
    $('#clear-saved-scripts-console').click(function () {
        $('#saved-scripts-console-output').html('// Console cleared');
    });

    $('#execute-preview-script').click(function () {
        if (window.currentSelectedScript) {
            const savedScripts = getSavedScripts();
            const script = savedScripts[window.currentSelectedScript];
            if (script) {
                executeScriptInSavedScriptsPage(script.content);
            }
        }
    });

    // Load to editor button
    $('#load-to-editor').click(function () {
        if (window.currentSelectedScript) {
            loadScriptToEditor(window.currentSelectedScript);
        }
    });
});

// Check current theme state
function isDarkMode() {
    return $('body').hasClass('dark-mode');
}

// Apply theme to UI elements
function setTheme(isDark) {
    if (isDark) {
        $('body').removeClass('light-mode').addClass('dark-mode');
        $('#theme-toggle').find('i').removeClass('fa-sun').addClass('fa-moon');
        $('#theme-toggle').find('span').text('Dark Mode');
        $('#darkModeSwitch').prop('checked', true);
    } else {
        $('body').removeClass('dark-mode').addClass('light-mode');
        $('#theme-toggle').find('i').removeClass('fa-moon').addClass('fa-sun');
        $('#theme-toggle').find('span').text('Light Mode');
        $('#darkModeSwitch').prop('checked', false);
    }
}

// Fetch current bridge and light status
function refreshStatus() {
    $.ajax({
        url: '/api/dashboard/status',
        type: 'GET',
        success: function (response) {
            updateStatusDisplay(response);
        },
        error: function () {
            showNotification('Failed to update status', 'error');
        }
    });
}

// Update UI with current status data
function updateStatusDisplay(status) {
    const connected = status.connected;

    $('.connection-status').removeClass('loading');

    if (connected) {
        $('.connection-status').removeClass('disconnected').addClass('connected');
        $('#bridge-status').text('Connected').removeClass('text-danger text-warning').addClass('text-success');

        $('.connection-status .status-text span').text('Connected');

        // Light state
        const lightsOn = status.lightsOn;
        $('#lights-state').text(lightsOn ? 'ON' : 'OFF');
        $('#light-power').toggleClass('on', lightsOn).toggleClass('off', !lightsOn);
        $('.power-label').text(lightsOn ? 'ON' : 'OFF');

        // Color - only update if user is not actively interacting
        const color = status.color || '#FFFFFF';
        $('#current-color').find('.color-indicator').css('background-color', color);
        $('#current-color').find('span').text(color);

        // Respect user interaction state for color controls
        if (!window.userInteractionState || (!window.userInteractionState.isInteractingWithColor &&
            (Date.now() - window.userInteractionState.lastInteractionTime) > window.userInteractionState.interactionCooldown)) {
            $('#color-preview').css('background-color', color);
            $('#color-picker').val(color);
            updateRGBFromHex(color);
        } else {
            console.log('Skipping color update - user is interacting with color controls');
        }

        // Brightness - only update if user is not actively interacting
        const brightness = status.brightness || 100;
        $('#current-brightness').text(brightness + '%');

        // Respect user interaction state for brightness controls
        if (!window.userInteractionState || (!window.userInteractionState.isInteractingWithBrightness &&
            (Date.now() - window.userInteractionState.lastInteractionTime) > window.userInteractionState.interactionCooldown)) {
            $('#brightness-slider').val(brightness);
            $('#brightness-percentage').text(brightness + '%');
            updateSliderBackground($('#brightness-slider'), brightness);
        } else {
            console.log('Skipping brightness update - user is interacting with brightness controls');
        }
    } else {
        $('.connection-status').removeClass('connected').addClass('disconnected');
        $('#bridge-status').text('Disconnected').removeClass('text-success text-warning').addClass('text-danger');

        $('.connection-status .status-text span').text('Disconnected');
    }
}

// Toggle light power state
function setLightState(state) {
    $.ajax({
        url: '/api/dashboard/lights/state',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ state: state }),
        success: function (response) {
            if (response.success) {
                $('#light-power').toggleClass('on', state).toggleClass('off', !state);
                $('.power-label').text(state ? 'ON' : 'OFF');
                $('#lights-state').text(state ? 'ON' : 'OFF');

                showNotification(response.message, 'success');
            } else {
                showNotification(response.error || 'Failed to set light state', 'error');
            }
        },
        error: function () {
            showNotification('Failed to communicate with server', 'error');
        }
    });
}

// Set light brightness level
function setBrightness(brightness) {
    $.ajax({
        url: '/api/dashboard/lights/brightness',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ brightness: brightness }),
        success: function (response) {
            if (response.success) {
                $('#current-brightness').text(brightness + '%');
                showNotification(response.message, 'success');
            } else {
                showNotification(response.error || 'Failed to set brightness', 'error');
            }
        },
        error: function () {
            showNotification('Failed to communicate with server', 'error');
        }
    });
}

// Set light color
function setColor(color) {
    $.ajax({
        url: '/api/dashboard/lights/color',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ color: color }),
        success: function (response) {
            if (response.success) {
                $('#current-color').find('.color-indicator').css('background-color', color);
                $('#current-color').find('span').text(color);
                showNotification(response.message, 'success');
            } else {
                showNotification(response.error || 'Failed to set color', 'error');
            }
        },
        error: function () {
            showNotification('Failed to communicate with server', 'error');
        }
    });
}

// Execute script with real-time or fallback method
function runScript(scriptContent) {
    if (!scriptContent.trim()) {
        showNotification('Script cannot be empty', 'error');
        return;
    }

    if (typeof EventSource !== 'undefined') {
        runScriptRealTime(scriptContent, '#console-output', '#run-script');
    } else {
        runScriptTraditional(scriptContent, '#console-output', '#run-script');
    }
}

// Execute script with real-time log streaming
function runScriptRealTime(scriptContent, consoleSelector, buttonSelector) {
    $(buttonSelector).prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i> Running...');
    $(consoleSelector).html('// Starting script execution...\n').addClass('streaming');

    const indicator = $('<div class="real-time-indicator">🔴 Live execution</div>');
    $(consoleSelector).before(indicator);

    $.ajax({
        url: '/api/scripts/execute-stream',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ scriptContent: scriptContent }),
        success: function (response) {
            if (response.success && response.connectionId) {
                const eventSource = new EventSource(`/api/scripts/logs?connectionId=${response.connectionId}`);

                eventSource.onopen = function () {
                    console.log('Connected to real-time log stream');
                    indicator.html('🟢 Connected - Live execution');
                };

                eventSource.addEventListener('connected', function (event) {
                    $(consoleSelector).html(event.data + '\n');
                });

                eventSource.addEventListener('log', function (event) {
                    try {
                        const data = JSON.parse(event.data);
                        const formattedMessage = formatConsoleOutput(data.message);

                        const logEntry = $('<span class="log-entry"></span>').html(formattedMessage + '\n');
                        $(consoleSelector).append(logEntry);

                        // Auto-scroll with animation
                        const consoleElement = $(consoleSelector)[0];
                        $(consoleElement).animate({
                            scrollTop: consoleElement.scrollHeight
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
                        $(consoleSelector).append(logEntry);

                        // Auto-scroll to bottom
                        const consoleElement = $(consoleSelector)[0];
                        $(consoleElement).animate({
                            scrollTop: consoleElement.scrollHeight
                        }, 200);

                        // Reset UI
                        $(buttonSelector).prop('disabled', false).html('<i class="fas fa-play"></i> Run Script');
                        $(consoleSelector).removeClass('streaming');
                        indicator.addClass('disconnected').html('✅ Execution completed');

                        // Cleanup indicator
                        setTimeout(() => indicator.fadeOut(500, () => indicator.remove()), 2000);

                        // Completion notification
                        if (data.message.includes('✅')) {
                            showNotification('Script executed successfully', 'success');
                        } else {
                            showNotification('Script executed with errors', 'warning');
                        }

                        // Status refresh
                        setTimeout(refreshStatus, 1000);

                    } catch (e) {
                        console.error('Error parsing completion data:', e);
                    }

                    eventSource.close();
                });

                eventSource.onerror = function (event) {
                    console.error('SSE connection error:', event);
                    $(consoleSelector).append('// Connection error occurred\n').removeClass('streaming');
                    $(buttonSelector).prop('disabled', false).html('<i class="fas fa-play"></i> Run Script');
                    indicator.addClass('disconnected').html('❌ Connection lost');

                    // Cleanup indicator
                    setTimeout(() => indicator.fadeOut(500, () => indicator.remove()), 3000);

                    showNotification('Connection error during script execution', 'error');
                    eventSource.close();
                };

            } else {
                // Connection failure handling
                $(consoleSelector).html('// Error: ' + (response.error || 'Failed to start script execution')).removeClass('streaming');
                $(buttonSelector).prop('disabled', false).html('<i class="fas fa-play"></i> Run Script');
                indicator.addClass('disconnected').html('❌ Failed to start');

                // Cleanup indicator
                setTimeout(() => indicator.fadeOut(500, () => indicator.remove()), 3000);

                showNotification('Failed to start script execution', 'error');
            }
        },
        error: function (xhr) {
            $(consoleSelector).html('// Error: ' + (xhr.responseText || 'Failed to start script execution')).removeClass('streaming');
            $(buttonSelector).prop('disabled', false).html('<i class="fas fa-play"></i> Run Script');
            indicator.addClass('disconnected').html('❌ Connection failed');

            // Cleanup indicator
            setTimeout(() => indicator.fadeOut(500, () => indicator.remove()), 3000);

            showNotification('Failed to start script execution', 'error');
        }
    });
}

function runScriptTraditional(scriptContent, consoleSelector, buttonSelector) {
    // UI state update
    $(buttonSelector).prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i> Running...');
    $(consoleSelector).html('// Running script...');

    $.ajax({
        url: '/api/scripts/execute',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ scriptContent: scriptContent }),
        success: function (response) {
            // Format and display output
            let outputHtml = formatConsoleOutput(response.log || '// Script executed successfully.');
            $(consoleSelector).html(outputHtml);

            // Reset UI
            $(buttonSelector).prop('disabled', false).html('<i class="fas fa-play"></i> Run Script');

            // Execution result notification
            if (response.success) {
                showNotification('Script executed successfully', 'success');
            } else {
                showNotification('Script executed with errors', 'warning');
            }

            // Status refresh
            setTimeout(refreshStatus, 1000);
        },
        error: function (xhr) {
            $(consoleSelector).html('// Error: ' + (xhr.responseText || 'Failed to execute script.'));
            $(buttonSelector).prop('disabled', false).html('<i class="fas fa-play"></i> Run Script');
            showNotification('Failed to execute script', 'error');
        }
    });
}

function emergencyStop() {
    $.ajax({
        url: '/api/test/emergency-stop',
        type: 'GET',
        success: function (response) {
            if (response.success) {
                $('#console-output').html('// ⚠️ EMERGENCY STOP ACTIVATED\n// ' + response.message);
                showNotification('Emergency stop activated', 'warning');

                // Status refresh
                setTimeout(refreshStatus, 1000);
            } else {
                $('#console-output').html('// ❌ Emergency stop failed: ' + response.error);
                showNotification('Emergency stop failed', 'error');
            }
        },
        error: function (xhr) {
            $('#console-output').html('// ❌ Error activating emergency stop: ' + xhr.responseText);
            showNotification('Emergency stop failed', 'error');
        }
    });
}

function testConnection() {
    $.ajax({
        url: '/api/scripts/test-connection',
        type: 'GET',
        success: function (response) {
            if (response.connected) {
                showNotification('Successfully connected to Hue Bridge', 'success');
            } else {
                showNotification('Failed to connect to Hue Bridge', 'error');
            }

            // Status update
            refreshStatus();
        },
        error: function () {
            showNotification('Failed to test connection', 'error');
        }
    });
}

// Update slider visual progress
function updateSliderBackground(slider, value) {
    const percentage = (value / slider.attr('max')) * 100;
    slider.css('background', `linear-gradient(to right, var(--hue-secondary) 0%, var(--hue-secondary) ${percentage}%, var(--dark-hover) ${percentage}%, var(--dark-hover) 100%)`);
}

// Color conversion helper functions
function rgbToHex(r, g, b) {
    const toHex = (n) => {
        const hex = Math.max(0, Math.min(255, n)).toString(16);
        return hex.length === 1 ? '0' + hex : hex;
    };
    return `#${toHex(r)}${toHex(g)}${toHex(b)}`.toUpperCase();
}

function hexToRgb(hex) {
    const normalizedHex = normalizeHex(hex);
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(normalizedHex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : null;
}

function isValidHex(hex) {
    return /^#?([a-f\d]{6}|[a-f\d]{3})$/i.test(hex);
}

function normalizeHex(hex) {
    let normalized = hex.replace('#', '');
    if (normalized.length === 3) {
        normalized = normalized.split('').map(char => char + char).join('');
    }
    return '#' + normalized.toUpperCase();
}

function updateRGBFromHex(hex) {
    const rgb = hexToRgb(hex);
    if (rgb) {
        $('#rgb-r').val(rgb.r);
        $('#rgb-g').val(rgb.g);
        $('#rgb-b').val(rgb.b);
        $('#hex-input').val(hex.toUpperCase());
    }
}

// Console output formatting
function formatConsoleOutput(output) {
    if (!output) return '';

    return output
        .replace(/✅/g, '<span class="text-success">✅</span>')
        .replace(/❌/g, '<span class="text-danger">❌</span>')
        .replace(/⛔/g, '<span class="text-warning">⛔</span>')
        .replace(/⏱️/g, '<span class="text-info">⏱️</span>')
        .replace(/💡/g, '<span class="text-warning">💡</span>')
        .replace(/🔄/g, '<span class="text-primary">🔄</span>')
        .replace(/🎨/g, '<span class="text-info">🎨</span>')
        .replace(/🌈/g, '<span class="text-primary">🌈</span>')
        .replace(/📋/g, '<span class="text-info">📋</span>')
        .replace(/(\b(error|failed|failure)\b)/gi, '<span class="text-danger">$1</span>')
        .replace(/(\b(success|successful|completed)\b)/gi, '<span class="text-success">$1</span>')
        .replace(/(\b(warning|cancelled|stopped)\b)/gi, '<span class="text-warning">$1</span>')
        .replace(/(\/\/.*)/g, '<span class="text-muted">$1</span>');
}

// Notification display
function showNotification(message, type = 'info') {
    const notification = $(`
        <div class="notification ${type}">
            ${message}
        </div>
    `);

    $('#notification-container').append(notification);

    setTimeout(function () {
        notification.remove();
    }, 3000);
}

// Script persistence
function saveScript(name, content, description = '') {
    const savedScripts = getSavedScripts();
    const timestamp = new Date().toISOString();

    savedScripts[name] = {
        content: content,
        description: description,
        timestamp: timestamp
    };

    localStorage.setItem('hueScripts', JSON.stringify(savedScripts));
    showNotification(`Script "${name}" saved successfully`, 'success');

    if ($('#saved-scripts').hasClass('active')) {
        loadSavedScripts();
    }
}

// Script retrieval
function getSavedScripts() {
    const scripts = localStorage.getItem('hueScripts');
    return scripts ? JSON.parse(scripts) : {};
}

// Saved scripts list display
function loadSavedScripts() {
    const savedScripts = getSavedScripts();
    const scriptsList = $('#saved-scripts-list');
    scriptsList.empty();

    const scriptNames = Object.keys(savedScripts);

    if (scriptNames.length === 0) {
        scriptsList.html(`
            <div class="no-scripts-message">
                <i class="fas fa-folder-open"></i>
                <p>No saved scripts found</p>
            </div>
        `);
        return;
    }

    // Sort by timestamp (newest first)
    scriptNames.sort((a, b) => {
        const dateA = new Date(savedScripts[a].timestamp || 0);
        const dateB = new Date(savedScripts[b].timestamp || 0);
        return dateB - dateA;
    });

    scriptNames.forEach(name => {
        const script = savedScripts[name];
        const date = new Date(script.timestamp || 0).toLocaleString();
        const description = script.description || 'No description provided';

        const scriptItem = $(`
            <div class="script-item" data-script-name="${name}">
                <div class="script-header">
                    <h4>${name}</h4>
                    <div class="script-actions">
                        <button class="btn btn-sm btn-outline-info preview-script-btn">
                            <i class="fas fa-eye"></i> Preview
                        </button>
                        <button class="btn btn-sm btn-outline-success execute-script-btn">
                            <i class="fas fa-play"></i> Execute
                        </button>
                        <button class="btn btn-sm btn-outline-primary load-script-btn">
                            <i class="fas fa-edit"></i> Edit
                        </button>
                        <button class="btn btn-sm btn-outline-danger delete-script-btn">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
                <div class="script-meta">
                    <small>Saved on ${date}</small>
                </div>
                <div class="script-description">${description}</div>
            </div>
        `);

        scriptsList.append(scriptItem);
    });

    // Script action handlers
    $('.preview-script-btn').click(function () {
        const scriptName = $(this).closest('.script-item').data('script-name');
        previewScript(scriptName);
    });

    $('.execute-script-btn').click(function () {
        const scriptName = $(this).closest('.script-item').data('script-name');
        executeScriptFromSavedScripts(scriptName);
    });

    $('.load-script-btn').click(function () {
        const scriptName = $(this).closest('.script-item').data('script-name');
        loadScriptToEditor(scriptName);
    });

    $('.delete-script-btn').click(function () {
        const scriptName = $(this).closest('.script-item').data('script-name');
        if (confirm(`Are you sure you want to delete the script "${scriptName}"?`)) {
            deleteScript(scriptName);
        }
    });
}

// Script preview display
function previewScript(name) {
    const savedScripts = getSavedScripts();
    if (savedScripts[name]) {
        window.currentSelectedScript = name;
        const script = savedScripts[name];

        $('#script-preview-content').html(`
            <div class="script-preview-header">
                <h5>${name}</h5>
                <small class="text-muted">${script.description || 'No description'}</small>
            </div>
            <pre class="script-preview-code">${script.content}</pre>
        `);

        $('#execute-preview-script, #load-to-editor').prop('disabled', false);

        $('.script-item').removeClass('selected');
        $(`.script-item[data-script-name="${name}"]`).addClass('selected');

        showNotification(`Script "${name}" loaded in preview`, 'info');
    } else {
        showNotification(`Script "${name}" not found`, 'error');
    }
}

// Script execution from list
function executeScriptFromSavedScripts(name) {
    const savedScripts = getSavedScripts();
    if (savedScripts[name]) {
        const script = savedScripts[name];
        executeScriptInSavedScriptsPage(script.content);
        showNotification(`Executing script "${name}"`, 'info');
    } else {
        showNotification(`Script "${name}" not found`, 'error');
    }
}

// Saved scripts page execution
function executeScriptInSavedScriptsPage(scriptContent) {
    if (!scriptContent.trim()) {
        showNotification('Script cannot be empty', 'error');
        return;
    }

    if (typeof EventSource !== 'undefined') {
        runScriptRealTime(scriptContent, '#saved-scripts-console-output', '#execute-preview-script');
    } else {
        executeScriptInSavedScriptsPageTraditional(scriptContent);
    }
}

// Traditional execution fallback
function executeScriptInSavedScriptsPageTraditional(scriptContent) {
    // UI state update
    $('#execute-preview-script').prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i> Running...');
    $('#saved-scripts-console-output').html('// Running script...');

    $.ajax({
        url: '/api/scripts/execute',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ scriptContent: scriptContent }),
        success: function (response) {
            // Format and display the output
            let outputHtml = formatConsoleOutput(response.log || '// Script executed successfully.');
            $('#saved-scripts-console-output').html(outputHtml);

            // Update UI
            $('#execute-preview-script').prop('disabled', false).html('<i class="fas fa-play"></i> Execute');

            // Show notification based on execution result
            if (response.success) {
                showNotification('Script executed successfully', 'success');
            } else {
                showNotification('Script executed with errors', 'warning');
            }

            // Refresh status after execution
            setTimeout(refreshStatus, 1000);
        },
        error: function (xhr) {
            $('#saved-scripts-console-output').html('// Error: ' + (xhr.responseText || 'Failed to execute script.'));
            $('#execute-preview-script').prop('disabled', false).html('<i class="fas fa-play"></i> Execute');
            showNotification('Failed to execute script', 'error');
        }
    });
}

// Editor redirection with script data
function loadScriptToEditor(name) {
    const savedScripts = getSavedScripts();
    if (savedScripts[name]) {
        const script = savedScripts[name];

        // Store script data for editor pickup
        localStorage.setItem('editingScript', JSON.stringify({
            name: name,
            content: script.content,
            description: script.description || '',
            isEditing: true
        }));

        // Navigate to editor
        window.location.href = '/editor';

        showNotification(`Redirecting to editor with script "${name}"`, 'info');
    } else {
        showNotification(`Script "${name}" not found`, 'error');
    }
}

// Script loading alias
function loadScript(name) {
    loadScriptToEditor(name);
}

// Script deletion
function deleteScript(name) {
    const savedScripts = getSavedScripts();
    if (savedScripts[name]) {
        delete savedScripts[name];
        localStorage.setItem('hueScripts', JSON.stringify(savedScripts));
        showNotification(`Script "${name}" deleted`, 'success');

        // Clear preview if selected
        if (window.currentSelectedScript === name) {
            window.currentSelectedScript = null;
            $('#script-preview-content').html(`
                <div class="no-script-selected">
                    <i class="fas fa-file-code"></i>
                    <p>Select a script to preview</p>
                </div>
            `);
            $('#execute-preview-script, #load-to-editor').prop('disabled', true);
        }

        loadSavedScripts();
    } else {
        showNotification(`Script "${name}" not found`, 'error');
    }
}

// Template loading
function loadTemplate(templateName, editor) {
    const templates = {
        simpleCycle: `// Simple On/Off Cycle
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

lights off;`,

        colorTransition: `// Color Transitions
// Smooth color progression sequence

brightness 100;
lights on;

// Red to blue transition
transition "red" to "blue" over 5 seconds;
wait 1 sec;

// Blue to green transition
transition "blue" to "green" over 5 seconds;
wait 1 sec;

// Green to purple transition
transition "green" to "purple" over 5 seconds;
wait 1 sec;

// Final warm setting
transition "purple" to "warm" over 5 seconds;`,

        partyMode: `// Party Mode
// High-energy lighting with rapid changes

brightness 100;
lights on;

// Rapid color cycling
repeat 20 seconds {
  lights color "red";
  wait 400 ms;
  lights color "blue";
  wait 400 ms;
  lights color "green";
  wait 400 ms;
  lights color "purple";
  wait 400 ms;
}

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
lights color "warm";`,

        relaxMode: `// Relax Mode
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

// Final calming state
transition "#9370DB" to "warm" over 10 seconds;
brightness 30;`
    };

    if (templates[templateName]) {
        editor.setValue(templates[templateName]);
        showNotification(`Template "${templateName}" loaded`, 'info');
    } else {
        showNotification(`Template "${templateName}" not found`, 'error');
    }
}

// Scene activation
function activateScene(sceneName) {
    const scenes = {
        relaxScene: `// Relax Scene
brightness 50;
lights on;
lights color "#FF9900"; // Warm orange`,

        concentrateScene: `// Concentrate Scene
brightness 100;
lights on;
lights color "#CCE5FF"; // Cool blue`,

        energizeScene: `// Energize Scene
brightness 100;
lights on;
lights color "#80CAFF"; // Bright cool blue`,

        readingScene: `// Reading Scene
brightness 70;
lights on;
lights color "#FFE0B2"; // Soft warm`,

        nightlightScene: `// Night Light Scene
brightness 15;
lights on;
lights color "#800080"; // Purple`,

        movieScene: `// Movie Scene
brightness 30;
lights on;
lights color "#3D2C8D"; // Dark blue`
    };

    if (scenes[sceneName]) {
        runScript(scenes[sceneName]);
        showNotification(`Activating ${sceneName.replace('Scene', '')} scene`, 'info');
    } else {
        showNotification(`Scene "${sceneName}" not found`, 'error');
    }
}

// Quick action execution
function executeQuickAction(action) {
    const actions = {
        relaxMode: `// Relax Mode
brightness 50;
lights on;
lights color "#FF9900"; // Warm orange`,

        concentrateMode: `// Concentrate Mode
brightness 100;
lights on;
lights color "#CCE5FF"; // Cool blue`,

        energizeMode: `// Energize Mode
brightness 100;
lights on;
lights color "#80CAFF"; // Bright cool blue`,

        nightLight: `// Night Light
brightness 15;
lights on;
lights color "#800080"; // Purple`,

        colorCycle: `// Color Cycle
brightness 100;
lights on;

// Color progression
transition "red" to "orange" over 3 seconds;
wait 1 sec;
transition "orange" to "yellow" over 3 seconds;
wait 1 sec;
transition "yellow" to "green" over 3 seconds;
wait 1 sec;
transition "green" to "blue" over 3 seconds;
wait 1 sec;
transition "blue" to "purple" over 3 seconds;`,

        partyMode: `// Party Mode
brightness 100;
lights on;

// Rapid color cycling
repeat 5 times {
  lights color "red";
  wait 500 ms;
  lights color "blue";
  wait 500 ms;
  lights color "green";
  wait 500 ms;
  lights color "purple";
  wait 500 ms;
}`
    };

    if (actions[action]) {
        runScript(actions[action]);
        showNotification(`Executing ${action.replace(/([A-Z])/g, ' $1').toLowerCase()}`, 'info');
    } else {
        showNotification(`Action "${action}" not found`, 'error');
    }
}

// Bridge settings save handler
$('#save-bridge-settings').click(function () {
    const bridgeIp = $('#bridgeIpInput').val().trim();
    const apiKey = $('#apiKeyInput').val().trim();

    if (!bridgeIp) {
        showNotification('Bridge IP cannot be empty', 'error');
        return;
    }

    // Loading state
    $(this).prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i> Saving...');

    // Save settings request
    $.ajax({
        url: '/api/settings/bridge',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({
            bridgeIp: bridgeIp,
            apiKey: apiKey
        }),
        success: function (response) {
            if (response.success) {
                showNotification('Bridge settings saved successfully', 'success');

                // Update display
                $('#bridge-ip').text(bridgeIp);

                // Test new connection
                testConnection();
            } else {
                showNotification(response.error || 'Failed to save settings', 'error');
            }
        },
        error: function () {
            showNotification('Failed to communicate with server', 'error');
        },
        complete: function () {
            // Reset button
            $('#save-bridge-settings').prop('disabled', false).html('Save Bridge Settings');
        }
    });
});