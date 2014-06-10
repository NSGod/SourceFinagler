//
//  TKImageDocumentAccessoryViewController.h
//  Source Finagler
//
//  Created by Mark Douma on 1/5/2011.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <TextureKit/TextureKit.h>


@class TKImageDocument;


@interface TKImageDocumentAccessoryViewController : NSViewController <NSMenuDelegate> {
	
	TKImageDocument					*document;		// non-retained
	
	NSSavePanel						*savePanel;		// non-retained
	
	TKImage							*image;			// non-retained
	
	TKImage							*previewImage;
	
	
	IBOutlet NSObjectController		*mediator;
	
	IBOutlet NSPopUpButton			*formatPopUpButton;
	
	IBOutlet NSBox					*compressionBox;
	
	IBOutlet NSView					*compressionView;
	IBOutlet NSPopUpButton			*compressionPopUpButton;
	
	IBOutlet NSTextField			*compressionQualityTextField;
	IBOutlet NSPopUpButton			*compressionQualityPopUpButton;
	
	IBOutlet NSButton				*ddsContainerCheckbox;
	
	IBOutlet NSTextField			*originalImageWidthField;
	IBOutlet NSTextField			*originalImageHeightField;
	
	IBOutlet NSImageView			*previewImageView;
	IBOutlet NSTextField			*previewImageWidthField;
	IBOutlet NSTextField			*previewImageHeightField;
	
	IBOutlet NSView					*tiffCompressionView;
	
	
	IBOutlet NSMenu					*vtfMenu;
	IBOutlet NSMenu					*ddsMenu;
	
	IBOutlet NSView					*jpegQualityView;
	
	IBOutlet NSView					*jpeg2000QualityView;
	
	IBOutlet NSView					*alphaView;
	
	IBOutlet NSView					*blankView;
	
	
	NSString						*imageUTType;
	
	TKVTFFormat						vtfFormat;
	
	TKDDSFormat						dds9Format;
	
	TKDDSFormat						dds10Format;
	
	TKDDSContainer					ddsContainer;
	
	
	TKDXTCompressionQuality			compressionQuality;
	
	BOOL							generateMipmaps;
	TKMipmapGenerationType			mipmapGenerationType;
	
	TKResizeMode					resizeMode;
	
	
	NSTIFFCompression				tiffCompression;
	
	CGFloat							jpegQuality;
	CGFloat							jpeg2000Quality;
	
	BOOL							saveAlpha;
	
	
}

- (id)initWithImageDocument:(TKImageDocument *)aDocument;

- (void)cleanup;


@property (nonatomic, assign) TKImageDocument *document;
@property (nonatomic, assign) NSSavePanel *savePanel;
@property (nonatomic, assign) TKImage *image;

@property (nonatomic, retain) TKImage *previewImage;


@property (nonatomic, retain) NSString *imageUTType;

/* The following returns a properties dictionary suitable for passing to `TKImage`'s `representationUsingImageType:properties:` method. */
@property (readonly, nonatomic, retain) NSDictionary *imageProperties;

@property (nonatomic, assign) TKVTFFormat vtfFormat;

@property (nonatomic, assign) TKDDSFormat dds9Format;
@property (nonatomic, assign) TKDDSFormat dds10Format;

@property (nonatomic, assign) TKDDSContainer ddsContainer;


@property (nonatomic, assign) TKDXTCompressionQuality compressionQuality;

@property (nonatomic, assign) BOOL generateMipmaps;
@property (nonatomic, assign) TKMipmapGenerationType mipmapGenerationType;

@property (nonatomic, assign) TKResizeMode resizeMode;


/* The following returns an options dictionary suitable for passing to `TKImage`'s *RepresentationWithOptions: methods. It will contain 
 the key/value pairs based on the current selected options for creating mipmaps, resizing, etc. */
@property (readonly, nonatomic, retain) NSDictionary *options;


@property (nonatomic, assign) NSTIFFCompression tiffCompression;
@property (nonatomic, assign) CGFloat jpegQuality;
@property (nonatomic, assign) CGFloat jpeg2000Quality;

@property (nonatomic, assign) BOOL saveAlpha;




- (BOOL)prepareSavePanel:(NSSavePanel *)aSavePanel;

- (IBAction)changeFormat:(id)sender;
- (IBAction)changeCompression:(id)sender;
- (IBAction)changeResizeMode:(id)sender;

- (IBAction)changeDDSContainer:(id)sender;


// save accessory panel
- (void)saveDefaults;

@end



