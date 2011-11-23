//
//  TKNode.h
//  Texture Kit
//
//  Created by Mark Douma on 11/22/2011.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Foundation/NSObject.h>
#import <TextureKit/TextureKitDefines.h>




@interface TKVMTNode : NSObject <NSCoding, NSCopying> {
	id					container;		// not retained
	TKVMTNode				*parent;		// non retained
	NSMutableArray		*children;
	
	NSString			*name;
	id					objectValue;
	
	BOOL				leaf;

}





@property (readonly, nonatomic, assign) id container;
@property (readonly, nonatomic, assign) TKVMTNode *parent;


@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) id objectValue;

@property (readonly, nonatomic, assign, getter=isLeaf) BOOL leaf;


@end



