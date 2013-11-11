//
//  TKVMTNode.h
//  Texture Kit
//
//  Created by Mark Douma on 11/22/2011.
//  Copyright (c) 2010-2013 Mark Douma LLC. All rights reserved.
//

#import <Foundation/NSObject.h>
#import <TextureKit/TextureKitDefines.h>


enum {
	TKVMTInvalidKind	= 0,
	TKVMTGroupKind,
	TKVMTCommentKind,
	TKVMTStringKind,
	TKVMTIntegerKind,
	TKVMTFloatKind,
//	TKVMTRootKind
};
typedef NSUInteger TKVMTNodeKind;



@interface TKVMTNode : NSObject <NSCopying> {
	TKVMTNode			*rootNode;		// non-retained
	
	TKVMTNode			*parent;		// non-retained
	
	NSMutableArray		*children;
	
	NSString			*name;
	id					objectValue;
	
	TKVMTNodeKind		kind;
	
	NSUInteger			index;
	
	NSUInteger			level;
	
	BOOL				leaf;

}

+ (id)nodeWithName:(NSString *)aName kind:(TKVMTNodeKind)aKind objectValue:(id)anObjectValue;
- (id)initWithName:(NSString *)aName kind:(TKVMTNodeKind)aKind objectValue:(id)anObjectValue;

+ (id)groupNodeWithName:(NSString *)aName;
+ (id)commentNodeWithStringValue:(NSString *)stringValue;
+ (id)stringNodeWithName:(NSString *)aName stringValue:(NSString *)stringValue;
+ (id)integerNodeWithName:(NSString *)aName integerValue:(NSInteger)anInteger;
+ (id)floatNodeWithName:(NSString *)aName floatValue:(CGFloat)aFloat;



@property (readonly, nonatomic, assign) TKVMTNode *rootNode;
@property (readonly, nonatomic, assign) TKVMTNode *parent;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) id objectValue;

@property (nonatomic, assign) TKVMTNodeKind kind;

@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) NSUInteger level;

@property (readonly, nonatomic, assign, getter=isLeaf) BOOL leaf;


- (NSArray *)children;

- (NSUInteger)countOfChildren;

- (TKVMTNode *)childAtIndex:(NSUInteger)anIndex;

- (void)insertChild:(TKVMTNode *)aChild atIndex:(NSUInteger)anIndex;

- (void)addChild:(TKVMTNode *)aChild;

- (void)removeChild:(TKVMTNode *)aChild;

- (void)removeAllChildren;


- (NSString *)stringRepresentation;

- (NSString *)stringValue;

- (NSInteger)integerValue;

- (CGFloat)floatValue;


@end



