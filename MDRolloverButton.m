//
//  MDRolloverButton.m
//  Copy Progress Window
//
//  Created by Mark Douma on 4/4/2006.
//  Copyright (c) 2006 Mark Douma. All rights reserved.
//


#import "MDRolloverButton.h"

#define MD_DEBUG 0

@implementation MDRolloverButton



- (void)awakeFromNib {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSTrackingArea *trackingArea = [[[NSTrackingArea alloc] initWithRect:[self visibleRect]
																 options:NSTrackingMouseEnteredAndExited | NSTrackingInVisibleRect | NSTrackingActiveAlways
																   owner:self
																userInfo:nil] autorelease];
	
	[self addTrackingArea:trackingArea];
	
}

- (void)mouseEntered:(NSEvent *)theEvent {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self setImage:[NSImage imageNamed:@"cancelRoll"]];
	[self setNeedsDisplay:YES];
	
	if (delegate && [delegate respondsToSelector:@selector(mouseDidEnterRolloverButton:)]) {
		[delegate mouseDidEnterRolloverButton:self];
	}
	
}



- (void)mouseExited:(NSEvent *)theEvent {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self setImage:[NSImage imageNamed:@"cancel"]];
	[self setNeedsDisplay:YES];
	
	if (delegate && [delegate respondsToSelector:@selector(mouseDidExitRolloverButton:)]) {
		[delegate mouseDidExitRolloverButton:self];
	}
	
}




@end
