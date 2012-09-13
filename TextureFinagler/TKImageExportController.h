//
//  TKImageExportController.h
//  Texture Kit
//
//  Created by Mark Douma on 12/11/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class TKImage, TKImageExportPreviewViewController, TKImageDocument, TKImageExportPreset;



@interface TKImageExportController : NSWindowController {
	IBOutlet NSBox							*mainBox;
	
	IBOutlet NSPopUpButton					*presetPopUpButton;
	IBOutlet NSPopUpButton					*formatPopUpButton;
	IBOutlet NSPopUpButton					*compressionPopUpButton;
	IBOutlet NSPopUpButton					*qualityPopUpButton;
	IBOutlet NSTextField					*qualityField;
	IBOutlet NSButton						*mipmapsCheckbox;
	
	IBOutlet NSMenu							*vtfMenu;
	IBOutlet NSMenu							*ddsMenu;
	
	IBOutlet NSView							*dualView;
	IBOutlet NSBox							*dualViewFirstBox;
	IBOutlet NSBox							*dualViewSecondBox;

	IBOutlet NSView							*quadView;
	IBOutlet NSBox							*quadViewFirstBox;
	IBOutlet NSBox							*quadViewSecondBox;
	IBOutlet NSBox							*quadViewThirdBox;
	IBOutlet NSBox							*quadViewFourthBox;
	
	IBOutlet NSPanel						*managePresetPanel;
	
	IBOutlet NSArrayController				*presetController;
	NSMutableArray							*presets;
	
	TKImageExportPreset						*firstPreset;
	TKImageExportPreset						*secondPreset;
	TKImageExportPreset						*thirdPreset;
	TKImageExportPreset						*fourthPreset;
	
	
	TKImageDocument							*document;	// non-retained
	
	
	TKImageExportPreviewViewController		*firstController;
	TKImageExportPreviewViewController		*secondController;
	TKImageExportPreviewViewController		*thirdController;
	TKImageExportPreviewViewController		*fourthController;

	
	
	NSOperationQueue						*operationQueue;
	
	
	NSInteger								previewMode;
	
//	IBOutlet TKImageView			*imageView;
	
	TKImage									*image;
}

- (id)initWithImageDocument:(TKImageDocument *)aDocument;


@property (nonatomic, assign) NSInteger previewMode;
@property (retain) TKImage *image;
@property (assign) TKImageDocument *document;

- (IBAction)cancel:(id)sender;
- (IBAction)export:(id)sender;

- (IBAction)changePreset:(id)sender;
- (IBAction)changeFormat:(id)sender;
- (IBAction)changeCompression:(id)sender;
- (IBAction)changeQuality:(id)sender;
- (IBAction)changeMipmaps:(id)sender;

- (IBAction)managePresets:(id)sender;

@end
