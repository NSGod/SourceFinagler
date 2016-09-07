//
//  MDCGImage.h
//  Source Finagler
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <ApplicationServices/ApplicationServices.h>
#import <Foundation/Foundation.h>


	
#ifdef __cplusplus
extern "C" {
#endif
	
	
extern NSString * const MDSourceQuickLookBundleIdentifier;
	
extern CGImageRef MDCGImageCreateFromURL(NSURL *URL, NSString *contentTypeUTI, NSError **outError) CF_RETURNS_RETAINED;
	
	
#ifdef __cplusplus
}
#endif

