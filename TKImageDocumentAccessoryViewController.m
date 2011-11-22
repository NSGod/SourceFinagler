//
//  TKImageDocumentAccessoryViewController.m
//  Texture Kit
//
//  Created by Mark Douma on 1/5/2011.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageDocumentAccessoryViewController.h"
#import "TKImageDocument.h"

#import <TextureKit/TKImage.h>

#import "MDAppKitAdditions.h"



NSString * const TKImageDocumentLastSavedFormatTypeKey = @"TKImageDocumentLastSavedFormatType";


static NSMutableDictionary *displayNameAndUTITypes = nil;


@implementation TKImageDocumentAccessoryViewController


@synthesize document, savePanel, imageUTType, vtfFormat, ddsFormat, compressionQuality, jpegQuality;


+ (void)initialize {
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject:TKVTFType forKey:TKImageDocumentLastSavedFormatTypeKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


- (id)init {
	return [self initWithImageDocument:nil];
}


- (id)initWithImageDocument:(TKImageDocument *)aDocument {
	if ((self = [super initWithNibName:[self nibName] bundle:nil])) {
		document = aDocument;
		
		[self setImageUTType:[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentLastSavedFormatTypeKey]];
		
		if (imageUTTypes == nil) {
			imageUTTypes = [[[document class] writableTypes] retain];
		}
		vtfFormat = TKVTFFormatDefault;
		ddsFormat = TKDDSFormatDefault;
		compressionQuality = TKDXTCompressionDefaultQuality;
	}
	return self;
}



- (void)dealloc {
	document = nil;
	savePanel = nil;
	[imageUTType release];
	[imageUTTypes release];
	[super dealloc];
}


- (NSString *)nibName {
	return @"TKImageDocumentAccessoryView";
}


- (void)awakeFromNib {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (displayNameAndUTITypes == nil) {
		displayNameAndUTITypes = [[NSMutableDictionary alloc] init];
		
		for (NSString *aSaveType in imageUTTypes) {
			NSString *displayName = [[NSDocumentController sharedDocumentController] displayNameForType:aSaveType];
			if (displayName) [displayNameAndUTITypes setObject:aSaveType forKey:displayName];
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
	
	NSArray *filenameExtensions = [[NSDocumentController sharedDocumentController] fileExtensionsFromType:utiType];
	NSString *filenameExtension = nil;
	
	if ([filenameExtensions count]) {
		filenameExtension = [filenameExtensions objectAtIndex:0];
		if (filenameExtension) [savePanel setAllowedFileTypes:[NSArray arrayWithObject:filenameExtension]];
	}
	
	if ([utiType isEqualToString:TKDDSType] ||
		[utiType isEqualToString:TKVTFType]) {
		
		
		if ([utiType isEqualToString:TKDDSType]) {
			
			
			[compressionPopUpButton setMenu:ddsMenu];
			[compressionPopUpButton selectItemWithTag:[compressionPopUpButton indexOfItemWithTag:ddsFormat]];
			
		} else {
			[compressionPopUpButton setMenu:vtfMenu];
			[compressionPopUpButton selectItemWithTag:[compressionPopUpButton indexOfItemWithTag:vtfFormat]];
		}
		
		[mipmapsCheckbox setHidden:NO];
		
		[compressionBox setContentView:compressionView];
		
	} else if ([utiType isEqualToString:(NSString *)kUTTypeJPEG] ||
			   [utiType isEqualToString:(NSString *)kUTTypeJPEG2000]) {
		
		
		[compressionBox setContentView:jpegQualityView];
		
	
	} else if ([utiType isEqualToString:(NSString *)kUTTypeTIFF]) {
		 
		[compressionPopUpButton setMenu:tiffMenu];
		[compressionPopUpButton selectItemWithTag:[compressionPopUpButton indexOfItemWithTag:tiffCompression]];
		[mipmapsCheckbox setHidden:YES];
		
		[compressionBox setContentView:compressionView];
		
		
	} else {
		[compressionBox setContentView:blankView];
	}
	
}

- (void)setNilValueForKey:(NSString *)key {
	if ([key isEqualToString:@"jpegQuality"]) {
		jpegQuality = 0.0;
	} else if ([super respondsToSelector:@selector(setNilValueForKey:)]) {
		[super setNilValueForKey:key];
	}
}


- (IBAction)changeCompression:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *title = [formatPopUpButton titleOfSelectedItem];
	NSString *utiType = [displayNameAndUTITypes objectForKey:title];
	
	if ([utiType isEqualToString:TKDDSType]) {
		ddsFormat = [[compressionPopUpButton selectedItem] tag];
	} else if ([utiType isEqualToString:TKVTFType]) {
		vtfFormat = [[compressionPopUpButton selectedItem] tag];
	} else if ([utiType isEqualToString:(NSString *)kUTTypeTIFF]) {
		tiffCompression = [[compressionPopUpButton selectedItem] tag];
	}
}


- (NSDictionary *)imageProperties {
	NSDictionary *imgProperties = nil;
	
	@synchronized(self) {
		if ([imageUTType isEqualToString:TKDDSType] || [imageUTType isEqualToString:TKVTFType]) {
			
		} else if ([imageUTType isEqualToString:(NSString *)kUTTypeJPEG] || [imageUTType isEqualToString:(NSString *)kUTTypeJPEG2000]) {
			imgProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:jpegQuality],(id)kCGImageDestinationLossyCompressionQuality,
							 [NSNumber numberWithBool:[[document image] hasAlpha]],(id)kCGImagePropertyHasAlpha, nil];
			
//		} else if ([imageUTType isEqualToString:(NSString *)kUTTypeTIFF]) {
//			imgProperties = [NSDictionary dictionaryWithObjectsAndKeys:
//							 [NSNumber numberWithBool:[[document image] hasAlpha]],(id)kCGImagePropertyHasAlpha, nil];
//			
		} else {
			imgProperties = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:[[document image] hasAlpha]],(id)kCGImagePropertyHasAlpha, nil];
			
		}
	}
	
	return imgProperties;
}



@end
