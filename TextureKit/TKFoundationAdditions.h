//
//  TKFoundationAdditions.h
//  Texture Kit
//
//  Created by Mark Douma on 12/25/2010.
//  Copyright (c) 2010-2013 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TextureKit/TextureKitDefines.h>


@interface NSObject (TKDeepMutableCopy)

- (id)deepMutableCopy NS_RETURNS_RETAINED;

@end


enum {
	TKUndeterminedVersion	= 0,
	TKCheetah				= 0x1000,
	TKPuma					= 0x1010,
	TKJaguar				= 0x1020,
	TKPanther				= 0x1030,
	TKTiger					= 0x1040,
	TKLeopard				= 0x1050,
	TKSnowLeopard			= 0x1060,
	TKLion					= 0x1070,
	TKMountainLion			= 0x1080,
	TKMavericks				= 0x1090,
	TKUnknownVersion		= 0x1100
};

TEXTUREKIT_EXTERN SInt32 TKGetSystemVersion();

	
