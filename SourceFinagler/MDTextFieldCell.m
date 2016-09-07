//
//  MDTextFieldCell.m
//  Source Finagler
//
//  Created by Mark Douma on 1/31/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//  

//	Based, in part, on "FileSystemBrowserCell":

/*
     File: FileSystemBrowserCell.m
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


#import "MDTextFieldCell.h"


#define MD_LEFT_EDGE_PADDING 16.0
#define MD_INSET_HORIZ		16.0		/* Distance image icon is inset from the left edge */
#define MD_INTER_SPACE		6.0		/* Distance between right edge of icon image and left edge of text */


#define MD_DEBUG 0
#define MD_DEBUG_DRAW 0



@interface MDTextFieldCell (MDPrivate)

- (NSPoint)calculatedImagePointForFrame:(NSRect)cellFrame imageSize:(NSSize)imageSize isFlipped:(BOOL)isFlipped;

- (NSRect)calculatedRichTextRectForFrame:(NSRect)cellFrame richText:(NSAttributedString *)richText fontSize:(CGFloat)fontSize imageSize:(NSSize)imageSize isFlipped:(BOOL)isFlipped;

@end


@implementation MDTextFieldCell

@synthesize leftEdgePadding;
@synthesize centerImageVertically;
@synthesize highlightedActiveEnabledAttributes;
@synthesize highlightedActiveDisabledAttributes;
@synthesize highlightedInactiveEnabledAttributes;
@synthesize highlightedInactiveDisabledAttributes;
@synthesize enabledAttributes;
@synthesize disabledAttributes;


- (id)copyWithZone:(NSZone *)zone {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	MDTextFieldCell *cell = (MDTextFieldCell *)[super copyWithZone:zone];
	cell->image = nil;
//	cell->highlightedActiveEnabledAttributes = nil;
//	cell->highlightedActiveDisabledAttributes = nil;
//	cell->highlightedInactiveEnabledAttributes = nil;
//	cell->highlightedInactiveDisabledAttributes = nil;
//	cell->enabledAttributes = nil;
//	cell->disabledAttributes = nil;
	
	cell.image = image;
	
	cell->highlightedActiveEnabledAttributes = [highlightedActiveEnabledAttributes mutableCopy];
	cell->highlightedActiveDisabledAttributes = [highlightedActiveDisabledAttributes mutableCopy];
	cell->highlightedInactiveEnabledAttributes = [highlightedInactiveEnabledAttributes mutableCopy];
	cell->highlightedInactiveDisabledAttributes = [highlightedInactiveDisabledAttributes mutableCopy];
	cell->enabledAttributes = [enabledAttributes mutableCopy];
	cell->disabledAttributes = [disabledAttributes mutableCopy];
	
	return cell;
}


- (void)initAttributes {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[style setLineBreakMode:NSLineBreakByTruncatingMiddle];
	style.alignment = self.alignment;
	
	
	highlightedActiveEnabledAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[self font],NSFontAttributeName,
										  style,NSParagraphStyleAttributeName,
										  [NSColor alternateSelectedControlTextColor],NSForegroundColorAttributeName, nil];
	
	highlightedActiveDisabledAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[self font],NSFontAttributeName,
										   style,NSParagraphStyleAttributeName,
										   [NSColor colorWithCalibratedRed:208.0/255.0 green:208.0/255.0 blue:208.0/255.0 alpha:1.0],NSForegroundColorAttributeName, nil];
	
	highlightedInactiveEnabledAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[self font],NSFontAttributeName,
											style,NSParagraphStyleAttributeName,
											[NSColor controlTextColor],NSForegroundColorAttributeName, nil];
	
	highlightedInactiveDisabledAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[self font],NSFontAttributeName,
											 style,NSParagraphStyleAttributeName,
											 [[NSColor controlTextColor] colorWithAlphaComponent:0.5],NSForegroundColorAttributeName, nil];
	
	enabledAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[self font],NSFontAttributeName,
						 style,NSParagraphStyleAttributeName,
						 [self textColor],NSForegroundColorAttributeName, nil];
	
	disabledAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[self font],NSFontAttributeName,
						  style,NSParagraphStyleAttributeName,
						  [[NSColor controlTextColor] colorWithAlphaComponent:0.5],NSForegroundColorAttributeName, nil];
	
	
	
}



- (id)initTextCell:(NSString *)value {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if  ((self = [super initTextCell:value])) {
		leftEdgePadding = MD_LEFT_EDGE_PADDING;
		[self initAttributes];
	}
	return self;
}


- (id)initImageCell:(NSImage *)value {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initImageCell:value])) {
		image = [value retain];
		leftEdgePadding = MD_LEFT_EDGE_PADDING;
		[self initAttributes];
	}
	return self;
}


- (id)init {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initTextCell:@""])) {
		leftEdgePadding = MD_LEFT_EDGE_PADDING;
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		leftEdgePadding = MD_LEFT_EDGE_PADDING;
		[self initAttributes];
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeObject:[NSNumber numberWithDouble:(double) MD_LEFT_EDGE_PADDING] forKey:@"MDLeftEdgePadding"];
	[coder encodeObject:[NSNumber numberWithBool:centerImageVertically] forKey:@"MDCenterImageVertically"];
}


- (void)dealloc {
	[image release];
	[highlightedActiveEnabledAttributes release];
	[highlightedActiveDisabledAttributes release];
	[highlightedInactiveEnabledAttributes release];
	[highlightedInactiveDisabledAttributes release];
	[enabledAttributes release];
	[disabledAttributes release];
	[super dealloc];
}


- (NSImage *)image {
    return image;
}


- (void)setImage:(NSImage *)value {
    [value retain];
    [image release];
    image = value;
}


- (void)setFont:(NSFont *)fontObj {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[highlightedActiveEnabledAttributes setObject:fontObj forKey:NSFontAttributeName];
	[highlightedActiveDisabledAttributes setObject:fontObj forKey:NSFontAttributeName];
	[highlightedInactiveEnabledAttributes setObject:fontObj forKey:NSFontAttributeName];
	[highlightedInactiveDisabledAttributes setObject:fontObj forKey:NSFontAttributeName];
	[enabledAttributes setObject:fontObj forKey:NSFontAttributeName];
	[disabledAttributes setObject:fontObj forKey:NSFontAttributeName];
	[super setFont:fontObj];
}


- (NSSize)cellSizeForBounds:(NSRect)aRect {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [super cellSizeForBounds:aRect];
}


- (NSSize)cellSize {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSSize cellSize = [super cellSize];
	
	if (image == nil) {
		cellSize.width += 30.0;
	} else {
		NSSize imageSize = [image size];
		cellSize.width += (31.0 + imageSize.width + MD_INTER_SPACE);
	}
	return cellSize;
}


- (NSRect)imageRectForBounds:(NSRect)cellFrame {
#if MD_DEBUG
//    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (image == nil) return NSZeroRect;
	
	NSSize imageSize = image.size;
	
	NSRect result;
	result.size = imageSize;
	result.origin = cellFrame.origin;
	result.origin.x += leftEdgePadding;
	result.origin.y += floor((cellFrame.size.height - result.size.height) / 2.0);
	
	return result;
}


- (NSRect)titleRectForBounds:(NSRect)theRect {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [super titleRectForBounds:theRect];
}


- (NSRect)calculatedRichTextRectForFrame:(NSRect)cellFrame richText:(NSAttributedString *)richText fontSize:(CGFloat)fontSize imageSize:(NSSize)imageSize isFlipped:(BOOL)isFlipped {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect richTextRect = NSZeroRect;
	
	CGFloat fontBaselineFudge = 0.0;
	
	if (isFlipped) {
		if (fontSize >= 12.0 && fontSize <= 14.0) {
			fontBaselineFudge = -1.0;
		} else if (fontSize == 16.0) {
			fontBaselineFudge = 1.0;
		}
	} else {
		if (fontSize >= 12.0 && fontSize <= 14.0) {
			fontBaselineFudge = 1.0;
		} else if (fontSize == 16.0) {
			fontBaselineFudge = -1.0;
		}
	}
	
	CGFloat textMarginFudge = 0.0;
	CGFloat textWidthFudge = 0.0;
	
	if (image == nil) {
		if ([self alignment] == NSLeftTextAlignment) {
			textMarginFudge = 15.0;
			textWidthFudge = -30.0;
		} else {
			textMarginFudge = 15.0;
			textWidthFudge = -30.0;
		}
	} else {
		if ([self alignment] == NSLeftTextAlignment) {
//			textMarginFudge = 15.0;
			textWidthFudge = -15.0;
		} else {
			textMarginFudge = -15.0;
		}
	}
	
	richTextRect.size = [richText size];
	
	richTextRect.origin.x = cellFrame.origin.x + textMarginFudge;
	
	if (isFlipped) {
		richTextRect.origin.y = cellFrame.origin.y + fontBaselineFudge + floor((cellFrame.size.height - richTextRect.size.height)/2.0);
	} else {
		richTextRect.origin.y = cellFrame.origin.y - 1.0 + fontBaselineFudge + ceil((cellFrame.size.height - richTextRect.size.height)/2.0);
	}
	
	richTextRect.size.width = cellFrame.size.width + textWidthFudge;
	
	if (image) {
		richTextRect.origin.x += (leftEdgePadding + imageSize.width + MD_INTER_SPACE);
		richTextRect.size.width -= (leftEdgePadding + imageSize.width + MD_INTER_SPACE);
	}
	return richTextRect;
}


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSSize	imageSize = NSZeroSize;
	
	if (image) imageSize = [image size];
	
	NSRect imageFrame = [self imageRectForBounds:cellFrame];
	
	
	NSDictionary *attributes = nil;
	
	BOOL isEnabled = [self isEnabled];
	
	if ([self isHighlighted]) {
		
		/* This is a hack to get the proper hightlight color behavior */
		
		NSImage *tempImage = [image retain];
		id tempObject = [[self objectValue] retain];
		
		[self setImage:nil];
		[self setStringValue:@""];
		
		[super drawInteriorWithFrame:cellFrame inView:controlView];
		
		[self setImage:tempImage];
		[self setObjectValue:tempObject];
		
		[tempImage release];
		[tempObject release];
		
		if ([[controlView window] isKeyWindow]) {
			attributes = (isEnabled ? highlightedActiveEnabledAttributes : highlightedActiveDisabledAttributes);
			
		} else {
			attributes = (isEnabled ? highlightedInactiveEnabledAttributes : highlightedInactiveDisabledAttributes);
		}
		
	} else {
		attributes = (isEnabled ? enabledAttributes : disabledAttributes);
	}
	
	if (image) {
		[image drawInRect:imageFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:(isEnabled ? 1.0 : 0.5) respectFlipped:YES hints:nil];
	}
	
	NSAttributedString *richText = [[[NSAttributedString alloc] initWithString:[self stringValue] attributes:attributes] autorelease];
	
	NSRect richTextRect = [self calculatedRichTextRectForFrame:cellFrame richText:richText fontSize:[[self font] pointSize] imageSize:imageSize isFlipped:[controlView isFlipped]];
	
	[richText drawInRect:richTextRect];
	
#if MD_DEBUG_DRAW
	[[NSColor greenColor] set];
	[NSBezierPath strokeRect:richTextRect];
	
	#if MD_DEBUG
		if (image) {
			NSLog(@"[%@ %@] imageFrame == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(imageFrame));
		}
	#endif
	
#endif
	
	
}


@end



