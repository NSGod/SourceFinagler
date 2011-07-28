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
#import "TKImageExportPreviewView.h"
#import "TKImageExportPreviewOperation.h"
#import "TKImageExportPreview.h"

#import "MDAppKitAdditions.h"

//#import <TextureKit/TextureKit.h>



NSString * const TKImageExportSelectedPreviewModeKey		= @"TKImageExportSelectedPreviewMode";

NSString * const TKImageExportPresetsKey					= @"TKImageExportPresets";
NSString * const TKImageExportFourChosenPresetsKey			= @"TKImageExportFourChosenPresets";

NSString * const TKImageExportFirstPresetKey				= @"TKImageExportFirstPreset";
NSString * const TKImageExportSecondPresetKey				= @"TKImageExportSecondPreset";
NSString * const TKImageExportThirdPresetKey				= @"TKImageExportThirdPreset";
NSString * const TKImageExportFourthPresetKey				= @"TKImageExportFourthPreset";

NSString * const TKImageExportSavedFrameKey					= @"TKImageExportSavedFrame";


@interface TKImageExportController (TKPrivate)

- (void)beginPreviewOperationForTag:(NSNumber *)aTag;

- (void)imageExportPreviewDidComplete:(NSNotification *)notification;
- (void)mainThreadImageExportPreviewDidComplete:(NSNotification *)notification;

- (void)assureInitializationForPreviewMode:(NSUInteger)aPreviewMode;


- (void)updatePresetsPopUpMenu;
- (void)synchronizeUI;

- (NSArray *)orderedPresetNamesWithoutOriginal;

@end


#define TK_DEBUG 1

enum {
	TKPreviewMode2Up	= 0,
	TKPreviewMode4Up	= 1
};

@implementation TKImageExportController

@synthesize image, document, selectedTag;

@dynamic preset, previewMode;

+ (void)initialize {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject:[NSNumber numberWithInteger:TKPreviewMode2Up] forKey:TKImageExportSelectedPreviewModeKey];
	NSArray *allDefaultPresets = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"allDefaultPresets" ofType:@"plist"]];
	if (allDefaultPresets) {
		[defaultValues setObject:allDefaultPresets forKey:TKImageExportPresetsKey];
	}
	
	NSDictionary *defaultPresets = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaultPresets" ofType:@"plist"]];
	if (defaultPresets) {
		NSArray *allKeys = [defaultPresets allKeys];
		for (NSString *key in allKeys) {
			NSDictionary *aPreset = [defaultPresets objectForKey:key];
			if ([key isEqualToString:@"0"]) {
				[defaultValues setObject:aPreset forKey:TKImageExportFirstPresetKey];
			} else if ([key isEqualToString:@"1"]) {
				[defaultValues setObject:aPreset forKey:TKImageExportSecondPresetKey];
			} else if ([key isEqualToString:@"2"]) {
				[defaultValues setObject:aPreset forKey:TKImageExportThirdPresetKey];
			} else if ([key isEqualToString:@"3"]) {
				[defaultValues setObject:aPreset forKey:TKImageExportFourthPresetKey];
			}
		}
	}
	
#if TK_DEBUG
	NSLog(@"[%@ %@] defaultValues == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), defaultValues);
#endif
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}



- (id)initWithImageDocument:(TKImageDocument *)aDocument {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithWindowNibName:[self windowNibName]])) {
		
		presetsAndNames = [[NSMutableDictionary alloc] init];
		
		presets = [[NSMutableArray alloc] init];
		
		previewControllers = [[NSMutableArray alloc] init];
		previews = [[NSMutableArray alloc] init];
		
		operationQueue = [[NSOperationQueue alloc] init];
		tagsAndOperations = [[NSMutableDictionary alloc] init];
		
		previewMode = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageExportSelectedPreviewModeKey] integerValue];
		
		NSArray *savedPresets = [TKImageExportPreset imageExportPresetsWithDictionaryRepresentations:[[NSUserDefaults standardUserDefaults] objectForKey:TKImageExportPresetsKey]];
		
		
		for (TKImageExportPreset *aPreset in savedPresets) {
			[presetsAndNames setObject:aPreset forKey:[aPreset name]];
		}
		
		[presets setArray:[NSArray arrayWithObjects:[TKImageExportPreset imageExportPresetWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:TKImageExportFirstPresetKey]],
						   [TKImageExportPreset imageExportPresetWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:TKImageExportSecondPresetKey]],
						   [TKImageExportPreset imageExportPresetWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:TKImageExportThirdPresetKey]],
						   [TKImageExportPreset imageExportPresetWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:TKImageExportFourthPresetKey]], nil]];
		
		[self setDocument:aDocument];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageExportPreviewDidComplete:) name:TKImageExportPreviewOperationDidCompleteNotification object:self];
		
	} else {
		[NSBundle runFailedNibLoadAlert:[NSString stringWithFormat:@"%@", [self windowNibName]]];
	}
	return self;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[presetsAndNames release];
	
	[preset release];
	
	[presets release];
	
	[previewControllers release];
	
	[previews release];
	
	[tagsAndOperations release];
	
	[operationQueue release];
	
	[image release];
	
	
	document = nil;
	
	[vtfMenu release];
	[ddsMenu release];
	
	[super dealloc];
}

- (NSString *)windowNibName {
	return @"TKImageExportPanel";
}


- (void)assureInitializationForPreviewMode:(NSUInteger)aPreviewMode {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ( !(aPreviewMode == TKPreviewMode2Up || aPreviewMode == TKPreviewMode4Up)) return;
	
	if (aPreviewMode == TKPreviewMode2Up) {
		if ([previewControllers count] < 2) {
			TKImageExportPreviewViewController *firstController = [[[TKImageExportPreviewViewController alloc] init] autorelease];
			TKImageExportPreview *firstPreview = [[[TKImageExportPreview alloc] initWithController:self image:[document image] preset:[presets objectAtIndex:0] tag:0] autorelease];
			[firstController setRepresentedObject:firstPreview];
			[(TKImageExportPreviewView *)[firstController view] setDelegate:self];
			[[firstController imageView] setDelegate:self];
			
			[previewControllers addObject:firstController];
			[previews addObject:firstPreview];
			
			TKImageExportPreviewViewController *secondController = [[[TKImageExportPreviewViewController alloc] init] autorelease];
			TKImageExportPreview *secondPreview = [[[TKImageExportPreview alloc] initWithController:self image:[document image] preset:[presets objectAtIndex:1] tag:1] autorelease];
			[secondController setRepresentedObject:secondPreview];
			[(TKImageExportPreviewView *)[secondController view] setDelegate:self];
			[[secondController imageView] setDelegate:self];
			
			[previewControllers addObject:secondController];
			[previews addObject:secondPreview];
			
		}
		
	} else {
		if ([previewControllers count] < 4) {
			if ([previewControllers count] == 0) {
				TKImageExportPreviewViewController *firstController = [[[TKImageExportPreviewViewController alloc] init] autorelease];
				TKImageExportPreview *firstPreview = [[[TKImageExportPreview alloc] initWithController:self image:[document image] preset:[presets objectAtIndex:0] tag:0] autorelease];
				[firstController setRepresentedObject:firstPreview];
				[(TKImageExportPreviewView *)[firstController view] setDelegate:self];
				[[firstController imageView] setDelegate:self];
				
				[previewControllers addObject:firstController];
				[previews addObject:firstPreview];
				
				TKImageExportPreviewViewController *secondController = [[[TKImageExportPreviewViewController alloc] init] autorelease];
				TKImageExportPreview *secondPreview = [[[TKImageExportPreview alloc] initWithController:self image:[document image] preset:[presets objectAtIndex:1] tag:1] autorelease];
				[secondController setRepresentedObject:secondPreview];
				[(TKImageExportPreviewView *)[secondController view] setDelegate:self];
				[[secondController imageView] setDelegate:self];

				[previewControllers addObject:secondController];
				[previews addObject:secondPreview];
				
			}
			
			TKImageExportPreviewViewController *thirdController = [[[TKImageExportPreviewViewController alloc] init] autorelease];
			TKImageExportPreview *thirdPreview = [[[TKImageExportPreview alloc] initWithController:self image:[document image] preset:[presets objectAtIndex:2] tag:2] autorelease];
			[thirdController setRepresentedObject:thirdPreview];
			[(TKImageExportPreviewView *)[thirdController view] setDelegate:self];
			[[thirdController imageView] setDelegate:self];
			
			[previewControllers addObject:thirdController];
			[previews addObject:thirdPreview];
			
			TKImageExportPreviewViewController *fourthController = [[[TKImageExportPreviewViewController alloc] init] autorelease];
			TKImageExportPreview *fourthPreview = [[[TKImageExportPreview alloc] initWithController:self image:[document image] preset:[presets objectAtIndex:3] tag:3] autorelease];
			[fourthController setRepresentedObject:fourthPreview];
			[(TKImageExportPreviewView *)[fourthController view] setDelegate:self];
			[[fourthController imageView] setDelegate:self];
			
			[previewControllers addObject:fourthController];
			[previews addObject:fourthPreview];
			
		}
	}
}


- (void)windowDidLoad {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ([[NSUserDefaults standardUserDefaults] objectForKey:TKImageExportSavedFrameKey] == nil) {
		[[NSUserDefaults standardUserDefaults] setObject:[[self window] stringWithSavedFrame] forKey:TKImageExportSavedFrameKey];
	}
	
	[[self window] setFrameFromString:[[NSUserDefaults standardUserDefaults] objectForKey:TKImageExportSavedFrameKey]];
	
	[vtfMenu retain];
	[ddsMenu retain];
	
	if (previewMode == TKPreviewMode2Up) {
		[self assureInitializationForPreviewMode:TKPreviewMode2Up];
		
		[dualViewFirstBox setContentView:[[previewControllers objectAtIndex:0] view]];
		[dualViewSecondBox setContentView:[[previewControllers objectAtIndex:1] view]];
		
		[mainBox setContentView:dualView];
		
		[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:0] afterDelay:0.0];
		[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:1] afterDelay:0.0];
		
	} else if (previewMode == TKPreviewMode4Up) {
		
		[self assureInitializationForPreviewMode:TKPreviewMode4Up];
		
		[quadViewFirstBox setContentView:[[previewControllers objectAtIndex:0] view]];
		[quadViewSecondBox setContentView:[[previewControllers objectAtIndex:1] view]];
		[quadViewThirdBox setContentView:[[previewControllers objectAtIndex:2] view]];
		[quadViewFourthBox setContentView:[[previewControllers objectAtIndex:3] view]];
		
		[mainBox setContentView:quadView];
		
		[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:0] afterDelay:0.0];
		[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:1] afterDelay:0.0];
		[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:2] afterDelay:0.0];
		[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:3] afterDelay:0.0];
		
	}
	
	[[self window] makeFirstResponder:[[previewControllers objectAtIndex:0] view]];
	
}



- (void)setPreviewMode:(NSInteger)aMode {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	previewMode = aMode;
	
	if (previewMode == TKPreviewMode2Up) {
		[self assureInitializationForPreviewMode:TKPreviewMode2Up];
		
		[dualViewFirstBox setContentView:[[previewControllers objectAtIndex:0] view]];
		[dualViewSecondBox setContentView:[[previewControllers objectAtIndex:1] view]];
		
		[mainBox setContentView:dualView];
		
		if ([[previews objectAtIndex:0] imageRep] == nil)
			[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:0] afterDelay:0.0];
		
		if ([[previews objectAtIndex:1] imageRep] == nil) 
			[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:1] afterDelay:0.0];
		
		if (selectedTag >= 2) {
			[(TKImageExportPreviewView *)[[previewControllers objectAtIndex:selectedTag] view] setHighlighted:NO];
			[self setSelectedTag:1];
			[[self window] makeFirstResponder:[[previewControllers objectAtIndex:selectedTag] view]];
		}
		
	} else if (previewMode == TKPreviewMode4Up) {
		
		[self assureInitializationForPreviewMode:TKPreviewMode4Up];
		
		[quadViewFirstBox setContentView:[[previewControllers objectAtIndex:0] view]];
		[quadViewSecondBox setContentView:[[previewControllers objectAtIndex:1] view]];
		[quadViewThirdBox setContentView:[[previewControllers objectAtIndex:2] view]];
		[quadViewFourthBox setContentView:[[previewControllers objectAtIndex:3] view]];
		
		[mainBox setContentView:quadView];
		
		if ([[previews objectAtIndex:0] imageRep] == nil)
			[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:0] afterDelay:0.0];
		
		if ([[previews objectAtIndex:1] imageRep] == nil) 
			[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:1] afterDelay:0.0];
		
		if ([[previews objectAtIndex:2] imageRep] == nil) 
			[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:2] afterDelay:0.0];
		
		if ([[previews objectAtIndex:3] imageRep] == nil) 
			[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:3] afterDelay:0.0];
		
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:previewMode] forKey:TKImageExportSelectedPreviewModeKey];
}


- (void)updatePresetsPopUpMenu {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *orderedNames = [self orderedPresetNamesWithoutOriginal];
	
	NSMutableArray *menuItems = [NSMutableArray array];
	
	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:[[TKImageExportPreset originalImagePreset] name] action:NULL keyEquivalent:@""] autorelease];
	if (menuItem) [menuItems addObject:menuItem];
	[menuItems addObject:[NSMenuItem separatorItem]];
	
	for (NSString *presetName in orderedNames) {
		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:presetName action:NULL keyEquivalent:@""] autorelease];
		if (menuItem) [menuItems addObject:menuItem];
	}
	NSArray *allPresets = [presetsAndNames allValues];
	
	if (![allPresets containsObject:preset]) {
		[menuItems addObject:[NSMenuItem separatorItem]];
		NSMenuItem *customMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"[Custom]", @"") action:NULL keyEquivalent:@""] autorelease];
		if (customMenuItem) [menuItems addObject:customMenuItem];
	}
	
	[[presetPopUpButton menu] setItemArray:menuItems];
	
}



- (void)synchronizeUI {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[self updatePresetsPopUpMenu];
	
	NSArray *allPresets = [presetsAndNames allValues];
	for (TKImageExportPreset *thePreset in allPresets) {
		if ([preset isEqualToPreset:thePreset]) {
			NSArray *presetNames = [presetsAndNames allKeysForObject:thePreset];
			if ([presetNames count]) {
				NSString *presetName = [presetNames objectAtIndex:0];
				[presetPopUpButton selectItemWithTitle:presetName];
				return;
			}
		}
	}
	
	[presetPopUpButton selectItemWithTitle:NSLocalizedString(@"[Custom]", @"")];
	
	[[previews objectAtIndex:selectedTag] setPreset:preset];
	
}


- (NSArray *)orderedPresetNamesWithoutOriginal {
	NSMutableArray *orderedPresetNames = [[[presetsAndNames allKeys] mutableCopy] autorelease];
	[orderedPresetNames removeObject:NSLocalizedString(@"Original", @"")];
	[orderedPresetNames removeObject:NSLocalizedString(@"[Custom]", @"")];
	[orderedPresetNames sortUsingSelector:@selector(caseInsensitiveNumericalCompare:)];
	return [[orderedPresetNames copy] autorelease];
}


- (void)menuNeedsUpdate:(NSMenu *)menu {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (menu == [presetPopUpButton menu]) {
		[self updatePresetsPopUpMenu];
		
	}
}


- (TKImageExportPreset *)preset {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    return preset;
}

- (void)setPreset:(TKImageExportPreset *)value {
#if TK_DEBUG
	NSLog(@"[%@ %@] preset == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), value);
#endif
	TKImageExportPreset *copy = [value copy];
	[preset release];
	preset = copy;
	
//	[value retain];
//	[preset release];
//	preset = value;
	
	if ([[[preset fileType] lowercaseString] isEqualToString:TKVTFFileType]) {
		[compressionPopUpButton setMenu:vtfMenu];
	} else if ([[[preset fileType] lowercaseString] isEqualToString:TKDDSFileType]) {
		[compressionPopUpButton setMenu:ddsMenu];
	}
	
}


- (void)didSelectImageExportPreviewView:(TKImageExportPreviewView *)anImageExportPreviewView {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	TKImageExportPreset *thePreset = [(TKImageExportPreview *)[[anImageExportPreviewView viewController] representedObject] preset];
	[self setPreset:thePreset];
	[self synchronizeUI];
	[self setSelectedTag:[(TKImageExportPreview *)[[anImageExportPreviewView viewController] representedObject] tag]];
	
	
}


- (void)beginPreviewOperationForTag:(NSNumber *)aTag {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSInteger tag = [aTag integerValue];
	TKImageExportPreview *imageExportPreview = [previews objectAtIndex:tag];
	if (imageExportPreview) {
		TKImageExportPreviewOperation *operation = [[TKImageExportPreviewOperation alloc] initWithImageExportPreview:imageExportPreview];
		[operationQueue addOperation:operation];
		[operation release];
	}
}


- (void)imageExportPreviewDidComplete:(NSNotification *)notification {
	if ([notification object] == self) {
#if TK_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		[self performSelectorOnMainThread:@selector(mainThreadImageExportPreviewDidComplete:) withObject:notification waitUntilDone:NO];
	}
}


- (void)mainThreadImageExportPreviewDidComplete:(NSNotification *)notification {
	if ([notification object] == self) {
#if TK_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		TKImageExportPreview *imageExportPreview = [[notification userInfo] objectForKey:TKImageExportPreviewKey];
		if (imageExportPreview == nil) return;
		TKImageRep *imageRep = [imageExportPreview imageRep];
		if (imageRep == nil) return;
		
		NSInteger tag = [imageExportPreview tag];
		[[[previewControllers objectAtIndex:tag] imageView] setImage:[imageRep CGImage] imageProperties:nil];
		
	}
}




- (void)imageViewDidBecomeFirstResponder:(TKImageView *)anImageView {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	for (TKImageExportPreviewViewController *previewController in previewControllers) {
		if (anImageView == [previewController imageView]) {
			[[self window] makeFirstResponder:[previewController view]];
		}
	}
}



- (IBAction)cancel:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[NSUserDefaults standardUserDefaults] setObject:[[self window] stringWithSavedFrame] forKey:TKImageExportSavedFrameKey];
	[document cancel:sender];
}

- (IBAction)export:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[NSUserDefaults standardUserDefaults] setObject:[[self window] stringWithSavedFrame] forKey:TKImageExportSavedFrameKey];
	[document exportWithPreset:preset];
}



- (IBAction)changePreset:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *selectedTitle = [[presetPopUpButton selectedItem] title];
	
	TKImageExportPreset	*selectedPreset = [presetsAndNames objectForKey:selectedTitle];

	[self setPreset:selectedPreset];
}


- (IBAction)changeFormat:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([[[preset fileType] lowercaseString] isEqualToString:TKVTFFileType]) {
		[compressionPopUpButton setMenu:vtfMenu];
	} else if ([[[preset fileType] lowercaseString] isEqualToString:TKDDSFileType]) {
		[compressionPopUpButton setMenu:ddsMenu];
	}
	
	[self synchronizeUI];
	
	[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:selectedTag] afterDelay:0.0];
}


- (IBAction)changeCompression:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *title = [[compressionPopUpButton selectedItem] title];
	
	[qualityPopUpButton setHidden:![title hasPrefix:@"DXT"]];
	[qualityField setHidden:![title hasPrefix:@"DXT"]];
	
	[self synchronizeUI];
	
	[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:selectedTag] afterDelay:0.0];
}

- (IBAction)changeQuality:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[self synchronizeUI];
	
	[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:selectedTag] afterDelay:0.0];

}


- (IBAction)changeMipmaps:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[self synchronizeUI];
	
	[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:selectedTag] afterDelay:0.0];

}

- (IBAction)managePresets:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}




@end



