//
//  TKImageDocument.h
//  Source Finagler
//
//  Created by Mark Douma on 10/15/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <TextureKit/TextureKit.h>

#import "TKImageView.h"


TEXTUREKIT_EXTERN NSString *TKImageIOLocalizedString(NSString *key);
	

@class IKImageBrowserView, TKImage, IKSaveOptions, TKImageExportController, TKImageDocumentAccessoryViewController;

@class TKBlueBackgroundView;


@interface TKImageDocument : NSDocument <NSSplitViewDelegate, NSMenuDelegate, NSWindowDelegate> {
	
	IBOutlet NSWindow							*imageWindow;
	
	IBOutlet NSSplitView						*mainSplitView;
	
	IBOutlet TKImageView						*imageView;
	
	IBOutlet NSSplitView						*facesMipmapsSplitView;
	
	IBOutlet IKImageBrowserView					*faceBrowserView;
	IBOutlet TKBlueBackgroundView				*faceBrowserViewView;
	
	IBOutlet IKImageBrowserView					*frameBrowserView;
	IBOutlet TKBlueBackgroundView				*frameBrowserViewView;
	
	IBOutlet IKImageBrowserView					*mipmapBrowserView;
	IBOutlet TKBlueBackgroundView				*mipmapBrowserViewView;
	
	
	IBOutlet NSSegmentedControl					*viewControl;
	IBOutlet NSToolbarItem						*togglePlayToolbarItem;
	IBOutlet NSSegmentedControl					*togglePlaySegmentedControl;
	
	
	
	TKImage										*image;
	
	NSDictionary								*metadata;
	NSString									*dimensions;
	
	NSMutableArray								*visibleFaceBrowserItems;
	NSMutableArray								*visibleFrameBrowserItems;
	
	NSMutableArray								*visibleMipmapReps;
	
	
	IKSaveOptions								*saveOptions;
	
	TKImageExportController						*imageExportController;
	
	TKImageDocumentAccessoryViewController		*accessoryViewController;
	
	
	
	CGFloat										faceBrowserWidth;
	CGFloat										frameBrowserHeight;
	CGFloat										mipmapBrowserWidth;
	
	BOOL										shouldShowFaceBrowserView;
	BOOL										shouldShowFrameBrowserView;
	BOOL										shouldShowMipmapBrowserView;
	
	
}

@property (nonatomic, retain) TKImage *image;

@property (nonatomic, retain) NSString *dimensions;


@property (nonatomic, assign) BOOL shouldShowFaceBrowserView;
@property (nonatomic, assign) BOOL shouldShowFrameBrowserView;
@property (nonatomic, assign) BOOL shouldShowMipmapBrowserView;


- (IBAction)cancel:(id)sender;
- (IBAction)export:(id)sender;


- (IBAction)changeToolMode:(id)sender;

- (IBAction)changeViewMode:(id)sender;


- (IBAction)togglePlayAnimation:(id)sender;
- (IBAction)toggleAutomaticallyResize:(id)sender;


@end

TEXTUREKIT_EXTERN NSString * const TKImageDocumentShowFaceBrowserViewKey;
TEXTUREKIT_EXTERN NSString * const TKImageDocumentShowFrameBrowserViewKey;
TEXTUREKIT_EXTERN NSString * const TKImageDocumentShowMipmapBrowserViewKey;
TEXTUREKIT_EXTERN NSString * const TKImageDocumentDoNotShowWarningAgainKey;


