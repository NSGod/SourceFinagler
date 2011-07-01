//
//  MDSelfExpandingTextField.m
//  Source Finagler
//
//  Created by Mark Douma on 7/19/2009.
//  Copyright 2009 Mark Douma. All rights reserved.
//

#import "MDSelfExpandingTextField.h"
#import "MDInspectorView.h"


#pragma mark view
#define MD_DEBUG 0



@interface MDSelfExpandingTextField (Private)
- (void)changeWindowHeightBy:(CGFloat)value;
@end


@implementation MDSelfExpandingTextField

- (id)initWithFrame:(NSRect)frame {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    if ((self = [super initWithFrame:frame])) {
		NSUInteger lineBreakMode = [[self cell] lineBreakMode];
		
		NSLog(@"lineBreakMode == %lu", (unsigned long)lineBreakMode);
		
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)coder {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		NSUInteger lineBreakMode = [[self cell] lineBreakMode];
		
		NSLog(@"lineBreakMode == %lu", (unsigned long)lineBreakMode);
		
	}
	return self;
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)awakeFromNib {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:[self window]];
//	[self setPostsFrameChangedNotifications:YES];
	
}



- (void)windowDidResize:(NSNotification *)notification {
	if ([notification object] == [self window]) {
#if MD_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		[self setStringValue:[self stringValue]];
	}
}


/*  Notifications  */
- (void)inspectorViewWillShow:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}

- (void)inspectorViewDidShow:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self setStringValue:[self stringValue]];
}



static NSTextStorage *textStorage = nil;
static NSLayoutManager *layoutManager = nil;
static NSTextContainer *textContainer = nil;

- (void)setStringValue:(NSString *)aValue {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (textStorage == nil) {
		textStorage = [[NSTextStorage alloc] initWithString:aValue];
		textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize([self frame].size.width, FLT_MAX)] autorelease];
		layoutManager = [[[NSLayoutManager alloc] init] autorelease];
		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		[textContainer setLineFragmentPadding:0.0];
		[textStorage addAttribute:NSFontAttributeName value:[[self cell] font] range:NSMakeRange(0, [textStorage length])];
		[layoutManager setUsesFontLeading:NO];
		NSInteger typesetterBehavior = [layoutManager typesetterBehavior];
		NSLog(@"[%@ %@] typesetterBehavior == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)typesetterBehavior);
	
	}
	
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:aValue];
	[textContainer setContainerSize:NSMakeSize(NSWidth([self frame]), FLT_MAX)];
	
	(void)[layoutManager glyphRangeForTextContainer:textContainer];
	
	NSRect usedRect = [layoutManager usedRectForTextContainer:textContainer];
	
	NSRect frameBefore = [self frame];
	
	CGFloat newHeight = 14.0 * ceil(usedRect.size.height/14.0);
	
	CGFloat difference = newHeight - [self frame].size.height;
	
	if (inspectorView && [inspectorView isShown]) {
		[inspectorView changeWindowHeightBy:difference];
	}
	
	NSRect newFrame = [self frame];
	newFrame.size.height = newHeight;
	newFrame.origin = frameBefore.origin;
	
	[self setFrame:newFrame];
	
	[super setStringValue:aValue];
}
	
	
@end
