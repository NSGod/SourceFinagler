//
//  TKImageExportController.h
//  Source Finagler
//
//  Created by Mark Douma on 12/11/2010.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TKImageExportPreviewView.h"
#import "TKImageView.h"
#import <TextureKit/TextureKit.h>

@class TKImageExportPreviewViewController, TKImageDocument, TKImageExportPreset, TKImageExportPreview;



@interface TKImageExportController : NSWindowController <TKImageExportPreviewViewDelegate, TKImageViewDelegate, NSMenuDelegate> {
	IBOutlet NSBox							*mainBox;
	
	IBOutlet NSPopUpButton					*presetPopUpButton;
	
	IBOutlet NSTextField					*formatField;
	IBOutlet NSPopUpButton					*formatPopUpButton;
	
	IBOutlet NSTextField					*compressionField;
	IBOutlet NSPopUpButton					*compressionPopUpButton;
	
	IBOutlet NSTextField					*qualityField;
	IBOutlet NSPopUpButton					*qualityPopUpButton;
	
	IBOutlet NSButton						*mipmapsCheckbox;
	
	IBOutlet NSTextField					*mipmapsField;
	IBOutlet NSPopUpButton					*mipmapsPopUpButton;
	
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
	
	IBOutlet NSObjectController				*mediator;
	
	
	IBOutlet NSObjectController				*zoomMediator;
	
	CGFloat									previewViewZoomFactor;
	
	
	TKImageDocument							*document;	// non-retained
	
	
	NSMutableDictionary						*presetsAndNames;
	
	TKImageExportPreset						*preset;
	
	
	NSMutableArray							*presets;
	
	NSMutableArray							*previewControllers;
	
	NSInteger								previewMode;
	
	NSInteger								selectedTag;
	
	NSOperationQueue						*operationQueue;
	
	TKImage									*image;
	
	NSMutableDictionary						*tagsAndOperations;
	
	TKVTFFormat								vtfFormat;
	TKDDSFormat								ddsFormat;
	
}

- (id)initWithImageDocument:(TKImageDocument *)aDocument;

- (void)cleanup;


@property (nonatomic, assign) CGFloat previewViewZoomFactor;

@property (nonatomic, assign) TKImageDocument *document;

@property (nonatomic, retain) TKImageExportPreset *preset;

@property (nonatomic, assign) NSInteger previewMode;

@property (nonatomic, assign) NSInteger selectedTag;

@property (nonatomic, retain) TKImage *image;



- (IBAction)cancel:(id)sender;
- (IBAction)export:(id)sender;

- (IBAction)changePreset:(id)sender;
- (IBAction)changeFormat:(id)sender;
- (IBAction)changeCompression:(id)sender;
- (IBAction)changeQuality:(id)sender;
- (IBAction)changeMipmaps:(id)sender;

- (IBAction)managePresets:(id)sender;

- (IBAction)changeTool:(id)sender;


@end


