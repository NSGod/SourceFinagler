//
//  TKImageView.h
//  Source Finagler
//
//  Created by Mark Douma on 11/15/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@class TKImageView;

enum {
	TKImageViewZoomOutTag			= -1,
	TKImageViewZoomActualSizeTag	= 0,
	TKImageViewZoomInTag			= 1
};


@interface TKImageView : IKImageView {
	@private
	id	_TK__private;
	
	
}


@property (copy) NSArray *animationImageReps;


- (void)startAnimating;
- (void)stopAnimating;

- (BOOL)isAnimating;


- (IBAction)zoom:(id)sender;

@end


