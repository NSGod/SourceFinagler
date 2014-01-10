//
//  VSSourceAddon.h
//  Source Finagler
//
//  Created by Mark Douma on 11/15/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
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
	NSURL					*URL;
	
	NSString				*fileName;
	NSImage					*fileIcon;
	
	VSGame					*game;
	
	VSGameID				sourceAddonGameID;
	
	VSSourceAddonStatus		sourceAddonStatus;
	
	BOOL					installed;
	
}

+ (id)sourceAddonWithContentsOfURL:(NSURL *)aURL error:(NSError **)outError;
- (id)initWithContentsOfURL:(NSURL *)aURL error:(NSError **)outError;



@property (nonatomic, readonly, retain) NSURL *URL;

@property (nonatomic, readonly, retain) NSString *fileName;
@property (nonatomic, readonly, retain) NSImage *fileIcon;

@property (nonatomic, readonly, retain) VSGame *game;

@property (nonatomic, readonly, assign) VSGameID sourceAddonGameID;

@property (nonatomic, readonly, assign) VSSourceAddonStatus sourceAddonStatus;

@property (nonatomic, readonly, assign, getter=isInstalled) BOOL installed;


@end

