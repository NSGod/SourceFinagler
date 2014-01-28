//
//  TKImageChannel.h
//  Source Finagler
//
//  Created by Mark Douma on 10/24/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class TKImageRep;

enum {
	TKImageChannelRedMask		= 1 << 0,
	TKImageChannelGreenMask		= 1 << 1,
	TKImageChannelBlueMask		= 1 << 2,
	TKImageChannelAlphaMask		= 1 << 3,
	TKImageChannelRGBAMask		= TKImageChannelRedMask | TKImageChannelGreenMask | TKImageChannelBlueMask | TKImageChannelAlphaMask
};
typedef NSUInteger TKImageChannelMask;



@interface TKImageChannel : NSObject {
	NSString				*name;
	NSImage					*image;
	TKImageChannelMask		channelMask;
	CIFilter				*filter;
	BOOL					enabled;
}

+ (NSArray *)imageChannelsWithImageRep:(TKImageRep *)anImageRep;


+ (id)imageChannelWithImageRep:(TKImageRep *)anImageRep channelMask:(TKImageChannelMask)aChannelMask;

- (id)initWithImageRep:(TKImageRep *)anImageRep channelMask:(TKImageChannelMask)aChannelMask;


@property (retain) NSString *name;
@property (retain) NSImage *image;
@property (assign) TKImageChannelMask channelMask;
@property (assign) BOOL enabled;
@property (retain) CIFilter *filter;


- (void)updateWithImageRep:(TKImageRep *)anImageRep;


@end



@interface CIFilter (TKImageChannelAdditions)

+ (CIFilter *)filterForChannelMask:(TKImageChannelMask)aChannelMask;

@end


