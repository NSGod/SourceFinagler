//
//  MDStatusImageView.m
//  Source Finagler
//
//  Created by Mark Douma on 2/5/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//	



#import "MDStatusImageView.h"


#define MD_DISABLED_OPACITY 0.41


@interface MDStatusImageView (MDPrivate)
- (void)finishSetup;
@end


@implementation MDStatusImageView


- (id)initWithFrame:(NSRect)aFrame {
	if ((self = [super initWithFrame:aFrame])) {
		[self finishSetup];
	} else {
		[self release];
		return nil;
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder])) {
		[self finishSetup];
	}
	return self;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self removeAllToolTips];
	[super dealloc];
}


- (void)finishSetup {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:[self window]];
}


- (void)windowDidBecomeMain:(NSNotification *)notification {
	if ([notification object] == [self window]) {
		[self setNeedsDisplay:YES];
	}
}


- (void)windowDidResignMain:(NSNotification *)notification {
	if ([notification object] == [self window]) {
		[self setNeedsDisplay:YES];
	}
}


- (void)drawRect:(NSRect)rect {
	if (self.image && ![self.window isMainWindow]) {
		[[self image] drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:MD_DISABLED_OPACITY];
		
	} else {
		[super drawRect:rect];
	}
}


- (BOOL)mouseDownCanMoveWindow {
	return YES;
}


@end

