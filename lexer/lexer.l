%{
/*
    flex lexer.l
    gcc lex.yy.c -o lexer
    ./lexer
*/
#include <string.h>
#include <stdlib.h>
#include <limits.h>

// 一些全局变量
int cur_line_num = 1;   // 定位行数，debug可能用到
int cur_pos = 0;        // 定位扫描位置
int lex_pos = 0;            // 开始变异的位置，来自AFL
char** lex_origin;          // 原始字符串，来自AFL
char** lex_repl;            // 替换字符串，来自AFL
int target_type = 1;    // 目标变异类型
int if_find = 0;

void lex_error(char* msg, int line);
int remain_or_mutate(int type, int target_type, int* pos, char** origin, char** repl);
void identifier_mutate(char** origin, char** repl, char* yytext);
void integer_mutate(char** origin, char** repl, char* yytext);
void float_mutate(char** origin, char** repl, char* yytext);
void type_spcf_mutate(char** origin, char** repl, char* yytext);
void string_mutate(char** origin, char** repl, char* yytext);
void char_mutate(char** origin, char** repl, char* yytext);
int comment(void);
int macro(void);

/* TODO
    针对不同类型关键字的变异
*/
enum {
    ID,          // 标识符
    INTEGER,     // 整数
    FLOAT,       // 浮点数
    TYPE_SPECIFIER,  // 类型标识符
    STRING,       // 字符串
    CHAR
};

%}

/* Definitions, note: \042 is '"' */
/* INTEGER             ([0-9]+)

STRING              (\042[^\042\n]*\042)
IDENTIFIER          ([_a-zA-Z][_a-zA-Z0-9]*)

 */

SPACE                   [ \t\r\a]+

DIGIT			        [0-9]
LETTER			        [a-zA-Z_]
HEX_DIGIT		        [a-fA-F0-9]
EXPONENT		        ([Ee][+-]?{DIGIT}+)
PREFIX			        ([Pp][+-]?{DIGIT}+)
FLOAT_SUFFIX		    (f|F|l|L)
INTEGER_SUFFIX		    ((u|U)|(u|U)?(l|L|ll|LL)|(l|L|ll|LL)(u|U))

IDENTIFIER		        ({LETTER}({LETTER}|{DIGIT})*)
HEX_INTEGER		        (0[xX]{HEX_DIGIT}+{INTEGER_SUFFIX}?)
OCT_INTEGER		        (0[0-7]*{INTEGER_SUFFIX}?)
DEC_INTEGER		        ([1-9]{DIGIT}*{INTEGER_SUFFIX}?)
CHARACTER		        (L?'(\\.|[^\\'\n])+')

FLOAT_DECIMAL		    ({DIGIT}+{EXPONENT}{FLOAT_SUFFIX}?)
FLOAT_DOT		        ({DIGIT}*"."{DIGIT}+{EXPONENT}?{FLOAT_SUFFIX}?)
FLOAT_DOT_LEADING	    ({DIGIT}+"."{DIGIT}*{EXPONENT}?{FLOAT_SUFFIX}?)
HEX_FLOAT		        (0[xX]{HEX_DIGIT}+{PREFIX}{FLOAT_SUFFIX}?)
HEX_FLOAT_DOT		    (0[xX]{HEX_DIGIT}*"."{HEX_DIGIT}+{PREFIX}{FLOAT_SUFFIX}?)
STRING			        (L?\"(\\.|[^\\"\n])*\")
UNTERM_STRING           (\042[^\042\n]*)

INTEGER             ({HEX_INTEGER}|{OCT_INTEGER}|{DEC_INTEGER})
FLOAT               ({FLOAT_DECIMAL}|{FLOAT_DOT}|{FLOAT_DOT_LEADING}|{HEX_FLOAT}|{HEX_FLOAT_DOT})
OPERATOR            ([+*-/%&|^~=,;!?:<>(){}\[\]\.])
SINGLE_COMMENT1     ("//"[^\n]*)
SINGLE_COMMENT2     ("#"[^\n]*)

/* TODO
    多行注释
    宏定义
    浮点数
    ……
*/

/* 暂时注释
"+="                {  ;          }
"-="                {  ;          }
"*="                {  ;          }
"/="                {  ;          }
"%="                {  ;          }
"&="                {  ;          }
"|="                {  ;           }
"^="                {  ;          }
"++"                {  ;             }
"--"                {  ;             }
"<="                {  ;              }
">="                {  ;              }
"=="                {  ;              }
"!="                {  ;              }
"&&"                {  ;             }
"||"                {  ;              }
"<<"                {  ;        }
"<<="               {  ;           }
">>="               {  ;           }
">>"                {  ;       }
"->"                {  ;           } 
*/

%%
"/*"			    { if(!comment()) return 0;                  }
[\n]                { cur_line_num++; cur_pos += strlen(yytext);}
{SPACE}             { cur_pos += strlen(yytext);                }
{SINGLE_COMMENT1}   { cur_pos += strlen(yytext);                }
{SINGLE_COMMENT2}   { if(!macro()) return 0;                    }

{OPERATOR}          { cur_pos += strlen(yytext);                }



"void"              {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"int"               {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"float"             {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"double"            {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"char"              {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"long"              {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"short"             {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"unsigned"          {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"signed"            {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"const"             {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"volatile"          {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"restrict"          {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"struct"            {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"_Bool"             {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"_Complex"          {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"_Imaginary"        {  if(remain_or_mutate(TYPE_SPECIFIER, target_type, &lex_pos, lex_origin, lex_repl)) return 0;     }
"union"             {  cur_pos += 5; }
"typedef"           {  cur_pos += 7; }
"extern"            {  cur_pos += 6; }
"static"            {  cur_pos += 6; }
"auto"              {  cur_pos += 4; }
"register"          {  cur_pos += 8; }
"inline"            {  cur_pos += 6; }
"do"                {  cur_pos += 2; }
"while"             {  cur_pos += 5; }
"if"                {  cur_pos += 2; }
"else"              {  cur_pos += 4; }
"for"               {  cur_pos += 3; }
"return"            {  cur_pos += 6; }
"break"             {  cur_pos += 5; }
"continue"          {  cur_pos += 8; }
"sizeof"            {  cur_pos += 6; }
"case"              {  cur_pos += 4; }
"default"           {  cur_pos += 7; }
"switch"            {  cur_pos += 6; }
"goto"              {  cur_pos += 4; }
"enum"              {  cur_pos += 4; }




{INTEGER}           { if(remain_or_mutate(INTEGER, target_type, &lex_pos, lex_origin, lex_repl)) return 0; }
{FLOAT}             { if(remain_or_mutate(FLOAT, target_type, &lex_pos, lex_origin, lex_repl)) return 0; }
{STRING}            { if(remain_or_mutate(STRING, target_type, &lex_pos, lex_origin, lex_repl)) return 0; }
{IDENTIFIER}        { if(remain_or_mutate(ID, target_type, &lex_pos, lex_origin, lex_repl)) return 0;/* yylval = strdup(yytext); */ }
{CHARACTER}         { if(remain_or_mutate(CHAR, target_type, &lex_pos, lex_origin, lex_repl)) return 0; }

<<EOF>>             { return 0; }

{UNTERM_STRING}     { return 0;/* lex_error("Unterminated string constant", cur_line_num); */  }
.                   { cur_pos += strlen(yytext);        }

%%
/*"..."               {  ;        }*/

/* TODO
    更多错误处理
*/

/* TODO
    将main函数改造为提供给AFL的接口
    如：flex_mutate(out_buf, origin, repl, pos, target_type);
*/
/*int main(int argc, char* argv[]) {
    char* ori_buf = (char*)malloc(1024);
    char* repl_buf = (char*)malloc(1024);
    origin = &ori_buf;
    repl = &repl_buf;
    target_type = INTEGER;
    
    if(argc >= 2) pos = atoi(argv[1]);
    if(argc >= 3) target_type = atoi(argv[2]);
    // printf("%d %d\n", pos, target_type);
    printf("Hello flex!\n");
    // char* input_string = "#include <stdio.h>\nint main() {\n\ta->b = 1;int a = 0; a->b = 0;\n\treturn 0;\n}";    // 测试用
    // yy_scan_string(input_string);       // 以字符串作为输入流

    int token;
    while (token = yylex()) ;

    free(ori_buf);
    free(repl_buf);
    if(!if_find) printf("asdfghjkl\n");
    printf("Bye flex!\n");
    return 0;
}*/

void lex_error(char* msg, int line) {
    printf("\nError at line %-3d: %s\n\n", line, msg);
}


/* TODO
    补全针对不同类型或关键字的变异策略
*/
/* remain_or_mutate(type belongs to the token, target type from afl, pos from afl, origin, repl from afl); */
int remain_or_mutate(int type, int target_type, int* pos, char** origin, char** repl) {
    /* CASE 1
        我们假设 *out_buf == "varchar; char", *pos == 0
        我们想将 `char` 变异为 `const char`
        经本函数处理后，*origin => "char", *repl => "const char"
        如果不对pos做处理，*out_buf会被变异为 "varconst char ; char"
        所以我们应将 pos 指针指向 char 关键字开始的准确位置，本例中为 10
    */
    int old_pos = cur_pos;
    cur_pos += strlen(yytext);
    // pos没到位，继续扫描下一个词素
    // CASE 2
    // 我们从头开始扫描，虽然速度慢，但一定程度上保证精度
    // 我们假设不从头开始扫描，*out_buf == ` printf("helloworld"); `
    // 如果根据 pos 来定位扫描开始位置，假设 *(out_buf + pos) == ` helloworld"); `
    // 我们想对关键字做变异，但事实上 out_buf 中没有关键字
    // 但在以上情况下，helloworld依旧会被识别为关键字
    if(cur_pos < *pos) return 0;

    if(type == target_type) {
        if_find = 1;
        strncpy(*origin, yytext, 1024);
        switch(type) {
            case ID:    // 标识符变异
                identifier_mutate(origin, repl, yytext);
                break;
            case INTEGER: 
                integer_mutate(origin, repl, yytext);            
                break;
            case FLOAT:
                float_mutate(origin, repl, yytext);
                break;
            case TYPE_SPECIFIER:
                type_spcf_mutate(origin, repl, yytext);
                break;
            case STRING:
                string_mutate(origin, repl, yytext);
                break;
            case CHAR:
                char_mutate(origin, repl, yytext);
                break;
        }
        *pos = old_pos; // 精确定位词素开始的位置，详见 CASE 1
        // printf("pos: %d\n", *pos);
        // printf("origin: %s\n", *origin);
        // printf("repl: %s\n", *repl);
        return 1;
    }
    else return 0;
}

void identifier_mutate(char** origin, char** repl, char* yytext) {
    int choice = rand() % 3;
    //int choice = UR(3);
    switch(choice) {
        case 0:      // identifier => *identifier      
            strncpy(*repl, "*", 1024);
            strncat(*repl, *origin, 1024);
            break;
        case 1:      // identifier => &identifier      
            strncpy(*repl, "&", 1024);
            strncat(*repl, *origin, 1024);
            break;
        case 2:      // identifier => identifier[0]      
            strncpy(*repl, *origin, 1024);
            strncat(*repl, "[0]", 1024);
            break;
    }
}

void integer_mutate(char** origin, char** repl, char* yytext) {
    int choice = rand()%2;
    switch(choice){
        case 0:     //0
            strncpy(*repl,"0",1024);
            break;
        case 1: {    //random integer
            char random_int_str[1024];
            for(int i = 0;i<10;i++){
                random_int_str[i]=rand() % (58 - 48) + 48;
            }
            strncpy(*repl,random_int_str,1024);
            break;}
    }
}

void float_mutate(char** origin, char** repl, char* yytext) {
    int choice = rand()%2;
    switch(choice){
        case 0:     //0
            strncpy(*repl,"0.0",1024);
            break;
        case 1: {    //random float number
            int random_devidend = rand();
            while(random_devidend == 0){
                random_devidend = rand();
            }
            float random_num = ((float)rand())/((float)random_devidend);
            char float_num_str[1024];
            sprintf(float_num_str, "%f", random_num);
            strncpy(*repl,float_num_str,1024);
            break;}
    }
}

void type_spcf_mutate(char** origin, char** repl, char* yytext) {
    int choice = rand() % 2;
    //int choice = UR(2);
    switch(choice) {
        case 0:      // type => type*      
            strncpy(*repl, *origin, 1024);
            strncat(*repl, "*", 1024);
            break;
        case 1:      // type => type&      
            strncpy(*repl, *origin, 1024);
            strncat(*repl, "&", 1024);
            break;
    }
}

void string_mutate(char** origin, char** repl, char* yytext){
    int choice = rand() % 3;
    switch(choice) {
        case 0:      // string null
            strncpy(*repl, "\"\"", 1024);
            break;
        case 1:      // string "\0"    
            strncpy(*repl, "\"\0\"", 1024);
            break;
        /*case 2:{
            int str_len = rand()%500+4;
            char random_str[512];//char *random_str=(char*)malloc(sizeof(char)*str_len);
            random_str[0]='\"';
            random_str[str_len-1]='\"';
            random_str[str_len]='\0';
            for(int i = 1;i<=str_len-2;i++){
                random_str[i]=(rand()%126+1);
            }
            strncpy(*repl, random_str, 1024);
            //free(random_str);
            
            break;}*/
    }
} 


void char_mutate(char** origin, char** repl, char* yytext){
    int choice = rand() % 2;
    switch(choice) {
        case 0:      // ""    
            strncpy(*repl, "\'\'", 1024);
            break;
        case 1:      // "/0"      
            strncpy(*repl, "\'\\0\'", 1024);
            break;
        case 2:     //random ascii
            	     {
            	     char random_char[5];//=(char*)malloc(sizeof(char)*5);
            random_char[0] = '\'';
            random_char[1] = rand()%128;
            random_char[2] = '\'';
            random_char[3] = '\0';
            strncpy(*repl, random_char, 1024);
            //free(random_char);
            break;
            		}
    }
}

/* 处理多行注释 */
int comment(void) {
	char c, prev = 0;
    cur_pos += 2;
    // input() 为 flex 内置函数，用于让扫描指针前进一个字符
	while((c = input()) != 0)      /* (EOF maps to 0) */
	{
		cur_pos++;
        if(c == '/' && prev == '*') return 1;

		prev = c;
	}
	// 未找到 */，源代码存在语法错误，变异失败
    return 0;
}

/* 简单处理宏定义 */
int macro(void) {
    char c, prev = '\\';
    cur_pos += strlen(yytext);

    if(yytext[strlen(yytext) - 1] != '\\') return 1;

    while((c = input()) != 0)
    {
        cur_pos++;
        if(c == '\n') {
            if(prev == '\\') cur_line_num++;
            else return 1;
        }
        prev = c;
    }
    return 0;
}

int yywrap(void) {
    return 1;
}
