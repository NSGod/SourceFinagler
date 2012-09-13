//
//  MDPathControlView.m
//  Source Finagler
//
//  Created by Mark Douma on 7/10/2009.
//  Copyright 2009 Mark Douma. All rights reserved.
//

#import "MDPathControlView.h"


@implementation MDPathControlView

//- (id)initWithFrame:(NSRect)frame {
//    if (self = [super initWithFrame:frame]) {
//		
//        // Initialization code here.
//    }
//    return self;
//}

- (void)drawRect:(NSRect)rect {
	[super drawRect:rect];
	
	[[NSColor colorWithCalibratedRed:142.0/255.0 green:142.0/255.0 blue:142.0/255.0 alpha:1.0] set];
	
//	[[NSColor colorWithCalibratedRed:165.0/255.0 green:165.0/255.0 blue:165.0/255.0 alpha:1.0] set];
//	[[NSColor colorWithCalibratedRed:255.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0] set];
	[NSBezierPath setDefaultLineWidth:2.0];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, rect.origin.y + (rect.size.height - 1.0)) toPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + (rect.size.height - 1.0))];
	
}

@end
