//
//  MDCopyOperation.h
//  Source Finagler
//
//  Created by Mark Douma on 9/7/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MDHLDocument.h"

extern NSString * const MDCopyOperationKey;
extern NSString * const MDCopyOperationDestinationKey;
extern NSString * const MDCopyOperationTotalBytesKey;
extern NSString * const MDCopyOperationCurrentBytesKey;
extern NSString * const MDCopyOperationTotalItemCountKey;
extern NSString * const MDCopyOperationCurrentItemIndexKey;
extern NSString * const MDCopyOperationTagKey;

extern NSString * const MDCopyOperationStageKey;

enum {
	MDCopyOperationPreparingStage		= 1,
	MDCopyOperationCopyingStage			= 2,
	MDCopyOperationFinishingStage		= 3,
	MDCopyOperationCancelledStage		= 4
};
typedef NSUInteger MDCopyOperationStage;



@interface MDCopyOperation : NSObject {
	
	double							zeroBytes;
	double							currentBytes;
	double							totalBytes;
	
	NSString						*messageText;
	NSString						*informativeText;
	
	NSImage							*icon;
	
	MDHLDocument					*source;
	id								destination; // can be MDHLDocument or an NSString (path)
	
	NSDictionary					*itemsAndPaths;
	
	NSInteger						tag;
	
	BOOL							isRolledOver;
	
	BOOL							indeterminate;
	
	BOOL							isCancelled;
}

+ (id)operationWithSource:(MDHLDocument *)aSource destination:(id)aDestination itemsAndPaths:(NSDictionary *)anItemsAndPaths tag:(NSInteger)aTag;

- (id)initWithSource:(MDHLDocument *)aSource destination:(id)aDestination itemsAndPaths:(NSDictionary *)anItemsAndPaths tag:(NSInteger)aTag;

@property (assign) BOOL indeterminate;
@property (assign, setter=setRolledOver:) BOOL isRolledOver;

@property (assign, setter=setCancelled:)	BOOL isCancelled;

@property (assign) double zeroBytes;
@property (assign) double currentBytes;
@property (assign) double totalBytes;


@property (copy) NSString *messageText;
@property (copy) NSString *informativeText;

@property (retain) NSImage *icon;

@property (readonly, assign) MDHLDocument *source;
@property (readonly, retain) id destination;
@property (readonly, retain) NSDictionary *itemsAndPaths;

@property (readonly, assign) NSInteger tag;


@end


