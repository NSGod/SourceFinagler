//
//  TKImageRepAdditions.h
//  Source Finagler
//
//  Created by Mark Douma on 10/6/2012.
//
//


#import <TextureKit/TextureKit.h>


@interface TKImageRep (IKImageBrowserItem)

- (NSString *)imageUID;					/* required */
- (NSString *)imageRepresentationType;	/* required */
- (id)imageRepresentation;				/* required */

- (NSString *)imageTitle;

//- (NSUInteger)imageVersion;
//- (NSString *)imageSubtitle;
//- (BOOL)isSelectable;

- (NSDictionary *)imageProperties;

@end


//@interface TKImageRep (IKImageProperties)
//- (NSDictionary *)imageProperties;
//@end




