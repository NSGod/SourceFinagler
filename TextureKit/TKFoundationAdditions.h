//
//  TKFoundationAdditions.h
//  Texture Kit
//
//  Created by Mark Douma on 12/25/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TextureKit/TextureKitDefines.h>


@interface NSObject (TKDeepMutableCopy)

- (id)deepMutableCopy NS_RETURNS_RETAINED;

@end


enum {
	TKCheetah				= 0,
	TKPuma					= 1,
	TKJaguar				= 2,
	TKPanther				= 3,
	TKTiger					= 4,
	TKLeopard				= 5,
	TKSnowLeopard			= 6,
	TKLion					= 7,
	TKMountainLion			= 8,
	TKMavericks				= 9,
	TKYosemite				= 10,
	TKElCapitan				= 11,
	TKUnknownVersion		= 12,
};

typedef struct {
    NSInteger majorVersion;
    NSInteger minorVersion;
    NSInteger patchVersion;
} TKOperatingSystemVersion;


TEXTUREKIT_EXTERN BOOL TKOperatingSystemVersionLessThan(TKOperatingSystemVersion osVersion, TKOperatingSystemVersion referenceVersion);
TEXTUREKIT_EXTERN BOOL TKOperatingSystemVersionGreaterThanOrEqual(TKOperatingSystemVersion osVersion, TKOperatingSystemVersion referenceVersion);


@interface NSProcessInfo (TKAdditions)

- (TKOperatingSystemVersion)tk__operatingSystemVersion;

@end


