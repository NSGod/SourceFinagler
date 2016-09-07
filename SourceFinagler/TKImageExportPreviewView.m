//
//  TKImageExportPreviewView.m
//  Source Finagler
//
//  Created by Mark Douma on 7/17/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageExportPreviewView.h"

//#define TK_DEBUG 1
#define TK_DEBUG 0

@implementation TKImageExportPreviewView

@synthesize delegate;
@synthesize viewController;

@dynamic isHighlighted;


- (id)initWithFrame:(NSRect)frame {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    if ((self = [super initWithFrame:frame])) {
		
    }
    return self;
}

- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	delegate = nil;
	viewController = nil;
	[super dealloc];
}


- (BOOL)acceptsFirstResponder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return YES;
}


- (BOOL)becomeFirstResponder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (delegate && [delegate respondsToSelector:@selector(didSelectImageExportPreviewView:)]) {
		[delegate didSelectImageExportPreviewView:self];
	}
	[self setHighlighted:YES];
	return YES;
}


- (BOOL)resignFirstResponder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self setHighlighted:NO];
	return YES;
}



- (BOOL)isHighlighted {
	return isHighlighted;
}


- (void)setHighlighted:(BOOL)aHighlighted {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	isHighlighted = aHighlighted;
	[self setNeedsDisplay:YES];
}


// this method needs work, I believe
- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];
	if (isHighlighted) {
		if (!NSEqualRects(dirtyRect, [self frame])) return;
		
		[[NSColor keyboardFocusIndicatorColor] set];
		[NSBezierPath setDefaultLineWidth:6.0];
		[NSBezierPath strokeRect:dirtyRect];
	}
}



@end
