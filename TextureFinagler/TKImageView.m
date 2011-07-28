//
//  TKImageView.m
//  Texture Kit
//
//  Created by Mark Douma on 11/15/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageView.h"
#import <TextureKit/TKImageRep.h>
#import <QuartzCore/QuartzCore.h>

#define TK_DEBUG 1

@interface TKImageView ()

- (void)loadAnimatedImageReps;
- (void)unloadAnimatedImageReps;

@end


@implementation TKImageView

@synthesize imageReps, playing, dataSource, delegate;


- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		
	}
	return self;
}


- (void)dealloc {
	[imageReps release];
	[animatedImageLayer release];
	[oldLayer release];
	dataSource = nil;
	delegate = nil;
	[super dealloc];
}


- (void)awakeFromNib {
	[self setCurrentToolMode:IKToolModeMove];
}


- (void)mouseDown:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (delegate && [delegate respondsToSelector:@selector(imageViewDidBecomeFirstResponder:)]) {
		[delegate imageViewDidBecomeFirstResponder:self];
	}
	[super mouseDown:event];
}


/*! 
 @method scrollToPoint:
 @abstract Scrolls the view to the specified point.
 */
- (void)scrollToPoint:(NSPoint)point {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super scrollToPoint:point];
}

/*! 
 @method scrollToRect:
 @abstract Scrolls the view so that it includes the provided rectangular area.
 */
- (void)scrollToRect:(NSRect)rect {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super scrollToRect:rect];
}




- (IBAction)zoom:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([sender isKindOfClass:[NSSegmentedControl class]]) {
		NSSegmentedCell *cell = [(NSSegmentedControl *)sender cell];
		NSInteger tag = [cell tagForSegment:[cell selectedSegment]];
		
		if (tag == TKImageViewZoomOutTag) {
			[self zoomOut:sender];
		} else if (tag == TKImageViewZoomActualSizeTag) {
			[self zoomImageToActualSize:sender];
		} else if (tag == TKImageViewZoomInTag) {
			[self zoomIn:sender];
		}
	}
	
}


- (IBAction)zoomIn:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (![IKImageView instancesRespondToSelector:@selector(zoomIn:)]) {
		NSLog(@"[%@ %@] NOTE: [IKImageView instancesRespondToSelector:@selector(zoomIn:)] == NO", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return;
	}
	[super zoomIn:sender];
}

- (IBAction)zoomOut:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (![IKImageView instancesRespondToSelector:@selector(zoomOut:)]) {
		NSLog(@"[%@ %@] NOTE: [IKImageView instancesRespondToSelector:@selector(zoomOut:)] == NO", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return;
	}
	[super zoomOut:sender];
}


#define TK_ZOOM_FACTOR_MIN 0.125
#define TK_ZOOM_FACTOR_MAX 32.0


- (void)scrollWheel:(NSEvent *)event {
	
	CGFloat deltaX = [event deltaX];
	CGFloat deltaY = [event deltaY];
	CGFloat deltaZ = [event deltaZ];
	
	CGFloat currentZoomFactor = [self zoomFactor];
	
#if TK_DEBUG
	NSLog(@"[%@ %@] currentZoomFactor == %.3f, deltaX == %.3f, deltaY == %.3f, deltaZ == %.3f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), currentZoomFactor, deltaX, deltaY, deltaZ);
#endif
	
	// resulting zoom factor should always be greater than 0, and less than, say, 16 (1600%) -- let's do 32
	
	if (currentZoomFactor > TK_ZOOM_FACTOR_MIN && currentZoomFactor <= TK_ZOOM_FACTOR_MAX) {
		CGFloat zoomOperation = 10 * deltaY;
		currentZoomFactor += zoomOperation;
		if (currentZoomFactor < 0.0) {
			currentZoomFactor = TK_ZOOM_FACTOR_MIN;
		} else if (currentZoomFactor > TK_ZOOM_FACTOR_MAX) {
			currentZoomFactor = TK_ZOOM_FACTOR_MAX;
		}
		[self setZoomFactor:currentZoomFactor];
//		[self setImageZoomFactor:currentZoomFactor centerPoint:[self convertViewPointToImagePoint:[self convertPoint:[event locationInWindow] fromView:nil]]];
//		[self setZoomFactor:(CGFloat)
	}
}


#define TK_FRAMES_PER_SECOND 0.75
#define TK_TIME_INTERVAL_PER_FRAME 1.0

- (void)loadAnimatedImageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[imageReps release];
	imageReps = nil;
	
	if (dataSource && [dataSource respondsToSelector:@selector(imageRepsForAnimationInImageView:)]) {
		imageReps = [[dataSource imageRepsForAnimationInImageView:self] retain];
#if TK_DEBUG
		NSLog(@"[%@ %@] imageReps == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageReps);
#endif
	
		
		if (imageReps && [imageReps count]) {
			NSMutableArray *imageRefs = [NSMutableArray array];
			for (TKImageRep *imageRep in imageReps) {
				[imageRefs addObject:(id)[imageRep CGImage]];
			}
			
			CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
			anim.duration = TK_FRAMES_PER_SECOND; // frame rate == [imageReps count] / duration
			anim.calculationMode = kCAAnimationDiscrete;
			anim.repeatCount = HUGE_VAL;
			anim.values = imageRefs;
			
			
			CALayer *currentLayer = [[self layer] retain];
			
			NSLog(@"[%@ %@] zoomFactor == %.3f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [self zoomFactor]);
	
			
//			NSLog(@"[%@ %@] currentLayer == %@; wantsLayer == %@; isFlipped == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), currentLayer, ([self wantsLayer] ? @"YES" : @"NO"), ([self isFlipped] ? @"YES" : @"NO"));
			
			[oldLayer release];
			oldLayer = currentLayer;
			
			[animatedImageLayer release];
			
			animatedImageLayer = [CALayer layer];
			NSImageRep *firstRep = (TKImageRep *)[imageReps objectAtIndex:0];
			
			animatedImageLayer.frame = NSRectToCGRect(NSMakeRect(0.0, 0.0, [firstRep size].width, [firstRep size].height));
			animatedImageLayer.position = NSPointToCGPoint(NSMakePoint([self bounds].size.width/2.0, [self bounds].size.height/2.0));
			
			[animatedImageLayer setValue:[NSNumber numberWithDouble:[self zoomFactor]] forKeyPath:@"transform.scale"];
			
			self.layer = animatedImageLayer;

			[self.layer addAnimation:anim forKey:@"animation"];
			
		}
	}
}


- (void)unloadAnimatedImageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self.layer removeAnimationForKey:@"animation"];
	
	self.layer = oldLayer;
	
	[oldLayer release];
	oldLayer = nil;
	
	[imageReps release];
	imageReps = nil;
	
	animatedImageLayer = nil;
	
}


- (IBAction)togglePlay:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	CALayer *layer = [self layer];
	NSLog(@"[%@ %@] layer == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), layer);
	
	if (playing) {
		
		[self unloadAnimatedImageReps];
	} else {
		[self loadAnimatedImageReps];
	}
	
	[self setPlaying:!playing];
	[self setNeedsDisplay:YES];
}
	

@end
