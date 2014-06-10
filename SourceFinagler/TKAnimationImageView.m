//
//  TKAnimationImageView.m
//  Source Finagler
//
//  Created by Mark Douma on 8/22/2013.
//
//

#import "TKAnimationImageView.h"
#import "TKImageView.h"
#import "TKImageViewPrivateInterfaces.h"

#import <TextureKit/TextureKit.h>
#import <Quartz/Quartz.h>



#define TK_DEBUG 1


@implementation TKAnimationImageView

@synthesize imageView;
@synthesize animationImageLayer;
@synthesize animationImageReps;




- (id)initWithFrame:(NSRect)frame {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithFrame:frame])) {
		CALayer *backgroundLayer = [CALayer layer];
		backgroundLayer.contentsGravity = kCAGravityCenter;
		backgroundLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
		
		CGColorRef color = TKCreateGrayBackgroundColor();
		backgroundLayer.backgroundColor = color;
		CGColorRelease(color);
		
		self.animationImageLayer = [CALayer layer];
		animationImageLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
		animationImageLayer.contentsGravity = kCAGravityCenter;
		
		[backgroundLayer addSublayer:animationImageLayer];
		
		self.layer = backgroundLayer;
		[self setWantsLayer:YES];
		
#if TK_DEBUG
		color = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
		self.layer.borderColor = color;
		CGColorRelease(color);
		self.layer.borderWidth = 4.0;
#endif

	}
	return self;
}


- (void)dealloc {
	[animationImageLayer release];
	[animationImageReps release];
	[super dealloc];
}



#define TK_FRAMES_PER_SECOND 0.75
#define TK_TIME_INTERVAL_PER_FRAME 1.0


- (void)startAnimating {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (isAnimating) return;
	
	if (animationImageReps.count) {
		
		NSMutableArray *imageRefs = [NSMutableArray array];
		
		for (TKImageRep *imageRep in animationImageReps) {
			[imageRefs addObject:(id)[imageRep CGImage]];
		}
		
		CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
		anim.duration = TK_FRAMES_PER_SECOND; // frame rate == [animationImageReps count] / duration
		anim.calculationMode = kCAAnimationDiscrete;
		anim.repeatCount = HUGE_VAL;
		anim.values = imageRefs;
		
		CGFloat zoomFactor = imageView.zoomFactor;
		
#if TK_DEBUG
		NSLog(@"[%@ %@] zoomFactor == %.3f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), zoomFactor);
#endif
		
		[CATransaction begin];
		
		[animationImageLayer setValue:[NSNumber numberWithDouble:zoomFactor] forKeyPath:@"transform.scale"];
		
		[animationImageLayer addAnimation:anim forKey:@"animation"];
		
		[CATransaction commit];
		
	}
	
	isAnimating = YES;
}


- (void)stopAnimating {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (isAnimating == NO) return;
	
	[animationImageLayer removeAnimationForKey:@"animation"];
	
	isAnimating = NO;
}


- (BOOL)isAnimating {
	return isAnimating;
}


- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
#if TK_DEBUG
	NSLog(@"[%@ %@] newSuperview == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), newSuperview);
#endif
	if (newSuperview == imageView) {
//		self.frame = NSMakeRect(0.0, 0.0, newSuperview.bounds.size.width, newSuperview.bounds.size.height);
	}
}


@end



