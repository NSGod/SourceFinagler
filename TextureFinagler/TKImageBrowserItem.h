//
//  TKImageBrowserItem.h
//  Source Finagler
//
//  Created by Mark Douma on 10/10/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TKImageRep;

enum {
	TKFaceBrowserItemType = 0,
	TKFrameBrowserItemType,
	TKPlaceholderBrowserItemType
};
typedef NSUInteger TKBrowserItemType;


@interface TKImageBrowserItem : NSObject {
	TKImageRep			*imageRep;
	TKBrowserItemType	type;
}

+ (NSArray *)faceBrowserItemsWithImageRepsInArray:(NSArray *)imageReps;
+ (id)faceBrowserItemWithImageRep:(TKImageRep *)anImageRep;

+ (NSArray *)frameBrowserItemsWithImageRepsInArray:(NSArray *)imageReps;
+ (id)frameBrowserItemWithImageRep:(TKImageRep *)anImageRep;

- (id)initWithImageRep:(TKImageRep *)anImageRep type:(TKBrowserItemType)aType;

@property (retain) TKImageRep *imageRep;
@property (assign) TKBrowserItemType type;


- (NSString *)imageUID;

- (NSString *)imageRepresentationType;

- (id)imageRepresentation;

- (NSString *)imageTitle;

- (BOOL)isSelectable;



@end
