//
//  MDCopyOperationView.m
//  Copy Progress Window
//
//  Created by Mark Douma on 4/4/2006.
//  Copyright (c) 2006 Mark Douma. All rights reserved.
//


#import "MDCopyOperationView.h"


#define MD_DEBUG 0

#define MD_COPY_OPERATION_VIEW_WIDTH 400.0
#define MD_COPY_OPERATION_VIEW_HEIGHT 68.0


@implementation MDCopyOperationView

@synthesize tag, separatorView;
@dynamic colorType;


- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
		whiteColor = [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0] retain];
		alternateColor = [[NSColor colorWithCalibratedRed:246.0/255.0 green:247.0/255.0 blue:249.0/255.0 alpha:1.0] retain];
		colorType = MDWhiteBackgroundColorType;

    }
    return self;
}

- (void)dealloc {
	[separatorView release];
	[lock release];
	[whiteColor release];
	[alternateColor release];
	[super dealloc];
}


+ (NSSize)copyOperationViewSize {
	return NSMakeSize(MD_COPY_OPERATION_VIEW_WIDTH, MD_COPY_OPERATION_VIEW_HEIGHT);
}

- (BOOL)isOpaque {
	return YES;
}

- (void)setColorType:(MDCopyOperationViewBackgroundColorType)value {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (lock == nil) lock = [[NSLock alloc] init];
	[lock lock];
	colorType = value;
	[lock unlock];
	[self setNeedsDisplay:YES];
}

- (MDCopyOperationViewBackgroundColorType)colorType {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	MDCopyOperationViewBackgroundColorType rColorType = 0;
	if (lock == nil) lock = [[NSLock alloc] init];
	[lock lock];
	rColorType = colorType;
	[lock unlock];
	return rColorType;
}


- (void)switchColorType {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self setColorType:[self colorType] == MDWhiteBackgroundColorType ? MDAlternateBackgroundColorType : MDWhiteBackgroundColorType];
}


- (void)drawRect:(NSRect)rect {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	// either white or 240 240 240
	// line is 184++
	
	if (colorType == MDWhiteBackgroundColorType) {
		[whiteColor set];
	} else {
		[alternateColor set];
	}

	[NSBezierPath fillRect:rect];
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@", [super description]];
	[description appendFormat:@" - (%ld)", (long)tag];
	if (separatorView) [description appendFormat:@"; ^__separator"];
//	[description appendFormat:@", separatorView == %@", separatorView];
	return description;
}


@end
