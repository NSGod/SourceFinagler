//
//  TKImageDocumentAccessoryViewController.m
//  Texture Kit
//
//  Created by Mark Douma on 1/5/2011.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import "TKImageDocumentAccessoryViewController.h"
#import "TKImageDocument.h"

#import <TextureKit/TextureKit.h>

#import "MDAppKitAdditions.h"



static NSString * const kTKUTTypeTGA = @"com.truevision.tga-image";
static NSString * const kTKUTTypePSD = @"com.adobe.photoshop-image";
static NSString * const kTKUTTypeOpenEXR = @"com.ilm.openexr-image";
static NSString * const kTKUTTypeSGI = @"com.sgi.sgi-image";



static NSString * const TKImageDocumentLastSavedFormatTypeKey		= @"TKImageDocumentLastSavedFormatType";

static NSString * const TKImageDocumentVTFFormatKey					= @"TKImageDocumentVTFFormat";
static NSString * const TKImageDocumentDDSFormatKey					= @"TKImageDocumentDDSFormat";
static NSString * const TKImageDocumentGenerateMipmapsKey			= @"TKImageDocumentGenerateMipmaps";

static NSString * const TKImageDocumentTIFFCompressionKey			= @"TKImageDocumentTIFFCompression";

static NSString * const TKImageDocumentJPEGQualityKey				= @"TKImageDocumentJPEGQuality";
static NSString * const TKImageDocumentJPEG2000QualityKey			= @"TKImageDocumentJPEG2000Quality";

static NSString * const TKImageDocumentSaveAlphaKey					= @"TKImageDocumentSaveAlpha";


static NSMutableDictionary *displayNameAndUTITypes = nil;


@implementation TKImageDocumentAccessoryViewController

@synthesize document;
@synthesize savePanel;
@synthesize image;
@synthesize imageUTType;
@synthesize vtfFormat;
@synthesize ddsFormat;
@synthesize compressionQuality;
@synthesize tiffCompression;
@synthesize jpegQuality;
@synthesize jpeg2000Quality;
@synthesize saveAlpha;
@synthesize generateMipmaps;


+ (void)initialize {
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject:TKSFTextureImageType forKey:TKImageDocumentLastSavedFormatTypeKey];
	[defaultValues setObject:[NSNumber numberWithUnsignedInteger:[TKVTFImageRep defaultFormat]] forKey:TKImageDocumentVTFFormatKey];
	[defaultValues setObject:[NSNumber numberWithUnsignedInteger:[TKDDSImageRep defaultFormat]] forKey:TKImageDocumentDDSFormatKey];
	[defaultValues setObject:[NSNumber numberWithDouble:0.8] forKey:TKImageDocumentJPEGQualityKey];
	[defaultValues setObject:[NSNumber numberWithDouble:0.8] forKey:TKImageDocumentJPEG2000QualityKey];
	[defaultValues setObject:[NSNumber numberWithUnsignedInteger:NSTIFFCompressionNone] forKey:TKImageDocumentTIFFCompressionKey];
	[defaultValues setObject:TKYES forKey:TKImageDocumentSaveAlphaKey];
	[defaultValues setObject:TKYES forKey:TKImageDocumentGenerateMipmapsKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


- (id)init {
	return [self initWithImageDocument:nil];
}


- (id)initWithImageDocument:(TKImageDocument *)aDocument {
	if ((self = [super initWithNibName:[self nibName] bundle:nil])) {
		document = aDocument;
		[self setImage:[document image]];
		
		[self setImageUTType:[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentLastSavedFormatTypeKey]];
		
		if (imageUTTypes == nil) imageUTTypes = [[[document class] writableTypes] retain];
		
		vtfFormat = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentVTFFormatKey] unsignedIntegerValue];
		ddsFormat = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentDDSFormatKey] unsignedIntegerValue];
		
		tiffCompression = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentTIFFCompressionKey] unsignedIntegerValue];
		
		jpegQuality = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentJPEGQualityKey] doubleValue];
		jpeg2000Quality = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentJPEG2000QualityKey] doubleValue];
		
		saveAlpha = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentSaveAlphaKey] boolValue];
		
		generateMipmaps = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentGenerateMipmapsKey] boolValue];
	}
	return self;
}


//- (void)dealloc {
////	document = nil;
////	savePanel = nil;
////	[imageUTType release];
////	[imageUTTypes release];
//	[super dealloc];
//}


- (void)cleanup {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[mediator unbind:@"contentObject"];
	[mediator setContent:nil];
	
	[imageUTType release];
	[imageUTTypes release];
	document = nil;
	savePanel = nil;
}




- (NSString *)nibName {
	return @"TKImageDocumentAccessoryView";
}


- (void)awakeFromNib {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	@synchronized([self class]) {
		if (displayNameAndUTITypes == nil) {
			displayNameAndUTITypes = [[NSMutableDictionary alloc] init];
			
			for (NSString *aSaveType in imageUTTypes) {
				NSString *displayName = [[NSDocumentController sharedDocumentController] displayNameForType:aSaveType];
				if (displayName) [displayNameAndUTITypes setObject:aSaveType forKey:displayName];
			}
		}
	}
	
	
	NSArray *sortedDisplayNames = [[displayNameAndUTITypes allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSMutableArray *menuItems = [NSMutableArray array];
	
	for (NSString *displayName in sortedDisplayNames) {
		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:displayName action:NULL keyEquivalent:@""] autorelease];
		if (menuItem) {
			[menuItems addObject:menuItem];
		}
	}
	[formatPopUpButton setItemArray:menuItems];
}



- (BOOL)prepareSavePanel:(NSSavePanel *)aSavePanel {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self setSavePanel:aSavePanel];
	[savePanel setAccessoryView:[self view]];
	[self changeFormat:self];
	
	return YES;
}


// save accessory panel
- (IBAction)changeFormat:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (sender == self) {
		// if it's us, then we need to set the selected item to type saved in user defaults
		NSArray *keys = [displayNameAndUTITypes allKeysForObject:imageUTType];
		if ([keys count]) {
			NSString *displayName = [keys objectAtIndex:0];
			[formatPopUpButton selectItemWithTitle:displayName];
		}
		[self setImageUTType:nil];
	}
	
	NSString *title = [formatPopUpButton titleOfSelectedItem];
	NSString *utiType = [displayNameAndUTITypes objectForKey:title];
	[self setImageUTType:utiType];
	
	NSArray *filenameExtensions = [[NSDocumentController sharedDocumentController] fileExtensionsFromType:imageUTType];
	NSString *filenameExtension = nil;
	
	if ([filenameExtensions count]) {
		filenameExtension = [filenameExtensions objectAtIndex:0];
		if (filenameExtension) [savePanel setAllowedFileTypes:[NSArray arrayWithObject:filenameExtension]];
	}
	
	if ([imageUTType isEqual:TKDDSType] ||
		[imageUTType isEqual:TKVTFType]) {
		
		
		if ([imageUTType isEqual:TKDDSType]) {
			
			[compressionPopUpButton setMenu:ddsMenu];
			[compressionPopUpButton selectItemWithTag:[compressionPopUpButton indexOfItemWithTag:ddsFormat]];
			
		} else {
			[compressionPopUpButton setMenu:vtfMenu];
			[compressionPopUpButton selectItemWithTag:[compressionPopUpButton indexOfItemWithTag:vtfFormat]];
		}
		
		[compressionBox setContentView:compressionView];
		
	} else if ([imageUTType isEqual:(NSString *)kUTTypeJPEG]) {
		
		[compressionBox setContentView:jpegQualityView];
		
	} else if ([imageUTType isEqual:(NSString *)kUTTypeJPEG2000]) {
		
		[compressionBox setContentView:jpeg2000QualityView];
	
	} else if ([imageUTType isEqual:(NSString *)kUTTypeTIFF]) {

		[compressionBox setContentView:tiffCompressionView];
		
	} else if ([imageUTType isEqual:(NSString *)kUTTypeBMP] ||
			   [imageUTType isEqual:(NSString *)kUTTypeAppleICNS] ||
			   [imageUTType isEqual:(NSString *)kUTTypeICO] ||
			   [imageUTType isEqual:kTKUTTypePSD] ||
			   [imageUTType isEqual:kTKUTTypeTGA] ||
			   [imageUTType isEqual:kTKUTTypeOpenEXR] ||
			   [imageUTType isEqual:(NSString *)kUTTypeGIF] ||
			   [imageUTType isEqual:(NSString *)kUTTypePDF] ||
			   [imageUTType isEqual:(NSString *)kUTTypePNG]) {
		
		[compressionBox setContentView:alphaView];
		
	} else {
		
		[compressionBox setContentView:blankView];
		
	}
}


- (IBAction)changeCompression:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ([imageUTType isEqual:TKDDSType]) {
		
		self.ddsFormat = [[compressionPopUpButton selectedItem] tag];
		
	} else if ([imageUTType isEqual:TKVTFType]) {
		
		self.vtfFormat = [[compressionPopUpButton selectedItem] tag];
	}
}


- (void)setNilValueForKey:(NSString *)key {
	
	if ([key isEqual:@"vtfFormat"]) {
		vtfFormat = [TKVTFImageRep defaultFormat];
		
	} else if ([key isEqual:@"ddsFormat"]) {
		ddsFormat = [TKDDSImageRep defaultFormat];
		
	} else if ([key isEqual:@"compressionQuality"]) {
		compressionQuality = [TKImageRep defaultDXTCompressionQuality];
		
	} else if ([key isEqual:@"tiffCompression"]) {
		tiffCompression = NSTIFFCompressionNone;
		
	} else if ([key isEqual:@"jpegQuality"]) {
		jpegQuality = 0.0;
		
	} else if ([key isEqual:@"jpeg2000Quality"]) {
		jpeg2000Quality = 0.0;
		
	} else if ([key isEqual:@"saveAlpha"]) {
		saveAlpha = NO;
		
	} else if ([key isEqual:@"generateMipmaps"]) {
		generateMipmaps = NO;
		
	} else if ([super respondsToSelector:@selector(setNilValueForKey:)]) {
		[super setNilValueForKey:key];
	}
}


- (void)saveDefaults {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:imageUTType forKey:TKImageDocumentLastSavedFormatTypeKey];
	[userDefaults setObject:[NSNumber numberWithUnsignedInteger:vtfFormat] forKey:TKImageDocumentVTFFormatKey];
	[userDefaults setObject:[NSNumber numberWithUnsignedInteger:ddsFormat] forKey:TKImageDocumentDDSFormatKey];
	[userDefaults setObject:[NSNumber numberWithDouble:jpegQuality] forKey:TKImageDocumentJPEGQualityKey];
	[userDefaults setObject:[NSNumber numberWithDouble:jpeg2000Quality] forKey:TKImageDocumentJPEG2000QualityKey];
	[userDefaults setObject:[NSNumber numberWithUnsignedInteger:tiffCompression] forKey:TKImageDocumentTIFFCompressionKey];
	[userDefaults setObject:(saveAlpha ? TKYES : TKNO) forKey:TKImageDocumentSaveAlphaKey];
	[userDefaults setObject:(generateMipmaps ? TKYES : TKNO) forKey:TKImageDocumentGenerateMipmapsKey];
}


- (NSDictionary *)imageProperties {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableDictionary *imgProperties = [NSMutableDictionary dictionary];
	
	BOOL imageHasAlpha = [image hasAlpha];
	
	if ([imageUTType isEqual:TKDDSType] || [imageUTType isEqual:TKVTFType]) {
		
		
	} else if ([imageUTType isEqual:(NSString *)kUTTypeJPEG]) {
		
		[imgProperties setObject:[NSNumber numberWithDouble:jpegQuality] forKey:(id)kCGImageDestinationLossyCompressionQuality];
		if (imageHasAlpha && saveAlpha) [imgProperties setObject:TKYES forKey:(id)kCGImagePropertyHasAlpha];
		
	} else if ([imageUTType isEqual:(NSString *)kUTTypeJPEG2000]) {
		
		[imgProperties setObject:[NSNumber numberWithDouble:jpeg2000Quality] forKey:(id)kCGImageDestinationLossyCompressionQuality];
		if (imageHasAlpha && saveAlpha) [imgProperties setObject:TKYES forKey:(id)kCGImagePropertyHasAlpha];
		
	} else if ([imageUTType isEqual:(NSString *)kUTTypeTIFF]) {
		
		[imgProperties setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:tiffCompression],(id)kCGImagePropertyTIFFCompression, nil]
						  forKey:(id)kCGImagePropertyTIFFDictionary];
		
		
	} else if ([imageUTType isEqual:(NSString *)kUTTypeBMP] ||
			   [imageUTType isEqual:(NSString *)kUTTypeAppleICNS] ||
			   [imageUTType isEqual:(NSString *)kUTTypeICO] ||
			   [imageUTType isEqual:(NSString *)kTKUTTypeTGA] ||
			   [imageUTType isEqual:(NSString *)kTKUTTypePSD] ||
			   [imageUTType isEqual:(NSString *)kTKUTTypeOpenEXR] ||
			   [imageUTType isEqual:(NSString *)kUTTypeGIF] ||
			   [imageUTType isEqual:(NSString *)kUTTypePDF] ||
			   [imageUTType isEqual:(NSString *)kUTTypePNG]) {
		
		if (imageHasAlpha && saveAlpha) [imgProperties setObject:TKYES forKey:(id)kCGImagePropertyHasAlpha];
		
	}
	
	[self saveDefaults];
	
	return imgProperties;
}



@end



