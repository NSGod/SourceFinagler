//
//  TKBase.m
//  Texture Kit
//
//  Created by Mark Douma on 10/31/2011.
//  Copyright (c) 2010-2013 Mark Douma LLC. All rights reserved.
//


#import <TextureKit/TKBase.h>


NSNumber * TKYES = nil;
NSNumber * TKNO = nil;


__attribute__((constructor)) static void TKInitBase() {
	TKYES = [[NSNumber numberWithBool:YES] retain];
	TKNO = [[NSNumber numberWithBool:NO] retain];
}
