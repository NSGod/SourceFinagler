//
//  TKImageView.m
//  Texture Kit
//
//  Created by Mark Douma on 11/15/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageView.h"
#import <TextureKit/TextureKit.h>
#import <QuartzCore/QuartzCore.h>

#define TK_DEBUG 1


typedef struct TKZoomMapping {
	CGFloat currentZoomLow;
	CGFloat currentZoomHigh;
} TKZoomMapping;


static const TKZoomMapping TKZoomMappingTable[] = {
	{ 0.0, 0.05 },
	{ 0.05, 0.075 },
	{ 0.075, 0.1 },
	{ 0.1, 0.15 },
	{ 0.15, 0.2 },
	{ 0.2, 0.25 },
	{ 0.25, 0.3 },
	{ 0.3, 0.4 },
	{ 0.4, 0.5 },
	{ 0.5, 0.75 },
	{ 0.75, 1.0 },
	{ 1.0, 1.5 },
	{ 1.5, 2.0 },
	{ 2.0, 3.0 },
	{ 3.0, 4.0 },
	{ 4.0, 6.0 },
	{ 6.0, 8.0 },
	{ 8.0, 10.0 },
	{ 10.0, 15.0 },
	{ 15.0, 20.0 },
	{ 20.0, 30.0 },
	{ 30.0, 40.0 },
	{ 40.0, 60.0 },
	{ 60.0, 80.0 }
};
static const NSUInteger TKZoomMappingTableCount = sizeof(TKZoomMappingTable)/sizeof(TKZoomMappingTable[0]);



static inline CGFloat TKNextZoomFactorForZoomFactorAndOperation(CGFloat currentZoomFactor, NSInteger zoomInOrZoomOut) {
	for (NSUInteger i = 0; i < TKZoomMappingTableCount; i++) {
		if (TKZoomMappingTable[i].currentZoomLow < currentZoomFactor && currentZoomFactor <= TKZoomMappingTable[i].currentZoomHigh) {
			if (zoomInOrZoomOut == TKImageViewZoomOutTag && i > 0) {
				return TKZoomMappingTable[i].currentZoomLow;
			} else {
				if (i < TKZoomMappingTableCount - 2) {
					return TKZoomMappingTable[i + 1].currentZoomHigh;
				}
			}
		}
	}
	return currentZoomFactor;
}



@interface TKImageView ()

- (void)setImageKitLayerIfNeeded;

- (void)loadAnimationImageReps;
- (void)unloadAnimationImageReps;

@end


@implementation TKImageView

@dynamic imageKitLayer;

@synthesize animationImageLayer;

@synthesize animationImageReps;


- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		
	}
	return self;
}


- (void)dealloc {
	[imageKitLayer release];
	[animationImageReps release];
	[animationImageLayer release];
	[super dealloc];
}


- (void)awakeFromNib {
	[self setCurrentToolMode:IKToolModeMove];
}


- (void)setImageKitLayerIfNeeded {
	if (imageKitLayer == nil) self.imageKitLayer = [self layer];
}

- (CALayer *)imageKitLayer {
	[self setImageKitLayerIfNeeded];
    return imageKitLayer;
}

- (void)setImageKitLayer:(CALayer *)aLayer {
	[aLayer retain];
	[imageKitLayer release];
	imageKitLayer = aLayer;
}


#define TK_FRAMES_PER_SECOND 0.75
#define TK_TIME_INTERVAL_PER_FRAME 1.0

- (void)loadAnimationImageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	
#if TK_DEBUG
//		NSLog(@"[%@ %@] animationImageReps == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), animationImageReps);
#endif
		
	if ([animationImageReps count]) {
		
		[self setImageKitLayerIfNeeded];
		
		
		NSMutableArray *imageRefs = [NSMutableArray array];
		for (TKImageRep *imageRep in animationImageReps) {
			[imageRefs addObject:(id)[imageRep CGImage]];
		}
		
		CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
		anim.duration = TK_FRAMES_PER_SECOND; // frame rate == [animationImageReps count] / duration
		anim.calculationMode = kCAAnimationDiscrete;
		anim.repeatCount = HUGE_VAL;
		anim.values = imageRefs;
		
#if TK_DEBUG
		NSLog(@"[%@ %@] zoomFactor == %.3f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [self zoomFactor]);
#endif
		
		TKImageRep *largestRep = [TKImageRep largestRepresentationInArray:animationImageReps];
		
		if (animationImageLayer == nil) animationImageLayer = [[CALayer layer] retain];
		
		animationImageLayer.frame = NSRectToCGRect(NSMakeRect(0.0, 0.0, [largestRep size].width, [largestRep size].height));
		animationImageLayer.position = NSPointToCGPoint(NSMakePoint([self bounds].size.width/2.0, [self bounds].size.height/2.0));
		
		[animationImageLayer setValue:[NSNumber numberWithDouble:[self zoomFactor]] forKeyPath:@"transform.scale"];
		
		self.layer = animationImageLayer;
		
		[self.layer addAnimation:anim forKey:@"animation"];
	}
}


- (void)unloadAnimationImageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self.layer removeAnimationForKey:@"animation"];
	
	self.layer = imageKitLayer;
	
//	[imageKitLayer release];
//	imageKitLayer = nil;
	
//	[animationImageReps release];
//	animationImageReps = nil;
//	
//	animationImageLayer = nil;
	
}


- (void)startAnimating {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (isAnimating) return;
	
	[self loadAnimationImageReps];
	
	isAnimating = YES;
}


- (void)stopAnimating {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (isAnimating == NO) return;
	
	[self unloadAnimationImageReps];
	
	isAnimating = NO;
}


- (BOOL)isAnimating {
	return isAnimating;
}



//- (IBAction)togglePlay:(id)sender {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	CALayer *layer = [self layer];
//	NSLog(@"[%@ %@] layer == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), layer);
//	
//	if (playing) {
//		
//		[self unloadAnimatedImageReps];
//	} else {
//		[self loadAnimatedImageReps];
//	}
//	
//	[self setPlaying:!playing];
//	[self setNeedsDisplay:YES];
//}



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

- (void)scrollWheel:(NSEvent *)event {
	
	CGFloat deltaY = [event deltaY];
	
	CGFloat currentZoomFactor = [self zoomFactor];
	
#if TK_DEBUG
	NSLog(@"[%@ %@] currentZoomFactor == %.5f, deltaY == %.5f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), currentZoomFactor, deltaY);
#endif
	
	[self setZoomFactor:TKNextZoomFactorForZoomFactorAndOperation(currentZoomFactor, (deltaY > 0 ? TKImageViewZoomInTag : TKImageViewZoomOutTag))];
}


//#define TK_ZOOM_FACTOR_MIN 0.125
//#define TK_ZOOM_FACTOR_MAX 32.0
//
//
//- (void)scrollWheel:(NSEvent *)event {
//	
//	CGFloat deltaX = [event deltaX];
//	CGFloat deltaY = [event deltaY];
//	CGFloat deltaZ = [event deltaZ];
//	
//	CGFloat currentZoomFactor = [self zoomFactor];
//	
//#if TK_DEBUG
//	NSLog(@"[%@ %@] currentZoomFactor == %.3f, deltaX == %.3f, deltaY == %.3f, deltaZ == %.3f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), currentZoomFactor, deltaX, deltaY, deltaZ);
//#endif
//	
//	// resulting zoom factor should always be greater than 0, and less than, say, 16 (1600%) -- let's do 32
//	
//	if (currentZoomFactor > TK_ZOOM_FACTOR_MIN && currentZoomFactor <= TK_ZOOM_FACTOR_MAX) {
//		CGFloat zoomOperation = 10 * deltaY;
//		currentZoomFactor += zoomOperation;
//		if (currentZoomFactor < 0.0) {
//			currentZoomFactor = TK_ZOOM_FACTOR_MIN;
//		} else if (currentZoomFactor > TK_ZOOM_FACTOR_MAX) {
//			currentZoomFactor = TK_ZOOM_FACTOR_MAX;
//		}
//		[self setZoomFactor:currentZoomFactor];
//		//		[self setImageZoomFactor:currentZoomFactor centerPoint:[self convertViewPointToImagePoint:[self convertPoint:[event locationInWindow] fromView:nil]]];
//		//		[self setZoomFactor:(CGFloat)
//	}
//}



@end
