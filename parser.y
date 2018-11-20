%{
	#include<stdio.h>
	#include<stdlib.h>
	
	void yyerror(int code);
	void printError(int code);
	extern int line_no;
	void context_check(char *name);
	void install(char *name);
	void printSymbolTable();
	extern char lastID[100];

%}

%start program
%token PROG BEG END INTEGER IDENTIFIER IF THEN ELSE ENDIF WHILE DO ENDWHILE READ WRITE NUMBER ASSIGN DOT COMMA SEMI_COLON

%right '='
%left '<' '>'
%left '+' '-'
%left '/' '*'

%%

program 	
	: PROG declarations BEG command_sequence END 
	;
declarations
	:  
	| INTEGER id_seq IDENTIFIER {install(lastID);} DOT
	;
id_seq
	:  
	| id_seq IDENTIFIER{install(lastID);} COMMA 
	;
command_sequence
	:  
	| command_sequence command SEMI_COLON
	;
command
	:  
	| IDENTIFIER ASSIGN expression {context_check(lastID);}
	| IF expression THEN command_sequence ELSE command_sequence ENDIF 
	| WHILE expression DO command_sequence ENDWHILE 
	| READ IDENTIFIER {context_check(lastID);}
	| WRITE expression 
	;
expression
	: NUMBER 
	| IDENTIFIER {context_check(lastID);}
	| '(' expression ')' 
	| expression '+' expression 
	| expression '*' expression 
	| expression '-' expression 
	| expression '/' expression 
	| expression '=' expression 
	| expression '<' expression 
	| expression '>' expression 
	;

%%


void main()
{
	
		yyparse();
		printf("successfully parsed...\n\n");
		printSymbolTable();
}
void yyerror(int code)
{
	printf("error %d at line no %d \n" , code , line_no);
	printError(code);
	exit(0);
}

void printError(int code){

	printf("Error %d : ", code);

	switch(code){

		case 2	:	printf("Redefinition of variable\n");
					break;
		case 3	:	printf("Use of undefined variable\n");
					break;

		default	:	printf("Invalid symbol\n");
	}
}