#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LEN 34			/* maximal input string size */

extern void assFunc(int x, int y);
char c_checkValidity(int x, int y);

int main(int argc, char** argv){

    int x, y;
    char s_x[MAX_LEN];
    char s_y[MAX_LEN];

    fgets(s_x, MAX_LEN, stdin);
    fgets(s_y, MAX_LEN, stdin);
    sscanf(s_x, "%u", &x);
    sscanf(s_y, "%u", &y);

    assFunc(x, y);

    return 0;
}

char c_checkValidity(int x, int y){
    if(x >= y){
        return '1';
    }
    return '0';
}


