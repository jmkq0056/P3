package com.soft.p4.hueScriptLanguage.exception;

/**
 * Exception thrown during script parsing with detailed error location
 * information.
 */
public class ParserException extends RuntimeException {

    private final int line;      // Line number where error occurred (-1 if unknown)
    private final int position;  // Character position in line (-1 if unknown)
    private final String source; // Source text snippet around error

    /**
     * Creates an exception with only an error message
     */
    public ParserException(String message) {
        super(message);
        this.line = -1;
        this.position = -1;
        this.source = null;
    }

    /**
     * Creates an exception with an error message and cause
     */
    public ParserException(String message, Throwable cause) {
        super(message, cause);
        this.line = -1;
        this.position = -1;
        this.source = null;
    }

    /**
     * Creates an exception with error location details
     *
     * @param line Line number in source
     * @param position Character position in line
     * @param source Source text snippet
     */
    public ParserException(String message, int line, int position, String source) {
        super(formatMessage(message, line, position, source));
        this.line = line;
        this.position = position;
        this.source = source;
    }

    /**
     * @return Line number where error occurred (-1 if unknown)
     */
    public int getLine() {
        return line;
    }

    /**
     * @return Character position in line (-1 if unknown)
     */
    public int getPosition() {
        return position;
    }

    /**
     * @return Source text snippet around error
     */
    public String getSource() {
        return source;
    }

    /**
     * Formats error message with location information and visual pointer
     */
    private static String formatMessage(String message, int line, int position, String source) {
        if (line < 0) {
            return message;
        }

        StringBuilder formattedMessage = new StringBuilder();
        formattedMessage.append(message);
        formattedMessage.append(" at line ").append(line);

        if (position >= 0) {
            formattedMessage.append(", position ").append(position);
        }

        if (source != null && !source.isEmpty()) {
            formattedMessage.append("\nSource: \"").append(source).append("\"");
            if (position >= 0 && position <= source.length()) {
                formattedMessage.append("\n        ");
                for (int i = 0; i < position - 1; i++) {
                    formattedMessage.append(" ");
                }
                formattedMessage.append("^");
            }
        }

        return formattedMessage.toString();
    }
}
