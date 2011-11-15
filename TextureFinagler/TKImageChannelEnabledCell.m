//
//  TKImageChannelEnabledCell.m
//  Source Finagler
//
//  Created by Mark Douma on 10/29/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageChannelEnabledCell.h"

#define TK_DEBUG 1

@implementation TKImageChannelEnabledCell




- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	if ([self state] == NSOnState) {
		[super drawInteriorWithFrame:cellFrame inView:controlView];
		
	} else if ([self state] == NSOffState) {
		[[NSColor whiteColor] set];
		[NSBezierPath fillRect:cellFrame];
	}
	
}




@end
