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

CGImageRef MDCGImageCreateCopyWithSize(CGImageRef imageRef, CGSize size);
	
#ifdef __cplusplus
}
#endif
	