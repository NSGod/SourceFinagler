//
//  MDBrowserCell.m
//  Source Finagler
//
//  Created by Mark Douma on 6/28/2005.
//  Copyright 2005 Mark Douma. All rights reserved.
//


#import "MDBrowserCell.h"


#define MD_INSET_HORIZ		6.0		/* Distance image icon is inset from the left edge */
#define MD_INTER_SPACE		4.0		/* Distance between right edge of icon image and left edge of text */
#define MD_BOTTOM_PADDING	1.0		/* Distance between bottom of image and bottom of cell */


#define MD_DEBUG 0


@implementation MDBrowserCell

@synthesize image;

- (id)init {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		[self setLineBreakMode:NSLineBreakByTruncatingMiddle];
		[self setItemIsInvisible:NO];
	}
    return self;
}


- (id)copyWithZone:(NSZone *)zone {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	MDBrowserCell *cell = (MDBrowserCell *)[super copyWithZone:zone];
	cell->image = nil;
	[cell setImage:image];
	return cell;
}

- (void)dealloc {
	[image release];
	[super dealloc];
}

- (BOOL)itemIsInvisible {
    return itemIsInvisible;
}

- (void)setItemIsInvisible:(BOOL)value {
	itemIsInvisible = value;
	[self setTextColor:(itemIsInvisible ? [NSColor disabledControlTextColor] : [NSColor controlTextColor] )];
//	[self setTextColor:(itemIsInvisible ? [[NSColor controlTextColor] colorWithAlphaComponent:0.5] : [NSColor controlTextColor] )];
}



- (NSRect)imageRectForBounds:(NSRect)bounds {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	bounds.origin.x += MD_INSET_HORIZ;
//	NSImage *image = [self image];
#if MD_DEBUG
//	NSLog(@"[%@ %@] image == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), image);
#endif
	
	NSSize imageSize = [[self image] size];
	bounds.size.width = imageSize.width;
	bounds.size.height = imageSize.height;
	bounds.origin.y += trunc((bounds.size.height - imageSize.height) / 2.0);
	return bounds;
}


- (NSRect)titleRectForBounds:(NSRect)bounds {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSSize imageSize = [[self image] size];
	bounds.origin.x += (MD_INSET_HORIZ + imageSize.width + MD_INTER_SPACE);
	bounds.size.width -= (MD_INSET_HORIZ + imageSize.width + MD_INTER_SPACE);
	return [super titleRectForBounds:bounds];
}


- (NSSize)cellSizeForBounds:(NSRect)aRect {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSSize cellSize = [super cellSizeForBounds:aRect];
	NSSize imageSize = [[self image] size];
	cellSize.width += (MD_INSET_HORIZ + imageSize.width + MD_INTER_SPACE);
	cellSize.height = (MD_BOTTOM_PADDING + imageSize.height);
	return cellSize;
}



- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect imageRect = [self imageRectForBounds:cellFrame];
	NSSize imageSize = [[self image] size];
	if ([self image]) {
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
		[[self image] drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:(itemIsInvisible ? 0.5 : 1.0)];
		if (isFlipped) [[NSGraphicsContext currentContext] restoreGraphicsState];
	}
	CGFloat inset = (MD_INSET_HORIZ + imageSize.width + MD_INTER_SPACE);
	cellFrame.origin.x += inset;
	cellFrame.size.width -= inset;
	cellFrame.origin.y += 1.0; // looks better ?
	cellFrame.size.height -= 1.0;
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}


@end



