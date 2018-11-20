%{
	#include "y.tab.h"
	#include<string.h>

	int input_line_no = 1;
	int data_offset = 0;
	char lastID[100];

	struct sym_rec{

		char *name;
		struct sym_rec *next;
		int data_offset;
	};

	struct sym_rec* put_symbol(char * name); //puts an identifier into the table.
	struct sym_rec* get_symbol(char * name); //returns a pointer to the symbol table entry or a NULL pointer if not found.
	void install(char *name);//installs a symbol into the symbol table if it is not in the symbol table using the above two functions.
							 //Reports appropriate error messages.
	void context_check(char *name);//checks the contest sensitive requirement of our language and if violated appropriate error messages.
	void printSymbolTable();
	struct sym_rec* HEAD = 0;
%}

%array


%%
[\n]		{input_line_no++;}
[\t\s]		{;}
"prog"		{return PROG;}
"begin"		{return BEG;}
"end"		{return END;}
"integer" 	{return INTEGER;}
":="		{return ASSIGN;}
"if"		{return IF;}
"then"		{return THEN;}
"else"		{return ELSE;}
"endif"		{return ENDIF;}
"while"		{return WHILE;}
"do"		{return DO;}
"endwhile"	{return ENDWHILE;}
"read"		{return READ;}
"write"		{return WRITE;}
"."			{return DOT;}
","			{return COMMA;}
";"			{return SEMI_COLON;}
"+"			{return '+';}
"-"			{return '-';}
"*"			{return '*';}
"/"			{return '/';}
"="			{return '=';}
"<"			{return '<';}
">"			{return '>';}
"("			{return '(';}
")"			{return ')';}
[a-zA-Z][a-zA-Z0-9_]* 		{
								strcpy(lastID,yytext);
								
								struct sym_rec *p = get_symbol(yytext);
								if(p != 0)
									yylval = (p->data_offset)/4;	

								return IDENTIFIER;
							}
[0-9]+		{yylval = atoi(yytext); return NUMBER;}
.			{;}

%%

int yywrap(void)
{
	{return 1;}
}

struct sym_rec* get_symbol(char * name){

	struct sym_rec* cur = HEAD;

	while(cur != 0){

		if( strcmp(name , cur->name) == 0)
			break;

		cur = cur->next;
	}

	return cur;
}

struct sym_rec* put_symbol(char * name){

	struct sym_rec* new_node = (struct sym_rec*)malloc(sizeof(struct sym_rec));

	new_node->next = 0;
	new_node->name = (char*)malloc(sizeof(name));

	strcpy(new_node->name , name);

	new_node->data_offset = data_offset;
	data_offset += 4;

	if(HEAD == 0)
		HEAD = new_node;

	else{

		struct sym_rec* last = HEAD;

		while(last->next != 0)
			last = last->next;

		last->next = new_node;
		
	}

	return new_node;
}

void install(char *name){

	if(get_symbol(name) == 0)
		put_symbol(name);
	
	else
		yyerror(2);
}

void context_check(char *name){

	if(get_symbol(name) == 0)
		yyerror(3);
}

void printSymbolTable(){

	struct sym_rec *cur = HEAD;

	printf("Symbol Table : \n==============\n");

	while(cur != 0){

		printf("%s\t%d\n" , cur->name , cur->data_offset);
		cur = cur->next;
	}
}
