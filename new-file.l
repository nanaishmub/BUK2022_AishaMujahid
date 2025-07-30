%{
	#include<stdio.h>
%}

%% //rule section
if |
else |
printf {printf("%s is a keyword", yytext);} //checks and matches keywords
[0-9]+ {printf("%s is a number", yytext);} //checks and matches numbers
[a-zA-Z]+ {printf("%s is a word", yytext);} //checks and matches words (leters in caps or not)
. |\n {ECHO;} // default statement runs when the first 3 do not match ECHO tells the computer to skip
%%

int main()
{
	printf("\n Enter the string: ");
	yylex();// this section passes the input entered above into the rule section
    return 0;
}

int yywrap()
{
	return 1;
} 