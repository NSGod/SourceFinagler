//
//  MDBottomBar.m
//  Source Finagler
//
//  Created by Mark Douma on 10/29/2008.
//  Copyright 2008 Mark Douma. All rights reserved.
//

#import "MDBottomBar.h"
#import "MDFileSizeFormatter.h"

#define MD_DISABLED_OPACITY 0.1

#pragma mark view
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

static SInt32 MDSystemVersion = MDUndeterminedVersion;

@implementation MDBottomBar

+ (void)initialize {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (MDSystemVersion == MDUndeterminedVersion) {
		SInt32 MDFullSystemVersion = 0;
		Gestalt(gestaltSystemVersion, &MDFullSystemVersion);
		MDSystemVersion = MDFullSystemVersion & 0xfffffff0;
	}
}


- (id)initWithFrame:(NSRect)frame {
	if ((self = [super initWithFrame:frame])) {
		formatter = [[MDFileSizeFormatter alloc] init];
	}
	return self;
}


- (void)dealloc {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[selectedIndexes release];
	[totalCount release];
	[freeSpace release];
	[formatter release];
	[super dealloc];
}



- (void)setSelectedIndexes:(NSIndexSet *)anIndexSet totalCount:(NSNumber *)aTotalCount freeSpace:(NSNumber *)aFreeSpace {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[anIndexSet retain];
	[selectedIndexes release];
	selectedIndexes = anIndexSet;
	
	[aTotalCount retain];
	[totalCount release];
	totalCount = aTotalCount;
	
	[aFreeSpace retain];
	[freeSpace release];
	freeSpace = aFreeSpace;
	
	[self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)rect {
	
	BOOL isMainWindow = [[self window] isMainWindow];
	
	
	if (MDSystemVersion == MDLeopard) {
		
		if (isMainWindow) {
			[NSBezierPath setDefaultLineWidth:2.0];
			
			[[NSColor colorWithCalibratedRed:47.0/255.0 green:47.0/255.0 blue:47.0/255.0 alpha:1.0] set];
			
			[NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, rect.origin.y + (rect.size.height - 1.0)) toPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + (rect.size.height - 1.0))];
			
			[[NSColor colorWithCalibratedRed:208.0/255.0 green:208.0/255.0 blue:208.0/255.0 alpha:1.0] set];
			
			
			[NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, rect.origin.y + (rect.size.height - 2.0)) toPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + (rect.size.height - 2.0))];
			
			NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:133.0/255.0 green:133.0/255.0 blue:133.0/255.0 alpha:1.0]
																  endingColor:[NSColor colorWithCalibratedRed:177.0/255.0 green:177.0/255.0 blue:177.0/255.0 alpha:1.0]] autorelease];
			
			NSRect gradientRect = rect;
			gradientRect.size.height -= 2.0;
			
			[gradient drawInRect:gradientRect angle:90];
			
		} else {
			
			[NSBezierPath setDefaultLineWidth:2.0];
			
			[[NSColor colorWithCalibratedRed:117.0/255.0 green:117.0/255.0 blue:117.0/255.0 alpha:1.0] set];
			
			[NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, rect.origin.y + (rect.size.height - 1.0)) toPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + (rect.size.height - 1.0))];
			
			[[NSColor colorWithCalibratedRed:234.0/255.0 green:234.0/255.0 blue:234.0/255.0 alpha:1.0] set];
			
			
			[NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, rect.origin.y + (rect.size.height - 2.0)) toPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + (rect.size.height - 2.0))];
			
			NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0]
																  endingColor:[NSColor colorWithCalibratedRed:222.0/255.0 green:222.0/255.0 blue:222.0/255.0 alpha:1.0]] autorelease];
			
			
			NSRect gradientRect = rect;
			gradientRect.size.height -= 2.0;
			
			[gradient drawInRect:gradientRect angle:90];
			
		}
		
	}
	
	
//	BOOL debug = YES;
//	
//	if (debug) {
//		[[NSColor redColor] set];
//		[NSBezierPath fillRect:rect];
//	}
	
	
	NSString *stringValue = nil;
	
	if ([selectedIndexes count] == 0) {
		if ([totalCount unsignedIntegerValue] == 0 || [totalCount unsignedIntegerValue] >= 2) {
			
			stringValue = [NSString stringWithFormat:NSLocalizedString(@"%@ items, %@ available", @""), totalCount, [formatter stringForObjectValue:freeSpace]];
			
		} else if ([totalCount unsignedIntegerValue] == 1) {
			
			stringValue = [NSString stringWithFormat:NSLocalizedString(@"%@ item, %@ available", @""), totalCount, [formatter stringForObjectValue:freeSpace]];
		}
	} else if ([selectedIndexes count] == 1) {
		
		stringValue = [NSString stringWithFormat:NSLocalizedString(@"%lu(single) of %@ selected, %@ available", @"String for when only 1 item is selected"), (unsigned long)[selectedIndexes count], totalCount, [formatter stringForObjectValue:freeSpace]];
		
	} else if ([selectedIndexes count] >= 2) {
		
		stringValue = [NSString stringWithFormat:NSLocalizedString(@"%lu(multiple) of %@ selected, %@ available", @"String for when more than one item is selected"), (unsigned long)[selectedIndexes count], totalCount, [formatter stringForObjectValue:freeSpace]];
	}

	
	NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[style setLineBreakMode:NSLineBreakByTruncatingMiddle];
	
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	
		[shadow setShadowColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.41]];
	
	NSColor *textColor = nil;
	
	if (MDSystemVersion == MDLeopard) {
		if (isMainWindow) {
			textColor = [NSColor controlTextColor];
		} else {
//			textColor = [NSColor disabledControlTextColor];
			textColor = [NSColor colorWithCalibratedRed:47.0/255.0 green:47.0/255.0 blue:47.0/255.0 alpha:1.0];
		}
		
	} else if (MDSystemVersion >= MDSnowLeopard) {
		if (isMainWindow) {
			textColor = [NSColor controlTextColor];
		} else {
			textColor = [NSColor disabledControlTextColor];
		}
	}
	
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName, style,NSParagraphStyleAttributeName, shadow,NSShadowAttributeName, textColor,NSForegroundColorAttributeName, nil];
	
	NSAttributedString *richText = [[[NSAttributedString alloc] initWithString:stringValue attributes:attributes] autorelease];
	
	NSRect richTextRect = NSZeroRect;
	
	richTextRect.size = [richText size];
	richTextRect.origin.x = ceil( (rect.size.width - richTextRect.size.width)/2.0);
	
	if (MDSystemVersion == MDLeopard) {
		
		richTextRect.origin.y = ceil( (rect.size.height - richTextRect.size.height)/2.0);
		
	} else if (MDSystemVersion >= MDSnowLeopard) {
		richTextRect.origin.y = ceil( (rect.size.height - richTextRect.size.height)/2.0);
		
	}
	
	[richText drawInRect:richTextRect];
	
}

@end

	




