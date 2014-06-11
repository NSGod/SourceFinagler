//
//  VSSourceAddon.h
//  SteamKit
//
//  Created by Mark Douma on 11/15/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import <Foundation/NSObject.h>
#import <SteamKit/VSGame.h>

@class NSImage, NSString, NSURL;


enum {
	VSSourceAddonStatusUnknown			= 0,
	VSSourceAddonNotAnAddonFile,
	VSSourceAddonNoAddonInfoFound,
	VSSourceAddonAddonInfoUnreadable,
	VSSourceAddonNoGameIDFoundInAddonInfo,
	VSSourceAddonValidAddon,
	VSSourceAddonGameNotFound,
	VSSourceAddonAlreadyInstalled,
};
typedef NSUInteger VSSourceAddonStatus;



@interface VSSourceAddon : NSObject {
	NSURL					*URL;			// can change if source addon is installed
	NSURL					*originalURL;
	
	NSNumber				*fileSize;
	
	NSString				*fileName;
	NSImage					*fileIcon;
	
	VSGame					*game;
	
	VSGameID				sourceAddonGameID;
	
	VSSourceAddonStatus		sourceAddonStatus;
	
	BOOL					installed;
	
}

+ (id)sourceAddonWithContentsOfURL:(NSURL *)aURL error:(NSError **)outError;
- (id)initWithContentsOfURL:(NSURL *)aURL error:(NSError **)outError;



@property (readonly, retain) NSURL *URL;	// can change if source addon is installed

@property (readonly, retain) NSURL *originalURL;

@property (readonly, retain) NSNumber *fileSize;

@property (readonly, retain) NSString *fileName;
@property (readonly, retain) NSImage *fileIcon;

@property (readonly, retain) VSGame *game;

@property (readonly, assign) VSGameID sourceAddonGameID;

@property (readonly, assign) VSSourceAddonStatus sourceAddonStatus;

@property (readonly, assign, getter=isInstalled) BOOL installed;


@end

