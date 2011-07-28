//
//  MDStash.m
//  Source Finagler
//
//  Created by Mark Douma on 11/1/2008.
//  Copyright 2008 Mark Douma. All rights reserved.
//

#import "MDStash.h"



#define BASE 65521L /* largest prime smaller than 65536 */
#define NMAX 5552 /* NMAX is the largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1 */
#define DO1(buf, i)  {s1 += buf[i]; s2 += s1;}
#define DO2(buf, i)  DO1(buf, i); DO1(buf, i + 1);
#define DO4(buf, i)  DO2(buf, i); DO2(buf, i + 2);
#define DO8(buf, i)  DO4(buf, i); DO4(buf, i + 4);
#define DO16(buf)   DO8(buf, 0); DO8(buf, 8);


UInt32 MDMakeStash(const char *string) {
	if (string) {
		int len = strlen(string);
		int k;
		UInt32 s1 = len * 0x0101;
		UInt32 s2 = s1 ^ 0xffff;
		while (len > 0) {
			k = len < NMAX ? len : NMAX;
			len -= k;
			while (k >= 16) {
				DO16(string);
				string += 16;
				k -= 16;
			}
			
			if (k != 0) do {
				s1 += *string++;
				s2 += s1;
			} while (--k);
			s1 %= BASE;
			s2 %= BASE;
		}
		return (s2 << 16) | s1;
	}
	return 0;
}
