//
//  MDResource.h
//  Font Finagler
//
//  Created by Mark Douma on 11/17/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>


@interface MDResource : NSObject {
	NSString			*resourceName;
	NSData				*resourceData;
	SInt32				resourceSize;
	ResType				resourceType;
	ResourceIndex		resourceIndex;
	ResID				resourceID;
	ResAttributes		resourceAttributes;
	BOOL				resChanged;
	
}

+ (id)resourceWithType:(ResType)aType index:(ResourceIndex)anIndex error:(NSError **)outError;

- (id)initWithType:(ResType)aType index:(ResourceIndex)anIndex error:(NSError **)outError;

- (id)initWithType:(ResType)aType resourceData:(NSData *)aData resourceID:(ResID)anID resourceName:(NSString *)aName resourceIndex:(ResourceIndex)anIndex resourceAttributes:(ResAttributes)anAttributes resChanged:(BOOL)aResChanged copy:(BOOL)shouldCopy error:(NSError **)outError;


- (BOOL)getResourceInfo:(NSError **)outError;
- (BOOL)parseResourceData:(NSError **)outError;


- (ResType)resourceType;
- (void)setResourceType:(ResType)value;
- (ResID)resourceID;
- (void)setResourceID:(ResID)value;
- (NSString *)resourceName;
- (void)setResourceName:(NSString *)value;
- (NSData *)resourceData;
- (void)setResourceData:(NSData *)value;
- (SInt32)resourceSize;
- (void)setResourceSize:(SInt32)value;
- (ResourceIndex)resourceIndex;
- (void)setResourceIndex:(ResourceIndex)value;
- (ResAttributes)resourceAttributes;
- (void)setResourceAttributes:(ResAttributes)value;
- (BOOL)resChanged;
- (void)setResChanged:(BOOL)value;
@end


