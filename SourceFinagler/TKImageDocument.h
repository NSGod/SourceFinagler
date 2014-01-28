//
//  TKImageDocument.h
//  Texture Kit
//
//  Created by Mark Douma on 10/15/2010.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <TextureKit/TextureKit.h>

#import "TKImageView.h"
#import "TKImageInspectorController.h"

#import "TKImageChannel.h"


TEXTUREKIT_EXTERN NSString * const TKShouldShowImageInspectorKey;
TEXTUREKIT_EXTERN NSString * const TKShouldShowImageInspectorDidChangeNotification;


TEXTUREKIT_EXTERN NSString *TKImageIOLocalizedString(NSString *key);
	

@class IKImageBrowserView, TKImage, IKSaveOptions, TKImageExportController, TKImageDocumentAccessoryViewController, TKImageExportPreset;

@class TKBlueBackgroundView;
@class TKGrayscaleFilter;

@class CIFilter;


@interface TKImageDocument : NSDocument <NSSplitViewDelegate, NSMenuDelegate, NSToolbarDelegate, NSWindowDelegate, NSUserInterfaceValidations, TKImageInspectorDataSource> {
									  
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
	
	IBOutlet NSSegmentedControl					*toolModeControl;
	
	IBOutlet NSSegmentedControl					*viewControl;
	IBOutlet NSToolbarItem						*togglePlayToolbarItem;
	IBOutlet NSSegmentedControl					*togglePlaySegmentedControl;
	
	
	
	IBOutlet NSPanel							*normalMapPanel;
	
	IBOutlet NSPanel							*grayscalePanel;
	
	
	TKImage										*image;
	
	NSDictionary								*metadata;
	NSString									*dimensions;
	
	NSMutableArray								*visibleFaceBrowserItems;
	NSMutableArray								*visibleFrameBrowserItems;
	
	NSMutableArray								*visibleMipmapReps;
	
	
	IKSaveOptions								*saveOptions;
	
	TKImageExportController						*imageExportController;
	
	TKImageDocumentAccessoryViewController		*accessoryViewController;
	
	TKImageExportPreset							*exportPreset;
	
	CGFloat										faceBrowserWidth;
	CGFloat										frameBrowserHeight;
	CGFloat										mipmapBrowserWidth;
	
	BOOL										shouldShowFaceBrowserView;
	BOOL										shouldShowFrameBrowserView;
	BOOL										shouldShowMipmapBrowserView;
	
	
	CGFloat										redScale;
	CGFloat										greenScale;
	CGFloat										blueScale;
	CGFloat										alphaScale;
	
	CGFloat										small;
	CGFloat										medium;
	CGFloat										big;
	CGFloat										large;

	TKWrapMode									normalMapWrapMode;
	
	BOOL										normalizeMipmaps;
	
	TKGrayscaleFilter							*grayscaleFilter;
	
	
	TKImageInspectorController					*imageInspectorController;	// non-retained
	
	NSMutableArray								*imageChannels;
	
	NSMutableDictionary							*imageChannelNamesAndFilters;
	
	TKImageChannelMask							imageChannelMask;
	
	NSArray										*draggedFilenames;
	
	IKImageBrowserView							*currentMenuBrowserView;
}

@property (retain) TKImage *image;

@property (retain) NSString *dimensions;

@property (retain) TKImageExportPreset *exportPreset;


@property (assign) BOOL shouldShowFaceBrowserView;
@property (assign) BOOL shouldShowFrameBrowserView;
@property (assign) BOOL shouldShowMipmapBrowserView;


@property (assign) CGFloat redScale;
@property (assign) CGFloat greenScale;
@property (assign) CGFloat blueScale;
@property (assign) CGFloat alphaScale;

@property (assign) CGFloat small;
@property (assign) CGFloat medium;
@property (assign) CGFloat big;
@property (assign) CGFloat large;

@property (assign) TKWrapMode normalMapWrapMode;

@property (assign) BOOL normalizeMipmaps;

@property (retain) TKGrayscaleFilter *grayscaleFilter;

@property (assign) TKImageInspectorController *imageInspectorController;

@property (retain) NSArray *draggedFilenames;

@property (assign) IKImageBrowserView *currentMenuBrowserView;


- (IBAction)cancel:(id)sender;
- (IBAction)exportWithPreset:(TKImageExportPreset *)preset;

- (IBAction)importImageSequence:(id)sender;


- (IBAction)changeToolMode:(id)sender;

- (IBAction)changeViewMode:(id)sender;


- (IBAction)normalMap:(id)sender;
- (IBAction)previewNormalMap:(id)sender;
- (IBAction)applyNormalMap:(id)sender;

- (IBAction)generateMipmaps:(id)sender;
- (IBAction)removeMipmaps:(id)sender;


- (IBAction)grayscale:(id)sender;
- (IBAction)previewGrayscale:(id)sender;
- (IBAction)applyGrayscale:(id)sender;


- (IBAction)togglePlayAnimation:(id)sender;
- (IBAction)toggleAutomaticallyResize:(id)sender;



- (BOOL)acceptsImageInspectorControl:(TKImageInspectorController *)controller;
- (void)beginImageInspectorControl:(TKImageInspectorController *)controller;
- (void)endImageInspectorControl:(TKImageInspectorController *)controller;


@end

TEXTUREKIT_EXTERN NSString * const TKImageDocumentShowFaceBrowserViewKey;
TEXTUREKIT_EXTERN NSString * const TKImageDocumentShowFrameBrowserViewKey;
TEXTUREKIT_EXTERN NSString * const TKImageDocumentShowMipmapBrowserViewKey;
TEXTUREKIT_EXTERN NSString * const TKImageDocumentDoNotShowWarningAgainKey;


