#include <stdio.h>

int main(void) {
    char name[32];
    printf("Enter your name: ");
    fgets(name, sizeof(name), stdin);
    printf("Hello, %s!\n", name);
    return 0;
}
