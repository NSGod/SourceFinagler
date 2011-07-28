//
//  TKImageDocument.h
//  Texture Kit
//
//  Created by Mark Douma on 10/15/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <TextureKit/TextureKit.h>

#import "TKImageView.h"


TEXTUREKIT_EXTERN NSString *TKImageIOLocalizedString(NSString *key);
	

@class IKImageBrowserView, TKImage, IKSaveOptions, TKImageExportController, TKImageDocumentAccessoryViewController, TKImageExportPreset;


@interface TKImageDocument : NSDocument <NSMenuDelegate, NSToolbarDelegate, NSWindowDelegate, NSUserInterfaceValidations, TKImageViewAnimatedImageDataSource> {
	IBOutlet NSWindow							*imageWindow;
	IBOutlet TKImageView						*imageView;
	IBOutlet IKImageBrowserView					*frameBrowserView;
	IBOutlet IKImageBrowserView					*mipmapBrowserView;
	
	IBOutlet NSSegmentedControl					*viewControl;
	IBOutlet NSToolbarItem						*togglePlayToolbarItem;
	IBOutlet NSSegmentedControl					*togglePlaySegmentedControl;
	
	IBOutlet NSView								*frameBrowserViewView;
	
	IBOutlet NSView								*mipmapBrowserViewView;
	
	TKImage										*image;
	
	NSDictionary								*metadata;
	NSString									*dimensions;
	
	NSMutableArray								*visibleMipmapReps;
	
	IKSaveOptions								*saveOptions;
	
	TKImageExportController						*imageExportController;
	
	TKImageDocumentAccessoryViewController		*accessoryController;
	
	TKImageExportPreset							*exportPreset;
	
	BOOL										shouldShowFrameBrowserView;
	BOOL										shouldShowMipmapBrowserView;
	
	CGFloat										frameBrowserHeight;
	CGFloat										mipmapBrowserWidth;
	
}

@property (retain) TKImage *image;

@property (retain) NSString *dimensions;

@property (retain) TKImageExportPreset *exportPreset;


@property (assign) BOOL shouldShowFrameBrowserView;
@property (assign) BOOL shouldShowMipmapBrowserView;


- (IBAction)cancel:(id)sender;
- (IBAction)exportWithPreset:(TKImageExportPreset *)preset;

- (IBAction)changeToolMode:(id)sender;

- (IBAction)changeViewMode:(id)sender;


- (IBAction)togglePlayAnimation:(id)sender;
- (IBAction)toggleAutomaticallyResize:(id)sender;

- (IBAction)changeColumnCount:(id)sender;
- (IBAction)changeBrowserSortOptions:(id)sender;

- (IBAction)openInNewWindow:(id)sender;
- (IBAction)saveCopyToFolder:(id)sender;

- (IBAction)sendImageTo:(id)sender;


@end

TEXTUREKIT_EXTERN NSString * const TKImageDocumentShowFrameBrowserViewKey;
TEXTUREKIT_EXTERN NSString * const TKImageDocumentShowMipmapBrowserViewKey;
TEXTUREKIT_EXTERN NSString * const TKImageDocumentDoNotShowWarningAgainKey;


