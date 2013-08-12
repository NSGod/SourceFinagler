//
//  TKImageView.h
//  Texture Kit
//
//  Created by Mark Douma on 11/15/2010.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@class TKImageView, TKImageRep;

enum {
	TKImageViewZoomOutTag			= -1,
	TKImageViewZoomActualSizeTag	= 0,
	TKImageViewZoomInTag			= 1
};


@protocol TKImageViewDelegate <NSObject>
- (void)imageViewDidBecomeFirstResponder:(TKImageView *)anImageView;
@end


@interface TKImageView : IKImageView {
	
	
	id <TKImageViewDelegate>					delegate;		// non-retained
	
	
	CALayer										*imageKitLayer;
	
	CALayer										*animationImageLayer;
	
	NSArray										*animationImageReps;
	BOOL										isAnimating;
	
	
	
	
	CGImageRef									image;
	
	TKImageRep									*previewImageRep;
	
	BOOL										previewing;
	
	BOOL										showsImageBackground;
	
}

@property (retain) CALayer *imageKitLayer;

@property (retain) CALayer *animationImageLayer;

@property (copy) NSArray *animationImageReps;


- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;


@property (assign) IBOutlet id <TKImageViewDelegate> delegate;

@property (retain) TKImageRep *previewImageRep;

@property (assign, getter=isPreviewing) BOOL previewing;


@property (assign) BOOL showsImageBackground;



- (IBAction)toggleShowImageBackground:(id)sender;

- (IBAction)zoom:(id)sender;


@end

