//
//  TKVMTNode.m
//  Texture Kit
//
//  Created by Mark Douma on 11/22/2011.
//  Copyright (c) 2010-2013 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKVMTNode.h>
#import <Foundation/Foundation.h>


#define TK_DEBUG 1


typedef struct TKVMTNodeKindMapping {
	TKVMTNodeKind	kind;
	NSString		*description;
} TKVMTNodeKindMapping;

static const TKVMTNodeKindMapping TKVMTNodeKindMappingTable[] = {
	{TKVMTInvalidKind,	@"TKVMTInvalidKind" },
	{TKVMTGroupKind,	@"TKVMTGroupKind" },
	{TKVMTCommentKind,	@"TKVMTCommentKind" },
	{TKVMTStringKind,	@"TKVMTStringKind" },
	{TKVMTIntegerKind,	@"TKVMTIntegerKind" },
	{TKVMTFloatKind,	@"TKVMTFloatKind" }
};
static const NSUInteger TKVMTNodeKindMappingTableCount = sizeof(TKVMTNodeKindMappingTable)/sizeof(TKVMTNodeKindMappingTable[0]);

static inline NSString *NSStringFromTKVMTNodeKind(TKVMTNodeKind kind) {
	for (NSUInteger i = 0; i < TKVMTNodeKindMappingTableCount; i++) {
		if (TKVMTNodeKindMappingTable[i].kind == kind) {
			return TKVMTNodeKindMappingTable[i].description;
		}
	}
	return @"<Unknown>";
}









@interface TKVMTNode ()

@property (nonatomic, assign) TKVMTNode *rootNode;
@property (nonatomic, assign) TKVMTNode *parent;
@property (nonatomic, assign, getter=isLeaf) BOOL leaf;

@end




@interface TKVMTNode (TKPrivate)

//- (id)initWithString:(NSString *)string error:(NSError **)outError;
//
//- (BOOL)parseNodeString:(NSString *)string error:(NSError **)outError;



- (void)setChildren:(NSArray *)anArray;

@end



@implementation TKVMTNode

@synthesize rootNode;
@synthesize parent;
@synthesize name;
@synthesize objectValue;
@synthesize leaf;
@synthesize kind;
@synthesize index;
@synthesize level;


//+ (id)nodeWithData:(NSData *)data error:(NSError **)outError {
//	return [[[[self class] alloc] initWithData:data error:outError] autorelease];
//}
//
//
//- (id)initWithData:(NSData *)data error:(NSError **)outError {
//	return [self initWithString:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease] error:outError];
//}
//
//
//- (id)initWithString:(NSString *)string error:(NSError **)outError {
//	NSParameterAssert(string != nil);
//	if ((self = [super init])) {
//		if (![self parseNodeString:string error:outError]) {
//			
//		}
//	}
//	return self;
//}


+ (id)nodeWithName:(NSString *)aName kind:(TKVMTNodeKind)aKind objectValue:(id)anObjectValue {
	return [[[[self class] alloc] initWithName:aName kind:aKind objectValue:anObjectValue] autorelease];
}


+ (id)stringNodeWithName:(NSString *)aName stringValue:(NSString *)stringValue {
	return [[[[self class] alloc] initWithName:aName kind:TKVMTStringKind objectValue:stringValue] autorelease];
}

+ (id)integerNodeWithName:(NSString *)aName integerValue:(NSInteger)anInteger {
	return [[[[self class] alloc] initWithName:aName kind:TKVMTIntegerKind objectValue:[NSNumber numberWithInteger:anInteger]] autorelease];
}

+ (id)floatNodeWithName:(NSString *)aName floatValue:(CGFloat)aFloat {
	return [[[[self class] alloc] initWithName:aName kind:TKVMTFloatKind objectValue:[NSNumber numberWithDouble:aFloat]] autorelease];
}

+ (id)commentNodeWithStringValue:(NSString *)stringValue {
	return [[[[self class] alloc] initWithName:nil kind:TKVMTCommentKind objectValue:stringValue] autorelease];
}

+ (id)groupNodeWithName:(NSString *)aName {
	return [[[[self class] alloc] initWithName:aName kind:TKVMTGroupKind objectValue:nil] autorelease];
}


- (id)initWithName:(NSString *)aName kind:(TKVMTNodeKind)aKind objectValue:(id)anObjectValue {
	if ((self = [super init])) {
		self.name = aName;
		self.objectValue = anObjectValue;
		self.kind = aKind;
		if (kind == TKVMTGroupKind) {
			children = [[NSMutableArray alloc] init];
		}
		
	}
	return self;
}


- (id)copyWithZone:(NSZone *)zone {
	TKVMTNode *copy = [[[self class] alloc] init];
	copy->children = nil;
	copy->name = nil;
	copy->objectValue = nil;
	[copy setChildren:children];
	[copy setName:name];
	[copy setObjectValue:objectValue];
	return copy;
}

- (void)dealloc {
    [children release];
	[name release];
	[objectValue release];
    [super dealloc];
}


- (NSUInteger)countOfChildren {
	return [children count];
}

- (TKVMTNode *)childAtIndex:(NSUInteger)anIndex {
	return [children objectAtIndex:anIndex];
}


- (void)insertChild:(TKVMTNode *)aChild atIndex:(NSUInteger)anIndex {
	[aChild setParent:self];
	[aChild setRootNode:rootNode];
	[children insertObject:aChild atIndex:anIndex];
}


- (NSArray *)children {
	return [[children copy] autorelease];
}


- (void)setChildren:(NSArray *)anArray {
	if (children == nil) children = [[NSMutableArray alloc] init];
	[children setArray:anArray];
}

- (void)addChild:(TKVMTNode *)aChild {
	[self insertChild:aChild atIndex:[children count]];
}


- (void)tk__removeChildrenIdenticalTo:(NSArray *)theChildren {
	[theChildren makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
	for (TKVMTNode *child in theChildren) {
		[children removeObjectIdenticalTo:child];
	}
}


- (void)removeChild:(TKVMTNode *)aChild {
	NSUInteger cIndex = [children indexOfObject:aChild];
	if (cIndex != NSNotFound) {
		[self tk__removeChildrenIdenticalTo:[NSArray arrayWithObject:[self childAtIndex:cIndex]]];
	}
}

- (void)removeAllChildren {
	
}


- (NSString *)stringRepresentation {
	return nil;
}


- (NSString *)stringValue {
	return nil;
}

- (NSInteger)integerValue {
	return 0;
}

- (CGFloat)floatValue {
	return 0.0;
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@\n", [super description]];
	if (kind == TKVMTGroupKind) {
		[description appendFormat:@"	%@\n", name];
		[description appendFormat:@"			%@\n", children];
		
	} else {
		[description appendFormat:@"	%@		%@\n", name, objectValue];
		
	}
	return description;
}



@end




