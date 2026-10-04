/* gcc -shared -fPIC -o gu.so gu.c
 * then: cp ~/level13 /tmp/l13 && LD_PRELOAD=/tmp/gu.so /tmp/l13
 * the binary wants uid 4242, nobody is 4242, so we just say we are :P */
int getuid(void) { return 4242; }
