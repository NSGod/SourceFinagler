//
//  TKImageExportTextField.m
//  Source Finagler
//
//  Created by Mark Douma on 8/2/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageExportTextField.h"

#define TK_DEBUG 1

@implementation TKImageExportTextField

- (void)mouseDown:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[self window] makeFirstResponder:[self superview]];
	[super mouseDown:event];
}


@end
