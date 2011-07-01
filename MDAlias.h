//
//  MDAlias.h
//  Source Finagler
//
//  Created by Mark Douma on 10/23/2006.
//  Copyright © 2006 Mark Douma. All rights reserved.
//



#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>



@interface MDAlias : NSObject {
	AliasHandle alias;
}
+ (id)aliasWithAlias:(AliasHandle)anAlias;
+ (id)aliasWithPath:(NSString *)aPath;
+ (id)aliasWithData:(NSData *)data;

- (id)initWithAlias:(AliasHandle)anAlias;
- (id)initWithPath:(NSString *)aPath;
- (id)initWithData:(NSData *)data;

- (NSData *)aliasData;
- (AliasHandle)alias;
- (NSString *)filePath;
@end


