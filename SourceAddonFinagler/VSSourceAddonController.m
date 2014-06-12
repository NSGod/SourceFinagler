//
//  VSSourceAddonController.m
//  Source Finagler
//
//  Created by Mark Douma on 10/8/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "VSSourceAddonController.h"
#import "MDAppKitAdditions.h"



static NSString * const VSSourceAddonInstallMethodKey = @"VSSourceAddonInstallMethod";

static NSString * const VSSourceAddonInstalledAddonsSortDescriptorsKey				= @"VSSourceAddonInstalledAddonsSortDescriptors";
static NSString * const VSSourceAddonAlreadyInstalledAddonsSortDescriptorsKey		= @"VSSourceAddonAlreadyInstalledAddonsSortDescriptors";
static NSString * const VSSourceAddonProblemAddonsSortDescriptorsKey				= @"VSSourceAddonProblemAddonsSortDescriptors";


#define VS_DEBUG 0


@interface VSSourceAddonController (VSPrivate)

- (void)beginProcessingSourceAddonsAtURLs:(NSArray *)URLs;
- (void)beginProcessingNextSetOfSourceAddonURLs;
- (void)processSourceAddonsAtURLs:(NSArray *)URLs;
- (void)finishInstallation;

@end


@implementation VSSourceAddonController

@synthesize addons;
@synthesize installedAddons;
@synthesize alreadyInstalledAddons;
@synthesize problemAddons;

@dynamic installedAddonsSortDescriptors;
@dynamic alreadyInstalledAddonsSortDescriptors;
@dynamic problemAddonsSortDescriptors;


+ (void)initialize {
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject:[NSNumber numberWithUnsignedInteger:VSSourceAddonInstallByMoving] forKey:VSSourceAddonInstallMethodKey];
	NSArray *sortDescriptors = [NSArray arrayWithObjects:[[[NSSortDescriptor alloc] initWithKey:@"fileName" ascending:YES selector:@selector(localizedCaseInsensitiveNumericalCompare:)] autorelease], nil];
	[defaultValues setSortDescriptors:sortDescriptors forKey:VSSourceAddonInstalledAddonsSortDescriptorsKey];
	[defaultValues setSortDescriptors:sortDescriptors forKey:VSSourceAddonAlreadyInstalledAddonsSortDescriptorsKey];
	[defaultValues setSortDescriptors:sortDescriptors forKey:VSSourceAddonProblemAddonsSortDescriptorsKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
}


- (id)init {
	if ((self = [super init])) {
		addons = [[NSMutableArray alloc] init];
		installedAddons = [[NSMutableArray alloc] init];
		alreadyInstalledAddons = [[NSMutableArray alloc] init];
		problemAddons = [[NSMutableArray alloc] init];
		
		[[VSSteamManager defaultManager] setDelegate:self];
		
		sourceAddonURLs = [[NSMutableArray alloc] init];
		sourceAddonURLsLock = [[NSRecursiveLock alloc] init];
	}
	return self;
}

- (void)dealloc {
	[addons release];
	[installedAddons release];
	[alreadyInstalledAddons release];
	[problemAddons release];
	[[VSSteamManager defaultManager] setDelegate:nil];
	[sourceAddonURLs release];
	[sourceAddonURLsLock release];
	[super dealloc];
}


- (void)awakeFromNib {
	[progressIndicator setUsesThreadedAnimation:YES];
	
	[installedTableView setSortDescriptors:[[NSUserDefaults standardUserDefaults] sortDescriptorsForKey:VSSourceAddonInstalledAddonsSortDescriptorsKey]];
	[alreadyInstalledTableView setSortDescriptors:[[NSUserDefaults standardUserDefaults] sortDescriptorsForKey:VSSourceAddonAlreadyInstalledAddonsSortDescriptorsKey]];
	[problemTableView setSortDescriptors:[[NSUserDefaults standardUserDefaults] sortDescriptorsForKey:VSSourceAddonProblemAddonsSortDescriptorsKey]];
}


- (void)applicationWillFinishLaunching:(NSNotification *)notification {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[NSApp setServicesProvider:self];
}


- (void)applicationWillTerminate:(NSNotification *)notification {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[NSUserDefaults standardUserDefaults] setSortDescriptors:[self installedAddonsSortDescriptors] forKey:VSSourceAddonInstalledAddonsSortDescriptorsKey];
	[[NSUserDefaults standardUserDefaults] setSortDescriptors:[self alreadyInstalledAddonsSortDescriptors] forKey:VSSourceAddonAlreadyInstalledAddonsSortDescriptorsKey];
	[[NSUserDefaults standardUserDefaults] setSortDescriptors:[self problemAddonsSortDescriptors] forKey:VSSourceAddonProblemAddonsSortDescriptorsKey];
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}


- (void)application:(NSApplication *)sender openFiles:(NSArray *)filePaths {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSMutableArray *URLs = [NSMutableArray array];
	for (NSString *filePath in filePaths) {
		NSURL *sourceAddonURL = [NSURL fileURLWithPath:filePath];
		if (sourceAddonURL) [URLs addObject:sourceAddonURL];
	}
	[self beginProcessingSourceAddonsAtURLs:URLs];
}


- (void)installSourceAddon:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)errorDescription {
#if VS_DEBUG
	NSLog(@"[%@ %@] pboard == %@, pboard.types == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), pboard, pboard.types);
#endif
	NSArray *URLs = [pboard readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]]
													 options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSPasteboardURLReadingFileURLsOnlyKey]];
	
#if VS_DEBUG
	NSLog(@"[%@ %@] URLs == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), URLs);
#endif
	
	[self beginProcessingSourceAddonsAtURLs:URLs];
}



- (NSUInteger)synchronizedSourceAddonURLsCount {
	NSUInteger sourceAddonURLsCount = 0;
	[sourceAddonURLsLock lock];
	sourceAddonURLsCount = sourceAddonURLs.count;
	[sourceAddonURLsLock unlock];
	return sourceAddonURLsCount;
}



- (void)beginProcessingSourceAddonsAtURLs:(NSArray *)URLs {
#if VS_DEBUG
	NSLog(@"[%@ %@] URLs == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), URLs);
#endif
	
	NSMutableSet *mURLs = [NSMutableSet setWithArray:URLs];
	
	[sourceAddonURLsLock lock];
	[sourceAddonURLs addObject:mURLs];
	[sourceAddonURLsLock unlock];
	
	if ([self synchronizedSourceAddonURLsCount] == 1) {
		[self beginProcessingNextSetOfSourceAddonURLs];
	}
}

#define VS_NEXT_SET_INTERVAL 1.0


- (void)beginProcessingNextSetOfSourceAddonURLs {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSMutableSet *mURLs = nil;
	
	[sourceAddonURLsLock lock];
	if (sourceAddonURLs.count) {
		mURLs = [[[sourceAddonURLs objectAtIndex:0] retain] autorelease];
	}
	[sourceAddonURLsLock unlock];
	
	[self processSourceAddonsAtURLs:[mURLs allObjects]];
}


- (void)processSourceAddonsAtURLs:(NSArray *)URLs {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:nil];
	
	if (!copyProgressWindow.isVisible) {
		[copyProgressWindow center];
		[copyProgressWindow makeKeyAndOrderFront:nil];
	}
	
	NSMutableArray *addonsToInstall = [NSMutableArray array];
	
	
	for (NSURL *sourceAddonURL in URLs) {
		VSSourceAddon *addon = [VSSourceAddon sourceAddonWithContentsOfURL:sourceAddonURL error:NULL];
		if (addon) {
			[addons addObject:addon];
			[addonsToInstall addObject:addon];
		}
	}
	
	unsigned long long totalFileSize = 0;
	
	for (VSSourceAddon *addon in addonsToInstall) totalFileSize += [addon.fileSize unsignedLongLongValue];
	
	// keep the progress indicator indeterminate until we've installed the first addon
	
	[progressIndicator setMaxValue:(double)totalFileSize];
	[progressIndicator setDoubleValue:0.0];
	
	
	VSSourceAddonInstallMethod installMethod = [[[NSUserDefaults standardUserDefaults] objectForKey:VSSourceAddonInstallMethodKey] unsignedIntegerValue];
	
	for (VSSourceAddon *addon in addonsToInstall) {
		[[VSSteamManager defaultManager] installSourceAddon:addon usingMethod:installMethod];
	}
	
}


- (void)updateProgressForSourceAddon:(VSSourceAddon *)sourceAddon {
#if VS_DEBUG
	NSLog(@"[%@ %@]  %@  ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName);
#endif
	
	if (progressIndicator.isIndeterminate) [progressIndicator setIndeterminate:NO];

	[progressIndicator setDoubleValue:[progressIndicator doubleValue] + (double)[sourceAddon.fileSize unsignedLongLongValue]];
	[progressIndicator display];
	
	
	NSURL *originalURL = sourceAddon.originalURL;
	
	
	NSMutableSet *setToRemove = nil;
	
	[sourceAddonURLsLock lock];
	
	for (NSMutableSet *URLs in sourceAddonURLs) {
		if ([URLs containsObject:originalURL]) {
			[URLs removeObject:originalURL];
			if (URLs.count == 0) {
				setToRemove = [[URLs retain] autorelease];
				break;
			}
		}
	}
	
	if (setToRemove) [sourceAddonURLs removeObject:setToRemove];
	
	[sourceAddonURLsLock unlock];
	
	
	if (setToRemove) {
		
		
#if VS_DEBUG
		NSUInteger totalInstalledCount = self.installedAddons.count + self.alreadyInstalledAddons.count + self.problemAddons.count;
		NSLog(@"[%@ %@]   %@   totalInstalledCount == %lu, addons.count == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName, (unsigned long)totalInstalledCount, (unsigned long)self.addons.count);
#endif
		
		[self finishInstallation];
		
	}
}



#pragma mark - <VSSteamManagerDelegate>

- (void)willInstallSourceAddon:(VSSourceAddon *)sourceAddon {
#if VS_DEBUG
	NSLog(@"[%@ %@]   %@  ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName);
#endif
	
	VSSourceAddonInstallMethod installMethod = [[[NSUserDefaults standardUserDefaults] objectForKey:VSSourceAddonInstallMethodKey] unsignedIntegerValue];
	
	[progressField setStringValue:[NSString stringWithFormat:(installMethod == VSSourceAddonInstallByMoving ? NSLocalizedString(@"Moving \"%@\"...", @"") : NSLocalizedString(@"Copying \"%@\"...", @"")), sourceAddon.fileName]];
	
}


- (void)didInstallSourceAddon:(VSSourceAddon *)sourceAddon {
#if VS_DEBUG
	NSLog(@"[%@ %@]   %@  ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName);
#endif
	
	VSSourceAddonStatus sourceAddonStatus = sourceAddon.sourceAddonStatus;
	
	(sourceAddonStatus == VSSourceAddonValidAddon ? [installedAddonsController addObject:sourceAddon] : [alreadyInstalledAddonsController addObject:sourceAddon]);
	
	[self updateProgressForSourceAddon:sourceAddon];
	
}


- (void)didFailToInstallSourceAddon:(VSSourceAddon *)sourceAddon {
#if VS_DEBUG
	NSLog(@"[%@ %@]   %@  ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName);
#endif
	[problemAddonsController addObject:sourceAddon];
	
	[self updateProgressForSourceAddon:sourceAddon];
	
}

#pragma mark END <VSSteamManagerDelegate>
#pragma mark -



- (void)finishInstallation {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSUInteger installedAddonsCount = self.installedAddons.count;
	NSUInteger alreadyInstalledAddonsCount = self.alreadyInstalledAddons.count;
	NSUInteger problemAddonsCount = self.problemAddons.count;
	
	if (installedAddonsCount > 0 && problemAddonsCount == 0) {
		if (installedAddonsCount == 1) {
			[resultsField setStringValue:NSLocalizedString(@"1 Source Addon was installed.", @"")];
			
		} else {
			[resultsField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%lu Source Addons were installed.", @""), (unsigned long)installedAddonsCount]];
		}
		
	} else if (installedAddonsCount > 0 && problemAddonsCount > 0) {
		
		[resultsField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%lu of %lu Source Addons were installed.", @""), (unsigned long)installedAddonsCount, (unsigned long)(installedAddonsCount + problemAddonsCount)]];
		
	} else if (installedAddonsCount == 0 && problemAddonsCount > 0) {
		
		[resultsField setStringValue:NSLocalizedString(@"No Source Addons were installed.", @"")];
		
	}
	
	if (!window.isVisible) {
		[window center];
	}
	
	NSRect windowFrame = window.frame;
	
	/*
	 The subview arrangement should be:
	 
	 -------------------------
	 |      installedView	 |
	 -------------------------
	 | alreadyInstalledView	 |
	 -------------------------
	 |	    problemView		 |
	 -------------------------
	 */
	
	NSMutableArray *subviews = [NSMutableArray array];
	
	if (installedAddonsCount) {
		[subviews addObject:installedView];
	} else {
		// don't adjust window frame if window is already visible
		if (!window.isVisible) windowFrame.size.height -= NSHeight([(NSView *)[[splitView subviews] lastObject] frame]);
	}
	
	if (alreadyInstalledAddonsCount) {
		[subviews addObject:alreadyInstalledView];
	} else {
		// don't adjust window frame if window is already visible
		if (!window.isVisible) windowFrame.size.height -= NSHeight([(NSView *)[[splitView subviews] lastObject] frame]);
	}
	
	if (problemAddonsCount) {
		[subviews addObject:problemView];
	} else {
		// don't adjust window frame if window is already visible
		if (!window.isVisible) windowFrame.size.height -= NSHeight([(NSView *)[[splitView subviews] lastObject] frame]);
	}
	
	
	[splitView setSubviews:subviews];
	
	[splitView adjustSubviews];
	
	
	if (!window.isVisible) {
		[window setFrame:windowFrame display:YES];
		[window center];
	}
	
	if (installedAddonsCount) [[NSSound soundNamed:@"copy"] play];
	
	
	[copyProgressWindow orderOut:nil];
	[progressIndicator stopAnimation:nil];
	
	
	if ([self synchronizedSourceAddonURLsCount]) {
		[self performSelector:@selector(beginProcessingNextSetOfSourceAddonURLs) withObject:nil afterDelay:VS_NEXT_SET_INTERVAL];
	}
	
	[window makeKeyAndOrderFront:nil];
	
}



- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
#if VS_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (aTableView == installedTableView || aTableView == alreadyInstalledTableView) {
		VSSourceAddon *addon = (aTableView == installedTableView ? [[installedAddonsController arrangedObjects] objectAtIndex:rowIndex] : [[alreadyInstalledAddonsController arrangedObjects] objectAtIndex:rowIndex]);
		
		NSImage *icon = nil;
		
		if ([[tableColumn identifier] isEqualToString:@"fileName"]) {
			icon = addon.fileIcon;
		} else {
			// game column
			icon = addon.game.icon;
		}
		[icon setSize:NSMakeSize(16.0, 16.0)];
		[cell setImage:icon];
		
	} else if (aTableView == problemTableView) {
		
		if ([[tableColumn identifier] isEqualToString:@"fileName"]) {
			NSImage *icon = [(VSSourceAddon *)[[problemAddonsController arrangedObjects] objectAtIndex:rowIndex] fileIcon];
			[icon setSize:NSMakeSize(16.0, 16.0)];
			[cell setImage:icon];
		}
	}
}


- (NSArray *)installedAddonsSortDescriptors {
	return [installedTableView sortDescriptors];
}

- (void)setInstalledAddonsSortDescriptors:(NSArray *)installedAddonsSortDescriptors {
	[installedTableView setSortDescriptors:installedAddonsSortDescriptors];
}


- (NSArray *)alreadyInstalledAddonsSortDescriptors {
	return [alreadyInstalledTableView sortDescriptors];
}

- (void)setAlreadyInstalledAddonsSortDescriptors:(NSArray *)alreadyInstalledAddonsSortDescriptors {
	[alreadyInstalledTableView setSortDescriptors:alreadyInstalledAddonsSortDescriptors];
}


- (NSArray *)problemAddonsSortDescriptors {
	return [problemTableView sortDescriptors];
}

- (void)setProblemAddonsSortDescriptors:(NSArray *)problemAddonsSortDescriptors {
	[problemTableView setSortDescriptors:problemAddonsSortDescriptors];
}



- (IBAction)ok:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[NSApp terminate:nil];
}


- (IBAction)showPrefsWindow:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (![prefsWindow isVisible]) [prefsWindow center];
	[prefsWindow makeKeyAndOrderFront:nil];
}


@end


