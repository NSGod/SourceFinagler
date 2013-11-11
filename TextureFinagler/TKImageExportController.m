//
//  TKImageExportController.m
//  Texture Kit
//
//  Created by Mark Douma on 12/11/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageExportController.h"
#import "TKImageExportPreviewViewController.h"
#import "TKImageDocument.h"
#import "TKImageExportPreset.h"
#import "MDAppKitAdditions.h"



#import <TextureKit/TKImage.h>

NSString * const TKImageExportSelectedPreviewModeKey		= @"TKImageExportSelectedPreviewMode";

NSString * const TKImageExportPresetsKey					= @"TKImageExportPresets";
NSString * const TKImageExportFourChosenPresetsKey			= @"TKImageExportFourChosenPresets";

NSString * const TKImageExportFirstPresetKey				= @"TKImageExportFirstPreset";
NSString * const TKImageExportSecondPresetKey				= @"TKImageExportSecondPreset";
NSString * const TKImageExportThirdPresetKey				= @"TKImageExportThirdPreset";
NSString * const TKImageExportFourthPresetKey				= @"TKImageExportFourthPreset";



#define TK_DEBUG 1

enum {
	TKPreviewMode2Up	= 0,
	TKPreviewMode4Up	= 1
};

@implementation TKImageExportController

@synthesize previewMode, image, document;


+ (void)initialize {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject:[NSNumber numberWithInteger:TKPreviewMode2Up] forKey:TKImageExportSelectedPreviewModeKey];
//	NSArray *allDefaultPresets = [TKImageExportPreset imageExportPresetsWithContentsOfArrayAtPath:[[NSBundle mainBundle] pathForResource:@"allDefaultPresets" ofType:@"plist"]];
//	if (allDefaultPresets) {
//		[defaultValues setObject:allDefaultPresets forKey:TKImageExportPresetsKey];
//	}
	
	NSDictionary *defaultPresets = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaultPresets" ofType:@"plist"]];
	if (defaultPresets) {
		NSArray *allKeys = [defaultPresets allKeys];
		for (NSString *key in allKeys) {
			NSDictionary *preset = [defaultPresets objectForKey:key];
			
			if ([key isEqualToString:@"0"]) {
				
				[defaultValues setObject:preset forKey:TKImageExportFirstPresetKey];
				
			} else if ([key isEqualToString:@"1"]) {
				[defaultValues setObject:preset forKey:TKImageExportSecondPresetKey];
				
			} else if ([key isEqualToString:@"2"]) {
				[defaultValues setObject:preset forKey:TKImageExportThirdPresetKey];
				
			} else if ([key isEqualToString:@"3"]) {
				[defaultValues setObject:preset forKey:TKImageExportFourthPresetKey];
			}
		}
	}
	
#if TK_DEBUG
	NSLog(@"[%@ %@] defaultValues == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), defaultValues);
#endif
	
	[[defaultValues retain] autorelease];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}



- (id)initWithImageDocument:(TKImageDocument *)aDocument {
	if ((self = [super initWithWindowNibName:[self windowNibName]])) {
		operationQueue = [[NSOperationQueue alloc] init];
		previewMode = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageExportSelectedPreviewModeKey] integerValue];
		presets = [[TKImageExportPreset imageExportPresetsWithContentsOfArrayAtPath:[[NSBundle mainBundle] pathForResource:@"allDefaultPresets" ofType:@"plist"]] mutableCopy];;
		[self setDocument:aDocument];
	} else {
		[NSBundle runFailedNibLoadAlert:[NSString stringWithFormat:@"%@", [self windowNibName]]];
	}
	return self;
}


- (void)dealloc {
	[image release];
	[operationQueue release];
	document = nil;
	[firstController release];
	[secondController release];
	[thirdController release];
	[fourthController release];
	
	[firstPreset release];
	[secondPreset release];
	[thirdPreset release];
	[fourthPreset release];
	
	
	[vtfMenu release];
	[ddsMenu release];
	[presets retain];
	[super dealloc];
}

- (NSString *)windowNibName {
	return @"TKImageExportPanel";
}


- (void)windowDidLoad {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[vtfMenu retain];
	[ddsMenu retain];
	
	if (previewMode == TKPreviewMode2Up) {
		if (firstController == nil) firstController = [[TKImageExportPreviewViewController alloc] init];
		if (secondController == nil) secondController = [[TKImageExportPreviewViewController alloc] init];
		
		[dualViewFirstBox setContentView:[firstController view]];
		[dualViewSecondBox setContentView:[secondController view]];
		
		[mainBox setContentView:dualView];
		
		
		
	} else if (previewMode == TKPreviewMode4Up) {
		
		if (firstController == nil) firstController = [[TKImageExportPreviewViewController alloc] init];
		if (secondController == nil) secondController = [[TKImageExportPreviewViewController alloc] init];
		if (thirdController == nil) thirdController = [[TKImageExportPreviewViewController alloc] init];
		if (fourthController == nil) fourthController = [[TKImageExportPreviewViewController alloc] init];
		
		[quadViewFirstBox setContentView:[firstController view]];
		[quadViewSecondBox setContentView:[secondController view]];
		[quadViewThirdBox setContentView:[thirdController view]];
		[quadViewFourthBox setContentView:[fourthController view]];
		
		[mainBox setContentView:quadView];
	}

}


- (void)setPreviewMode:(NSInteger)aMode {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	previewMode = aMode;
	
	if (previewMode == TKPreviewMode2Up) {
		if (firstController == nil) firstController = [[TKImageExportPreviewViewController alloc] init];
		if (secondController == nil) secondController = [[TKImageExportPreviewViewController alloc] init];
		
		[dualViewFirstBox setContentView:[firstController view]];
		[dualViewSecondBox setContentView:[secondController view]];
		
		[mainBox setContentView:dualView];
		
		
		
	} else if (previewMode == TKPreviewMode4Up) {
		
		if (firstController == nil) firstController = [[TKImageExportPreviewViewController alloc] init];
		if (secondController == nil) secondController = [[TKImageExportPreviewViewController alloc] init];
		if (thirdController == nil) thirdController = [[TKImageExportPreviewViewController alloc] init];
		if (fourthController == nil) fourthController = [[TKImageExportPreviewViewController alloc] init];
		
		[quadViewFirstBox setContentView:[firstController view]];
		[quadViewSecondBox setContentView:[secondController view]];
		[quadViewThirdBox setContentView:[thirdController view]];
		[quadViewFourthBox setContentView:[fourthController view]];
		
		[mainBox setContentView:quadView];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:previewMode] forKey:TKImageExportSelectedPreviewModeKey];
}





- (IBAction)cancel:(id)sender {
	[document cancel:sender];
}

- (IBAction)export:(id)sender {
	[document export:sender];
}

- (IBAction)changePreset:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}


- (IBAction)changeFormat:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}


- (IBAction)changeCompression:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}

- (IBAction)changeQuality:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}


- (IBAction)changeMipmaps:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}

- (IBAction)managePresets:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}




@end
