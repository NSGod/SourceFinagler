//
//  TKImageView.h
//  Source Finagler
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
	@private
	id	_TK__private;
	
	id <TKImageViewDelegate>					delegate;		// non-retained
	

	CGImageRef									image;
	
	TKImageRep									*previewImageRep;
	
	BOOL										previewing;
	
	BOOL										showsImageBackground;
	
}


@property (nonatomic, copy) NSArray *animationImageReps;


- (void)startAnimating;
- (void)stopAnimating;

- (BOOL)isAnimating;


@property (assign) IBOutlet id <TKImageViewDelegate> delegate;

@property (nonatomic, retain) TKImageRep *previewImageRep;

@property (assign, getter=isPreviewing) BOOL previewing;


@property (nonatomic, assign) BOOL showsImageBackground;



- (IBAction)toggleShowImageBackground:(id)sender;

- (IBAction)zoom:(id)sender;


@end


