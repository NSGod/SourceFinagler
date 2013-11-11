//
//  MDStatusImageView.m
//  Source Finagler
//
//  Created by Mark Douma on 2/5/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//	



#import "MDStatusImageView.h"


#define MD_DISABLED_OPACITY 0.41

#define MD_DEBUG 0


@interface MDStatusImageView (Private)
- (void)finishSetup;
@end


@implementation MDStatusImageView


- (id)initWithFrame:(NSRect)aFrame {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	if ((self = [super initWithFrame:aFrame])) {
		[self finishSetup];
	} else {
		[self release];
		return nil;
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	if ((self = [super initWithCoder:coder])) {
		[self finishSetup];
	}
	return self;
}


- (void)dealloc {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self removeAllToolTips];
	[super dealloc];
}


- (void)finishSetup {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:[self window]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:[self window]];
	
}

- (void)awakeFromNib {
	NSTrackingArea *tracker = [[[NSTrackingArea alloc] initWithRect:[self frame] options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil] autorelease];
	[self addTrackingArea:tracker];
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	if ([notification object] == [self window]) {
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseEntered:(NSEvent *)theEvent {

}

- (void)mouseExited:(NSEvent *)theEvent {
	
}


- (void)windowDidResignMain:(NSNotification *)notification {
	
	if ([notification object] == [self window]) {
		[self setNeedsDisplay:YES];
	}
}



- (void)drawRect:(NSRect)rect {
	if ([self image]) {
		if ([[self window] isMainWindow]) {
			[super drawRect:rect];
//			[[self image] drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		} else {
			[[self image] drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:MD_DISABLED_OPACITY];
		}
	} else {
		[super drawRect:rect];
	}
}



- (BOOL)mouseDownCanMoveWindow {
	return YES;
}



@end















