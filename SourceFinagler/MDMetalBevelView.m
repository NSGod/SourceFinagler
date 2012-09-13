//
//  MDMetalBevelView.m
//  Source Finagler
//
//  Created by Mark Douma on 4/4/2006.
//  Copyright © 2007 Mark Douma. All rights reserved.
//



#import "MDMetalBevelView.h"


#define MD_DEBUG 0

enum {
	MDUndeterminedVersion	= -1,
	MDCheetah				= 0x1000,
	MDPuma					= 0x1010,
	MDJaguar				= 0x1020,
	MDPanther				= 0x1030,
	MDTiger					= 0x1040,
	MDLeopard				= 0x1050,
	MDSnowLeopard			= 0x1060,
	MDLion					= 0x1070,
	MDMountainLion			= 0x1080,
	MDUnknownKitty			= 0x1090,
	MDUnknownVersion		= 0x1100
};


static SInt32 MDMetalBevelViewSystemVersion = 0;

@implementation MDMetalBevelView

+ (void)initialize {
	SInt32 MDFullSystemVersion = 0;
	Gestalt(gestaltSystemVersion, &MDFullSystemVersion);
	MDMetalBevelViewSystemVersion = MDFullSystemVersion & 0xfffffff0;
}


- (id)initWithFrame:(NSRect)frame {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
	if ((self = [super initWithFrame:frame])) {
		drawsBackground = NO;
	}
    return self;
}



- (void)drawRect:(NSRect)rect {
	
//	[super drawRect:rect]; // ??
	
	[[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0] set];
	[NSBezierPath fillRect:rect];
	
	BOOL isMain = [[self window] isMainWindow];
	
	if (MDMetalBevelViewSystemVersion == MDLeopard) {
		
		if (drawsBackground) {
			if (isMain) {
				[[NSColor colorWithCalibratedRed:81.0/255.0 green:81.0/255.0 blue:81.0/255.0 alpha:1.0] set];
			} else {
				[[NSColor colorWithCalibratedRed:81.0/255.0 green:81.0/255.0 blue:81.0/255.0 alpha:1.0] set];
			}
			
			[NSBezierPath setDefaultLineWidth:2.0];
			
			[NSBezierPath strokeLineFromPoint:NSMakePoint(0.0,rect.size.height) toPoint:NSMakePoint(rect.size.width, rect.size.height)];
			
			[NSBezierPath strokeLineFromPoint:NSMakePoint(0.0,0.0) toPoint:NSMakePoint(rect.size.width, 0.0)];
			
		} else {
			[super drawRect:rect];
			
		}
		
	} else if (MDMetalBevelViewSystemVersion >= MDSnowLeopard) {
		
		if (drawsBackground) {
			if (isMain) {
				[[NSColor colorWithCalibratedRed:81.0/255.0 green:81.0/255.0 blue:81.0/255.0 alpha:1.0] set];
			} else {
				[[NSColor colorWithCalibratedRed:81.0/255.0 green:81.0/255.0 blue:81.0/255.0 alpha:1.0] set];
			}
			
			[NSBezierPath setDefaultLineWidth:2.0];
			
			[NSBezierPath strokeLineFromPoint:NSMakePoint(0.0,rect.size.height) toPoint:NSMakePoint(rect.size.width, rect.size.height)];
			
			[NSBezierPath strokeLineFromPoint:NSMakePoint(0.0,0.0) toPoint:NSMakePoint(rect.size.width, 0.0)];
			
		} else {
			[super drawRect:rect];
			
		}
	}
}




- (BOOL)drawsBackground {
    return drawsBackground;
}

- (void)setDrawsBackground:(BOOL)value {
	drawsBackground = value;
	[self setNeedsDisplay:YES];
}




@end









