%{
	#include<stdio.h>
	#include<stdlib.h>
	
	void yyerror(int code);
	void printError(int code);
	void write_machine_code();
	void write_machine_code_to_file(const char*);
	extern int input_line_no;
	void context_check(char *name);
	void install(char *name);
	void printSymbolTable();
	extern char lastID[100];
	extern int data_offset;
	extern struct sym_rec;
	struct sym_rec* get_symbol(char *name);

	char machine_code[1000];
	int  pos = 0;
	int output_line_no = 1;

	struct stack_node{

		int pos;
		struct stack_node* next;
	};

	struct stack_node *stack_top = 0;

	void push(int pos);
	int  pop();
	void replace(char str[], int pos , int n);


%}

%start program
%token PROG BEG END INTEGER IDENTIFIER IF THEN ELSE ENDIF WHILE DO ENDWHILE READ WRITE NUMBER ASSIGN DOT COMMA SEMI_COLON

%right '='
%left '<' '>'
%left '+' '-'
%left '/' '*'

%%

program 	
	: PROG declarations 		{
									pos += sprintf( machine_code+pos , "res\t\t%d\n" , data_offset/4);
									output_line_no++;
								} 
	  BEG command_sequence END  {
		  							pos += sprintf(machine_code+pos , "halt\t\t0\n");
									output_line_no++;
								}
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
										
										pos += sprintf(machine_code+pos , "store\t\t%d\n" , $1);
										output_line_no++;
									}
	| IF expression THEN 			{
										push(pos + 11);
										pos += sprintf(machine_code+pos , "jmp_false\t\t000\n");
										output_line_no++;
									}
	 command_sequence				{
		 								replace(machine_code , pop() , output_line_no+1);
										push(pos + 6);
										pos += sprintf(machine_code+pos , "goto\t\t000\n");
										output_line_no++;
									} 
	 ELSE command_sequence ENDIF	{
		 								replace(machine_code , pop() , output_line_no);
									}

	| WHILE 						{
										push(output_line_no);
									}
	 expression DO					{	
		 								push(pos + 11);
										pos += sprintf(machine_code+pos , "jmp_false\t\t000\n");
										output_line_no++;
									}
	 command_sequence				{	
		 								int rep_pos = pop();
		 								pos += sprintf(machine_code+pos , "goto\t\t%03d\n" , pop());
										output_line_no++;

										replace(machine_code , rep_pos , output_line_no);
	 								} 
	 
	 ENDWHILE 

	| READ IDENTIFIER 				{
										context_check(lastID);

										pos += sprintf(machine_code+pos , "read\t\t%d\n" , $2);
										output_line_no++;
									}
	| WRITE expression 				{
										pos += sprintf(machine_code+pos , "write\t\t0\n");
										output_line_no++;
									}
	;
expression
	: NUMBER		{
						pos += sprintf(machine_code+pos , "load_int\t\t%d\n" , $1);
						output_line_no++;

						$$ = $1;
					}
	| IDENTIFIER 	{
						context_check(lastID);

						pos += sprintf(machine_code+pos , "load_var\t\t%d\n" , $1);
						output_line_no++;

						$$ = $1;
						
					}

	| '(' expression ')'	{

								$$ = $2;
							}

	| expression '+' expression	{

									pos += sprintf(machine_code+pos , "add\t\t0\n");
									output_line_no++;
								} 	
	| expression '*' expression {

									pos += sprintf(machine_code+pos , "mul\t\t0\n");
									output_line_no++;
								}
	| expression '-' expression {

									pos += sprintf(machine_code+pos , "sub\t\t0\n");
									output_line_no++;
								}
	| expression '/' expression {

									pos += sprintf(machine_code+pos , "div\t\t0\n");
									output_line_no++;
								}
	| expression '=' expression {

									pos += sprintf(machine_code+pos , "eq\t\t0\n");
									output_line_no++;
								}
	| expression '<' expression {

									pos += sprintf(machine_code+pos , "lt\t\t0\n");
									output_line_no++;
								}
	| expression '>' expression {

									pos += sprintf(machine_code+pos , "gt\t\t0\n");
									output_line_no++;
								}
	;

%%


void main()
{
	
		yyparse();

		printf("successfully parsed...\n\n");
		
		printSymbolTable();
		write_machine_code();
		write_machine_code_to_file("machine_code");

}
void yyerror(int code)
{
	printf("error %d at line no %d \n" , code , input_line_no);
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

	int line_no = 0;

	printf("\nStack Machine Code : \n\n" );

	for(int i = 0 ; machine_code[i] != '\0' ; i++){

		if(i == 0 || machine_code[i-1] == '\n'){

			line_no++;

			printf("%03d : ", line_no);
		}

		printf("%c",machine_code[i]);
	}
}

void write_machine_code_to_file(const char* filename){

	FILE *output = fopen(filename , "w");

	fprintf(output , "%s", machine_code);

	fclose(output);
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

void replace(char str[] , int pos , int n){

	str[pos]   = n/100 + '0';
	str[pos+1] = (n%100) / 10 + '0';
	str[pos+2] = (n%10) + '0';
}