//
//  TKImageView.h
//  Texture Kit
//
//  Created by Mark Douma on 11/15/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@class TKImageView, CALayer;

enum {
	TKImageViewZoomOutTag			= -1,
	TKImageViewZoomActualSizeTag	= 0,
	TKImageViewZoomInTag			= 1
};


@interface TKImageView : IKImageView {
	
	
	CALayer									*imageKitLayer;
	
	CALayer									*animationImageLayer;
	
	NSArray									*animationImageReps;
	BOOL									isAnimating;
	
}

@property (retain) CALayer *imageKitLayer;

@property (retain) CALayer *animationImageLayer;

@property (copy) NSArray *animationImageReps;


- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;



//- (IBAction)togglePlay:(id)sender;

- (IBAction)zoom:(id)sender;

@end


