// +build enablecgo

package main

/*
int dummy(void) { return 42; }
*/
import "C"

func init() {
	C.dummy()
}
