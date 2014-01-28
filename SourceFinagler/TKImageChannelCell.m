//
//  TKImageChannelCell.m
//  Source Finagler
//
//  Created by Mark Douma on 10/24/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageChannelCell.h"


//#define TK_INSET_HORIZ		6.0		/* Distance image icon is inset from the left edge */
//#define TK_INTER_SPACE		4.0		/* Distance between right edge of icon image and left edge of text */
//#define TK_BOTTOM_PADDING	1.0		/* Distance between bottom of image and bottom of cell */

#define TK_INSET_HORIZ		2.0		/* Distance image icon is inset from the left edge */
#define TK_INTER_SPACE		5.0		/* Distance between right edge of icon image and left edge of text */
#define TK_BOTTOM_PADDING	1.0		/* Distance between bottom of image and bottom of cell */

#define TK_DEBUG 1


@implementation TKImageChannelCell

@synthesize image;

- (id)init {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		[self setLineBreakMode:NSLineBreakByTruncatingMiddle];
	}
    return self;
}


- (id)copyWithZone:(NSZone *)zone {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	TKImageChannelCell *cell = (TKImageChannelCell *)[super copyWithZone:zone];
	cell->image = nil;
	[cell setImage:image];
	return cell;
}

- (void)dealloc {
	[image release];
	[super dealloc];
}


- (NSRect)imageRectForBounds:(NSRect)bounds {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	bounds.origin.x += TK_INSET_HORIZ;
//	NSImage *image = [self image];
#if TK_DEBUG
//	NSLog(@"[%@ %@] image == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), image);
#endif
	
	NSSize imageSize = [[self image] size];
	bounds.size.width = imageSize.width;
	bounds.size.height = imageSize.height;
	bounds.origin.y += trunc((bounds.size.height - imageSize.height) / 2.0);
	return bounds;
}


- (NSRect)titleRectForBounds:(NSRect)bounds {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSSize imageSize = [[self image] size];
	bounds.origin.x += (TK_INSET_HORIZ + imageSize.width + TK_INTER_SPACE);
	bounds.size.width -= (TK_INSET_HORIZ + imageSize.width + TK_INTER_SPACE);
	return [super titleRectForBounds:bounds];
}


- (NSSize)cellSizeForBounds:(NSRect)aRect {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSSize cellSize = [super cellSizeForBounds:aRect];
	NSSize imageSize = [[self image] size];
	cellSize.width += (TK_INSET_HORIZ + imageSize.width + TK_INTER_SPACE);
	cellSize.height = (TK_BOTTOM_PADDING + imageSize.height);
	return cellSize;
}


- (NSRect)adjustFrameToVerticallyCenterText:(NSRect)frame {
	// super would normally draw text at the top of the cell
	NSInteger offset = floor((NSHeight(frame) - ([[self font] ascender] - [[self font] descender])) / 2);
	return NSInsetRect(frame, 0.0, offset);
}


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect imageRect = [self imageRectForBounds:cellFrame];
	NSSize imageSize = [[self image] size];
	if ([self image]) {
		[NSBezierPath setDefaultLineWidth:1.0];
		NSRect strokeRect = NSInsetRect(imageRect, 0.25, 0.25);
		
#if TK_DEBUG
//		NSLog(@"[%@ %@] imageRect == %@, strokeRect == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(imageRect), NSStringFromRect(strokeRect));
#endif
		[[NSColor blackColor] set];
		[NSBezierPath strokeRect:strokeRect];
		
		
//		[NSBezierPath setDefaultLineWidth:2.0];
//		[[NSColor blackColor] set];
//		[NSBezierPath strokeRect:imageRect];
		
		// Flip images that don't agree with our flipped state
		BOOL isFlipped = [controlView isFlipped] != [[self image] isFlipped];
		if (isFlipped) {
			[[NSGraphicsContext currentContext] saveGraphicsState];
			NSAffineTransform *transform = [[NSAffineTransform alloc] init];
			[transform translateXBy:0.0 yBy:(cellFrame.origin.y + cellFrame.size.height)];
			[transform scaleXBy:1.0 yBy:-1.0];
			[transform translateXBy:0.0 yBy:-cellFrame.origin.y];
			[transform concat];
			[transform release];
		}
//		NSLog(@"[%@ %@] drawing image", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		[[self image] drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		if (isFlipped) [[NSGraphicsContext currentContext] restoreGraphicsState];
	}
	CGFloat inset = (TK_INSET_HORIZ + imageSize.width + TK_INTER_SPACE);
	cellFrame.origin.x += inset;
	cellFrame.size.width -= inset;
	[super drawInteriorWithFrame:[self adjustFrameToVerticallyCenterText:cellFrame] inView:controlView];
	
	
//	cellFrame.origin.y += 1.0; // looks better ?
//	cellFrame.size.height -= 1.0;
//	[super drawInteriorWithFrame:cellFrame inView:controlView];
}





@end
