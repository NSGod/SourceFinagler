//
//  MDAppController.m
//  Source Finagler
//
//  Created by Mark Douma on 5/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//


#import "MDAppController.h"

#import "MDSteamAppsRelocatorController.h"
#import "MDOtherAppsHelperController.h"

#import "MDAppKitAdditions.h"

#import "MDAboutWindowController.h"
#import "MDInspectorController.h"
#import "MDViewOptionsController.h"
#import "MDQuickLookController.h"
#import "MDHLDocument.h"
#import "TKDocumentController.h"

#import "MDUserDefaults.h"

#import "MDPrefsController.h"
#import "MDBrowser.h"
#import "MDOutlineView.h"

#import <Sparkle/Sparkle.h>



NSString * const MDCurrentViewKey							= @"MDCurrentView";

NSString * const MDLastVersionRunKey						= @"MDLastVersionRun";

NSString * const MDLastSpotlightImporterVersionKey			= @"MDLastSpotlightImporterVersion";
NSString * const MDLastSourceAddonFinaglerVersionKey		= @"MDLastSourceAddonFinaglerVersion";
NSString * const MDSpotlightImporterBundleIdentifierKey		= @"com.markdouma.mdimporter.Source";

NSString * const MDSteamAppsRelocatorIdentifierKey			= @"MDSteamAppsRelocatorIdentifier";
NSString * const MDOtherAppsHelperIdentifierKey				= @"MDOtherAppsHelperIdentifier";
NSString * const MDConfigCopyIdentifierKey					= @"MDConfigCopyIdentifier";

NSString * const MDLaunchTimeActionKey						= @"MDLaunchTimeAction";

NSString * const MDQuitAfterAllWindowsClosedKey				= @"MDQuitAfterAllWindowsClosed";
NSString * const MDLastWindowDidCloseNotification			= @"MDLastWindowDidClose";

NSString * const MDFinderBundleIdentifierKey = @"com.apple.finder";


/*************		websites & email addresses	*************/

NSString * const MDWebpage						= @"http://www.markdouma.com/sourcefinagler/";

NSString * const MDEmailStaticURLString			= @"mailto:mark@markdouma.com";

NSString * const MDEmailDynamicURLString		= @"mailto:mark@markdouma.com?subject=Source Finagler (%@)&body=Note: creating a unique Subject for your email will help me keep track of your inquiry more easily. Feel free to alter the one provided as you like.";


NSString * const MDEmailAddress					= @"mark@markdouma.com";
NSString * const MDiChatURLString				= @"aim:goim?screenname=MarkDouma46&message=Type+your+message+here.";

static NSString * const MDSUFeedURLLeopard		= @"http://www.markdouma.com/sourcefinagler/versionLeopard.xml";



BOOL	MDShouldShowViewOptions = NO;
BOOL	MDShouldShowInspector = NO;
BOOL	MDShouldShowQuickLook = NO;

BOOL	MDShouldShowPathBar = NO;

BOOL	MDPlaySoundEffects = NO;
BOOL	MDPerformingBatchOperation = NO;


#define VS_DEBUG 0

#define MD_DEBUG 0

#define MD_DEBUG_SPOTLIGHT 0

#define defaultFontSize 12
#define defaultIconSize 16
#define defaultBrowserViewFontAndIconSize 13


SInt32 MDSystemVersion = 0;

BOOL needSpotlightReimport = NO;
BOOL needSourceAddonFinaglerRegister = NO;


@interface MDAppController (Private)
- (void)forceSpotlightReimport:(id)sender;
@end

@implementation MDAppController


+ (void)initialize {
	
	SInt32 MDFullSystemVersion = 0;

	Gestalt(gestaltSystemVersion, &MDFullSystemVersion);
	MDSystemVersion = MDFullSystemVersion & 0xfffffff0;
	
	
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
	
		
	finderListViewFontSize = [[[userDefaults objectForKey:@"StandardViewOptions" forAppIdentifier:MDFinderBundleIdentifierKey inDomain:MDUserDefaultsUserDomain] objectForKey:@"ListViewOptions"] objectForKey:@"FontSize"];
	finderListViewIconSize = [[[userDefaults objectForKey:@"StandardViewOptions" forAppIdentifier:MDFinderBundleIdentifierKey inDomain:MDUserDefaultsUserDomain] objectForKey:@"ListViewOptions"] objectForKey:@"IconSize"];
	
	finderColumnViewFontAndIconSize = [[[userDefaults objectForKey:@"StandardViewOptions" forAppIdentifier:MDFinderBundleIdentifierKey inDomain:MDUserDefaultsUserDomain] objectForKey:@"ColumnViewOptions"] objectForKey:@"FontSize"];
	
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
	
	[defaultValues setObject:[NSNumber numberWithUnsignedInteger:MDLaunchTimeActionOpenMainWindow] forKey:MDLaunchTimeActionKey];
	
	[defaultValues setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] forKey:MDLastVersionRunKey];
	
	if ([[NSUserDefaults standardUserDefaults] objectForKey:MDLastSpotlightImporterVersionKey] == nil) {
		needSpotlightReimport = YES;
		NSLog(@"[%@ %@] needSpotlightReimport = YES", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	}
	[defaultValues setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] forKey:MDLastSpotlightImporterVersionKey];

	if ([[NSUserDefaults standardUserDefaults] objectForKey:MDLastSourceAddonFinaglerVersionKey] == nil) {
		needSourceAddonFinaglerRegister = YES;
		NSLog(@"[%@ %@] needSourceAddonFinaglerRegister = YES", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	}
	[defaultValues setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] forKey:MDLastSourceAddonFinaglerVersionKey];
	
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:MDQuitAfterAllWindowsClosedKey];
	
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:MDShouldShowViewOptionsKey];
	
	
	[defaultValues setObject:[NSNumber numberWithUnsignedInteger:MDSteamAppsRelocatorView] forKey:MDCurrentViewKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
}

- (id)init {
	if ((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lastWindowDidClose:) name:MDLastWindowDidCloseNotification object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowViewOptionsDidChange:) name:MDShouldShowViewOptionsDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowInspectorDidChange:) name:MDShouldShowInspectorDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowQuickLookDidChange:) name:MDShouldShowQuickLookDidChangeNotification object:nil];
		
	}
	return self;
}

- (void)dealloc {
	[aboutWindowController release];
	
	[inspectorController release];
	[viewOptionsController release];
	[quickLookController release];
	
	[prefsController release];
		
	[steamAppsRelocatorController release];
	[otherAppsHelperController release];
	
	[viewToggleToolbarShownMenuItem release];
	[viewCustomizeToolbarMenuItem release];
	[viewOptionsMenuItem release];
	
	[globalUndoManager release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	
	[super dealloc];
}

- (void)awakeFromNib {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (MDSystemVersion <= MDLeopard) {
		[sparkleUpdater setFeedURL:[NSURL URLWithString:MDSUFeedURLLeopard]];
	}
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	[viewModeAsListMenuItem retain];
	
	if (MDSystemVersion < MDSnowLeopard) {
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
	
	[emailMenuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Email: %@", @""), MDEmailAddress]];
	NSImage *emailAppImage = [[NSWorkspace sharedWorkspace] iconForApplicationForURL:[NSURL URLWithString:MDEmailStaticURLString]];
	if (emailAppImage) {
		[emailAppImage setSize:NSMakeSize(16.0,16.0)];
		[emailMenuItem setImage:emailAppImage];
	}
	
	NSImage *chatAppImage = [[NSWorkspace sharedWorkspace] iconForApplicationForURL:[NSURL URLWithString:MDiChatURLString]];
	if (chatAppImage) {
		[chatAppImage setSize:NSMakeSize(16.0,16.0)];
		[chatMenuItem setImage:chatAppImage];
	}
	
	NSImage *webAppImage = [[NSWorkspace sharedWorkspace] iconForApplicationForURL:[NSURL URLWithString:MDWebpage]];
	if (webAppImage) {
		[webAppImage setSize:NSMakeSize(16.0,16.0)];
		[webpageMenuItem setImage:webAppImage];
	}
	
	MDShouldShowInspector = [[userDefaults objectForKey:MDShouldShowInspectorKey] boolValue];
	MDShouldShowViewOptions = [[userDefaults objectForKey:MDShouldShowViewOptionsKey] boolValue];
	MDShouldShowQuickLook = [[userDefaults objectForKey:MDShouldShowQuickLookKey] boolValue];
	
	
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
	
	currentView = [[userDefaults objectForKey:MDCurrentViewKey] unsignedIntegerValue];
	[self switchView:self];
	
	
	[NSApp setServicesProvider:self];
	
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:MDLaunchTimeActionKey] unsignedIntegerValue] & MDLaunchTimeActionOpenMainWindow) {
		[window makeKeyAndOrderFront:nil];
	}
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSInteger previousVersion = 0, currentVersion = 0;
	previousVersion = [[[NSUserDefaults standardUserDefaults] objectForKey:MDLastSourceAddonFinaglerVersionKey] integerValue];
	currentVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] integerValue];
	
	if (currentVersion > previousVersion || needSourceAddonFinaglerRegister) {
		NSString *sourceAddonFinaglerPath = [[NSBundle mainBundle] pathForResource:@"Source Addon Finagler" ofType:@"app"];
		if (sourceAddonFinaglerPath) {
			OSStatus status = LSRegisterURL((CFURLRef)[NSURL fileURLWithPath:sourceAddonFinaglerPath], true);
			if (status) {
				NSLog(@"[%@ %@] LSRegisterURL() returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
			} else {
				[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:currentVersion] forKey:MDLastSourceAddonFinaglerVersionKey];
			}
		}
	}
	
	
	if (needSpotlightReimport == NO) needSpotlightReimport = MD_DEBUG_SPOTLIGHT;
	
	previousVersion = 0;
	currentVersion = 0;
	
	previousVersion = [[[NSUserDefaults standardUserDefaults] objectForKey:MDLastSpotlightImporterVersionKey] integerValue];
	currentVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] integerValue];
	if (currentVersion > previousVersion || needSpotlightReimport) {
		[self performSelector:@selector(forceSpotlightReimport:) withObject:nil afterDelay:3.0];
	}
	
}


- (void)forceSpotlightReimport:(id)sender {
//#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
	NSString *spotlightImporterPath = nil;
	
	spotlightImporterPath = [[[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Spotlight"] stringByAppendingPathComponent:@"Source.mdimporter"];
	
	NSData *standardOutputData = nil;
	NSData *standardErrorData = nil;
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:@"/usr/bin/mdimport"];
	[task setArguments:[NSArray arrayWithObjects:@"-r", spotlightImporterPath, nil]];
	[task setStandardOutput:[NSPipe pipe]];
	[task setStandardError:[NSPipe pipe]];
	[task launch];
	[task waitUntilExit];
	
	standardOutputData = [[[task standardOutput] fileHandleForReading] availableData];
	if (standardOutputData && [standardOutputData length]) {
		NSString *standardOutputString = [[[NSString alloc] initWithData:standardOutputData encoding:NSUTF8StringEncoding] autorelease];
		NSLog(@"[%@ %@] standardOutputString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardOutputString);
	}
	standardErrorData = [[[task standardError] fileHandleForReading] availableData];
	if (standardErrorData && [standardErrorData length]) {
		NSString *standardErrorString = [[[NSString alloc] initWithData:standardErrorData encoding:NSUTF8StringEncoding] autorelease];
		NSLog(@"[%@ %@] standardErrorString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardErrorString);
	}
	if (![task isRunning]) {
		if ([task terminationStatus] != 0) {
			NSLog(@"[%@ %@] /usr/bin/mdimport returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [task terminationStatus]);
		}
	}
	[[NSUserDefaults standardUserDefaults] setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] forKey:MDLastSpotlightImporterVersionKey];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:MDQuitAfterAllWindowsClosedKey] boolValue];
}


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:MDLaunchTimeActionKey] unsignedIntegerValue] & MDLaunchTimeActionOpenNewDocument;
}


- (void)applicationWillTerminate:(NSNotification *)notification {
	[steamAppsRelocatorController cleanup];
	[otherAppsHelperController cleanup];
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:currentView] forKey:MDCurrentViewKey];
}

- (NSUndoManager *)globalUndoManager {
#if MD_DEBUG
	NSLog(@"[%@ %@] *****************", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (globalUndoManager == nil) globalUndoManager = [[NSUndoManager alloc] init];
	return globalUndoManager;
}


	// this method is used 
- (void)didSwitchTo:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (MDSystemVersion == MDLeopard) {
		[viewMenu setItemArray:[NSArray arrayWithObjects:viewModeAsListMenuItem,[NSMenuItem separatorItem], viewTogglePathBarMenuItem, [NSMenuItem separatorItem], viewToggleToolbarShownMenuItem,viewCustomizeToolbarMenuItem,[NSMenuItem separatorItem],viewOptionsMenuItem, nil]];
		
	} else if (MDSystemVersion >= MDSnowLeopard) {
		[viewMenu setItemArray:[NSArray arrayWithObjects:viewModeAsListMenuItem,viewModeAsColumnsMenuItem,[NSMenuItem separatorItem], viewTogglePathBarMenuItem, [NSMenuItem separatorItem], viewToggleToolbarShownMenuItem,viewCustomizeToolbarMenuItem,[NSMenuItem separatorItem],viewOptionsMenuItem, nil]];
		
	}
	
}


- (IBAction)switchView:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (sender != self) {
		NSInteger tag = [(NSToolbarItem *)sender tag];
		
		if (currentView != tag) {
			currentView = tag;
		}
	}
	
	if (currentView == MDSteamAppsRelocatorView) {
		if (steamAppsRelocatorController == nil) {
			steamAppsRelocatorController = [[MDSteamAppsRelocatorController alloc] init];
			if (![NSBundle loadNibNamed:@"MDSteamAppsRelocatorView" owner:steamAppsRelocatorController]) {
				NSLog(@"[%@ %@] failed to load MDSteamAppsRelocatorView!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
			}
			[steamAppsRelocatorController appControllerDidLoadNib:self];
		}
		
		
		[window switchView:[steamAppsRelocatorController view] newTitle:@"Steam Apps Re-locator"];
		[steamAppsRelocatorController didSwitchToView:self];
		[[window toolbar] setSelectedItemIdentifier:MDSteamAppsRelocatorIdentifierKey];
		
	} else if (currentView == MDOtherAppsHelperView) {
		
		if (otherAppsHelperController == nil) {
			otherAppsHelperController = [[MDOtherAppsHelperController alloc] init];
			if (![NSBundle loadNibNamed:@"MDOtherAppsHelperView" owner:otherAppsHelperController]) {
				NSLog(@"[%@ %@] failed to load MDOtherAppsHelperView!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				
			}
			[otherAppsHelperController appControllerDidLoadNib:self];
		}
		[window switchView:[otherAppsHelperController view] newTitle:@"Other Apps Helper"];
		[otherAppsHelperController didSwitchToView:self];
		
		[[window toolbar] setSelectedItemIdentifier:MDOtherAppsHelperIdentifierKey];
		
	}

}


- (void)lastWindowDidClose:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[viewMenu setItemArray:[NSArray arrayWithObjects:viewTogglePathBarMenuItem, [NSMenuItem separatorItem], viewToggleToolbarShownMenuItem, viewCustomizeToolbarMenuItem, [NSMenuItem separatorItem], viewOptionsMenuItem, nil]];
	
}


- (IBAction)toggleShowInspector:(id)sender {
#if MD_DEBUG
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
#if MD_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		[inspectorController release]; inspectorController = nil;
	}
}


- (IBAction)toggleShowViewOptions:(id)sender {
#if MD_DEBUG
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
#if MD_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		[viewOptionsController release]; viewOptionsController = nil;
	}
}


- (IBAction)toggleShowQuickLook:(id)sender {
#if MD_DEBUG
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
#if MD_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		[quickLookController release]; quickLookController = nil;
	}
}

- (IBAction)showMainWindow:(id)sender {
	if (![window isVisible]) [window makeKeyAndOrderFront:nil];
}


- (IBAction)showAboutWindow:(id)sender {
	if (aboutWindowController == nil) aboutWindowController = [[MDAboutWindowController alloc] init];
	[aboutWindowController showWindow:self];
}


- (IBAction)showPrefsWindow:(id)sender {
	if (prefsController == nil) prefsController = [[MDPrefsController alloc] init];
	[prefsController showWindow:self];
}


- (void)menuNeedsUpdate:(NSMenu *)menu {
#if MD_DEBUG
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
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[NSString stringWithFormat:MDEmailDynamicURLString, NSUserName()] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

- (IBAction)chat:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:MDiChatURLString]];
}

- (IBAction)webpage:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:MDWebpage]];
}


- (IBAction)resetAllWarningDialogs:(id)sender {

}


@end


