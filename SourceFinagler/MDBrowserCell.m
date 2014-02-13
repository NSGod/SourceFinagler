//
//  MDBrowserCell.m
//  Source Finagler
//
//  Created by Mark Douma on 6/28/2005.
//  Copyright 2005 Mark Douma. All rights reserved.
//

//	Based, in part, on "FileSystemBrowserCell":

/*
 File: FileSystemBrowserCell.h
 Abstract: A cell that can draw an image/icon and a label color.
 Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */


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



