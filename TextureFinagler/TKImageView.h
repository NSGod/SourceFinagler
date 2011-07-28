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

@protocol TKImageViewAnimatedImageDataSource <NSObject>
- (NSArray *)imageRepsForAnimationInImageView:(TKImageView *)anImageView;
@end


@protocol TKImageViewDelegate <NSObject>
- (void)imageViewDidBecomeFirstResponder:(TKImageView *)anImageView;
@end


@interface TKImageView : IKImageView {
	NSArray										*imageReps;
	
	id <TKImageViewAnimatedImageDataSource>		dataSource;		// non-retained
	
	id <TKImageViewDelegate>					delegate;		// non-retained
	
	
	CALayer										*animatedImageLayer;
	
	CALayer										*oldLayer;
	
	BOOL										playing;
}

@property (retain) NSArray *imageReps;

@property (assign) IBOutlet id <TKImageViewAnimatedImageDataSource> dataSource;

@property (assign) IBOutlet id <TKImageViewDelegate> delegate;

@property (assign, getter=isPlaying) BOOL playing;

//@property (nonatomic, retain) NSArray *imageReps;
//
//@property (nonatomic, assign) IBOutlet id <TKImageViewAnimatedImageDataSource> dataSource;
//
//@property (nonatomic, assign, getter=isPlaying) BOOL playing;

- (IBAction)togglePlay:(id)sender;

- (IBAction)zoom:(id)sender;

@end
