//
//  MDAppController.m
//  Source Finagler
//
//  Created by Mark Douma on 5/12/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//


#import "MDAppController.h"
#import "MDViewController.h"
#import "MDAppKitAdditions.h"

#import "MDAboutWindowController.h"
#import "MDInspectorController.h"
#import "MDViewOptionsController.h"
#import "MDQuickLookController.h"
#import "MDHLDocument.h"
#import "MDDocumentController.h"

#import "MDUserDefaults.h"

#import "MDPrefsController.h"

#import "TKImageDocument.h"
#import "TKImageInspectorController.h"
#import <Sparkle/Sparkle.h>




static NSString * const MDCurrentViewIndexKey						= @"MDCurrentViewIndex";

static NSString * const MDLastVersionRunKey							= @"MDLastVersionRun";

static NSString * const MDLastSpotlightImporterVersionKey			= @"MDLastSpotlightImporterVersion";
static NSString * const MDLastSourceAddonFinaglerVersionKey			= @"MDLastSourceAddonFinaglerVersion";
static NSString * const MDSpotlightImporterBundleIdentifierKey		= @"com.markdouma.mdimporter.Source";

NSString * const MDLaunchTimeActionKey								= @"MDLaunchTimeAction";

static NSString * const MDQuitAfterAllWindowsClosedKey				= @"MDQuitAfterAllWindowsClosed";


/*************		websites & email addresses	*************/

static NSString * const MDWebpage						= @"http://www.markdouma.com/sourcefinagler/";

static NSString * const MDEmailStaticURLString			= @"mailto:mark@markdouma.com";

static NSString * const MDEmailDynamicURLString		= @"mailto:mark@markdouma.com?subject=Source Finagler (%@)&body=Note: creating a unique Subject for your email will help me keep track of your inquiry more easily. Feel free to alter the one provided as you like.";


static NSString * const MDEmailAddress					= @"mark@markdouma.com";
static NSString * const MDiChatURLString				= @"aim:goim?screenname=MarkDouma46&message=Type+your+message+here.";

static NSString * const MDSUFeedURLLeopard		= @"http://www.markdouma.com/sourcefinagler/versionLeopard.xml";


BOOL	TKShouldShowImageInspector = NO;

#define MD_DEBUG 1

#define MD_DEBUG_SPOTLIGHT 0



static BOOL needSpotlightReimport = NO;
static BOOL needSourceAddonFinaglerRegister = NO;


static NSArray *appClassNames = nil;


@interface MDAppController (MDPrivate)
- (void)forceSpotlightReimport:(id)sender;
@end

@implementation MDAppController


+ (void)initialize {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	@synchronized(self) {
		
		if (appClassNames == nil) {
			appClassNames = [[[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MDAppController" ofType:@"plist"]] objectForKey:@"MDAppControllerClassNames"] retain];
		}
		
		// cause MDHLDocument's +initialize method to be called, which will make sure its defaults are set up and, in turn, make sure MDOutlineView's and MDBrowser's default values are set up
		[MDHLDocument class];
		
		
		NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
		
		[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:TKShouldShowImageInspectorKey];
		
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
		
		[defaultValues setObject:[NSNumber numberWithUnsignedInteger:0] forKey:MDCurrentViewIndexKey];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
		[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
		
	}
}

- (id)init {
	if ((self = [super init])) {
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowViewOptionsDidChange:) name:MDHLDocumentShouldShowViewOptionsDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowInspectorDidChange:) name:MDHLDocumentShouldShowInspectorDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowQuickLookDidChange:) name:MDHLDocumentShouldShowQuickLookDidChangeNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowImageInspectorDidChange:) name:TKShouldShowImageInspectorDidChangeNotification object:nil];
		
		viewControllers = [[NSMutableArray alloc] init];
		
		for (NSUInteger i = 0; i < appClassNames.count; i++) {
			[viewControllers addObject:[NSNull null]];
		}
		
	}
	return self;
}

- (void)dealloc {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[viewControllers release];
	
	[aboutWindowController release];
	
	[inspectorController release];
	[viewOptionsController release];
	[quickLookController release];
	
	[imageInspectorController release];
	
	[prefsController release];
	
	[super dealloc];
}


- (void)awakeFromNib {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([[NSProcessInfo processInfo] md__operatingSystemVersion].minorVersion <= MDLeopard) {
		[sparkleUpdater setFeedURL:[NSURL URLWithString:MDSUFeedURLLeopard]];
	}
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if ([[NSProcessInfo processInfo] md__operatingSystemVersion].minorVersion < MDSnowLeopard) {
		[[viewModeAsColumnsMenuItem menu] removeItem:viewModeAsColumnsMenuItem];
		viewModeAsColumnsMenuItem = nil;
	}
	
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
	
	TKShouldShowImageInspector = [[userDefaults objectForKey:TKShouldShowImageInspectorKey] boolValue];
	
	if ([MDHLDocument shouldShowViewOptions]) {
		if (viewOptionsController == nil) viewOptionsController = [[MDViewOptionsController alloc] init];
		[viewOptionsController showWindow:self];
	}
	
	if ([MDHLDocument shouldShowInspector]) {
		if (inspectorController == nil) inspectorController = [[MDInspectorController alloc] init];
		[inspectorController showWindow:self];
	}
	
	if ([MDHLDocument shouldShowQuickLook]) {
		if (quickLookController == nil) quickLookController = [[MDQuickLookController alloc] init];
		[quickLookController showWindow:self];
	}
	
	if (TKShouldShowImageInspector) {
		if (imageInspectorController == nil) imageInspectorController = [[TKImageInspectorController alloc] init];
		[imageInspectorController showWindow:self];
	}
	
	currentViewIndex = [[userDefaults objectForKey:MDCurrentViewIndexKey] unsignedIntegerValue];
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
	NSString *spotlightImporterPath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[NSBundle mainBundle] bundlePath], @"Contents", @"Library", @"Spotlight", @"Source.mdimporter", nil]];
	
#if MD_DEBUG
	NSLog(@"[%@ %@] spotlightImporterPath == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), spotlightImporterPath);
#endif
	
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
//	[[NSUserDefaults standardUserDefaults] setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] forKey:MDLastSpotlightImporterVersionKey];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:MDQuitAfterAllWindowsClosedKey] boolValue];
}


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:MDLaunchTimeActionKey] unsignedIntegerValue] & MDLaunchTimeActionOpenNewDocument;
}


- (void)applicationWillTerminate:(NSNotification *)notification {
	for (MDViewController *viewConroller in viewControllers) {
		if ((NSNull *)viewConroller != [NSNull null]) {
			[viewConroller cleanup];
		}
	}
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:currentViewIndex] forKey:MDCurrentViewIndexKey];
}



- (IBAction)switchView:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (sender == self || sender == nil) {
		
		NSUInteger count = viewControllers.count;
		
		while (currentViewIndex >= count) {
			currentViewIndex--;
		}
		
		NSArray *toolbarItems = window.toolbar.items;
		for (NSToolbarItem *toolbarItem in toolbarItems) {
			if (toolbarItem.tag == currentViewIndex) {
				[window.toolbar setSelectedItemIdentifier:toolbarItem.itemIdentifier]; break;
			}
		}
	} else {
		currentViewIndex = [(NSToolbarItem *)sender tag];
	}
	
	MDViewController *viewController = [viewControllers objectAtIndex:currentViewIndex];
	
	if ((NSNull *)viewController == [NSNull null]) {
		NSString *className = [appClassNames objectAtIndex:currentViewIndex];
		
		Class viewControllerClass = NSClassFromString(className);
		
		viewController = [[viewControllerClass alloc] init];
		
		[viewControllers replaceObjectAtIndex:currentViewIndex withObject:viewController];
		
		[viewController release];
	}
	
	[window switchView:viewController.view newTitle:viewController.title];
	[viewController didSwitchToView:self];
	
}



- (IBAction)toggleShowInspector:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[MDHLDocument setShouldShowInspector:![MDHLDocument shouldShowInspector]];
	
	if ([MDHLDocument shouldShowInspector]) {
		if (inspectorController == nil) inspectorController = [[MDInspectorController alloc] init];
		[inspectorController showWindow:self];
	} else {
		if (inspectorController) [[inspectorController window] performClose:self];
	}
}


- (void)shouldShowInspectorDidChange:(NSNotification *)notification {
	if ([MDHLDocument shouldShowInspector] == NO) {
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
	[MDHLDocument setShouldShowViewOptions:![MDHLDocument shouldShowViewOptions]];
	
	if ([MDHLDocument shouldShowViewOptions]) {
		if (viewOptionsController == nil) viewOptionsController = [[MDViewOptionsController alloc] init];
		[viewOptionsController showWindow:self];
	} else {
		if (viewOptionsController) [[viewOptionsController window] performClose:self];
	}
}


- (void)shouldShowViewOptionsDidChange:(NSNotification *)notification {
	if ([MDHLDocument shouldShowViewOptions] == NO) {
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
	[MDHLDocument setShouldShowQuickLook:![MDHLDocument shouldShowQuickLook]];
	
	if ([MDHLDocument shouldShowQuickLook]) {
		if (quickLookController == nil) quickLookController = [[MDQuickLookController sharedQuickLookController] retain];
		[quickLookController showWindow:self];
	} else {
		if (quickLookController) [[quickLookController window] performClose:self];
	}
}


- (void)shouldShowQuickLookDidChange:(NSNotification *)notification {
	if ([MDHLDocument shouldShowQuickLook] == NO) {
#if MD_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		[quickLookController release]; quickLookController = nil;
	}
}


- (IBAction)toggleShowImageInspector:(id)sender {
#if MD_DEBUG
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
#if MD_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//		[imageInspectorController release]; imageInspectorController = nil;
	}
}



- (IBAction)showMainWindow:(id)sender {
	[window makeKeyAndOrderFront:nil];
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



#pragma mark - <NSMenuDelegate>

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
#if MD_DEBUG
	NSLog(@"[%@ %@] menuItem == %@, action == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), menuItem, NSStringFromSelector(menuItem.action));
#endif
	
	SEL action = [menuItem action];
	
	if (action == @selector(switchView:)) {
		
	} else if (action == @selector(showPrefsWindow:)) {
		return YES;
		
	} else if (action == @selector(toggleShowViewOptions:)) {
		[menuItem setTitle:([MDHLDocument shouldShowViewOptions] ? NSLocalizedString(@"Hide View Options", @"") : NSLocalizedString(@"Show View Options", @""))];
		return YES;
		
	} else if (action == @selector(toggleShowInspector:)) {
		[menuItem setTitle:([MDHLDocument shouldShowInspector] ? NSLocalizedString(@"Hide Inspector", @"") : NSLocalizedString(@"Show Inspector", @""))];
		return YES;
		
	} else if (action == @selector(toggleShowImageInspector:)) {
		[menuItem setTitle:(TKShouldShowImageInspector ? NSLocalizedString(@"Hide Image Inspector", @"") : NSLocalizedString(@"Show Image Inspector", @""))];
		
		return YES;
		
	} else if (action == @selector(toggleShowQuickLook:)) {
		[menuItem setTitle:([MDHLDocument shouldShowQuickLook] ? NSLocalizedString(@"Close Quick Look", @"") : NSLocalizedString(@"Quick Look", @""))];
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


