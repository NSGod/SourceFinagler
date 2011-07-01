//
//  VSSourceAddonController.m
//  Source Finagler
//
//  Created by Mark Douma on 10/8/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "VSSourceAddonController.h"
#import <SteamKit/SteamKit.h>
#import "MDAppKitAdditions.h"
#import "VSSourceAddon.h"
#import "MDTextFieldCell.h"



NSString * const VSSourceAddonInstallMethodKey = @"VSSourceAddonInstallMethod";


#define MD_DEBUG 1


@implementation VSSourceAddonController

+ (void)initialize {
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject:[NSNumber numberWithUnsignedInteger:VSSourceAddonInstallByMoving] forKey:VSSourceAddonInstallMethodKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
}


- (id)init {
	if ((self = [super init])) {
		installedAddons = [[NSMutableArray alloc] init];
		problemAddons = [[NSMutableArray alloc] init];
		steamManager = [[VSSteamManager defaultManager] retain];
	}
	return self;
}

- (void)dealloc {
	[installedAddons release];
	[problemAddons release];
	[steamManager release];
	[super dealloc];
}


- (void)awakeFromNib {
	[progressIndicator setUsesThreadedAnimation:YES];
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filePaths {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	VSSourceAddonInstallMethod installMethod = [[[NSUserDefaults standardUserDefaults] objectForKey:VSSourceAddonInstallMethodKey] unsignedIntegerValue];
	
	[progressIndicator startAnimation:nil];
	
	if (![copyProgressWindow isVisible]) {
		[copyProgressWindow center];
		[copyProgressWindow makeKeyAndOrderFront:nil];
	}
	
	
	for (NSString *filePath in filePaths) {
		NSError *outError = nil;
		NSString *resultingPath = nil;
		VSGame *resultingGame = nil;
		[steamManager installAddonAtPath:filePath method:installMethod resultingPath:&resultingPath resultingGame:&resultingGame overwrite:YES error:&outError];
		
		VSSourceAddon *addon = [VSSourceAddon sourceAddonWithPath:resultingPath game:resultingGame error:outError];
		
		if ([addon problem] == nil) {
			[[self mutableArrayValueForKey:@"installedAddons"] addObject:addon];
		} else {
			[[self mutableArrayValueForKey:@"problemAddons"] addObject:addon];
		}
	}
	NSUInteger installedAddonsCount = [installedAddons count];
	NSUInteger problemAddonsCount = [problemAddons count];
	
	if (installedAddonsCount > 0 && problemAddonsCount == 0) {
		if (installedAddonsCount == 1) {
			[resultsField setStringValue:NSLocalizedString(@"1 Source addon was installed.", @"")];
			
		} else {
			[resultsField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%lu Source addons were installed.", @""), installedAddonsCount]];
		}

	} else if (installedAddonsCount > 0 && problemAddonsCount > 0) {
		[resultsField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%lu of %lu addons were installed.", @""), installedAddonsCount, installedAddonsCount + problemAddonsCount]];
	} else if (installedAddonsCount == 0 && problemAddonsCount > 0) {
		[resultsField setStringValue:NSLocalizedString(@"No Source addons were installed.", @"")];

	}
	
	
	if ([installedAddons count]) {
		[[NSSound soundNamed:@"copy"] play];
	}
	
	if ([installedAddons count] > 0 && [problemAddons count] == 0) {
		
		NSSize newSize = [window frame].size;
		newSize.height += (NSHeight([successView frame]) - NSHeight([box frame]));
		[window resizeToSize:newSize];
		[window setMinSize:newSize];
		[box setContentView:successView];
		
	} else if ([installedAddons count] == 0 && [problemAddons count] > 0) {
		
		NSSize newSize = [window frame].size;
		newSize.height += (NSHeight([problemView frame]) - NSHeight([box frame]));
		[window resizeToSize:newSize];
		[window setMinSize:newSize];
		[box setContentView:problemView];
		
	} else if ([installedAddons count] > 0 && [problemAddons count] > 0) {
		
		[successBox setContentView:successView];
		[problemBox setContentView:problemView];
		
		[box setContentView:comboView];
	} 
	
	[copyProgressWindow orderOut:nil];
	
	[progressIndicator stopAnimation:nil];
	
	if ([[NSUserDefaults standardUserDefaults] objectForKey:[window frameAutosaveName]] == nil) {
		[window center];
	}
	[window makeKeyAndOrderFront:nil];
	
	[successTableView reloadData];
	[problemTableView reloadData];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (tableView == successTableView) {
		return [installedAddons count];
		
	} else if (tableView == problemTableView) {
		return [problemAddons count];
	}
	return 0;
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (tableView == successTableView) {
		return [[installedAddons objectAtIndex:row] valueForKey:[tableColumn identifier]];
		
	} else if (tableView == problemTableView) {
		return [[problemAddons objectAtIndex:row] valueForKey:[tableColumn identifier]];
	}
	return nil;
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (aTableView == successTableView) {
		
		VSSourceAddon *addon = [installedAddons objectAtIndex:rowIndex];
		NSImage *image = (tableColumn == successFileNameColumn ? [addon fileIcon] : [addon gameIcon]);
		[cell setImage:image];
		
	} else if (aTableView == problemTableView) {
		VSSourceAddon *addon = [problemAddons objectAtIndex:rowIndex];
		NSImage *image = (tableColumn == problemFileNameColumn ? [addon fileIcon] : nil);
		[cell setImage:image];
	}
}


- (IBAction)ok:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[NSApp terminate:nil];
}

- (IBAction)showPrefsWindow:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (![prefsWindow isVisible]) [prefsWindow center];
	[prefsWindow makeKeyAndOrderFront:nil];
}


@end
