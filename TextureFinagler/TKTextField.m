//
//  TKTextField.m
//  Source Finagler
//
//  Created by Mark Douma on 10/10/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import "TKTextField.h"

#define TK_DEBUG 0


@implementation TKTextField


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (void)awakeFromNib {
 #if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:[self window]];

}


- (void)windowDidBecomeMain:(NSNotification *)notification {
	[self setNeedsDisplay:YES];
}

- (void)windowDidResignMain:(NSNotification *)notification {
	[self setNeedsDisplay:YES];
}



@end
