//
//  TKImageView.m
//  Source Finagler
//
//  Created by Mark Douma on 11/15/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageView.h"
#import <TextureKit/TextureKit.h>
#import <QuartzCore/QuartzCore.h>
#import "TKAnimationImageView.h"
#import "TKImageViewPrivateInterfaces.h"



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

@property (nonatomic, retain) TKAnimationImageView *animationImageView;

@end


@implementation TKImageView

@synthesize animationImageView = _TK__private;

@dynamic animationImageReps;


- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		
	}
	return self;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	self.animationImageView.imageView = nil;
	[_TK__private release];
	[super dealloc];
}


- (void)awakeFromNib {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[self setCurrentToolMode:IKToolModeMove];
	
	
#if TK_DEBUG
//	NSColor *backgroundColor = [self backgroundColor];
//	NSLog(@"[%@ %@] backgroundColor == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), backgroundColor);
//	CGColorRef colorRef = [backgroundColor CGColor];
//	NSLog(@"colorRef == %@", colorRef);
	
#endif

}



- (TKAnimationImageView *)animationImageView {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (_TK__private == nil) {
		_TK__private = [[TKAnimationImageView alloc] initWithFrame:NSMakeRect(0.0, 0.0, self.bounds.size.width, self.bounds.size.height)];
		[(TKAnimationImageView *)_TK__private setImageView:self];
		[(TKAnimationImageView *)_TK__private setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[[(TKAnimationImageView *)_TK__private layer] setBackgroundColor:self.layer.backgroundColor];
	}
	return _TK__private;
}


- (void)setAnimationImageReps:(NSArray *)animationImageReps {
	self.animationImageView.animationImageReps = animationImageReps;
}

- (NSArray *)animationImageReps {
	return self.animationImageView.animationImageReps;
}


- (void)startAnimating {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (self.isAnimating) return;
	
	if (self.animationImageView.animationImageReps.count) {
		[self.animationImageView startAnimating];
		[self addSubview:self.animationImageView];
	}
}


- (void)stopAnimating {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (self.isAnimating == NO) return;
	
	[self.animationImageView removeFromSuperview];
	[self.animationImageView stopAnimating];
	
}


- (BOOL)isAnimating {
	return self.animationImageView.isAnimating;
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


@end

