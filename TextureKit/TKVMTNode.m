//
//  TKNode.m
//  Texture Kit
//
//  Created by Mark Douma on 11/22/2011.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKVMTNode.h>


#define TK_DEBUG 1


@implementation TKVMTNode

@synthesize container;
@synthesize parent;
@synthesize name;
@synthesize objectValue;
@synthesize leaf;



- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        
		
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {

}


- (id)copyWithZone:(NSZone *)zone {
	TKVMTNode *copy = nil;
	
}



- (void)dealloc {
    [children release];
	[name release];
	[objectValue release];
    [super dealloc];
}








@end
