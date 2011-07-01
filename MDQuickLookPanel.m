//
//  MDQuickLookPanel.m
//  Source Finagler
//
//  Created by Mark Douma on 10/1/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDQuickLookPanel.h"

#define MD_DEBUG 0


@implementation MDQuickLookPanel


- (void)keyDown:(NSEvent *)theEvent {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *characters = [theEvent characters];
	if ([characters isEqualToString:@" "]) {
		[self performClose:self];
	} else {
		[super keyDown:theEvent];
	}
}


@end
