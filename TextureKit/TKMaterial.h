//
//  TKMaterial.h
//  Texture Kit
//
//  Created by Mark Douma on 1/17/2011.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import <Foundation/NSObject.h>
#import <TextureKit/TextureKitDefines.h>


@class TKVMTNode;


@interface TKMaterial : NSObject <NSCopying> {
	TKVMTNode		*rootNode;
}

+ (id)materialWithContentsOfFile:(NSString *)aPath error:(NSError **)outError;
+ (id)materialWithContentsOfURL:(NSURL *)URL error:(NSError **)outError;
+ (id)materialWithData:(NSData *)aData error:(NSError **)outError;

- (id)initWithContentsOfFile:(NSString *)aPath error:(NSError **)outError;
- (id)initWithContentsOfURL:(NSURL *)URL error:(NSError **)outError;
- (id)initWithData:(NSData *)aData error:(NSError **)outError;


- (NSDictionary *)dictionaryRepresentation;

- (NSString *)stringRepresentation;


@property (nonatomic, retain) TKVMTNode *rootNode;


@end
