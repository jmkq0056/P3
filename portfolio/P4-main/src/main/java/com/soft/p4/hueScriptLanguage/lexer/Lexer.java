package com.soft.p4.hueScriptLanguage.lexer;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.soft.p4.hueScriptLanguage.exception.ParserException;

/**
 * Lexical analyzer for the Hue script language. Breaks input text into tokens
 * using regex patterns and keyword matching. Preserves pattern matching order
 * to ensure correct token precedence. Handles keywords, literals, and special
 * tokens.
 */
public class Lexer {

    private static final Map<Pattern, TokenType> PATTERNS = new LinkedHashMap<>();
    private static final Map<String, TokenType> KEYWORDS = new HashMap<>();

    static {
        // Core language keywords
        KEYWORDS.put("lights", TokenType.LIGHTS);
        KEYWORDS.put("light", TokenType.LIGHT);
        KEYWORDS.put("group", TokenType.GROUP);
        KEYWORDS.put("on", TokenType.ON);
        KEYWORDS.put("off", TokenType.OFF);
        KEYWORDS.put("brightness", TokenType.BRIGHTNESS);
        KEYWORDS.put("color", TokenType.COLOR);
        KEYWORDS.put("wait", TokenType.WAIT);
        KEYWORDS.put("repeat", TokenType.REPEAT);
        KEYWORDS.put("times", TokenType.TIMES);
        KEYWORDS.put("for", TokenType.FOR);
        KEYWORDS.put("transition", TokenType.TRANSITION);
        KEYWORDS.put("to", TokenType.TO);

        // Variable and scene support
        KEYWORDS.put("var", TokenType.VAR);
        KEYWORDS.put("scene", TokenType.SCENE);
        KEYWORDS.put("define", TokenType.DEFINE);

        // Time unit keywords
        KEYWORDS.put("sec", TokenType.SEC);
        KEYWORDS.put("min", TokenType.MIN);
        KEYWORDS.put("hr", TokenType.HR);
        KEYWORDS.put("ms", TokenType.MS);
        KEYWORDS.put("seconds", TokenType.SECONDS);
        KEYWORDS.put("minutes", TokenType.MINUTES);
        KEYWORDS.put("hours", TokenType.HOURS);
        KEYWORDS.put("second", TokenType.SECOND);
        KEYWORDS.put("minute", TokenType.MINUTE);
        KEYWORDS.put("hour", TokenType.HOUR);
        KEYWORDS.put("milliseconds", TokenType.MILLISECONDS);
        KEYWORDS.put("millisecond", TokenType.MILLISECOND);

        // Token patterns in precedence order
        PATTERNS.put(Pattern.compile("^\\{"), TokenType.LEFT_BRACE);
        PATTERNS.put(Pattern.compile("^\\}"), TokenType.RIGHT_BRACE);
        PATTERNS.put(Pattern.compile("^\\s+"), TokenType.WHITESPACE);
        PATTERNS.put(Pattern.compile("^\"[^\"]*\""), TokenType.STRING);
        PATTERNS.put(Pattern.compile("^//.*"), TokenType.COMMENT);
        PATTERNS.put(Pattern.compile("^;"), TokenType.SEMICOLON);
        PATTERNS.put(Pattern.compile("^\\d+"), TokenType.NUMBER);
        PATTERNS.put(Pattern.compile("^="), TokenType.ASSIGN);
        PATTERNS.put(Pattern.compile("^[a-zA-Z_][a-zA-Z0-9_]*"), TokenType.IDENTIFIER);
    }

    /**
     * Tokenizes a script into a sequence of tokens. Processes input line by
     * line, matching patterns in order of precedence. Identifiers are checked
     * against keywords for potential token type remapping.
     *
     * @param script The input script text
     * @return List of tokens, ending with EOF
     * @throws ParserException if an invalid character is encountered
     */
    public List<Token> tokenize(String script) {
        List<Token> tokens = new ArrayList<>();
        String[] lines = script.split("\n");

        for (int lineNum = 0; lineNum < lines.length; lineNum++) {
            String line = lines[lineNum].trim();
            if (line.isEmpty()) {
                continue;
            }

            int position = 0;
            while (position < line.length()) {
                boolean matched = false;

                for (Map.Entry<Pattern, TokenType> entry : PATTERNS.entrySet()) {
                    Matcher matcher = entry.getKey().matcher(line.substring(position));

                    if (matcher.find()) {
                        String value = matcher.group();
                        TokenType type = entry.getValue();

                        if (type == TokenType.IDENTIFIER && KEYWORDS.containsKey(value.toLowerCase())) {
                            type = KEYWORDS.get(value.toLowerCase());
                        }

                        if (type != TokenType.WHITESPACE && type != TokenType.COMMENT) {
                            tokens.add(new Token(type, value, lineNum + 1, position + 1));
                        }

                        position += value.length();
                        matched = true;
                        break;
                    }
                }

                if (!matched) {
                    throw new ParserException("Unexpected character '" + line.charAt(position)
                            + "' at line " + (lineNum + 1) + ", position " + (position + 1));
                }
            }
        }

        tokens.add(new Token(TokenType.EOF, "", lines.length + 1, 0));
        return tokens;
    }
}
