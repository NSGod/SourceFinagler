//
//  MDCopyOperation.m
//  Source Finagler
//
//  Created by Mark Douma on 9/7/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDCopyOperation.h"


NSString * const MDCopyOperationKey						= @"MDCopyOperation";
NSString * const MDCopyOperationDestinationKey			= @"MDCopyOperationDestination";
NSString * const MDCopyOperationTotalBytesKey			= @"MDCopyOperationTotalBytes";
NSString * const MDCopyOperationCurrentBytesKey			= @"MDCopyOperationCurrentBytes";

NSString * const MDCopyOperationTotalItemCountKey		= @"MDCopyOperationTotalItemCount";
NSString * const MDCopyOperationCurrentItemIndexKey		= @"MDCopyOperationCurrentItemIndex";

NSString * const MDCopyOperationTagKey					= @"MDCopyOperationTag";

NSString * const MDCopyOperationStageKey				= @"MDCopyOperationStage";


#define MD_DEBUG 0

@implementation MDCopyOperation

@synthesize indeterminate, messageText, icon, source, destination, tag, itemsAndPaths, zeroBytes, currentBytes, totalBytes, isRolledOver, isCancelled;
@dynamic informativeText;

+ (id)operationWithSource:(MDHLDocument *)aSource destination:(id)aDestination itemsAndPaths:(NSDictionary *)anItemsAndPaths tag:(NSInteger)aTag {
	return [[[[self class] alloc] initWithSource:aSource destination:aDestination itemsAndPaths:anItemsAndPaths tag:aTag] autorelease];
}


- (id)initWithSource:(MDHLDocument *)aSource destination:(id)aDestination itemsAndPaths:(NSDictionary *)anItemsAndPaths tag:(NSInteger)aTag {
	if ((self = [super init])) {
		
		icon = [[NSImage imageNamed:NSImageNameMultipleDocuments] retain];
		
		source = aSource;
		destination = [aDestination retain];
		tag = aTag;
		itemsAndPaths = [anItemsAndPaths retain];
		
		[self setIndeterminate:YES];
	}
	return self;
}


- (void)dealloc {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[messageText release];
	[informativeText release];
	[icon release];
	[destination release];
	[itemsAndPaths release];
	[super dealloc];
}


- (NSString *)informativeText {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return (isRolledOver ? NSLocalizedString(@"Stop copying", @"") : informativeText);
}


- (void)setInformativeText:(NSString *)text {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	@synchronized(self) {
		NSString *copy = [text copy];
		[informativeText release];
		informativeText = copy;
	}
}


@end



