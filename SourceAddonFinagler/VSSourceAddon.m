//
//  VSSourceAddon.m
//  Source Finagler
//
//  Created by Mark Douma on 11/15/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "VSSourceAddon.h"
#import <SteamKit/SteamKit.h>


@implementation VSSourceAddon

@synthesize path, fileName, fileIcon, gameName, gameIcon, problem;

+ (id)sourceAddonWithPath:(NSString *)aPath game:(VSGame *)aGame error:(NSError *)inError {
	return [[[[self class] alloc] initWithPath:aPath game:aGame error:inError] autorelease];
}

- (id)initWithPath:(NSString *)aPath game:(VSGame *)game error:(NSError *)inError {
	if ((self = [super init])) {
		path = [aPath retain];
		fileName = [[path lastPathComponent] retain];
		
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
		if (icon) [icon setSize:NSMakeSize(16.0, 16.0)];
		[self setFileIcon:icon];
		
		if (game) {
			if ([game displayName]) {
				[self setGameName:[game displayName]];
			}
			NSImage *icon = [game icon];
			if (icon) [icon setSize:NSMakeSize(16.0, 16.0)];
			[self setGameIcon:icon];
		}
		
		if (inError) {
//			NSString *domain = [inError domain];
			NSInteger errorCode = [inError code];
			
			switch (errorCode) {
				case VSSourceAddonNotAValidAddonFileError : {
					[self setProblem:NSLocalizedString(@"Not a valid Source addon file", @"")];
					break;
				}
					
				case VSSourceAddonSourceFileIsDestinationFileError : {
					[self setProblem:NSLocalizedString(@"This addon file is already installed", @"")];
					break;
				}
					
				case VSSourceAddonNoAddonInfoFoundError : {
					[self setProblem:NSLocalizedString(@"No addoninfo.txt file could be found inside the Source addon file", @"")];
					break;
				}
					
				case VSSourceAddonAddonInfoUnreadableError : {
					[self setProblem:NSLocalizedString(@"Couldn't read the addoninfo.txt file inside the Source addon file", @"")];
					break;
				}
					
				case VSSourceAddonNoGameIDFoundInAddonInfoError : {
					[self setProblem:NSLocalizedString(@"Didn't find a valid game ID in the addoninfo.txt file inside the Source addon file", @"")];
					break;
				}
					
				case VSSourceAddonGameNotFoundError : {
					NSInteger gameID = [[[inError userInfo] objectForKey:VSSourceAddonGameIDKey] integerValue];
					[self setProblem:[NSString stringWithFormat:NSLocalizedString(@"Could not locate installed game for Steam Game ID %ld", @""), gameID]];
					break;
				}
					
				default:
					[self setProblem:NSLocalizedString(@"Unknown error", @"")];
					break;
			}
		}
		
	}
	return self;
}


- (void)dealloc {
	[path release];
	[fileName release];
	[fileIcon release];
	[gameName release];
	[gameIcon release];
	[problem release];
	[super dealloc];
}



@end
