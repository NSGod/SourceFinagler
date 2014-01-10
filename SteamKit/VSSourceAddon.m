//
//  VSSourceAddon.m
//  Source Finagler
//
//  Created by Mark Douma on 11/15/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "VSSourceAddon.h"
#import <Cocoa/Cocoa.h>
#import <HLKit/HLKit.h>
#import "VSSteamManager.h"
#import "VSPrivateInterfaces.h"



#define VS_DEBUG 0



@implementation VSSourceAddon

@synthesize URL;
@synthesize fileName;
@synthesize fileIcon;
@synthesize game;
@synthesize sourceAddonGameID;
@synthesize sourceAddonStatus;
@synthesize installed;


+ (id)sourceAddonWithContentsOfURL:(NSURL *)aURL error:(NSError **)outError {
	return [[(VSSourceAddon *)[[self class] alloc] initWithContentsOfURL:aURL error:outError] autorelease];
}


- (id)initWithContentsOfURL:(NSURL *)aURL error:(NSError **)outError {
	if ((self = [super init])) {
		
		if (outError) *outError = nil;
		
		URL = [aURL retain];
		
		fileName = [[URL.path lastPathComponent] retain];
		
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:URL.path];
		[icon setSize:NSMakeSize(16.0, 16.0)];
		fileIcon = [icon retain];
		
		HKVPKFile *file = [[[HKVPKFile alloc] initWithContentsOfFile:URL.path showInvisibleItems:YES sortDescriptors:nil error:outError] autorelease];
		
		switch (file.sourceAddonStatus) {
				
			case HKSourceAddonNotAnAddonFile : sourceAddonStatus = VSSourceAddonNotAnAddonFile;
				break;
				
			case HKSourceAddonNoAddonInfoFound : sourceAddonStatus = VSSourceAddonNoAddonInfoFound;
				break;
				
			case HKSourceAddonAddonInfoUnreadable : sourceAddonStatus = VSSourceAddonAddonInfoUnreadable;
				break;
				
			case HKSourceAddonNoGameIDFoundInAddonInfo : sourceAddonStatus = VSSourceAddonGameNotFound;
				break;
				
			case HKSourceAddonValidAddon : sourceAddonStatus = VSSourceAddonValidAddon;
				break;
				
			default:
				break;
		}
		
		sourceAddonGameID = file.sourceAddonGameID;
		
		if (sourceAddonStatus == VSSourceAddonValidAddon) {
			game = [[[VSSteamManager defaultManager] gameWithGameID:file.sourceAddonGameID] retain];
			
			if (game) {
				
				if ([[URL URLByDeletingLastPathComponent] isEqual:game.sourceAddonsFolderURL]) {
					installed = YES;
					sourceAddonStatus = VSSourceAddonAlreadyInstalled;
				}
				
			} else {
				sourceAddonStatus = VSSourceAddonGameNotFound;
			}
		}
	}
	return self;
}


- (void)dealloc {
	[URL release];
	[fileName release];
	[fileIcon release];
	[game release];
	[super dealloc];
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@ -", [super description]];
	
	[description appendFormat:@" %@", fileName];
	[description appendFormat:@", game == %@", game];
	if (game == nil) {
		[description appendFormat:@", sourceAddonGameID == %lu", (unsigned long)sourceAddonGameID];
	}
	[description appendFormat:@", isInstalled == %@", (installed ? @"YES" : @"NO")];
	return description;
}


@end



