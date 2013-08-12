//
//  TKImageDocumentAccessoryViewController.h
//  Texture Kit
//
//  Created by Mark Douma on 1/5/2011.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <TextureKit/TextureKit.h>


@class TKImage, TKImageDocument;


@interface TKImageDocumentAccessoryViewController : NSViewController {
	
	TKImageDocument					*document;		// non-retained
	
	NSSavePanel						*savePanel;		// non-retained
	
	TKImage							*image;			// non-retained
	
	IBOutlet NSObjectController		*mediator;
	
	IBOutlet NSPopUpButton			*formatPopUpButton;
	
	IBOutlet NSBox					*compressionBox;
	
	IBOutlet NSView					*compressionView;
	IBOutlet NSPopUpButton			*compressionPopUpButton;
	
	IBOutlet NSView					*tiffCompressionView;
	
	
	IBOutlet NSMenu					*vtfMenu;
	IBOutlet NSMenu					*ddsMenu;
	
	IBOutlet NSView					*jpegQualityView;
	
	IBOutlet NSView					*jpeg2000QualityView;
	
	IBOutlet NSView					*alphaView;
	
	IBOutlet NSView					*blankView;
	
	
	NSArray							*imageUTTypes;
	
	NSString						*imageUTType;
	
	TKVTFFormat						vtfFormat;
	
	TKDDSFormat						ddsFormat;
	
	TKDXTCompressionQuality			compressionQuality;
	
	NSTIFFCompression				tiffCompression;
	
	CGFloat							jpegQuality;
	CGFloat							jpeg2000Quality;
	
	BOOL							saveAlpha;
	
	BOOL							generateMipmaps;
}

- (id)initWithImageDocument:(TKImageDocument *)aDocument;

- (void)cleanup;


@property (assign) TKImageDocument *document;
@property (assign) NSSavePanel *savePanel;
@property (assign) TKImage *image;


@property (retain) NSString *imageUTType;
@property (readonly) NSDictionary *imageProperties;

@property (assign) TKVTFFormat vtfFormat;
@property (assign) TKDDSFormat ddsFormat;
@property (assign) TKDXTCompressionQuality compressionQuality;

@property (assign) NSTIFFCompression tiffCompression;
@property (assign) CGFloat jpegQuality;
@property (assign) CGFloat jpeg2000Quality;

@property (assign) BOOL saveAlpha;

@property (assign) BOOL generateMipmaps;


- (BOOL)prepareSavePanel:(NSSavePanel *)aSavePanel;

// save accessory panel
- (IBAction)changeFormat:(id)sender;
- (IBAction)changeCompression:(id)sender;


@end

//TEXTUREKIT_EXTERN NSString * const TKImageDocumentLastSavedFormatTypeKey;



