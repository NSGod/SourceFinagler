//
//  TKImageDocumentAccessoryViewController.m
//  Source Finagler
//
//  Created by Mark Douma on 1/5/2011.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import "TKImageDocumentAccessoryViewController.h"
#import "TKImageDocument.h"
#import "MDAppKitAdditions.h"



static NSString * const kTKUTTypeTGA = @"com.truevision.tga-image";
static NSString * const kTKUTTypePSD = @"com.adobe.photoshop-image";
static NSString * const kTKUTTypeOpenEXR = @"com.ilm.openexr-image";
//static NSString * const kTKUTTypeSGI = @"com.sgi.sgi-image";



static NSString * const TKImageDocumentLastSavedFormatTypeKey		= @"TKImageDocumentLastSavedFormatType";

static NSString * const TKImageDocumentVTFFormatKey					= @"TKImageDocumentVTFFormat";

static NSString * const TKImageDocumentDDS9FormatKey				= @"TKImageDocumentDDS9Format";
static NSString * const TKImageDocumentDDS10FormatKey				= @"TKImageDocumentDDS10Format";
static NSString * const TKImageDocumentDDSContainerKey				= @"TKImageDocumentDDSContainer";

static NSString * const TKImageDocumentDXTCompressionQualityKey		= @"TKImageDocumentDXTCompressionQuality";

static NSString * const TKImageDocumentGenerateMipmapsKey			= @"TKImageDocumentGenerateMipmaps";
static NSString * const TKImageDocumentMipmapGenerationTypeKey		= @"TKImageDocumentMipmapGenerationType";

static NSString * const TKImageDocumentResizeModeKey				= @"TKImageDocumentResizeMode";

static NSString * const TKImageDocumentTIFFCompressionKey			= @"TKImageDocumentTIFFCompression";

static NSString * const TKImageDocumentJPEGQualityKey				= @"TKImageDocumentJPEGQuality";
static NSString * const TKImageDocumentJPEG2000QualityKey			= @"TKImageDocumentJPEG2000Quality";

static NSString * const TKImageDocumentSaveAlphaKey					= @"TKImageDocumentSaveAlpha";




#define TK_DEBUG 1


@interface TKImageDocumentAccessoryViewController (TKPrivate)

- (void)updateDDSMenu;
- (void)updatePreviewImage;
- (void)updateDXTCompression;

@end


static NSMutableDictionary *displayNameAndUTITypes = nil;


@implementation TKImageDocumentAccessoryViewController

@synthesize document;
@synthesize savePanel;
@synthesize image;
@synthesize previewImage;
@synthesize imageUTType;
@synthesize vtfFormat;
@synthesize dds9Format;
@synthesize dds10Format;
@synthesize ddsContainer;

@synthesize compressionQuality;
@synthesize generateMipmaps;
@synthesize mipmapGenerationType;
@synthesize resizeMode;

@synthesize tiffCompression;
@synthesize jpegQuality;
@synthesize jpeg2000Quality;

@synthesize saveAlpha;

@dynamic imageProperties;
@dynamic options;


+ (void)initialize {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	// wil be called twice because of bindings: `[NSKVONotifying_TKImageDocumentAccessoryViewController initialize]`
	
	static BOOL initialized = NO;
	
	@synchronized(self) {
		if (displayNameAndUTITypes == nil) {
			displayNameAndUTITypes = [[NSMutableDictionary alloc] init];
			
			NSArray *imageUTTypes = [TKImageDocument writableTypes];
			
			for (NSString *aSaveType in imageUTTypes) {
				NSString *displayName = [[NSDocumentController sharedDocumentController] displayNameForType:aSaveType];
				if (displayName) [displayNameAndUTITypes setObject:aSaveType forKey:displayName];
			}
		}
		
		NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
		[defaultValues setObject:TKSFTextureImageType forKey:TKImageDocumentLastSavedFormatTypeKey];
		[defaultValues setObject:[NSNumber numberWithUnsignedInteger:[TKVTFImageRep defaultFormat]] forKey:TKImageDocumentVTFFormatKey];
		[defaultValues setObject:[NSNumber numberWithUnsignedInteger:[TKDDSImageRep defaultFormat]] forKey:TKImageDocumentDDS9FormatKey];
		[defaultValues setObject:[NSNumber numberWithUnsignedInteger:TKDDSFormatBC1] forKey:TKImageDocumentDDS10FormatKey];
		[defaultValues setObject:[NSNumber numberWithUnsignedInteger:[TKDDSImageRep defaultContainer]] forKey:TKImageDocumentDDSContainerKey];
		
		[defaultValues setObject:[NSNumber numberWithUnsignedInteger:[TKImageRep defaultDXTCompressionQuality]] forKey:TKImageDocumentDXTCompressionQualityKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:TKImageDocumentGenerateMipmapsKey];
		[defaultValues setObject:[NSNumber numberWithUnsignedInteger:TKMipmapGenerationUsingKaiserFilter] forKey:TKImageDocumentMipmapGenerationTypeKey];
		[defaultValues setObject:[NSNumber numberWithUnsignedInteger:TKResizeModeNearestPowerOfTwo] forKey:TKImageDocumentResizeModeKey];
		
		[defaultValues setObject:[NSNumber numberWithDouble:0.8] forKey:TKImageDocumentJPEGQualityKey];
		[defaultValues setObject:[NSNumber numberWithDouble:0.8] forKey:TKImageDocumentJPEG2000QualityKey];
		[defaultValues setObject:[NSNumber numberWithUnsignedInteger:NSTIFFCompressionNone] forKey:TKImageDocumentTIFFCompressionKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:TKImageDocumentSaveAlphaKey];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
		
		initialized = YES;
	}
	
}


- (id)init {
	return [self initWithImageDocument:nil];
}


- (id)initWithImageDocument:(TKImageDocument *)aDocument {
#if TK_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithNibName:[self nibName] bundle:nil])) {
		document = aDocument;
		image = [document image];
		
		previewImage = [[TKImage alloc] initWithSize:image.size];
		
		TKImageRep *copiedImageRep = [[[TKImageRep largestRepresentationInArray:image.representations] copy] autorelease];
		
		[previewImage addRepresentation:copiedImageRep];
		
		[self setImageUTType:[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentLastSavedFormatTypeKey]];
		
		vtfFormat = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentVTFFormatKey] unsignedIntegerValue];
		
		dds9Format = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentDDS9FormatKey] unsignedIntegerValue];
		dds10Format = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentDDS10FormatKey] unsignedIntegerValue];
		ddsContainer = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentDDSContainerKey] unsignedIntegerValue];
		
		compressionQuality = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentDXTCompressionQualityKey] unsignedIntegerValue];
		generateMipmaps = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentGenerateMipmapsKey] boolValue];
		mipmapGenerationType = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentMipmapGenerationTypeKey] unsignedIntegerValue];
		resizeMode = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentResizeModeKey] unsignedIntegerValue];
		
		tiffCompression = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentTIFFCompressionKey] unsignedIntegerValue];
		jpegQuality = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentJPEGQualityKey] doubleValue];
		jpeg2000Quality = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentJPEG2000QualityKey] doubleValue];
		
		saveAlpha = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentSaveAlphaKey] boolValue];
		
	}
	return self;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[previewImage release];
	[super dealloc];
}


- (void)cleanup {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[mediator unbind:@"contentObject"];
	[mediator setContent:nil];
	
	[imageUTType release];
	
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
	
	NSArray *sortedDisplayNames = [[displayNameAndUTITypes allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSMutableArray *menuItems = [NSMutableArray array];
	
	for (NSString *displayName in sortedDisplayNames) {
		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:displayName action:NULL keyEquivalent:@""] autorelease];
		if (menuItem) {
			[menuItems addObject:menuItem];
		}
	}
	[formatPopUpButton setItemArray:menuItems];
	
	[originalImageWidthField setObjectValue:[NSNumber numberWithDouble:image.size.width]];
	[originalImageHeightField setObjectValue:[NSNumber numberWithDouble:image.size.height]];
	
	NSMutableArray *vtfMenuItems = [NSMutableArray array];
	
	NSArray *vtfFormats = [TKVTFImageRep availableFormatsForOperationMask:TKVTFOperationWrite];
	
	for (NSNumber *aVTFFormat in vtfFormats) {
		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:[TKVTFImageRep localizedNameOfFormat:[aVTFFormat unsignedIntegerValue]] action:NULL keyEquivalent:@""] autorelease];
		if (menuItem) {
			[menuItem setTag:[aVTFFormat unsignedIntegerValue]];
			[vtfMenuItems addObject:menuItem];
		}
	}
	[vtfMenu setItemArray:vtfMenuItems];
	
	
	NSMutableArray *ddsMenuItems = [NSMutableArray array];
	
	NSArray *ddsFormats = [TKDDSImageRep availableFormatsForOperationMask:TKDDSOperationDX9Write | TKDDSOperationDX10Write];
	
	for (NSNumber *ddsFormat in ddsFormats) {
		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:[TKDDSImageRep localizedNameOfFormat:[ddsFormat unsignedIntegerValue]] action:NULL keyEquivalent:@""] autorelease];
		if (menuItem) {
			[menuItem setTag:[ddsFormat unsignedIntegerValue]];
			[ddsMenuItems addObject:menuItem];
		}
	}
	[ddsMenu setItemArray:ddsMenuItems];
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
	
	if ([imageUTType isEqualToString:TKDDSType] || [imageUTType isEqualToString:TKVTFType]) {
		
		if ([imageUTType isEqualToString:TKDDSType]) {
			
			[ddsContainerCheckbox setState:(ddsContainer == TKDDSContainerDX10 ? NSOnState : NSOffState)];
			[ddsContainerCheckbox setHidden:NO];
			
			[compressionPopUpButton setMenu:ddsMenu];
			
			[self updateDDSMenu];
			
		} else {
			
			[ddsContainerCheckbox setHidden:YES];
			
			[compressionPopUpButton setMenu:vtfMenu];
			[compressionPopUpButton selectItemWithTag:vtfFormat];
		}
		
		[self updateDXTCompression];
		[self updatePreviewImage];
		
		[compressionBox setContentView:compressionView];
		
	} else if ([imageUTType isEqualToString:(NSString *)kUTTypeJPEG]) {
		
		[compressionBox setContentView:jpegQualityView];
		
	} else if ([imageUTType isEqualToString:(NSString *)kUTTypeJPEG2000]) {
		
		[compressionBox setContentView:jpeg2000QualityView];
	
	} else if ([imageUTType isEqualToString:(NSString *)kUTTypeTIFF]) {

		[compressionBox setContentView:tiffCompressionView];
		
	} else if ([imageUTType isEqualToString:(NSString *)kUTTypeBMP] ||
			   [imageUTType isEqualToString:(NSString *)kUTTypeAppleICNS] ||
			   [imageUTType isEqualToString:(NSString *)kUTTypeICO] ||
			   [imageUTType isEqualToString:kTKUTTypePSD] ||
			   [imageUTType isEqualToString:kTKUTTypeTGA] ||
			   [imageUTType isEqualToString:kTKUTTypeOpenEXR] ||
			   [imageUTType isEqualToString:(NSString *)kUTTypeGIF] ||
			   [imageUTType isEqualToString:(NSString *)kUTTypePDF] ||
			   [imageUTType isEqualToString:(NSString *)kUTTypePNG]) {
		
		[compressionBox setContentView:alphaView];
		
	} else {
		
		[compressionBox setContentView:blankView];
		
	}
}


- (IBAction)changeCompression:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ([imageUTType isEqualToString:TKDDSType]) {
		
		if (ddsContainer == TKDDSContainerDX9) {
			self.dds9Format = [[compressionPopUpButton selectedItem] tag];
			
		} else if (ddsContainer == TKDDSContainerDX10) {
			self.dds10Format = [[compressionPopUpButton selectedItem] tag];
			
		}
		
	} else if ([imageUTType isEqualToString:TKVTFType]) {
		
		self.vtfFormat = [[compressionPopUpButton selectedItem] tag];
	}
	
	[self updateDXTCompression];
}


- (IBAction)changeResizeMode:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@] resizeMode == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)resizeMode);
#endif
	[self updatePreviewImage];
}


- (IBAction)changeDDSContainer:(id)sender {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	ddsContainer = ([sender state] == NSOnState ? TKDDSContainerDX10 : TKDDSContainerDX9);
	
	[self updateDDSMenu];
}


- (void)updateDDSMenu {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (ddsContainer == TKDDSContainerDX9) {
		[compressionPopUpButton selectItemWithTag:dds9Format];
		
	} else if (ddsContainer == TKDDSContainerDX10) {
		[compressionPopUpButton selectItemWithTag:dds10Format];
		
	}
	// hack to get selected item to no longer be grayed-out
	[[compressionPopUpButton selectedItem] setEnabled:YES];
}


- (void)updatePreviewImage {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSSize adjustedSize = [TKImageRep powerOfTwoSizeForSize:image.size usingResizeMode:resizeMode];
	
	[previewImage setSize:adjustedSize];
	
	[previewImageWidthField setObjectValue:[NSNumber numberWithDouble:adjustedSize.width]];
	[previewImageHeightField setObjectValue:[NSNumber numberWithDouble:adjustedSize.height]];
	
	// force refresh of image
	[previewImageView setNeedsDisplay:YES];
	
}


- (void)updateDXTCompression {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL isDXTCompressed = NO;
	
	if ([imageUTType isEqualToString:TKDDSType]) {
		if (ddsContainer == TKDDSContainerDX9) {
			isDXTCompressed = [TKDDSImageRep isDXTCompressionQualityApplicableToFormat:dds9Format];
		} else if (ddsContainer == TKDDSContainerDX10) {
			isDXTCompressed = [TKDDSImageRep isDXTCompressionQualityApplicableToFormat:dds10Format];
		}
	} else if ([imageUTType isEqualToString:TKVTFType]) {
		isDXTCompressed = [TKVTFImageRep isDXTCompressionQualityApplicableToFormat:vtfFormat];
	}
	
	[compressionQualityTextField setHidden:!isDXTCompressed];
	[compressionQualityPopUpButton setHidden:!isDXTCompressed];
	
}



- (void)setNilValueForKey:(NSString *)key {
	
	if ([key isEqualToString:@"vtfFormat"]) {
		vtfFormat = [TKVTFImageRep defaultFormat];
		
	} else if ([key isEqualToString:@"dds9Format"]) {
		dds9Format = [TKDDSImageRep defaultFormat];
		
	} else if ([key isEqualToString:@"dds10Format"]) {
		dds10Format = [TKDDSImageRep defaultFormat];
		
	} else if ([key isEqualToString:@"ddsContainer"]) {
		ddsContainer = [TKDDSImageRep defaultContainer];
		
		
	} else if ([key isEqualToString:@"compressionQuality"]) {
		compressionQuality = [TKImageRep defaultDXTCompressionQuality];
		
	} else if ([key isEqualToString:@"generateMipmaps"]) {
		generateMipmaps = NO;
		
	} else if ([key isEqualToString:@"mipmapGenerationType"]) {
		mipmapGenerationType = TKMipmapGenerationUsingKaiserFilter;
		
	} else if ([key isEqualToString:@"resizeMode"]) {
		resizeMode = TKResizeModeNone;
		
		
	} else if ([key isEqualToString:@"tiffCompression"]) {
		tiffCompression = NSTIFFCompressionNone;
		
	} else if ([key isEqualToString:@"jpegQuality"]) {
		jpegQuality = 0.0;
		
	} else if ([key isEqualToString:@"jpeg2000Quality"]) {
		jpeg2000Quality = 0.0;
		
	} else if ([key isEqualToString:@"saveAlpha"]) {
		saveAlpha = NO;
		
	} else if ([super respondsToSelector:@selector(_cmd)]) {
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
	[userDefaults setObject:[NSNumber numberWithUnsignedInteger:dds9Format] forKey:TKImageDocumentDDS9FormatKey];
	[userDefaults setObject:[NSNumber numberWithUnsignedInteger:dds10Format] forKey:TKImageDocumentDDS10FormatKey];
	[userDefaults setObject:[NSNumber numberWithUnsignedInteger:ddsContainer] forKey:TKImageDocumentDDSContainerKey];
	
	[userDefaults setObject:[NSNumber numberWithUnsignedInteger:compressionQuality] forKey:TKImageDocumentDXTCompressionQualityKey];
	[userDefaults setObject:[NSNumber numberWithBool:generateMipmaps] forKey:TKImageDocumentGenerateMipmapsKey];
	[userDefaults setObject:[NSNumber numberWithUnsignedInteger:mipmapGenerationType] forKey:TKImageDocumentMipmapGenerationTypeKey];
	[userDefaults setObject:[NSNumber numberWithUnsignedInteger:resizeMode] forKey:TKImageDocumentResizeModeKey];
	
	[userDefaults setObject:[NSNumber numberWithDouble:jpegQuality] forKey:TKImageDocumentJPEGQualityKey];
	[userDefaults setObject:[NSNumber numberWithDouble:jpeg2000Quality] forKey:TKImageDocumentJPEG2000QualityKey];
	[userDefaults setObject:[NSNumber numberWithUnsignedInteger:tiffCompression] forKey:TKImageDocumentTIFFCompressionKey];
	[userDefaults setObject:[NSNumber numberWithBool:saveAlpha] forKey:TKImageDocumentSaveAlphaKey];
}


- (NSDictionary *)imageProperties {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([imageUTType isEqualToString:TKDDSType] || [imageUTType isEqualToString:TKVTFType]) return nil;
	
	NSMutableDictionary *imgProperties = [NSMutableDictionary dictionary];
	
	BOOL imageHasAlpha = [image hasAlpha];
	
	if ([imageUTType isEqualToString:(NSString *)kUTTypeJPEG]) {
		
		[imgProperties setObject:[NSNumber numberWithDouble:jpegQuality] forKey:(id)kCGImageDestinationLossyCompressionQuality];
		if (imageHasAlpha && saveAlpha) [imgProperties setObject:[NSNumber numberWithBool:YES] forKey:(id)kCGImagePropertyHasAlpha];
		
	} else if ([imageUTType isEqualToString:(NSString *)kUTTypeJPEG2000]) {
		
		[imgProperties setObject:[NSNumber numberWithDouble:jpeg2000Quality] forKey:(id)kCGImageDestinationLossyCompressionQuality];
		if (imageHasAlpha && saveAlpha) [imgProperties setObject:[NSNumber numberWithBool:YES] forKey:(id)kCGImagePropertyHasAlpha];
		
	} else if ([imageUTType isEqualToString:(NSString *)kUTTypeTIFF]) {
		
		[imgProperties setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:tiffCompression],(id)kCGImagePropertyTIFFCompression, nil]
						  forKey:(id)kCGImagePropertyTIFFDictionary];
		
		
	} else if ([imageUTType isEqualToString:(NSString *)kUTTypeBMP] ||
			   [imageUTType isEqualToString:(NSString *)kUTTypeAppleICNS] ||
			   [imageUTType isEqualToString:(NSString *)kUTTypeICO] ||
			   [imageUTType isEqualToString:(NSString *)kTKUTTypeTGA] ||
			   [imageUTType isEqualToString:(NSString *)kTKUTTypePSD] ||
			   [imageUTType isEqualToString:(NSString *)kTKUTTypeOpenEXR] ||
			   [imageUTType isEqualToString:(NSString *)kUTTypeGIF] ||
			   [imageUTType isEqualToString:(NSString *)kUTTypePDF] ||
			   [imageUTType isEqualToString:(NSString *)kUTTypePNG]) {
		
		if (imageHasAlpha && saveAlpha) [imgProperties setObject:[NSNumber numberWithBool:YES] forKey:(id)kCGImagePropertyHasAlpha];
		
	}
	return imgProperties;
}


- (NSDictionary *)options {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (![imageUTType isEqualToString:TKDDSType] && ![imageUTType isEqualToString:TKVTFType]) return nil;
	
	NSMutableDictionary *options = [NSMutableDictionary dictionary];
	
	[options setObject:[NSNumber numberWithUnsignedInteger:(generateMipmaps ? mipmapGenerationType : TKMipmapGenerationNoMipmaps)] forKey:TKImageMipmapGenerationKey];
	[options setObject:[NSNumber numberWithUnsignedInteger:(image.hasDimensionsThatArePowerOfTwo ? TKResizeModeNone : resizeMode)] forKey:TKImageResizeModeKey];
	if (!image.hasDimensionsThatArePowerOfTwo) {
		[options setObject:[NSNumber numberWithUnsignedInteger:TKResizeFilterKaiser] forKey:TKImageResizeFilterKey];
	}
	return options;
}




#pragma mark - <NSMenuDelegate>

- (void)menuNeedsUpdate:(NSMenu *)menu {
#if TK_DEBUG
//	NSLog(@"[%@ %@] menu == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), menu);
#endif
	
}



- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
#if TK_DEBUG
//    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([menuItem menu] != ddsMenu && [menuItem menu] != vtfMenu) return YES;
	
	NSInteger tag = [menuItem tag];
	
	if ([imageUTType isEqualToString:TKDDSType]) {
		if (ddsContainer == TKDDSContainerDX9) {
			return ([TKDDSImageRep operationMaskForFormat:tag] & TKDDSOperationDX9Write) == TKDDSOperationDX9Write;
		} else if (ddsContainer == TKDDSContainerDX10) {
			return ([TKDDSImageRep operationMaskForFormat:tag] & TKDDSOperationDX10Write) == TKDDSOperationDX10Write;
		}
	} else if ([imageUTType isEqualToString:TKVTFType]) {
		return ([TKVTFImageRep operationMaskForFormat:tag] & TKVTFOperationWrite) == TKVTFOperationWrite;
	}
	
	return YES;
}


#pragma mark -

@end



