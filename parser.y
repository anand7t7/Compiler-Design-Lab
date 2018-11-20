%{
	#include<stdio.h>
	#include<stdlib.h>
	
	void yyerror(int code);
	void printError(int code);
	void write_machine_code();
	extern int line_no;
	void context_check(char *name);
	void install(char *name);
	void printSymbolTable();
	extern char lastID[100];
	extern int data_offset;
	extern struct sym_rec;
	struct sym_rec* get_symbol(char *name);

	char machine_code[1000];
	int  pos = 0;

	struct stack_node{

		int pos;
		struct stack_node* next;
	};

	stack_node *stack_top = 0;

	void push(int pos);
	int  pop();


%}

%start program
%token PROG BEG END INTEGER IDENTIFIER IF THEN ELSE ENDIF WHILE DO ENDWHILE READ WRITE NUMBER ASSIGN DOT COMMA SEMI_COLON

%right '='
%left '<' '>'
%left '+' '-'
%left '/' '*'

%%

program 	
	: PROG declarations 	{pos += sprintf( machine_code+pos , "res\t\t%d\n" , data_offset/4);} 
	  BEG command_sequence END {pos += sprintf(machine_code+pos , "halt\t\t0\n");}
	;
declarations
	:  
	| INTEGER id_seq IDENTIFIER 	{install(lastID);} 
	  DOT
	;
id_seq
	:  
	| id_seq IDENTIFIER		{install(lastID);} 
	  COMMA 
	;
command_sequence
	:  
	| command_sequence command SEMI_COLON
	;
command
	:  
	| IDENTIFIER ASSIGN expression 	{
										context_check(lastID);

										pos += sprintf(machine_code+pos , "store\t\t%d\n" , $3);
									}
	| IF expression THEN 			{
										pos += sprintf(machine_code+pos , "jmp_false\tL1\n");
									}
	 command_sequence				{
										pos += sprintf(machine_code+pos , "goto\t\tL2\n");
									} 
	 ELSE command_sequence ENDIF 

	| WHILE expression DO			{
										pos += sprintf(machine_code+pos , "jmp_false\tL2\n");
									}
	 command_sequence				{
		 								pos += sprintf(machine_code+pos , "goto\t\tL1\n");
	 								} 
	 
	 ENDWHILE 

	| READ IDENTIFIER 				{
										context_check(lastID);

										pos += sprintf(machine_code+pos , "read\t\t%d\n" , $2);
									}
	| WRITE expression 				{
										pos += sprintf(machine_code+pos , "write\t\t0\n");
									}
	;
expression
	: NUMBER		{
						pos += sprintf(machine_code+pos , "load_int\t%d\n" , $1);

						$$ = $1;
					}
	| IDENTIFIER 	{
						context_check(lastID);

						pos += sprintf(machine_code+pos , "load_var\t%d\n" , $1);

						$$ = $1;
						
					}

	| '(' expression ')'	{

								$$ = $2;
							}

	| expression '+' expression	{

									pos += sprintf(machine_code+pos , "add\t\t0\n");
								} 	
	| expression '*' expression {

									pos += sprintf(machine_code+pos , "mul\t\t0\n");
								}
	| expression '-' expression {

									pos += sprintf(machine_code+pos , "sub\t\t0\n");
								}
	| expression '/' expression {

									pos += sprintf(machine_code+pos , "div\t\t0\n");
								}
	| expression '=' expression {

									pos += sprintf(machine_code+pos , "eq\t\t0\n");
								}
	| expression '<' expression {

									pos += sprintf(machine_code+pos , "lt\t\t0\n");
								}
	| expression '>' expression {

									pos += sprintf(machine_code+pos , "gt\t\t0\n");
								}
	;

%%


void main()
{
	
		yyparse();

		printf("successfully parsed...\n\n");
		
		printSymbolTable();
		write_machine_code();
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

		default	:	printf("Unknown error\n");
		
	}
}

void write_machine_code(){

	printf("\nStack Machine Code : \n\n%s\n" , machine_code);
}

void push(int pos){

	struct stack_node *node = (struct stack_node*)malloc(sizeof(struct stack_node));

	node->pos = pos;
	node->next = stack_top;
	stack_top = node;
}

int pop(){

	if(stack_top == 0)
		return -1;

	int pos = stack_top->pos;
	struct stack_node* node = stack_top;

	stack_top = stack_top->next;

	free(node);

	return pos;
}