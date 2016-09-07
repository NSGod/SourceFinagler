//
//  TKImageExportPreviewView.h
//  Source Finagler
//
//  Created by Mark Douma on 7/17/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TKImageExportPreviewView, TKImageExportPreviewViewController;


@protocol TKImageExportPreviewViewDelegate <NSObject>
- (void)didSelectImageExportPreviewView:(TKImageExportPreviewView *)anImageExportPreviewView;
@end


@interface TKImageExportPreviewView : NSView {
	IBOutlet id <TKImageExportPreviewViewDelegate>	delegate;			// non-retained
	IBOutlet TKImageExportPreviewViewController		*viewController;	// non-retained
	BOOL											isHighlighted;
}

@property (nonatomic, assign) id <TKImageExportPreviewViewDelegate> delegate;
@property (nonatomic, assign) TKImageExportPreviewViewController *viewController;
@property (nonatomic, assign, setter=setHighlighted:) BOOL isHighlighted;


@end


