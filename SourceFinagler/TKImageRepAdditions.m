//
//  TKImageRepAdditions.m
//  Source Finagler
//
//  Created by Mark Douma on 10/6/2012.
//
//


#import "TKImageRepAdditions.h"
#import <Quartz/Quartz.h>

#define TK_DEBUG 0


@implementation TKImageRep (IKImageBrowserItem)


- (NSString *)imageUID {
	return [NSString stringWithFormat:@"%lu", (unsigned long)[self hash]];
}


- (NSString *)imageRepresentationType {
	return IKImageBrowserNSBitmapImageRepresentationType;
}

- (id)imageRepresentation {
	return self;
}

- (NSString *)imageTitle {
	return [NSString stringWithFormat:@"%lupx x %lupx", (unsigned long)[self size].width, (unsigned long)[self size].height];
}


@end


