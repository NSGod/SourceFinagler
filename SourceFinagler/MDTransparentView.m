//
//  MDTransparentView.m
//  Source Finagler
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDTransparentView.h"


@implementation MDTransparentView

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
		
    }
    return self;
}

- (BOOL)isOpaque {
	return NO;
}

- (void)drawRect:(NSRect)frame {
	[[NSColor clearColor] set];
	[NSBezierPath fillRect:frame];

}

- (BOOL)mouseDownCanMoveWindow {
	return YES;
}

@end
