//
//  TKTextFieldCell.m
//  Source Finagler
//
//  Created by Mark Douma on 10/10/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import "TKTextFieldCell.h"

@interface TKTextFieldCell (TKPrivate)
- (void)finishSetup;
@end

#define TK_DEBUG 0


static NSDictionary *activeAttributes = nil;
static NSDictionary *inactiveAttributes = nil;


@implementation TKTextFieldCell

+ (void)initialize {
	@synchronized(self) {
		if (activeAttributes == nil && inactiveAttributes == nil) {
			NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
			[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
			[shadow setShadowColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
			
			activeAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName,
								 [NSColor colorWithCalibratedRed:112.0/255.0 green:126.0/255.0 blue:140.0/255 alpha:1.0],NSForegroundColorAttributeName,
								 shadow,NSShadowAttributeName, nil] retain];
			
			inactiveAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName,
								 [NSColor colorWithCalibratedRed:134.0/255.0 green:139.0/255.0 blue:146.0/255 alpha:1.0],NSForegroundColorAttributeName,
								 shadow,NSShadowAttributeName, nil] retain];
		}
	}
}
	
- (id)initTextCell:(NSString *)aString {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initTextCell:aString])) {
		[self finishSetup];
	}
	return self;
}


- (void)dealloc {
	[richText release];
	[super dealloc];
}


- (id)initWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		[self finishSetup];
	}
	return self;
}



- (void)finishSetup {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	richText = [[NSMutableAttributedString alloc] initWithString:[self stringValue] attributes:([[[self controlView] window] isMainWindow] ? activeAttributes : inactiveAttributes)];
	[self setAttributedStringValue:richText];
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	([[controlView window] isMainWindow] ? [richText setAttributes:activeAttributes range:NSMakeRange(0, [richText length])] :
	 [richText setAttributes:inactiveAttributes range:NSMakeRange(0, [richText length])]);
	
	[self setAttributedStringValue:richText];
	
	[super drawWithFrame:cellFrame inView:controlView];
	
}




@end






