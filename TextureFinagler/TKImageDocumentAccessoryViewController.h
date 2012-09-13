//
//  TKImageDocumentAccessoryViewController.h
//  Texture Kit
//
//  Created by Mark Douma on 1/5/2011.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <TextureKit/TextureKitDefines.h>
#import <TextureKit/TKDDSImageRep.h>
#import <TextureKit/TKVTFImageRep.h>


@class TKImage, TKImageDocument;


@interface TKImageDocumentAccessoryViewController : NSViewController {
	
	TKImageDocument					*document;		// non-retained
	
	NSSavePanel						*savePanel;		// non-retained
	
	IBOutlet NSPopUpButton			*formatPopUpButton;
	
	IBOutlet NSBox					*compressionBox;
	IBOutlet NSView					*compressionView;
	IBOutlet NSPopUpButton			*compressionPopUpButton;
	
	IBOutlet NSMenu					*vtfMenu;
	IBOutlet NSMenu					*ddsMenu;
	IBOutlet NSMenu					*tiffMenu;
	IBOutlet NSButton				*mipmapsCheckbox;
	
	IBOutlet NSView					*jpegQualityView;
	
	IBOutlet NSView					*blankView;
	
	
	NSArray							*imageUTTypes;
	
	NSString						*imageUTType;
	
	TKVTFFormat						vtfFormat;
	
	TKDDSFormat						ddsFormat;
	
	NSTIFFCompression				tiffCompression;
	
	TKDXTCompressionQuality			compressionQuality;
	
	CGFloat							jpegQuality;
}

- (id)initWithImageDocument:(TKImageDocument *)aDocument;

@property (assign) TKImageDocument *document;
@property (assign) NSSavePanel *savePanel;


@property (retain) NSString *imageUTType;
@property (readonly) NSDictionary *imageProperties;

@property (assign) TKVTFFormat vtfFormat;
@property (assign) TKDDSFormat ddsFormat;
@property (assign) TKDXTCompressionQuality compressionQuality;
@property (assign) CGFloat jpegQuality;


- (BOOL)prepareSavePanel:(NSSavePanel *)aSavePanel;

// save accessory panel
- (IBAction)changeFormat:(id)sender;
- (IBAction)changeCompression:(id)sender;


@end

TEXTUREKIT_EXTERN NSString * const TKImageDocumentLastSavedFormatTypeKey;



