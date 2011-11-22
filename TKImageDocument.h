//
//  TKImageDocument.h
//  Texture Kit
//
//  Created by Mark Douma on 10/15/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <TextureKit/TextureKitDefines.h>
#import <TextureKit/TKDDSImageRep.h>
#import <TextureKit/TKVTFImageRep.h>

#import "TKImageView.h"


TEXTUREKIT_EXTERN NSString *TKImageIOLocalizedString(NSString *key);
	

@class IKImageBrowserView, TKImage, IKSaveOptions, TKImageExportController, TKImageDocumentAccessoryViewController;


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
	
	IBOutlet NSWindow								*originalWindow;
	
	IBOutlet NSWindow								*conversionWindow;
	IBOutlet IKImageBrowserView				*conversionFrameBrowserView;
	IBOutlet IKImageBrowserView				*conversionMipmapBrowserView;
	IBOutlet TKImageView					*conversionImageView;
	

	TKImage									*convertedImage;
	NSMutableArray							*convertedVisibleMipmapReps;
	
	
	IBOutlet NSPopUpButton					*conversionFormatPopUpButton;
	IBOutlet NSPopUpButton					*conversionCompressionPopUpButton;
	IBOutlet NSMenu							*conversionVTFMenu;
	IBOutlet NSMenu							*conversionDDSMenu;
	
	TKVTFFormat								conversionVTFFormat;
	TKDDSFormat								conversionDDSFormat;
	
	TKDXTCompressionQuality					compressionQuality;
	
	BOOL										shouldShowFrameBrowserView;
	BOOL										shouldShowMipmapBrowserView;
	
	CGFloat										frameBrowserHeight;
	CGFloat										mipmapBrowserWidth;
	
	BOOL										closingDocument;
}

@property (retain) TKImage *image;

@property (assign) TKVTFFormat conversionVTFFormat;

@property (assign) TKDDSFormat conversionDDSFormat;

@property (assign) TKDXTCompressionQuality compressionQuality;

@property (retain) NSString *dimensions;


@property (assign) BOOL shouldShowFrameBrowserView;
@property (assign) BOOL shouldShowMipmapBrowserView;


- (IBAction)cancel:(id)sender;
- (IBAction)export:(id)sender;


- (IBAction)changeToolMode:(id)sender;

- (IBAction)changeViewMode:(id)sender;


- (IBAction)togglePlayAnimation:(id)sender;
- (IBAction)toggleAutomaticallyResize:(id)sender;

- (IBAction)changeColumnCount:(id)sender;
- (IBAction)changeBrowserSortOptions:(id)sender;

- (IBAction)openInNewWindow:(id)sender;
- (IBAction)saveCopyToFolder:(id)sender;

- (IBAction)sendImageTo:(id)sender;



- (IBAction)createImage:(id)sender;
- (IBAction)changeConversionFormat:(id)sender;
- (IBAction)changeConversionCompression:(id)sender;


@end

TEXTUREKIT_EXTERN NSString * const TKImageDocumentShowFrameBrowserViewKey;
TEXTUREKIT_EXTERN NSString * const TKImageDocumentShowMipmapBrowserViewKey;
TEXTUREKIT_EXTERN NSString * const TKImageDocumentDoNotShowWarningAgainKey;


