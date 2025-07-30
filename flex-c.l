#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// Token types
typedef enum {
    TOKEN_KEYWORD,
    TOKEN_IDENTIFIER,
    TOKEN_NUMBER,
    TOKEN_OPERATOR,
    TOKEN_DELIMITER,
    TOKEN_STRING_LITERAL,
    TOKEN_COMMENT,
    TOKEN_EOF,
    TOKEN_UNKNOWN
} TokenType;

// Token structure
typedef struct {
    TokenType type;
    char value[256];
    int line;
    int column;
} Token;

// Global variables
char *input;
int position = 0;
int line = 1;
int column = 1;

// Keywords array
const char *keywords[] = {
    "if", "else", "while", "for", "int", "float", "char", "void",
    "return", "break", "continue", "switch", "case", "default",
    "struct", "union", "typedef", "sizeof", "const", "static"
};
const int num_keywords = sizeof(keywords) / sizeof(keywords[0]);

// Function prototypes
Token getNextToken();
int isKeyword(const char *str);
void skipWhitespace();
void skipComment();
Token readNumber();
Token readIdentifier();
Token readString();
void printToken(Token token);
const char* getTokenTypeName(TokenType type);

int main() {
    printf("=== Simple Lexical Analyzer ===\n");
    printf("Enter your code (end with EOF - Ctrl+D on Unix/Linux, Ctrl+Z on Windows):\n");
    
    // Read input from user
    char buffer[4096];
    char *temp = malloc(4096);
    temp[0] = '\0';
    
    while (fgets(buffer, sizeof(buffer), stdin)) {
        temp = realloc(temp, strlen(temp) + strlen(buffer) + 1);
        strcat(temp, buffer);
    }
    
    input = temp;
    position = 0;
    line = 1;
    column = 1;
    
    printf("\n=== TOKENS ===\n");
    printf("%-15s %-20s %-8s %-8s\n", "TYPE", "VALUE", "LINE", "COLUMN");
    printf("%-15s %-20s %-8s %-8s\n", "----", "-----", "----", "------");
    
    Token token;
    do {
        token = getNextToken();
        if (token.type != TOKEN_EOF && token.type != TOKEN_COMMENT) {
            printToken(token);
        }
    } while (token.type != TOKEN_EOF);
    
    free(input);
    return 0;
}

Token getNextToken() {
    Token token;
    token.line = line;
    token.column = column;
    
    skipWhitespace();
    
    if (position >= strlen(input)) {
        token.type = TOKEN_EOF;
        strcpy(token.value, "EOF");
        return token;
    }
    
    char current = input[position];
    
    // Handle comments
    if (current == '/' && position + 1 < strlen(input)) {
        if (input[position + 1] == '/') {
            skipComment();
            token.type = TOKEN_COMMENT;
            strcpy(token.value, "//comment");
            return getNextToken(); // Skip comment and get next token
        }
    }
    
    // Handle string literals
    if (current == '"') {
        return readString();
    }
    
    // Handle numbers
    if (isdigit(current)) {
        return readNumber();
    }
    
    // Handle identifiers and keywords
    if (isalpha(current) || current == '_') {
        return readIdentifier();
    }
    
    // Handle operators and delimiters
    token.line = line;
    token.column = column;
    
    switch (current) {
        case '+': case '-': case '*': case '/': case '%':
        case '=': case '!': case '<': case '>': case '&': case '|':
            token.type = TOKEN_OPERATOR;
            token.value[0] = current;
            token.value[1] = '\0';
            
            // Handle compound operators
            if (position + 1 < strlen(input)) {
                char next = input[position + 1];
                if ((current == '=' && next == '=') ||
                    (current == '!' && next == '=') ||
                    (current == '<' && next == '=') ||
                    (current == '>' && next == '=') ||
                    (current == '&' && next == '&') ||
                    (current == '|' && next == '|') ||
                    (current == '+' && next == '+') ||
                    (current == '-' && next == '-')) {
                    token.value[1] = next;
                    token.value[2] = '\0';
                    position++;
                    column++;
                }
            }
            break;
            
        case '(': case ')': case '{': case '}': case '[': case ']':
        case ';': case ',': case '.': case ':':
            token.type = TOKEN_DELIMITER;
            token.value[0] = current;
            token.value[1] = '\0';
            break;
            
        default:
            token.type = TOKEN_UNKNOWN;
            token.value[0] = current;
            token.value[1] = '\0';
            break;
    }
    
    position++;
    column++;
    return token;
}

int isKeyword(const char *str) {
    for (int i = 0; i < num_keywords; i++) {
        if (strcmp(str, keywords[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

void skipWhitespace() {
    while (position < strlen(input) && isspace(input[position])) {
        if (input[position] == '\n') {
            line++;
            column = 1;
        } else {
            column++;
        }
        position++;
    }
}

void skipComment() {
    while (position < strlen(input) && input[position] != '\n') {
        position++;
        column++;
    }
}

Token readNumber() {
    Token token;
    token.type = TOKEN_NUMBER;
    token.line = line;
    token.column = column;
    
    int i = 0;
    while (position < strlen(input) && 
           (isdigit(input[position]) || input[position] == '.')) {
        token.value[i++] = input[position++];
        column++;
    }
    token.value[i] = '\0';
    
    return token;
}

Token readIdentifier() {
    Token token;
    token.line = line;
    token.column = column;
    
    int i = 0;
    while (position < strlen(input) && 
           (isalnum(input[position]) || input[position] == '_')) {
        token.value[i++] = input[position++];
        column++;
    }
    token.value[i] = '\0';
    
    // Check if it's a keyword
    if (isKeyword(token.value)) {
        token.type = TOKEN_KEYWORD;
    } else {
        token.type = TOKEN_IDENTIFIER;
    }
    
    return token;
}

Token readString() {
    Token token;
    token.type = TOKEN_STRING_LITERAL;
    token.line = line;
    token.column = column;
    
    position++; // Skip opening quote
    column++;
    
    int i = 0;
    token.value[i++] = '"'; // Include opening quote in value
    
    while (position < strlen(input) && input[position] != '"') {
        if (input[position] == '\\' && position + 1 < strlen(input)) {
            token.value[i++] = input[position++]; // Include backslash
            column++;
        }
        token.value[i++] = input[position++];
        column++;
    }
    
    if (position < strlen(input)) {
        token.value[i++] = '"'; // Include closing quote
        position++; // Skip closing quote
        column++;
    }
    
    token.value[i] = '\0';
    return token;
}

void printToken(Token token) {
    printf("%-15s %-20s %-8d %-8d\n", 
           getTokenTypeName(token.type), 
           token.value, 
           token.line, 
           token.column);
}

const char* getTokenTypeName(TokenType type) {
    switch (type) {
        case TOKEN_KEYWORD: return "KEYWORD";
        case TOKEN_IDENTIFIER: return "IDENTIFIER";
        case TOKEN_NUMBER: return "NUMBER";
        case TOKEN_OPERATOR: return "OPERATOR";
        case TOKEN_DELIMITER: return "DELIMITER";
        case TOKEN_STRING_LITERAL: return "STRING";
        case TOKEN_COMMENT: return "COMMENT";
        case TOKEN_EOF: return "EOF";
        case TOKEN_UNKNOWN: return "UNKNOWN";
        default: return "UNKNOWN";
    }
}