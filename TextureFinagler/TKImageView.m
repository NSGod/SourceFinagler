//
//  TKImageView.m
//  Texture Kit
//
//  Created by Mark Douma on 11/15/2010.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import "TKImageView.h"
#import <TextureKit/TKImageRep.h>
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


static TKImageRep *checkerboardImageRep = nil;


CGPatternRef TKCreatePatternWithImage(CGImageRef imageRef);
CGColorRef TKCreatePatternColorWithImage(CGImageRef imageRef);



@interface TKImageView ()


- (void)setImageKitLayerIfNeeded;

- (void)loadAnimationImageReps;
- (void)unloadAnimationImageReps;

@end


@implementation TKImageView

@dynamic imageKitLayer;

@synthesize animationImageLayer;

@synthesize animationImageReps;

@synthesize delegate;
@synthesize previewing;

@dynamic previewImageRep;
@dynamic showsImageBackground;


- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		
	}
	return self;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[imageKitLayer release];
	[animationImageLayer release];
	[animationImageReps release];
	delegate = nil;
	CGImageRelease(image);
	[previewImageRep release];
	[super dealloc];
}


- (void)awakeFromNib {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[self setCurrentToolMode:IKToolModeMove];
	
//	[self setImageKitLayer:[self layer]];
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


- (TKImageRep *)previewImageRep {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return previewImageRep;
}


- (void)setPreviewImageRep:(TKImageRep *)aPreviewImageRep {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[aPreviewImageRep retain];
	[previewImageRep release];
	previewImageRep = aPreviewImageRep;
	
	if (previewImageRep) {
		CGImageRelease(image);
		image = CGImageRetain([self image]);
		
		[self setImage:[previewImageRep CGImage] imageProperties:nil];
		
	} else {
		
		[self setImage:image imageProperties:nil];
	}
	
	[self setPreviewing:(previewImageRep != nil)];
	
}



- (BOOL)showsImageBackground {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    return showsImageBackground;
}

- (void)setShowsImageBackground:(BOOL)showImageBackground {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	showsImageBackground = showImageBackground;
	
	[self setImageKitLayerIfNeeded];
	
	if (self.layer != imageKitLayer) self.layer = imageKitLayer;
	
	if (showsImageBackground) {
		@synchronized([self class]) {
			if (checkerboardImageRep == nil) {
				checkerboardImageRep = [[TKImageRep imageRepWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"checkerboard" ofType:@"png"]] retain];
			}
		}
		CGImageRef checkerboardImageRef = CGImageRetain([checkerboardImageRep CGImage]);
		CGColorRef patternColorRef = TKCreatePatternColorWithImage(checkerboardImageRef);
		imageKitLayer.backgroundColor = patternColorRef;
		CGColorRelease(patternColorRef);
		
	} else {
		imageKitLayer.backgroundColor = nil;
	}
}

- (IBAction)toggleShowImageBackground:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self setShowsImageBackground:!showsImageBackground];
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
	//	}
}


- (void)unloadAnimationImageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self.layer removeAnimationForKey:@"animation"];
	
	self.layer = imageKitLayer;
	
//	[animationImageLayer release];
//	animationImageLayer = nil;
//	
//	[animationImageReps release];
//	animationImageReps = nil;
	
}


- (void)startAnimating {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (isAnimating) return;
	
	[self loadAnimationImageReps];
}


- (void)stopAnimating {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (isAnimating == NO) return;
	
	[self unloadAnimationImageReps];
}


- (BOOL)isAnimating {
	return isAnimating;
}



//- (IBAction)togglePlay:(id)sender {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//	CALayer *layer = [self layer];
//	NSLog(@"[%@ %@] layer == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), layer);
//#endif
//	
//	if (playing) {
//		
//		[self unloadAnimationImageReps];
//	} else {
//		[self loadAnimationImageReps];
//	}
//	
//	[self setPlaying:!playing];
//	[self setNeedsDisplay:YES];
//}


- (void)mouseDown:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (delegate && [delegate respondsToSelector:@selector(imageViewDidBecomeFirstResponder:)]) {
		[delegate imageViewDidBecomeFirstResponder:self];
	}
	[super mouseDown:event];
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


- (void)scrollWheel:(NSEvent *)event {
	
	CGFloat deltaY = [event deltaY];
	
	CGFloat currentZoomFactor = [self zoomFactor];
	
#if TK_DEBUG
	NSLog(@"[%@ %@] currentZoomFactor == %.5f, deltaY == %.5f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), currentZoomFactor, deltaY);
#endif
	
	[self setZoomFactor:TKNextZoomFactorForZoomFactorAndOperation(currentZoomFactor, (deltaY > 0 ? TKImageViewZoomInTag : TKImageViewZoomOutTag))];
}


- (void)setRotationAngle:(CGFloat)aRotationAngle centerPoint:(NSPoint)centerPoint {
#if TK_DEBUG
	NSLog(@"[%@ %@] rotationAngle == %.3f, centerPoint == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aRotationAngle, NSStringFromPoint(centerPoint));
#endif
	[super setRotationAngle:aRotationAngle centerPoint:centerPoint];
}



/*! 
 @method setImageZoomFactor:centerPoint:
 @abstract Sets the zoom factor at the provided origin.
 */
- (void)setImageZoomFactor:(CGFloat)aZoomFactor centerPoint:(NSPoint)centerPoint {
#if TK_DEBUG
	NSLog(@"[%@ %@] zoomFactor == %.3f, centerPoint == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aZoomFactor, NSStringFromPoint(centerPoint));
#endif
	[super setImageZoomFactor:aZoomFactor centerPoint:centerPoint];
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




- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	SEL action = [menuItem action];
	
	if (action == @selector(toggleShowImageBackground:)) {
		[menuItem setState:showsImageBackground];
	}
	return YES;
}
	

@end


         // can be resource name or abs. path
//CGColorRef GetCGPatternNamed(NSString *name) {
//	
//    // For efficiency, loaded patterns are cached in a dictionary by name.
//    static NSMutableDictionary *sMap;
//    if (!sMap)
//        sMap = [[NSMutableDictionary alloc] init];
//    
//    CGColorRef pattern = (CGColorRef) [sMap objectForKey: name];
//    if (!pattern) {
//        pattern = CreatePatternColor(MDGetCGImageNamed(name));
//        [sMap setObject:(id)pattern forKey: name];
//    }
//    return pattern;
//}



#pragma mark -
#pragma mark PATTERNS:


// callback for TKCreatePatternWithImage.
static void TKDrawPatternImage(void *info, CGContextRef ctx) {
    CGImageRef imageRef = (CGImageRef)info;
    CGContextDrawImage(ctx, CGRectMake(0, 0, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef)), imageRef);
}


// callback for TKCreatePatternWithImage.
static void TKReleasePatternImage(void *info) {
    CGImageRelease((CGImageRef)info);
}


CGPatternRef TKCreatePatternWithImage(CGImageRef imageRef) {
    NSCParameterAssert(imageRef);
    NSInteger imageWidth = CGImageGetWidth(imageRef);
    NSInteger imageHeight = CGImageGetHeight(imageRef);
    static const CGPatternCallbacks callbacks = {0, &TKDrawPatternImage, &TKReleasePatternImage};
    return CGPatternCreate(imageRef,
						   CGRectMake(0, 0, imageWidth, imageHeight),
						   CGAffineTransformMake(1, 0, 0, 1, 0, 0),
						   imageWidth,
						   imageHeight,
						   kCGPatternTilingConstantSpacing,
						   true,
						   &callbacks);
}


CGColorRef TKCreatePatternColorWithImage(CGImageRef imageRef) {
    CGPatternRef pattern = TKCreatePatternWithImage(imageRef);
    CGColorSpaceRef space = CGColorSpaceCreatePattern(NULL);
    CGFloat components[1] = {(CGFloat)1.0};
    CGColorRef color = CGColorCreateWithPattern(space, pattern, components);
    CGColorSpaceRelease(space);
    CGPatternRelease(pattern);
    return color;
}






