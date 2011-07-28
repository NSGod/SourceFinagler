//
//  TKImageExportController.h
//  Texture Kit
//
//  Created by Mark Douma on 12/11/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TKImageExportPreviewView.h"
#import "TKImageView.h"
#import <TextureKit/TextureKit.h>

@class TKImage, TKImageExportPreviewViewController, TKImageDocument, TKImageExportPreset, TKImageExportPreview;



@interface TKImageExportController : NSWindowController <TKImageExportPreviewViewDelegate, TKImageViewDelegate, NSMenuDelegate> {
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
	
	
	TKImageDocument							*document;	// non-retained
	
	
	IBOutlet NSObjectController				*presetController;
	
	NSMutableDictionary						*presetsAndNames;
	
	TKImageExportPreset						*preset;
	
	
	NSMutableArray							*presets;
	
	NSMutableArray							*previewControllers;
	NSMutableArray							*previews;
	
	NSInteger								previewMode;
	
	NSInteger								selectedTag;
	
	NSOperationQueue						*operationQueue;
	
	TKImage									*image;
	
	NSMutableDictionary						*tagsAndOperations;
	
	TKVTFFormat								vtfFormat;
	TKDDSFormat								ddsFormat;
	
}

- (id)initWithImageDocument:(TKImageDocument *)aDocument;


@property (assign) TKImageDocument *document;

@property (copy) TKImageExportPreset *preset;
//@property (retain) TKImageExportPreset *preset;

@property (assign) NSInteger previewMode;

@property (assign) NSInteger selectedTag;

@property (retain) TKImage *image;



- (IBAction)cancel:(id)sender;
- (IBAction)export:(id)sender;

- (IBAction)changePreset:(id)sender;
- (IBAction)changeFormat:(id)sender;
- (IBAction)changeCompression:(id)sender;
- (IBAction)changeQuality:(id)sender;
- (IBAction)changeMipmaps:(id)sender;

- (IBAction)managePresets:(id)sender;

@end


