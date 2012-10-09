//
//  MDMouseAppHelperController.m
//  Source Finagler
//
//  Created by Mark Douma on 6/13/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//
//#if TARGET_CPU_X86 || TARGET_CPU_X86_64



#import "MDOtherAppsHelperController.h"
#import "VSSteamManager.h"
#import "MDAppKitAdditions.h"
#import "MDProcessManager.h"


//#define VS_DEBUG 0
#define VS_DEBUG 1

NSString * const MDOtherAppsHelperViewSizeKey = @"MDOtherAppsHelperViewSize";

NSString * const MDUSBOverdriveHelperBundleIdentifierKey		= @"com.montalcini.usboverdrivehelper";
NSString * const MDSteerMouseBundleIdentifierKey				= @"jp.plentycom.boa.SteerMouse";
NSString * const MDLogitechBundleIdentifierKey					= @"com.Logitech.Control Center.Daemon";


static NSString * const MDOtherAppsHelperSortDescriptorsKey		= @"MDOtherAppsHelperSortDescriptors";



@implementation MDOtherAppsHelperController

@synthesize enableSourceFinaglerAgent;


@dynamic sortDescriptors;


+ (void)initialize {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES selector:@selector(caseInsensitiveNumericalCompare:)] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
//	NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES selector:@selector(caseInsensitiveNumericalCompare:)], nil];
    [defaults setSortDescriptors:sortDescriptors forKey:MDOtherAppsHelperSortDescriptorsKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}


- (id)init {
	if ((self = [super init])) {
		games = [[NSMutableArray alloc] init];
		steamManager = [[VSSteamManager defaultManager] retain];
		[steamManager setDelegate:self];
		resizable = YES;
		if ([steamManager sourceFinaglerLaunchAgentStatus] == VSSourceFinaglerLaunchAgentUpdateNeeded) {
			[steamManager updateSourceFinaglerLaunchAgentWithError:NULL];
		}
		
		enableSourceFinaglerAgent = ([steamManager sourceFinaglerLaunchAgentStatus] == VSSourceFinaglerLaunchAgentInstalled);
	}
	return self;
}


- (void)dealloc {
	[games release];
	[steamManager release];
	[super dealloc];
}


- (void)awakeFromNib {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	minWinSize = [view frame].size;
	maxWinSize = NSMakeSize(16000, 16000);
	
	
	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(launchGame:)];
	[tableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
	[tableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
	[tableView setVerticalMotionCanBeginDrag:NO];
	
	[tableView setSortDescriptors:[[NSUserDefaults standardUserDefaults] sortDescriptorsForKey:MDOtherAppsHelperSortDescriptorsKey]];
	
	
//	[gamesController setSortDescriptors:[tableView sortDescriptors]];
	
	NSDictionary *usbInfo = MDInfoForProcessWithBundleIdentifier(MDUSBOverdriveHelperBundleIdentifierKey);
	
	
	mouseSoftware |= (usbInfo == nil ? 0 : MDUSBOverdrive);
	mouseSoftware |= (MDInfoForProcessWithBundleIdentifier(MDSteerMouseBundleIdentifierKey) == nil ? 0 : MDSteerMouse);
	mouseSoftware |= (MDInfoForProcessWithBundleIdentifier(MDLogitechBundleIdentifierKey) == nil ? 0 : MDLogitech);
	
	[usbOverdriveView setHidden:!(mouseSoftware & MDUSBOverdrive)];
	
	if (mouseSoftware & MDUSBOverdrive) {
//		NSLog(@"[%@ %@] usbInfo == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), usbInfo);
		NSString *bundlePath = [usbInfo objectForKey:@"BundlePath"];
		if (bundlePath) {
			NSImage *usbIcon = [[NSWorkspace sharedWorkspace] iconForFile:bundlePath];
			[usbOverdriveIconButton setImage:usbIcon];
		}
	}
	
	[[self mutableArrayValueForKey:@"games"] setArray:[steamManager games]];
	
	[VSSteamManager	setDefaultPersistentOptions:VSGameLaunchDefault];
	[steamManager setMonitoringGames:YES];
	
}

- (void)appControllerDidLoadNib:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSUserDefaults *uD = [NSUserDefaults standardUserDefaults];
	if ([uD objectForKey:MDOtherAppsHelperViewSizeKey] == nil) [uD setObject:[view stringWithSavedFrame] forKey:MDOtherAppsHelperViewSizeKey];
	[view setFrameFromString:[uD objectForKey:MDOtherAppsHelperViewSizeKey]];
	[super appControllerDidLoadNib:self];
	
}


- (void)setSortDescriptors:(NSArray *)aSortDescriptors {
	[tableView setSortDescriptors:aSortDescriptors];
}


- (NSArray *)sortDescriptors {
	return [tableView sortDescriptors];
}


- (void)cleanup {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[NSUserDefaults standardUserDefaults] setObject:[view stringWithSavedFrame] forKey:MDOtherAppsHelperViewSizeKey];
}


- (void)gameDidLaunch:(VSGame *)game {
#if VS_DEBUG
	NSLog(@"[%@ %@] game == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), game);
#endif
	[self refresh:nil];
}


- (void)gameDidTerminate:(VSGame *)game {
#if VS_DEBUG
	NSLog(@"[%@ %@] game == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), game);
#endif
	[self refresh:nil];
}


- (IBAction)toggleEnableAgent:(id)sender {
	NSLog(@"[%@ %@] sender's state == %ld; enableSourceFinaglerAgent == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)[(NSButton *)sender state], (enableSourceFinaglerAgent ? @"YES" : @"NO"));
	NSError *outError = nil;
	
	if (enableSourceFinaglerAgent) {
		[steamManager installSourceFinaglerLaunchAgentWithError:&outError];
	} else {
		[steamManager uninstallSourceFinaglerLaunchAgentWithError:&outError];
	}
}


- (NSArray *)games {
    return games;
}

- (NSUInteger)countOfGames {
    return [games count];
}

- (id)objectInGamesAtIndex:(NSUInteger)theIndex {
    return [games objectAtIndex:theIndex];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSUInteger count = [[gamesController selectedObjects] count];
	if (count > 1) {
		[helpButton setTitle:@"Help Other Apps Recognize Games"];
	} else {
		[helpButton setTitle:@"Help Other Apps Recognize Game"];
	}
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
#if VS_DEBUG
//	NSLog(@"[%@ %@] rowIndexes == %@ ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), rowIndexes);
#endif
	NSIndexSet *selectionIndexes = [gamesController selectionIndexes];
//	NSLog(@"[%@ %@] selectionIndexes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), selectionIndexes);
	
	if (![selectionIndexes isEqualToIndexSet:rowIndexes]) {
		[gamesController setSelectionIndexes:rowIndexes];
	}
	
	
	NSArray *selectedGames = [gamesController selectedObjects];
	if ([selectedGames count] == 0) {
		NSInteger clickedRow = [aTableView clickedRow];
//		NSLog(@"[%@ %@] clickedRow == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), clickedRow);
		if (clickedRow >= 0) {
			[gamesController setSelectionIndexes:[NSIndexSet indexSetWithIndex:clickedRow]];
		}
	}
	
	selectedGames = [gamesController selectedObjects];
	
	if (selectedGames && [selectedGames count] == 1) {
		[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
		NSString *filePath = [(VSGame *)[selectedGames objectAtIndex:0] executablePath];
		if (filePath) {
			[pboard setPropertyList:[NSArray arrayWithObject:filePath] forType:NSFilenamesPboardType];
			return YES;
		}
	}
	return NO;
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:@"displayName"]) {
		VSGame *game = [[gamesController arrangedObjects] objectAtIndex:row];
		NSImage *gameIcon = [game icon];
		[gameIcon setSize:NSMakeSize(16.0, 16.0)];
		[cell setImage:gameIcon];
	}
}



- (IBAction)showUSBOverdriveTip:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[NSApp beginSheet:usbOverdriveWindow modalForWindow:[view window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	
}


- (IBAction)ok:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[NSApp endSheet:usbOverdriveWindow];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[sheet orderOut:nil];
}


- (IBAction)launchGame:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *selectedGames = [gamesController selectedObjects];
	NSError *error = nil;
	
	if (selectedGames && [selectedGames count] == 1) {
		if (![steamManager launchGame:[selectedGames objectAtIndex:0] options:VSGameLaunchDefault error:&error]) {
			NSLog(@"[%@ %@] failed to launch game, error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
		}
	}
}


- (IBAction)toggleHelpApps:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	mouseSoftware |= (MDInfoForProcessWithBundleIdentifier(MDUSBOverdriveHelperBundleIdentifierKey) == nil ? 0 : MDUSBOverdrive);
	mouseSoftware |= (MDInfoForProcessWithBundleIdentifier(MDSteerMouseBundleIdentifierKey) == nil ? 0 : MDSteerMouse);
	mouseSoftware |= (MDInfoForProcessWithBundleIdentifier(MDLogitechBundleIdentifierKey) == nil ? 0 : MDLogitech);
	
	NSArray *selectedGames = [gamesController selectedObjects];
	if ([selectedGames count] == 0) return;
	VSGame *game = [selectedGames objectAtIndex:0];
	BOOL isHelped = [game isHelped];
	
	NSError *error = nil;
	
	for (VSGame *game in selectedGames) {
		if (isHelped) {
			if (![steamManager unhelpGame:game error:&error]) {
				NSLog(@"[%@ %@] failed to unhelp game == %@, error = %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), game, error);
			}
		} else {
			if (![steamManager helpGame:game forUSBOverdrive:(mouseSoftware & MDUSBOverdrive) updateLaunchAgent:YES error:&error]) {
				NSLog(@"[%@ %@] failed to help game == %@, error = %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), game, error);
			}
		}
	}
	[self refresh:self];
	
}


- (IBAction)helpApps:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *selectedGames = [gamesController selectedObjects];
	NSError *error = nil;
	
	for (VSGame *game in selectedGames) {
		if (![steamManager helpGame:game forUSBOverdrive:(mouseSoftware & MDUSBOverdrive) updateLaunchAgent:YES error:&error]) {
			NSLog(@"[%@ %@] failed to help game == %@, error = %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), game, error);
		}
	}
	[self refresh:self];
}


- (IBAction)restoreToDefault:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSArray *selectedGames = [gamesController selectedObjects];
	
	NSError *error = nil;
	
	for (VSGame *game in selectedGames) {
		if (![steamManager unhelpGame:game error:&error]) {
			NSLog(@"[%@ %@] failed to unhelp game == %@, error = %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), game, error);
		}
	}
	[self refresh:self];
}



- (IBAction)refresh:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[steamManager locateSteamApps];
	
	NSArray *theGames = [steamManager games];
	NSArray *selectedObjects = [[gamesController selectedObjects] retain];
	if (theGames) {
		[[self mutableArrayValueForKey:@"games"] setArray:theGames];
	}
	[gamesController setSelectedObjects:selectedObjects];
	[selectedObjects release];
}


- (IBAction)revealInFinder:(id)sender {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *selectedGames = [gamesController selectedObjects];
	NSMutableArray *filePaths = [NSMutableArray array];
	
	for (VSGame *game in selectedGames) {
		NSString *path = [game executablePath];
		if (path) {
			[filePaths addObject:path];
		}
	}
	
	if ([filePaths count]) {
		if (![[NSWorkspace sharedWorkspace] revealInFinder:filePaths]) {
			NSLog(@"[%@ %@] [[NSWorkspace sharedWorkspace] revealInFinder:filePaths] returned NO! ", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
		}
	}
	
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	SEL action = [menuItem action];
	NSArray *selectedGames = [gamesController selectedObjects];
	NSUInteger count = [selectedGames count];
	
	if (action == @selector(revealInFinder:)) {
		
		return count;
		
	} else if (action == @selector(toggleHelpApps:)) {
		if (count) {
			VSGame *game = [selectedGames objectAtIndex:0];
			BOOL isHelped = [game isHelped];
			if (count == 1) {
				[menuItem setTitle:(isHelped ? NSLocalizedString(@"Unhelp Game", @"") : NSLocalizedString(@"Help Game", @""))];
				
			} else {
				[menuItem setTitle:(isHelped ? NSLocalizedString(@"Unhelp Games", @"") : NSLocalizedString(@"Help Games", @""))];
				
			}
		} else {
			[menuItem setTitle:NSLocalizedString(@"Help Games", @"")];
		}
		return count;
	}
	
	return YES;
}


@end






