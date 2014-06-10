//
//  TKAnimationImageView.h
//  Source Finagler
//
//  Created by Mark Douma on 8/22/2013.
//
//

#import <Cocoa/Cocoa.h>


@class TKImageView;


@interface TKAnimationImageView : NSView {
	
	IBOutlet TKImageView						*imageView; // non-retained
	
	CALayer										*animationImageLayer;
	
	NSArray										*animationImageReps;
	
	BOOL										isAnimating;
	
}


@property (nonatomic, assign) IBOutlet TKImageView *imageView; // non-retained

@property (nonatomic, retain) CALayer *animationImageLayer;


@property (copy) NSArray *animationImageReps;


- (void)startAnimating;
- (void)stopAnimating;

- (BOOL)isAnimating;



@end


