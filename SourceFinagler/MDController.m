//
//  MDController.m
//  Source Finagler
//
//  Created by Mark Douma on 3/02/2006.
//  Copyright © 2006 Mark Douma. All rights reserved.
//  


#import "MDController.h"

#define VS_DEBUG 0

@implementation MDController


- (id)init {
	if ((self = [super init])) {
		resizable = NO;
		
		minWinSize = NSZeroSize;
		maxWinSize = NSZeroSize;
	}
	return self;
}


- (void)dealloc {
//	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)appControllerDidLoadNib:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}

- (void)didSwitchToView:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (resizable) {
		
		[[[self view] window] setShowsResizeIndicator:YES];
		
		[[[self view] window] setMinSize:minWinSize];
		[[[self view] window] setMaxSize:maxWinSize];
		
		[[[[self view] window] standardWindowButton:NSWindowZoomButton] setEnabled:YES];
		
	} else {
		
		NSSize minSize = NSZeroSize;
		NSSize maxSize = NSZeroSize;
		
		NSRect viewFrame = [view frame];
		
		minSize = NSMakeSize(NSWidth(viewFrame), NSHeight(viewFrame) + 22.0);
		maxSize = NSMakeSize(NSWidth(viewFrame), NSHeight(viewFrame) + 22.0);
		
		[[[self view] window] setShowsResizeIndicator:NO];
		
		[[[self view] window] setMinSize:minSize];
		[[[self view] window] setMaxSize:maxSize];
		
		[[[[self view] window] standardWindowButton:NSWindowZoomButton] setEnabled:NO];
		
	}
	
	
}



- (NSView *)view {
	return view;
}


- (void)cleanup {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}



@end


