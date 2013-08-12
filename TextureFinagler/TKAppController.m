//
//  TKAppController.m
//  Source Finagler
//
//  Created by Mark Douma on 5/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//


#import "TKAppController.h"

#import "TKViewController.h"
#import "MDSteamAppsRelocatorController.h"
#import "MDOtherAppsHelperController.h"

#import "TKAppKitAdditions.h"

#import "TKAboutWindowController.h"
#import "MDInspectorController.h"
#import "MDViewOptionsController.h"
#import "MDQuickLookController.h"
#import "MDHLDocument.h"
#import "TKDocumentController.h"

#import "MDUserDefaults.h"

#import "TKPrefsController.h"
#import "MDBrowser.h"
#import "MDOutlineView.h"

#import "TKImageDocument.h"
#import "TKImageInspectorController.h"




NSString * const MDCurrentViewKey							= @"MDCurrentView";

NSString * const TKLastVersionRunKey						= @"TKLastVersionRun";

NSString * const TKLastSpotlightImporterVersionKey			= @"TKLastSpotlightImporterVersion";
NSString * const TKLastSourceAddonFinaglerVersionKey		= @"TKLastSourceAddonFinaglerVersion";
NSString * const TKSpotlightImporterBundleIdentifierKey		= @"com.markdouma.mdimporter.Source";

NSString * const TKLaunchTimeActionKey						= @"TKLaunchTimeAction";

NSString * const TKQuitAfterAllWindowsClosedKey				= @"TKQuitAfterAllWindowsClosed";
NSString * const TKLastWindowDidCloseNotification			= @"TKLastWindowDidClose";

NSString * const TKFinderBundleIdentifierKey				= @"com.apple.finder";


/*************		websites & email addresses	*************/

NSString * const TKWebpage						= @"http://www.markdouma.com/sourcefinagler/";

NSString * const TKEmailStaticURLString			= @"mailto:mark@markdouma.com";

NSString * const TKEmailDynamicURLString		= @"mailto:mark@markdouma.com?subject=Source Finagler (%@)&body=Note: creating a unique Subject for your email will help me keep track of your inquiry more easily. Feel free to alter the one provided as you like.";


NSString * const TKEmailAddress					= @"mark@markdouma.com";
NSString * const TKiChatURLString				= @"aim:goim?screenname=MarkDouma46&message=Type+your+message+here.";


BOOL	MDShouldShowViewOptions = NO;
BOOL	MDShouldShowInspector = NO;
BOOL	MDShouldShowQuickLook = NO;

BOOL	TKShouldShowImageInspector = NO;

BOOL	MDShouldShowPathBar = NO;

BOOL	MDPlaySoundEffects = NO;
BOOL	MDPerformingBatchOperation = NO;


#define TK_DEBUG 1

#define TK_DEBUG_SPOTLIGHT 0

#define defaultFontSize 12
#define defaultIconSize 16
#define defaultBrowserViewFontAndIconSize 13


SInt32 TKSystemVersion = 0;

BOOL needSpotlightReimport = NO;
BOOL needSourceAddonFinaglerRegister = NO;


static NSArray *appClassNames = nil;


@interface TKAppController (TKPrivate)
- (void)forceSpotlightReimport:(id)sender;
@end

@implementation TKAppController


+ (void)initialize {
	
	@synchronized(self) {
		
		if (appClassNames == nil) {
			appClassNames = [[[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TKAppController" ofType:@"plist"]] objectForKey:@"TKAppControllerClassNames"] retain];
		}
		
		SInt32 MDFullSystemVersion = 0;
		
		Gestalt(gestaltSystemVersion, &MDFullSystemVersion);
		TKSystemVersion = MDFullSystemVersion & 0xfffffff0;
		
		
		// need to run it here in case the font document isn't created prior to the view options window being instantiated.
		
		MDPlaySoundEffects = NO;
		
		NSNumber *enabled = [[MDUserDefaults standardUserDefaults] objectForKey:MDSystemSoundEffectsLeopardKey forAppIdentifier:MDSystemSoundEffectsLeopardBundleIdentifierKey inDomain:MDUserDefaultsUserDomain];
		
		/*	enabled is an NSNumber, not a YES or NO value. If enabled is nil, we assume the default sound effect setting, which is enabled. Only if enabled is non-nil do we have an actual YES or NO answer to examine	*/
		
		if (enabled) {
			MDPlaySoundEffects = (BOOL)[enabled intValue];
		} else {
			MDPlaySoundEffects = YES;
		}
		
		NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
		
		NSNumber *finderListViewFontSize = nil;
		NSNumber *finderListViewIconSize = nil;
		NSNumber *finderColumnViewFontAndIconSize = nil;
		
		MDUserDefaults *userDefaults = [MDUserDefaults standardUserDefaults];
		
		
		finderListViewFontSize = [[[userDefaults objectForKey:@"StandardViewOptions" forAppIdentifier:TKFinderBundleIdentifierKey inDomain:MDUserDefaultsUserDomain] objectForKey:@"ListViewOptions"] objectForKey:@"FontSize"];
		finderListViewIconSize = [[[userDefaults objectForKey:@"StandardViewOptions" forAppIdentifier:TKFinderBundleIdentifierKey inDomain:MDUserDefaultsUserDomain] objectForKey:@"ListViewOptions"] objectForKey:@"IconSize"];
		
		finderColumnViewFontAndIconSize = [[[userDefaults objectForKey:@"StandardViewOptions" forAppIdentifier:TKFinderBundleIdentifierKey inDomain:MDUserDefaultsUserDomain] objectForKey:@"ColumnViewOptions"] objectForKey:@"FontSize"];
		
		[defaultValues setObject:[NSNumber numberWithInteger:MDListViewMode] forKey:MDDocumentViewModeKey];
		
		if (finderListViewFontSize) {
			[defaultValues setObject:finderListViewFontSize forKey:MDListViewFontSizeKey];
		} else {
			[defaultValues setObject:[NSNumber numberWithInteger:defaultFontSize] forKey:MDListViewFontSizeKey];
		}
		
		if (finderListViewIconSize) {
			[defaultValues setObject:finderListViewIconSize forKey:MDListViewIconSizeKey];
		} else {
			[defaultValues setObject:[NSNumber numberWithInteger:defaultIconSize] forKey:MDListViewIconSizeKey];
		}
		
		if (finderColumnViewFontAndIconSize) {
			[defaultValues setObject:finderColumnViewFontAndIconSize forKey:MDBrowserFontAndIconSizeKey];
		} else {
			[defaultValues setObject:[NSNumber numberWithInteger:defaultBrowserViewFontAndIconSize] forKey:MDBrowserFontAndIconSizeKey];
		}
		
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:MDShouldShowInvisibleItemsKey];
		
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:MDShouldShowKindColumnKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:MDShouldShowSizeColumnKey];
		
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:MDBrowserShouldShowIconsKey];
		[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:MDBrowserShouldShowPreviewKey];
		
		[defaultValues setObject:[NSNumber numberWithInteger:MDBrowserSortByName] forKey:MDBrowserSortByKey];
		
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:MDShouldShowInspectorKey];
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:MDShouldShowQuickLookKey];
		
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:TKShouldShowImageInspectorKey];
		
		[defaultValues setObject:[NSNumber numberWithUnsignedInteger:TKLaunchTimeActionOpenMainWindow] forKey:TKLaunchTimeActionKey];
		
		[defaultValues setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] forKey:TKLastVersionRunKey];
		
		if ([[NSUserDefaults standardUserDefaults] objectForKey:TKLastSpotlightImporterVersionKey] == nil) {
			needSpotlightReimport = YES;
			NSLog(@"[%@ %@] needSpotlightReimport = YES", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
		[defaultValues setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] forKey:TKLastSpotlightImporterVersionKey];
		
		if ([[NSUserDefaults standardUserDefaults] objectForKey:TKLastSourceAddonFinaglerVersionKey] == nil) {
			needSourceAddonFinaglerRegister = YES;
			NSLog(@"[%@ %@] needSourceAddonFinaglerRegister = YES", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
		[defaultValues setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] forKey:TKLastSourceAddonFinaglerVersionKey];
		
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:TKQuitAfterAllWindowsClosedKey];
		
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:MDShouldShowViewOptionsKey];
		
		
		[defaultValues setObject:[NSNumber numberWithUnsignedInteger:TKSteamAppsRelocatorView] forKey:MDCurrentViewKey];
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
		[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
		
	}
}

- (id)init {
	if ((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lastWindowDidClose:) name:TKLastWindowDidCloseNotification object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowViewOptionsDidChange:) name:MDShouldShowViewOptionsDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowInspectorDidChange:) name:MDShouldShowInspectorDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowQuickLookDidChange:) name:MDShouldShowQuickLookDidChangeNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowImageInspectorDidChange:) name:TKShouldShowImageInspectorDidChangeNotification object:nil];
		
		viewControllers = [[NSMutableArray alloc] init];
		
		NSUInteger count = appClassNames.count;
		
		for (NSUInteger i = 0; i < count; i++) {
			[viewControllers addObject:[NSNull null]];
		}
		
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[viewControllers release];
	
	[aboutWindowController release];
	
	[inspectorController release];
	[viewOptionsController release];
	[quickLookController release];
	
	[imageInspectorController release];
	
	[prefsController release];
		
	[steamAppsRelocatorController release];
	[otherAppsHelperController release];
	
	[viewToggleToolbarShownMenuItem release];
	[viewCustomizeToolbarMenuItem release];
	[viewOptionsMenuItem release];
	
	[globalUndoManager release];
	
	[super dealloc];
}

- (void)awakeFromNib {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
//	if ([[userDefaults objectForKey:MDSourceAddonFinaglerIsRegisteredKey] boolValue] == NO) {
//		NSString *sourceAddonFinaglerPath = [[NSBundle mainBundle] pathForResource:@"Source Addon Finagler" ofType:@"app"];
//		if (sourceAddonFinaglerPath) {
//			OSStatus status = LSRegisterURL((CFURLRef)[NSURL fileURLWithPath:sourceAddonFinaglerPath], true);
//			if (status) {
//				NSLog(@"[%@ %@] LSRegisterURL() returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), status);
//			} else {
//				[userDefaults setObject:[NSNumber numberWithBool:YES] forKey:MDSourceAddonFinaglerIsRegisteredKey];
//			}
//		}
//	}
	
	[viewModeAsListMenuItem retain];
	
	if (TKSystemVersion < TKSnowLeopard) {
		[viewMenu removeItem:viewModeAsColumnsMenuItem];
		viewModeAsColumnsMenuItem = nil;
	} else {
		[viewModeAsColumnsMenuItem retain];
	}
	
	
	[viewTogglePathBarMenuItem retain];
	
	[viewToggleToolbarShownMenuItem retain];
	[viewCustomizeToolbarMenuItem retain];
	[viewOptionsMenuItem retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSwitchTo:) name:MDDidSwitchDocumentNotification object:nil];
	
	// from setupUI, since it only needs to be done once
	
	[emailMenuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Email: %@", @""), TKEmailAddress]];
	NSImage *emailAppImage = [[NSWorkspace sharedWorkspace] iconForApplicationForURL:[NSURL URLWithString:TKEmailStaticURLString]];
	if (emailAppImage) {
		[emailAppImage setSize:NSMakeSize(16.0,16.0)];
		[emailMenuItem setImage:emailAppImage];
	}
	
	NSImage *chatAppImage = [[NSWorkspace sharedWorkspace] iconForApplicationForURL:[NSURL URLWithString:TKiChatURLString]];
	if (chatAppImage) {
		[chatAppImage setSize:NSMakeSize(16.0,16.0)];
		[chatMenuItem setImage:chatAppImage];
	}
	
	NSImage *webAppImage = [[NSWorkspace sharedWorkspace] iconForApplicationForURL:[NSURL URLWithString:TKWebpage]];
	if (webAppImage) {
		[webAppImage setSize:NSMakeSize(16.0,16.0)];
		[webpageMenuItem setImage:webAppImage];
	}
	
	MDShouldShowInspector = [[userDefaults objectForKey:MDShouldShowInspectorKey] boolValue];
	MDShouldShowViewOptions = [[userDefaults objectForKey:MDShouldShowViewOptionsKey] boolValue];
	MDShouldShowQuickLook = [[userDefaults objectForKey:MDShouldShowQuickLookKey] boolValue];
	
	TKShouldShowImageInspector = [[userDefaults objectForKey:TKShouldShowImageInspectorKey] boolValue];
	
	
	if (MDShouldShowViewOptions) {
		if (viewOptionsController == nil) viewOptionsController = [[MDViewOptionsController alloc] init];
		[viewOptionsController showWindow:self];
	}
	
	if (MDShouldShowInspector) {
		if (inspectorController == nil) inspectorController = [[MDInspectorController alloc] init];
		[inspectorController showWindow:self];
	}
	
	if (MDShouldShowQuickLook) {
		if (quickLookController == nil) quickLookController = [[MDQuickLookController alloc] init];
		[quickLookController showWindow:self];
	}
	
	if (TKShouldShowImageInspector) {
		if (imageInspectorController == nil) imageInspectorController = [[TKImageInspectorController alloc] init];
		[imageInspectorController showWindow:self];
	}
	
	currentView = [[userDefaults objectForKey:MDCurrentViewKey] unsignedIntegerValue];
	[self switchView:self];
	
	
	[NSApp setServicesProvider:self];
	
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:TKLaunchTimeActionKey] unsignedIntegerValue] & TKLaunchTimeActionOpenMainWindow) {
		[window makeKeyAndOrderFront:nil];
	}
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSInteger previousVersion = 0, currentVersion = 0;
	previousVersion = [[[NSUserDefaults standardUserDefaults] objectForKey:TKLastSourceAddonFinaglerVersionKey] integerValue];
	currentVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] integerValue];
	
	if (currentVersion > previousVersion || needSourceAddonFinaglerRegister) {
		NSString *sourceAddonFinaglerPath = [[NSBundle mainBundle] pathForResource:@"Source Addon Finagler" ofType:@"app"];
		if (sourceAddonFinaglerPath) {
			OSStatus status = LSRegisterURL((CFURLRef)[NSURL fileURLWithPath:sourceAddonFinaglerPath], true);
			if (status) {
				NSLog(@"[%@ %@] LSRegisterURL() returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
			} else {
				[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:currentVersion] forKey:TKLastSourceAddonFinaglerVersionKey];
			}
		}
	}
	
	
	if (needSpotlightReimport == NO) needSpotlightReimport = TK_DEBUG_SPOTLIGHT;
	
	previousVersion = 0;
	currentVersion = 0;
	
	previousVersion = [[[NSUserDefaults standardUserDefaults] objectForKey:TKLastSpotlightImporterVersionKey] integerValue];
	currentVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] integerValue];
	if (currentVersion > previousVersion || needSpotlightReimport) {
		[self performSelector:@selector(forceSpotlightReimport:) withObject:nil afterDelay:3.0];
	}
	
}


- (void)forceSpotlightReimport:(id)sender {
//#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	NSString *spotlightImporterPath = nil;
//	
//	spotlightImporterPath = [[[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Spotlight"] stringByAppendingPathComponent:@"Source.mdimporter"];
//	
//	NSData *standardOutputData = nil;
//	NSData *standardErrorData = nil;
//	NSTask *task = [[[NSTask alloc] init] autorelease];
//	[task setLaunchPath:@"/usr/bin/mdimport"];
//	[task setArguments:[NSArray arrayWithObjects:@"-r", spotlightImporterPath, nil]];
//	[task setStandardOutput:[NSPipe pipe]];
//	[task setStandardError:[NSPipe pipe]];
//	[task launch];
//	[task waitUntilExit];
//	
//	standardOutputData = [[[task standardOutput] fileHandleForReading] availableData];
//	if (standardOutputData && [standardOutputData length]) {
//		NSString *standardOutputString = [[[NSString alloc] initWithData:standardOutputData encoding:NSUTF8StringEncoding] autorelease];
//		NSLog(@"[%@ %@] standardOutputString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardOutputString);
//	}
//	standardErrorData = [[[task standardError] fileHandleForReading] availableData];
//	if (standardErrorData && [standardErrorData length]) {
//		NSString *standardErrorString = [[[NSString alloc] initWithData:standardErrorData encoding:NSUTF8StringEncoding] autorelease];
//		NSLog(@"[%@ %@] standardErrorString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardErrorString);
//	}
//	if (![task isRunning]) {
//		if ([task terminationStatus] != 0) {
//			NSLog(@"[%@ %@] /usr/bin/mdimport returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [task terminationStatus]);
//		}
//	}
//	[[NSUserDefaults standardUserDefaults] setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] forKey:TKLastSpotlightImporterVersionKey];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:TKQuitAfterAllWindowsClosedKey] boolValue];
}


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:TKLaunchTimeActionKey] unsignedIntegerValue] & TKLaunchTimeActionOpenNewDocument;
}


- (void)applicationWillTerminate:(NSNotification *)notification {
	[steamAppsRelocatorController cleanup];
	[otherAppsHelperController cleanup];
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:currentView] forKey:MDCurrentViewKey];
}

- (NSUndoManager *)globalUndoManager {
#if TK_DEBUG
	NSLog(@"[%@ %@] *****************", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (globalUndoManager == nil) globalUndoManager = [[NSUndoManager alloc] init];
	return globalUndoManager;
}


	// this method is used 
- (void)didSwitchTo:(NSNotification *)notification {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (TKSystemVersion == TKLeopard) {
		[viewMenu setItemArray:[NSArray arrayWithObjects:viewModeAsListMenuItem,[NSMenuItem separatorItem], viewTogglePathBarMenuItem, [NSMenuItem separatorItem], viewToggleToolbarShownMenuItem,viewCustomizeToolbarMenuItem,[NSMenuItem separatorItem],viewOptionsMenuItem, nil]];
		
	} else if (TKSystemVersion >= TKSnowLeopard) {
		[viewMenu setItemArray:[NSArray arrayWithObjects:viewModeAsListMenuItem,viewModeAsColumnsMenuItem,[NSMenuItem separatorItem], viewTogglePathBarMenuItem, [NSMenuItem separatorItem], viewToggleToolbarShownMenuItem,viewCustomizeToolbarMenuItem,[NSMenuItem separatorItem],viewOptionsMenuItem, nil]];
		
	}
	
}


- (IBAction)switchView:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (sender == self || sender == nil) {
		
		NSUInteger count = viewControllers.count;
		
		while (currentView >= count) {
			currentView--;
		}
		
		NSArray *toolbarItems = window.toolbar.items;
		for (NSToolbarItem *toolbarItem in toolbarItems) {
			if (toolbarItem.tag == currentView) {
				[window.toolbar setSelectedItemIdentifier:toolbarItem.itemIdentifier]; break;
			}
		}
	} else {
		currentView = [(NSToolbarItem *)sender tag];
	}
	
	TKViewController *viewController = [viewControllers objectAtIndex:currentView];
	
	if ((NSNull *)viewController == [NSNull null]) {
		NSString *className = [appClassNames objectAtIndex:currentView];
		
		Class viewControllerClass = NSClassFromString(className);
		
		viewController = [[viewControllerClass alloc] init];
		
		[viewControllers replaceObjectAtIndex:currentView withObject:viewController];
		
		[viewController release];
	}
	
	[window switchView:viewController.view newTitle:viewController.title];
	[viewController didSwitchToView:self];
	
}


- (void)lastWindowDidClose:(NSNotification *)notification {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[viewMenu setItemArray:[NSArray arrayWithObjects:viewTogglePathBarMenuItem, [NSMenuItem separatorItem], viewToggleToolbarShownMenuItem, viewCustomizeToolbarMenuItem, [NSMenuItem separatorItem], viewOptionsMenuItem, nil]];
	
}


- (IBAction)toggleShowInspector:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	MDShouldShowInspector = !MDShouldShowInspector;
	
	if (MDShouldShowInspector) {
		if (inspectorController == nil) inspectorController = [[MDInspectorController alloc] init];
		[inspectorController showWindow:self];
	} else {
		if (inspectorController) [[inspectorController window] performClose:self];
	}
}


- (void)shouldShowInspectorDidChange:(NSNotification *)notification {
	if (MDShouldShowInspector == NO) {
#if TK_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		[inspectorController release]; inspectorController = nil;
	}
}


- (IBAction)toggleShowViewOptions:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	MDShouldShowViewOptions = !MDShouldShowViewOptions;
	
	if (MDShouldShowViewOptions) {
		if (viewOptionsController == nil) viewOptionsController = [[MDViewOptionsController alloc] init];
		[viewOptionsController showWindow:self];
	} else {
		if (viewOptionsController) [[viewOptionsController window] performClose:self];
	}
}


- (void)shouldShowViewOptionsDidChange:(NSNotification *)notification {
	if (MDShouldShowViewOptions == NO) {
#if TK_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		[viewOptionsController release]; viewOptionsController = nil;
	}
}


- (IBAction)toggleShowQuickLook:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	MDShouldShowQuickLook = !MDShouldShowQuickLook;
	
	if (MDShouldShowQuickLook) {
		if (quickLookController == nil) quickLookController = [[MDQuickLookController sharedQuickLookController] retain];
		[quickLookController showWindow:self];
	} else {
		if (quickLookController) [[quickLookController window] performClose:self];
	}
}


- (void)shouldShowQuickLookDidChange:(NSNotification *)notification {
	if (MDShouldShowQuickLook == NO) {
#if TK_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		[quickLookController release]; quickLookController = nil;
	}
}


- (IBAction)toggleShowImageInspector:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	TKShouldShowImageInspector = !TKShouldShowImageInspector;
	
	if (TKShouldShowImageInspector) {
		if (imageInspectorController == nil) imageInspectorController = [[TKImageInspectorController sharedController] retain];
		[imageInspectorController showWindow:self];
	} else {
		if (imageInspectorController) [[imageInspectorController window] performClose:self];
	}
}


- (void)shouldShowImageInspectorDidChange:(NSNotification *)notification {
	if (TKShouldShowImageInspector == NO) {
#if TK_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//		[imageInspectorController release]; imageInspectorController = nil;
	}
}



- (IBAction)showMainWindow:(id)sender {
	if (![window isVisible]) [window makeKeyAndOrderFront:nil];
}


- (IBAction)showAboutWindow:(id)sender {
	if (aboutWindowController == nil) aboutWindowController = [[TKAboutWindowController alloc] init];
	[aboutWindowController showWindow:self];
}


- (IBAction)showPrefsWindow:(id)sender {
	if (prefsController == nil) prefsController = [[TKPrefsController alloc] init];
	[prefsController showWindow:self];
}


- (void)menuNeedsUpdate:(NSMenu *)menu {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
//	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), menuItem);
	
	SEL action = [menuItem action];
//	NSInteger tag = [menuItem tag];
	
	if (action == @selector(switchView:)) {
	} else if (action == @selector(showPrefsWindow:)) {
		return YES;
	} else if (action == @selector(toggleShowViewOptions:)) {
		[menuItem setTitle:(MDShouldShowViewOptions ? NSLocalizedString(@"Hide View Options", @"") : NSLocalizedString(@"Show View Options", @""))];
		return YES;
	} else if (action == @selector(toggleShowInspector:)) {
		[menuItem setTitle:(MDShouldShowInspector ? NSLocalizedString(@"Hide Inspector", @"") : NSLocalizedString(@"Show Inspector", @""))];
		
		return YES;
		
	} else if (action == @selector(toggleShowImageInspector:)) {
		[menuItem setTitle:(TKShouldShowImageInspector ? NSLocalizedString(@"Hide Image Inspector", @"") : NSLocalizedString(@"Show Image Inspector", @""))];
		
		return YES;
		
	} else if (action == @selector(toggleShowQuickLook:)) {
		[menuItem setTitle:(MDShouldShowQuickLook ? NSLocalizedString(@"Close Quick Look", @"") : NSLocalizedString(@"Quick Look", @""))];
		
		return YES;
	} else if (action == @selector(showMainWindow:)) {
		[menuItem setState:(NSInteger)([window isVisible] && [window isMainWindow])];
		
		return YES;
		
	}
	return YES;
}



- (IBAction)email:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[NSString stringWithFormat:TKEmailDynamicURLString, NSUserName()] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

- (IBAction)chat:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:TKiChatURLString]];
}

- (IBAction)webpage:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:TKWebpage]];
}


- (IBAction)resetAllWarningDialogs:(id)sender {

}


@end


