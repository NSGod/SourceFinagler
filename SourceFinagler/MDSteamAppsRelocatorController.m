//
//  MDSteamAppsRelocatorController.m
//  Source Finagler
//
//  Created by Mark Douma on 6/13/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

//#if TARGET_CPU_X86 || TARGET_CPU_X86_64

#import "MDSteamAppsRelocatorController.h"
#import "MDAppKitAdditions.h"
#import "MDFoundationAdditions.h"
#import "MDFolderManager.h"
#import "VSSteamManager.h"
#import "MDProcessManager.h"


#define VS_DEBUG 0


static NSString * const MDSteamAppsRelocatorViewSizeKey = @"MDSteamAppsRelocatorViewSize";


// default "SteamApps" path is now
/*		/Users/~/Library/Application Support/Steam/SteamApps/			*/


NSString * const MDSteamBundleIdentifierKey = @"com.valvesoftware.steam";

@implementation MDSteamAppsRelocatorController

@synthesize currentURL;
@synthesize proposedNewPath;
@synthesize canCreate;
@synthesize steamIsRunning;
@synthesize steamDidLaunch;



- (id)init {
	if ((self = [super init])) {
		resizable = YES;
		
		steamManager = [[VSSteamManager defaultManager] retain];
		
		NSString *currentPath = [steamManager steamAppsPath];
		
		if (currentPath) {
			[self setCurrentURL:[NSURL fileURLWithPath:currentPath]];
		} 
		
		[self setSteamIsRunning:MDInfoForProcessWithBundleIdentifier(MDSteamBundleIdentifierKey) != nil];
		
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationDidLaunch:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationDidTerminate:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	}
	return self;
}


- (void)dealloc {
	[currentURL release];
	[proposedNewPath release];
	[steamManager release];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[super dealloc];
}


- (void)awakeFromNib {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	minWinSize = [view frame].size;
	minWinSize.height += 22.0;
	maxWinSize = NSMakeSize(16000, minWinSize.height);
	
	if (steamIsRunning) {
		[statusField setStringValue:NSLocalizedString(@"Steam cannot be running", @"")];
	}
}


- (void)applicationDidLaunch:(NSNotification *)notification {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSDictionary *userInfo = [notification userInfo];
	if ([[userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:MDSteamBundleIdentifierKey]) {
		[self setSteamIsRunning:YES];
		[statusField setStringValue:NSLocalizedString(@"Steam cannot be running", @"")];
		
		if (currentURL == nil) {
			steamDidLaunch = YES;
			[self performSelector:@selector(updateSteamPath:) withObject:nil afterDelay:5.0];
		}
	}
}


- (void)updateSteamPath:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (steamDidLaunch) {
		NSString *currentPath = [steamManager steamAppsPath];
		if (currentPath) {
			[self setCurrentURL:[NSURL fileURLWithPath:currentPath]];
			steamDidLaunch = NO;
			
		} else {
			
			[self performSelector:@selector(updateSteamPath:) withObject:nil afterDelay:5.0];
		}
	}
}


- (void)applicationDidTerminate:(NSNotification *)notification {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSDictionary *userInfo = [notification userInfo];
	if ([[userInfo objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:MDSteamBundleIdentifierKey]) {
		[self setSteamIsRunning:NO];
		[statusField setStringValue:@""];
	}
}


- (IBAction)quitSteam:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSDictionary *errorMessage = nil;
	NSAppleEventDescriptor *result = nil;
	
	NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:@"tell app \"Steam\" to quit"] autorelease];
	if (script) {
		result = [script executeAndReturnError:&errorMessage];
		if (errorMessage) {
			NSLog(@"%@, result == %@", errorMessage, result);
		}
	}
}


- (void)appControllerDidLoadNib:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSUserDefaults *uD = [NSUserDefaults standardUserDefaults];
	if ([uD objectForKey:MDSteamAppsRelocatorViewSizeKey] == nil) [uD setObject:[view stringWithSavedFrame] forKey:MDSteamAppsRelocatorViewSizeKey];
	[view setFrameFromString:[uD objectForKey:MDSteamAppsRelocatorViewSizeKey]];
	[super appControllerDidLoadNib:self];
}

- (void)cleanup {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[NSUserDefaults standardUserDefaults] setObject:[view stringWithSavedFrame] forKey:MDSteamAppsRelocatorViewSizeKey];
}


- (void)controlTextDidChange:(NSNotification *)notification {
//	NSLog(@"[%@ %@] newPath == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), newPath);
	[self setProposedNewPath:[[newPathField stringValue] stringByStandardizingPath]];
	
	NSString *status = nil;
	
	BOOL isValid = [steamManager isProposedRelocationPathValid:proposedNewPath errorDescription:&status];
	
	[self setCanCreate:isValid];
	if (status) {
		[statusField setStringValue:status];
	}
	
}

- (IBAction)revealInFinder:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (currentURL) {
		[[NSWorkspace sharedWorkspace] revealInFinder:[NSArray arrayWithObject:[currentURL path]]];
	}
}

- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (currentURL) {
		if ([filename isEqualToString:[currentURL path]]) {
			NSLog(@"returning no");
			return NO;
		}
	}
	
	if ([filename isEqualToString:[steamManager defaultSteamAppsPath]]) {
		return NO;
	}
	return YES;
}


- (IBAction)browse:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanelWithTitle:[NSString stringWithFormat:@"Locate %@", VSSteamAppsDirectoryNameKey]
													 message:[NSString stringWithFormat:@"Locate the copy of your “%@” folder you created in Step 2.", VSSteamAppsDirectoryNameKey]
										   actionButtonTitle:@"Open"
									 allowsMultipleSelection:NO
										canChooseDirectories:YES
													delegate:self];
	[openPanel setResolvesAliases:NO];
	
	NSInteger result = [openPanel runModalForDirectory:nil file:nil types:nil];
	
	if (result == NSOKButton) {
		NSArray *filePaths = [openPanel filenames];
		NSString *filePath = [filePaths objectAtIndex:0];
		if (filePaths && [filePaths count]) {
			[self setProposedNewPath:filePath];
		}
		
		NSString *status = nil;
		
		BOOL isValid = [steamManager isProposedRelocationPathValid:proposedNewPath errorDescription:&status];
		
		[self setCanCreate:isValid];
		if (status) {
			[statusField setStringValue:status];
		}
	}
}


- (IBAction)createSteamAppsShortcut:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSError *error = nil;
	if ([steamManager relocateSteamAppsToPath:proposedNewPath error:&error]) {
		[statusField setStringValue:@"Success"];
		[self setCanCreate:NO];
		[self setCurrentURL:[NSURL fileURLWithPath:proposedNewPath]];
		[statusField performSelector:@selector(setStringValue:) withObject:@"" afterDelay:10.0];
		
	} else {
		NSLog(@"[%@ %@] error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
		
	}
}


@end
//#endif




