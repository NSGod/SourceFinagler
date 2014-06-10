//
//  TKImageBrowserItem.m
//  Source Finagler
//
//  Created by Mark Douma on 10/10/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageBrowserItem.h"
#import <TextureKit/TextureKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import "TKImageRepAdditions.h"



#define TK_DEBUG 1

@interface TKImageBrowserItem (TKPrivate)
+ (id)placeholderBrowserItemWithSize:(NSSize)aSize;
@end

@interface TKImageRep (TKImageBrowserItemAdditions)
+ (id)emptyImageRepWithSize:(NSSize)aSize;
@end


static NSMutableDictionary	*placeholderImageBrowserItemsAndSizes = nil;


@implementation TKImageBrowserItem

@synthesize imageRep;
@synthesize type;


+ (void)initialize {
	@synchronized(self) {
		if (placeholderImageBrowserItemsAndSizes == nil) placeholderImageBrowserItemsAndSizes = [[NSMutableDictionary alloc] init];
	}
}


+ (NSArray *)faceBrowserItemsWithImageRepsInArray:(NSArray *)imageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	TKImageRep *largestImageRep = [TKImageRep largestRepresentationInArray:imageReps];
	
	NSSize largestSize = [largestImageRep size];
	
	TKImageBrowserItem *rightFaceItem = [[self class] faceBrowserItemWithImageRep:[TKImageRep imageRepForFace:TKFaceRight
																						   ofImageRepsInArray:imageReps]];
	
	TKImageBrowserItem *leftFaceItem = [[self class] faceBrowserItemWithImageRep:[TKImageRep imageRepForFace:TKFaceLeft
																						  ofImageRepsInArray:imageReps]];
	
	TKImageBrowserItem *backFaceItem = [[self class] faceBrowserItemWithImageRep:[TKImageRep imageRepForFace:TKFaceBack
																						  ofImageRepsInArray:imageReps]];
	
	TKImageBrowserItem *frontFaceItem = [[self class] faceBrowserItemWithImageRep:[TKImageRep imageRepForFace:TKFaceFront
																						   ofImageRepsInArray:imageReps]];
	
	TKImageBrowserItem *upFaceItem = [[self class] faceBrowserItemWithImageRep:[TKImageRep imageRepForFace:TKFaceUp
																						  ofImageRepsInArray:imageReps]];
	
	TKImageBrowserItem *downFaceItem = [[self class] faceBrowserItemWithImageRep:[TKImageRep imageRepForFace:TKFaceDown
																						  ofImageRepsInArray:imageReps]];
	
	TKImageBrowserItem *placeholderItem = [[self class] placeholderBrowserItemWithSize:largestSize];
	
	if (!(rightFaceItem && leftFaceItem && backFaceItem && frontFaceItem && upFaceItem && downFaceItem && placeholderItem)) {
		return nil;
	}
	
	return [NSArray arrayWithObjects:placeholderItem, backFaceItem, placeholderItem, placeholderItem,
									leftFaceItem, upFaceItem, rightFaceItem, downFaceItem,
									placeholderItem, frontFaceItem, placeholderItem, placeholderItem, nil];
}


+ (id)faceBrowserItemWithImageRep:(TKImageRep *)anImageRep {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[[[self class] alloc] initWithImageRep:anImageRep type:TKFaceBrowserItemType] autorelease];
}


+ (id)placeholderBrowserItemWithSize:(NSSize)aSize {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	TKImageBrowserItem *placeholderBrowserItem = nil;
	@synchronized(placeholderImageBrowserItemsAndSizes) {
		placeholderBrowserItem = [[placeholderImageBrowserItemsAndSizes objectForKey:NSStringFromSize(aSize)] retain];
		if (placeholderBrowserItem == nil) {
			TKImageRep *emptyImageRep = [TKImageRep emptyImageRepWithSize:aSize];
			placeholderBrowserItem = [[[self class] alloc] initWithImageRep:emptyImageRep type:TKPlaceholderBrowserItemType];
			[placeholderImageBrowserItemsAndSizes setObject:placeholderBrowserItem forKey:NSStringFromSize(aSize)];
		}
	}
	return [placeholderBrowserItem autorelease];
}



+ (NSArray *)frameBrowserItemsWithImageRepsInArray:(NSArray *)imageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableArray *items = [NSMutableArray array];
	for (TKImageRep *tkImageRep in imageReps) {
		TKImageBrowserItem *browserItem = [[self class] frameBrowserItemWithImageRep:tkImageRep];
		if (browserItem) [items addObject:browserItem];
	}
	return [[items copy] autorelease];
}


+ (id)frameBrowserItemWithImageRep:(TKImageRep *)anImageRep {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[[[self class] alloc] initWithImageRep:anImageRep type:TKFrameBrowserItemType] autorelease];
}




- (id)initWithImageRep:(TKImageRep *)anImageRep type:(TKBrowserItemType)aType {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		imageRep = [anImageRep retain];
		type = aType;
	}
	return self;
}


- (void)dealloc {
	[imageRep release];
	[super dealloc];
}


- (NSString *)imageUID {
	return [imageRep imageUID];
}

- (NSString *)imageRepresentationType {
	return [imageRep imageRepresentationType];
}

- (id)imageRepresentation {
	return [imageRep imageRepresentation];
}

- (NSString *)imageTitle {
	switch (type) {
			
		case TKPlaceholderBrowserItemType :
		case TKFaceBrowserItemType :
			return nil;
			
		case TKFrameBrowserItemType :
			return [NSString stringWithFormat:@"%lu", (unsigned long)[imageRep frameIndex] + 1];
			
		default:
			return nil;
	}
	return nil;
}


- (BOOL)isSelectable {
	return !(type == TKPlaceholderBrowserItemType);
}


@end


@implementation TKImageRep (TKImageBrowserItemAdditions)

+ (id)emptyImageRepWithSize:(NSSize)aSize {
#if TK_DEBUG
	NSLog(@"[%@ %@] size == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromSize(aSize));
#endif
	NSMutableData *mData = [[NSMutableData alloc] initWithLength: aSize.width * aSize.height * 4];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)mData);
	[mData release];
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGImageRef imageRef = CGImageCreate(aSize.width,
										aSize.height,
										8,
										32,
										aSize.width * 4,
										colorSpace,
										kCGImageAlphaLast,
										provider,
										NULL,
										false,
										kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorSpace);
	CGDataProviderRelease(provider);
	TKImageRep *emptyImageRep = [[[[self class] alloc] initWithCGImage:imageRef] autorelease];
	CGImageRelease(imageRef);
	return emptyImageRep;
}

@end



