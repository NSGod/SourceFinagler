//
//  VSSourceAddonInstallOperation.h
//  SteamKit
//
//  Created by Mark Douma on 5/20/2014.
//  Copyright (c) 2014 Mark Douma. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SteamKit/SteamKitDefines.h>
#import <SteamKit/VSSteamManager.h>


@class VSSourceAddon;



@interface VSSourceAddonInstallOperation : NSOperation {
	
	VSSourceAddon					*sourceAddon;
	VSSourceAddonInstallMethod		installMethod;
	
}

- (id)initWithSourceAddon:(VSSourceAddon *)aSourceAddon installMethod:(VSSourceAddonInstallMethod)anInstallMethod;


@property (readonly, retain) VSSourceAddon *sourceAddon;
@property (readonly, assign) VSSourceAddonInstallMethod installMethod;


@end
