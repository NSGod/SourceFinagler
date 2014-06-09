//
//  TKError.h
//  Texture Kit
//
//  Created by Mark Douma on 4/16/2014.
//  Copyright (c) 2014 Mark Douma. All rights reserved.
//

#import <TextureKit/TextureKitDefines.h>
#import <Foundation/Foundation.h>



/*!
 @const      TKErrorDomain
 @abstract   Error domain for NSError values stemming from the TextureKit Framework.
 @discussion This error domain is used as the domain for all NSError instances stemming from the TextureKit Framework.
 */

TEXTUREKIT_EXTERN NSString * const TKErrorDomain;

enum {
	TKErrorCorruptDDSFile					= -10000,
	TKErrorUnsupportedDDSFormat				= -10001,
	TKErrorCorruptVTFFile					= -10002,
	TKErrorUnsupportedVTFFormat				= -10003,
	
	// these correspond to CGImageSourceStatus codes for native images
	TKErrorCGImageSourceUnexpectedEOF		= -10010,	// kCGImageStatusUnexpectedEOF
	TKErrorCGImageSourceInvalidData			= -10011,	// kCGImageStatusInvalidData
	TKErrorCGImageSourceUnknownType			= -10012,	// kCGImageStatusUnknownType
	
	TKErrorUnknown							= -10020,
};

