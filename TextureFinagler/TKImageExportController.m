//
//  TKImageExportController.m
//  Texture Kit
//
//  Created by Mark Douma on 12/11/2010.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import "TKImageExportController.h"
#import "TKImageExportPreviewViewController.h"
#import "TKImageDocument.h"
#import "TKImageExportPreset.h"
#import "TKImageExportPreviewView.h"
#import "TKImageExportPreviewOperation.h"
#import "TKImageExportPreview.h"


#import "TKAppKitAdditions.h"



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


- (void)synchronizeUI;

@end


#define TK_DEBUG 1


enum {
	TKPreviewMode2Up	= 0,
	TKPreviewMode4Up	= 1
};

@implementation TKImageExportController

@synthesize image, document, selectedTag, previewViewZoomFactor;

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
		
		vtfFormat = TKVTFFormatDefault;
		ddsFormat = TKDDSFormatDefault;
		
		presetsAndNames = [[NSMutableDictionary alloc] init];
		
		presets = [[NSMutableArray alloc] init];
		
		previewControllers = [[NSMutableArray alloc] init];
		
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
		
		document = aDocument;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageExportPreviewDidComplete:) name:TKImageExportPreviewOperationDidCompleteNotification object:self];
		
	} else {
		[NSBundle runFailedNibLoadAlert:[NSString stringWithFormat:@"%@", [self windowNibName]]];
	}
	return self;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"********* [%@ %@] *********", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super dealloc];
}


- (NSString *)windowNibName {
	return @"TKImageExportPanel";
}


- (oneway void)release {
#if TK_DEBUG
//	NSLog(@"***** [%@ %@] *****", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super release];
}


- (void)cleanup {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[mediator unbind:@"contentObject"];
	[mediator setContent:nil];
	
	for (TKImageExportPreviewViewController *controller in previewControllers) {
		[[controller imageView] unbind:@"zoomFactor"];
	}
	
	
	[self setPreset:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[presetsAndNames release];
	
	[preset release];
	
	[presets release];
	
	[previewControllers release];
	
	[tagsAndOperations release];
	
	[operationQueue release];
	
	[image release];
	
	document = nil;
	
	[vtfMenu release];
	[ddsMenu release];
}


- (void)assureInitializationForPreviewMode:(NSUInteger)aPreviewMode {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ( !(aPreviewMode == TKPreviewMode2Up || aPreviewMode == TKPreviewMode4Up)) return;
	
	if (aPreviewMode == TKPreviewMode2Up) {
		if ([previewControllers count] < 2) {
			TKImageExportPreviewViewController *firstController = [TKImageExportPreviewViewController previewViewControllerWithExportController:self
																																		 preset:[presets objectAtIndex:0]
																																			tag:0];
			[previewControllers addObject:firstController];
			
			[[firstController imageView] bind:@"zoomFactor" toObject:zoomMediator withKeyPath:@"selection.previewViewZoomFactor" options:nil];
			
			
			TKImageExportPreviewViewController *secondController = [TKImageExportPreviewViewController previewViewControllerWithExportController:self
																																		  preset:[presets objectAtIndex:1]
																																			 tag:1];
			[previewControllers addObject:secondController];
			
			[[secondController imageView] bind:@"zoomFactor" toObject:zoomMediator withKeyPath:@"selection.previewViewZoomFactor" options:nil];
		}
		
	} else {
		if ([previewControllers count] < 4) {
			if ([previewControllers count] == 0) {
				
				TKImageExportPreviewViewController *firstController = [TKImageExportPreviewViewController previewViewControllerWithExportController:self
																																			 preset:[presets objectAtIndex:0]
																																				tag:0];
				[previewControllers addObject:firstController];
				
				[[firstController imageView] bind:@"zoomFactor" toObject:zoomMediator withKeyPath:@"selection.previewViewZoomFactor" options:nil];
				
				
				TKImageExportPreviewViewController *secondController = [TKImageExportPreviewViewController previewViewControllerWithExportController:self
																																			  preset:[presets objectAtIndex:1]
																																				 tag:1];
				[previewControllers addObject:secondController];
				
				[[secondController imageView] bind:@"zoomFactor" toObject:zoomMediator withKeyPath:@"selection.previewViewZoomFactor" options:nil];
				
			}
			
			TKImageExportPreviewViewController *thirdController = [TKImageExportPreviewViewController previewViewControllerWithExportController:self
																																		 preset:[presets objectAtIndex:2]
																																			tag:2];
			[previewControllers addObject:thirdController];
			
			[[thirdController imageView] bind:@"zoomFactor" toObject:zoomMediator withKeyPath:@"selection.previewViewZoomFactor" options:nil];
			
			
			TKImageExportPreviewViewController *fourthController = [TKImageExportPreviewViewController previewViewControllerWithExportController:self
																																		  preset:[presets objectAtIndex:3]
																																			 tag:3];
			[previewControllers addObject:fourthController];
			
			[[fourthController imageView] bind:@"zoomFactor" toObject:zoomMediator withKeyPath:@"selection.previewViewZoomFactor" options:nil];
			
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
		
		[[[previewControllers objectAtIndex:0] view] setNextKeyView:[[previewControllers objectAtIndex:1] view]];
		[[[previewControllers objectAtIndex:1] view] setNextKeyView:[[previewControllers objectAtIndex:0] view]];
		
		[mainBox setContentView:dualView];
		
		[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:0] afterDelay:0.0];
		[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:1] afterDelay:0.0];
		
	} else if (previewMode == TKPreviewMode4Up) {
		
		[self assureInitializationForPreviewMode:TKPreviewMode4Up];
		
		[quadViewFirstBox setContentView:[[previewControllers objectAtIndex:0] view]];
		[quadViewSecondBox setContentView:[[previewControllers objectAtIndex:1] view]];
		[quadViewThirdBox setContentView:[[previewControllers objectAtIndex:2] view]];
		[quadViewFourthBox setContentView:[[previewControllers objectAtIndex:3] view]];
		
		[[[previewControllers objectAtIndex:0] view] setNextKeyView:[[previewControllers objectAtIndex:1] view]];
		[[[previewControllers objectAtIndex:1] view] setNextKeyView:[[previewControllers objectAtIndex:2] view]];
		[[[previewControllers objectAtIndex:2] view] setNextKeyView:[[previewControllers objectAtIndex:3] view]];
		[[[previewControllers objectAtIndex:3] view] setNextKeyView:[[previewControllers objectAtIndex:0] view]];
		
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
		
		NSView *firstView = [[[[previewControllers objectAtIndex:0] view] retain] autorelease];
		NSView *secondView = [[[[previewControllers objectAtIndex:1] view] retain] autorelease];
		
		if ([quadViewFirstBox contentView] == firstView) {
#if TK_DEBUG
			NSLog(@"[%@ %@] ********* [quadViewFirstBox contentView] == firstView", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
			[[quadViewFirstBox contentView] removeFromSuperview];
		}
		
		if ([quadViewSecondBox contentView] == secondView) {
#if TK_DEBUG
			NSLog(@"[%@ %@] ********* quadViewSecondBox contentView] == secondView", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
			[[quadViewSecondBox contentView] removeFromSuperview];
		}
		
		
		[dualViewFirstBox setContentView:[[previewControllers objectAtIndex:0] view]];
		[dualViewSecondBox setContentView:[[previewControllers objectAtIndex:1] view]];
		
		[[[previewControllers objectAtIndex:0] view] setNextKeyView:[[previewControllers objectAtIndex:1] view]];
		[[[previewControllers objectAtIndex:1] view] setNextKeyView:[[previewControllers objectAtIndex:0] view]];
		
		[mainBox setContentView:dualView];
		
		if ([(TKImageExportPreview *)[[previewControllers objectAtIndex:0] representedObject] imageRep] == nil) {
			[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:0] afterDelay:0.0];
		}
		
		if ([(TKImageExportPreview *)[[previewControllers objectAtIndex:1] representedObject] imageRep] == nil) {
			[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:1] afterDelay:0.0];
		}
		
		if (selectedTag >= 2) {
			[(TKImageExportPreviewView *)[[previewControllers objectAtIndex:selectedTag] view] setHighlighted:NO];
			[self setSelectedTag:1];
			[[self window] makeFirstResponder:[[previewControllers objectAtIndex:selectedTag] view]];
		}
		
	} else if (previewMode == TKPreviewMode4Up) {
		
		[self assureInitializationForPreviewMode:TKPreviewMode4Up];
		
		NSView *firstView = [[[[previewControllers objectAtIndex:0] view] retain] autorelease];
		NSView *secondView = [[[[previewControllers objectAtIndex:1] view] retain] autorelease];
		
		if ([dualViewFirstBox contentView] == firstView) {
#if TK_DEBUG
			NSLog(@"[%@ %@] ********* [dualViewFirstBox contentView] == firstView", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
			[[dualViewFirstBox contentView] removeFromSuperview];
		}
		
		if ([dualViewSecondBox contentView] == secondView) {
#if TK_DEBUG
			NSLog(@"[%@ %@] ********* [dualViewSecondBox contentView] == secondView", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
			[[dualViewSecondBox contentView] removeFromSuperview];
		}
		
		
		[quadViewFirstBox setContentView:[[previewControllers objectAtIndex:0] view]];
		[quadViewSecondBox setContentView:[[previewControllers objectAtIndex:1] view]];
		[quadViewThirdBox setContentView:[[previewControllers objectAtIndex:2] view]];
		[quadViewFourthBox setContentView:[[previewControllers objectAtIndex:3] view]];
		
		[[[previewControllers objectAtIndex:0] view] setNextKeyView:[[previewControllers objectAtIndex:1] view]];
		[[[previewControllers objectAtIndex:1] view] setNextKeyView:[[previewControllers objectAtIndex:2] view]];
		[[[previewControllers objectAtIndex:2] view] setNextKeyView:[[previewControllers objectAtIndex:3] view]];
		[[[previewControllers objectAtIndex:3] view] setNextKeyView:[[previewControllers objectAtIndex:0] view]];
		
		
		[mainBox setContentView:quadView];
		
		
		if ([(TKImageExportPreview *)[[previewControllers objectAtIndex:0] representedObject] imageRep] == nil)
			[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:0] afterDelay:0.0];
			
		if ([(TKImageExportPreview *)[[previewControllers objectAtIndex:1] representedObject] imageRep] == nil)
			[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:1] afterDelay:0.0];
			
		if ([(TKImageExportPreview *)[[previewControllers objectAtIndex:2] representedObject] imageRep] == nil)
			[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:2] afterDelay:0.0];
			
		if ([(TKImageExportPreview *)[[previewControllers objectAtIndex:3] representedObject] imageRep] == nil)
			[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:3] afterDelay:0.0];
			
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:previewMode] forKey:TKImageExportSelectedPreviewModeKey];
}



- (void)synchronizeUI {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	/****** -updatePresetsPopUpMenu  ******/
	
	NSString *selectedItemTitle = [presetPopUpButton titleOfSelectedItem];
	
	static BOOL initializedPopUpMenu = NO;
	
	if (!initializedPopUpMenu) {
		NSMutableArray *orderedNames = [[[presetsAndNames allKeys] mutableCopy] autorelease];
		[orderedNames removeObject:NSLocalizedString(@"Original", @"")];
		[orderedNames removeObject:NSLocalizedString(@"[Custom]", @"")];
		[orderedNames sortUsingSelector:@selector(caseInsensitiveNumericalCompare:)];
		
		NSMutableArray *menuItems = [NSMutableArray array];
		
		NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:[[TKImageExportPreset originalImagePreset] name] action:NULL keyEquivalent:@""] autorelease];
		if (menuItem) [menuItems addObject:menuItem];
		
		[menuItems addObject:[NSMenuItem separatorItem]];
		
		for (NSString *presetName in orderedNames) {
			NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:presetName action:NULL keyEquivalent:@""] autorelease];
			if (menuItem) [menuItems addObject:menuItem];
		}
		
		[[presetPopUpButton menu] setItemArray:menuItems];
		
		initializedPopUpMenu = YES;
	}
	
	
	NSArray *allPresets = [presetsAndNames allValues];
	
	NSArray *allItems = [[presetPopUpButton menu] itemArray];
	
	NSMenuItem *lastItem = [allItems lastObject];
	
	
	if ([allPresets containsObject:preset]) {
		
		if ([[lastItem title] isEqualToString:NSLocalizedString(@"[Custom]", @"")]) {
			[[presetPopUpButton menu] removeItemAtIndex:[allItems count] - 1];
			[[presetPopUpButton menu] removeItemAtIndex:[allItems count] - 2];
		}
		
		NSArray *presetNames = [presetsAndNames allKeysForObject:preset];
		if ([presetNames count]) {
			NSString *presetName = [presetNames objectAtIndex:0];
			[presetPopUpButton selectItemWithTitle:presetName];
			
			selectedItemTitle = presetName;
		}
		
	} else {
		
		if (![[lastItem title] isEqualToString:NSLocalizedString(@"[Custom]", @"")]) {
			
			[[presetPopUpButton menu] addItem:[NSMenuItem separatorItem]];
			
			NSMenuItem *customMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"[Custom]", @"") action:NULL keyEquivalent:@""] autorelease];
			
			if (customMenuItem) [[presetPopUpButton menu] addItem:customMenuItem];
			
		}
		
		[presetPopUpButton selectItemWithTitle:NSLocalizedString(@"[Custom]", @"")];
		
		selectedItemTitle = NSLocalizedString(@"[Custom]", @"");

	}
	
	allItems = [[presetPopUpButton menu] itemArray];
	
	for (NSMenuItem *menuItem in allItems) {
		if ([[menuItem title] isEqualToString:selectedItemTitle]) {
			[menuItem setState:NSOnState];
		} else {
			[menuItem setState:NSOffState];
		}
	}
	
	/****** -synchronizeUI  ******/
	
	/****** -updateUI  ******/
	
	NSString *selectedCompressionFormat = [preset compressionFormat];
	
	if ([[[preset fileType] lowercaseString] isEqualToString:TKVTFFileType]) {
		
		[compressionPopUpButton setMenu:vtfMenu];
		
		BOOL hasTitle = NO;
		
		NSArray *menuItems = [vtfMenu itemArray];
		
		for (NSMenuItem *menuItem in menuItems) {
			if ([[menuItem title] isEqualToString:selectedCompressionFormat]) {
				hasTitle = YES;
				break;
			}
		}
		
		if (hasTitle == NO) {
			[preset setCompressionFormat:NSStringFromVTFFormat(vtfFormat)];
		}
		
		vtfFormat = TKVTFFormatFromString([preset compressionFormat]);
		
	} else if ([[[preset fileType] lowercaseString] isEqualToString:TKDDSFileType]) {
		
		[compressionPopUpButton setMenu:ddsMenu];
		
		BOOL hasTitle = NO;
		
		NSArray *menuItems = [ddsMenu itemArray];
		
		for (NSMenuItem *menuItem in menuItems) {
			if ([[menuItem title] isEqualToString:selectedCompressionFormat]) {
				hasTitle = YES;
				break;
			}
		}
		
		if (hasTitle == NO) {
			[preset setCompressionFormat:NSStringFromDDSFormat(ddsFormat)];
		}
		
		ddsFormat = TKDDSFormatFromString([preset compressionFormat]);
	}
	
	if ([preset isEqualToPreset:[TKImageExportPreset originalImagePreset]]) {
		[formatField setHidden:YES];
		[formatPopUpButton setHidden:YES];
		[compressionField setHidden:YES];
		[compressionPopUpButton setHidden:YES];
		[qualityField setHidden:YES];
		[qualityPopUpButton setHidden:YES];
		[mipmapsCheckbox setHidden:YES];
		[mipmapsField setHidden:YES];
		[mipmapsPopUpButton setHidden:YES];
		
	} else {
		
		[formatField setHidden:NO];
		[formatPopUpButton setHidden:NO];
		[compressionField setHidden:NO];
		[compressionPopUpButton setHidden:NO];
		[qualityField setHidden:![[preset compressionFormat] hasPrefix:@"DXT"]];
		[qualityPopUpButton setHidden:![[preset compressionFormat] hasPrefix:@"DXT"]];
		[mipmapsCheckbox setHidden:NO];
		[mipmapsField setHidden:NO];
		[mipmapsPopUpButton setHidden:NO];
		
	}
	
	[formatPopUpButton selectItemWithTitle:[preset fileType]];
	[compressionPopUpButton selectItemWithTitle:[preset compressionFormat]];
	
	
	if (![qualityPopUpButton isHidden]) [qualityPopUpButton selectItemWithTitle:[preset compressionQuality]];
	
	[mipmapsCheckbox setState:[preset mipmapGeneration] != TKMipmapGenerationNoMipmaps];
	
	if ([preset mipmapGeneration] == TKMipmapGenerationNoMipmaps) {
		[mipmapsPopUpButton setEnabled:NO];
	} else {
		[mipmapsPopUpButton setEnabled:YES];
		
		if (![mipmapsPopUpButton isHidden]) [mipmapsPopUpButton selectItemWithTag:[preset mipmapGeneration]];
		
	}
	
}


- (TKImageExportPreset *)preset {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    return preset;
}


- (void)setPreset:(TKImageExportPreset *)aPreset {
#if TK_DEBUG
	NSLog(@"[%@ %@] presets == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), presets);
	NSLog(@"[%@ %@] presetsAndNames == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), presetsAndNames);
	NSLog(@"[%@ %@] previewControllers == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), previewControllers);
	NSLog(@"[%@ %@] preset == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aPreset);
#endif
	
	[aPreset retain];
	[preset release];
	preset = aPreset;
	
	[self synchronizeUI];
}


- (void)didSelectImageExportPreviewView:(TKImageExportPreviewView *)anImageExportPreviewView {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	TKImageExportPreset *thePreset = [(TKImageExportPreview *)[[anImageExportPreviewView viewController] representedObject] preset];
	[self setSelectedTag:[(TKImageExportPreview *)[[anImageExportPreviewView viewController] representedObject] tag]];
	[self setPreset:thePreset];
	
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



- (IBAction)changePreset:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *selectedTitle = [presetPopUpButton titleOfSelectedItem];
	
	TKImageExportPreset	*selectedPreset = [presetsAndNames objectForKey:selectedTitle];
	
	if (selectedPreset != preset) {
		[preset setName:[selectedPreset name]];
		[preset setFileType:[selectedPreset fileType]];
		[preset setCompressionFormat:[selectedPreset compressionFormat]];
		[preset setCompressionQuality:[selectedPreset compressionQuality]];
		[preset setMipmapGeneration:[selectedPreset mipmapGeneration]];
//		[preset setMipmaps:[selectedPreset mipmaps]];
	}
	
	[self synchronizeUI];
	
	[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:selectedTag] afterDelay:0.0];
}


- (IBAction)changeFormat:(id)sender {
#if TK_DEBUG
	NSString *selectedTitle = [(NSPopUpButton *)sender titleOfSelectedItem];
	NSString *presetFileType = [preset fileType];
	NSLog(@"[%@ %@] selectedTitle == %@, presetFileType == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), selectedTitle, presetFileType);
#endif
	
	[preset setFileType:[formatPopUpButton titleOfSelectedItem]];
	
	[self synchronizeUI];
	
	[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:selectedTag] afterDelay:0.0];
}


- (IBAction)changeCompression:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[preset setCompressionFormat:[compressionPopUpButton titleOfSelectedItem]];
	
	[self synchronizeUI];
	
	[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:selectedTag] afterDelay:0.0];
}


- (IBAction)changeQuality:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[preset setCompressionQuality:[qualityPopUpButton titleOfSelectedItem]];
	
	[self synchronizeUI];
	
	[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:selectedTag] afterDelay:0.0];
}


- (IBAction)changeMipmaps:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ([sender isKindOfClass:[NSButton class]]) {
		if ([(NSButton *)sender state]) {
			[mipmapsPopUpButton setEnabled:YES];
			[preset setMipmapGeneration:[mipmapsPopUpButton selectedTag]];
		} else {
			[mipmapsPopUpButton setEnabled:NO];
			[preset setMipmapGeneration:TKMipmapGenerationNoMipmaps];
		}
	} else if ([sender isKindOfClass:[NSPopUpButton class]]) {
		[preset setMipmapGeneration:[mipmapsPopUpButton selectedTag]];
	}
	
//	[preset setMipmaps:[mipmapsCheckbox state]];
	
	[self synchronizeUI];
	
	[self performSelector:@selector(beginPreviewOperationForTag:) withObject:[NSNumber numberWithInteger:selectedTag] afterDelay:0.0];
}


- (IBAction)managePresets:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}


- (void)beginPreviewOperationForTag:(NSNumber *)aTag {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSInteger tag = [aTag integerValue];
	TKImageExportPreview *imageExportPreview = (TKImageExportPreview *)[[previewControllers objectAtIndex:tag] representedObject];
	
	if (imageExportPreview) {
		[imageExportPreview setImageRep:nil];
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
		[(TKImageView *)[[previewControllers objectAtIndex:tag] imageView] setImage:[imageRep CGImage] imageProperties:nil];
		
	}
}


- (void)saveDefaults {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[NSUserDefaults standardUserDefaults] setObject:[[self window] stringWithSavedFrame] forKey:TKImageExportSavedFrameKey];
	
	[[NSUserDefaults standardUserDefaults] setObject:[(TKImageExportPreset *)[presets objectAtIndex:0] dictionaryRepresentation] forKey:TKImageExportFirstPresetKey];
	[[NSUserDefaults standardUserDefaults] setObject:[(TKImageExportPreset *)[presets objectAtIndex:1] dictionaryRepresentation] forKey:TKImageExportSecondPresetKey];
	[[NSUserDefaults standardUserDefaults] setObject:[(TKImageExportPreset *)[presets objectAtIndex:2] dictionaryRepresentation] forKey:TKImageExportThirdPresetKey];
	[[NSUserDefaults standardUserDefaults] setObject:[(TKImageExportPreset *)[presets objectAtIndex:3] dictionaryRepresentation] forKey:TKImageExportFourthPresetKey];

	
}


- (IBAction)cancel:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self saveDefaults];
	[document cancel:sender];
}

- (IBAction)export:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self saveDefaults];
	[document exportWithPreset:preset];
}



- (IBAction)changeTool:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//	NSInteger tag = [sender tag];
	
	
	
	
}








@end



