//
//  VSSourceAddonController.m
//  Source Finagler
//
//  Created by Mark Douma on 10/8/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "VSSourceAddonController.h"
#import "TKAppKitAdditions.h"



static NSString * const VSSourceAddonInstallMethodKey = @"VSSourceAddonInstallMethod";

static NSString * const VSSourceAddonInstalledAddonsSortDescriptorsKey				= @"VSSourceAddonInstalledAddonsSortDescriptors";
static NSString * const VSSourceAddonAlreadyInstalledAddonsSortDescriptorsKey		= @"VSSourceAddonAlreadyInstalledAddonsSortDescriptors";
static NSString * const VSSourceAddonProblemAddonsSortDescriptorsKey				= @"VSSourceAddonProblemAddonsSortDescriptors";


#define VS_DEBUG 0



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
	NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"fileName" ascending:YES selector:@selector(localizedStandardCompare:)], nil];
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
		
	}
	return self;
}

- (void)dealloc {
	[addons release];
	[installedAddons release];
	[alreadyInstalledAddons release];
	[problemAddons release];
	[[VSSteamManager defaultManager] setDelegate:nil];
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


- (void)application:(NSApplication *)sender openFiles:(NSArray *)filePaths {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSMutableArray *sourceAddonURLs = [NSMutableArray array];
	for (NSString *filePath in filePaths) {
		NSURL *sourceAddonURL = [NSURL fileURLWithPath:filePath];
		if (sourceAddonURL) [sourceAddonURLs addObject:sourceAddonURL];
	}
	[self processSourceAddonsAtURLs:sourceAddonURLs];
}


- (void)installSourceAddon:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)errorDescription {
#if VS_DEBUG
	NSLog(@"[%@ %@] pboard == %@, pboard.types == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), pboard, pboard.types);
#endif
	NSArray *sourceAddonURLs = [pboard readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]]
													 options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSPasteboardURLReadingFileURLsOnlyKey]];
	
#if VS_DEBUG
	NSLog(@"[%@ %@] sourceAddonURLs == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddonURLs);
#endif
	
	[self processSourceAddonsAtURLs:sourceAddonURLs];
}
	

- (void)processSourceAddonsAtURLs:(NSArray *)sourceAddonURLs {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	VSSourceAddonInstallMethod installMethod = [[[NSUserDefaults standardUserDefaults] objectForKey:VSSourceAddonInstallMethodKey] unsignedIntegerValue];
	
	[progressIndicator startAnimation:nil];
	
	if (![copyProgressWindow isVisible]) {
		[copyProgressWindow center];
		[copyProgressWindow makeKeyAndOrderFront:nil];
	}
	
	for (NSURL *sourceAddonURL in sourceAddonURLs) {
		VSSourceAddon *addon = [VSSourceAddon sourceAddonWithContentsOfURL:sourceAddonURL error:NULL];
		if (addon) [addons addObject:addon];
	}
	
	for (VSSourceAddon *addon in addons) {
		[[VSSteamManager defaultManager] installSourceAddon:addon usingMethod:installMethod];
	}
	
	[progressIndicator setMaxValue:addons.count];
	
	[progressIndicator setDoubleValue:0.0];
	[progressIndicator setIndeterminate:NO];
}


#pragma mark - <VSSteamManagerDelegate>

- (void)didInstallSourceAddon:(VSSourceAddon *)sourceAddon {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	VSSourceAddonStatus sourceAddonStatus = sourceAddon.sourceAddonStatus;
	
	(sourceAddonStatus == VSSourceAddonValidAddon ? [installedAddonsController addObject:sourceAddon] : [alreadyInstalledAddonsController addObject:sourceAddon]);
	
	NSUInteger totalInstalledCount = self.installedAddons.count + self.alreadyInstalledAddons.count + self.problemAddons.count;
	
	[progressIndicator setDoubleValue:(double)totalInstalledCount];
	[progressIndicator display];
	
	if (totalInstalledCount == self.addons.count) [self finishInstallation];
	
}


- (void)didFailToInstallSourceAddon:(VSSourceAddon *)sourceAddon {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[problemAddonsController addObject:sourceAddon];
	
	NSUInteger totalInstalledCount = self.installedAddons.count + self.alreadyInstalledAddons.count + self.problemAddons.count;
	
	[progressIndicator setDoubleValue:(double)totalInstalledCount];
	[progressIndicator display];
	
	if (totalInstalledCount == self.addons.count) [self finishInstallation];
}

#pragma mark END <VSSteamManagerDelegate>
#pragma mark -


- (void)finishInstallation {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSUInteger installedAddonsCount = installedAddons.count;
	NSUInteger alreadyInstalledAddonsCount = alreadyInstalledAddons.count;
	NSUInteger problemAddonsCount = problemAddons.count;
	
	if (installedAddonsCount > 0 && problemAddonsCount == 0) {
		if (installedAddonsCount == 1) {
			[resultsField setStringValue:NSLocalizedString(@"1 Source Addon was installed.", @"")];
			
		} else {
			[resultsField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%lu Source Addons were installed.", @""), installedAddonsCount]];
		}
		
	} else if (installedAddonsCount > 0 && problemAddonsCount > 0) {
		
		[resultsField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%lu of %lu Source Addons were installed.", @""), installedAddonsCount, installedAddonsCount + problemAddonsCount]];
		
	} else if (installedAddonsCount == 0 && problemAddonsCount > 0) {
		
		[resultsField setStringValue:NSLocalizedString(@"No Source Addons were installed.", @"")];
		
	}
	
	[window center];
	
	NSRect windowFrame = window.frame;
	
	// get count of split subviews correct
	
	NSMutableArray *subviews = [NSMutableArray arrayWithObjects:installedView, alreadyInstalledView, problemView, nil];
	
	if (problemAddonsCount == 0) {
		NSBox *box = [[splitView subviews] lastObject];
		windowFrame.size.height -= NSHeight(box.frame);
		[box removeFromSuperview];
		[subviews removeObject:problemView];
	}
	
	if (alreadyInstalledAddonsCount == 0) {
		NSBox *box = [[splitView subviews] lastObject];
		windowFrame.size.height -= NSHeight(box.frame);
		[box removeFromSuperview];
		[subviews removeObject:alreadyInstalledView];
	}
	
	if (installedAddonsCount == 0) {
		NSBox *box = [[splitView subviews] lastObject];
		windowFrame.size.height -= NSHeight(box.frame);
		[box removeFromSuperview];
		[subviews removeObject:installedView];
	}
	
	[splitView adjustSubviews];
	
	[window setFrame:windowFrame display:YES];
	[window center];
	
	
	// now fill the boxes in with proper views
	
	NSUInteger i = 0;
	
	for (NSView *subview in subviews) {
		[(NSBox *)[[splitView subviews] objectAtIndex:i] setContentView:subview];
		i++;
	}
	
	if (installedAddonsCount) [[NSSound soundNamed:@"copy"] play];
	
	
	[copyProgressWindow orderOut:nil];
	[progressIndicator stopAnimation:nil];
	
	[window makeKeyAndOrderFront:nil];
	
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
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


