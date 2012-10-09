//
//  TKImageRepAdditions.m
//  Source Finagler
//
//  Created by Mark Douma on 10/6/2012.
//
//


#import "TKImageRepAdditions.h"
#import <Quartz/Quartz.h>


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


- (NSDictionary *)imageProperties {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	CGImageRef imageRef = [self CGImage];
	CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
	CGImageSourceRef imageSource = CGImageSourceCreateWithDataProvider(provider, NULL);
	
	NSDictionary *imageProperties = [(NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL) autorelease];
	NSLog(@"[%@ %@] imageProperties == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageProperties);
	CFRelease(imageSource);
	
//	NSMutableDictionary *imageProperties = [NSMutableDictionary dictionary];
//	[imageProperties setObject:[NSNumber numberWithInteger:(NSInteger)[self size].width] forKey:(NSString *)kCGImagePropertyPixelWidth];
//	[imageProperties setObject:[NSNumber numberWithInteger:(NSInteger)[self size].height] forKey:(NSString *)kCGImagePropertyPixelHeight];
//	[imageProperties setObject:[NSNumber numberWithBool:[self hasAlpha]] forKey:(NSString *)kCGImagePropertyHasAlpha];
//	[imageProperties setObject:(NSString *)kCGImagePropertyColorModelRGB forKey:(NSString *)kCGImagePropertyColorModel];
	
	return imageProperties;
}



@end


