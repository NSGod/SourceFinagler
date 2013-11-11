//
//  TKMaterialPropertyViewController.m
//  Source Finagler
//
//  Created by Mark Douma on 10/6/2012.
//
//

#import "TKMaterialPropertyViewController.h"
#import <SceneKit/SceneKit.h>




#define TK_DEBUG 1




@implementation TKMaterialPropertyViewController


- (id)init {
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])) {
		
		
	}
	return self;
}


- (void)setRepresentedObject:(id)representedObject {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super setRepresentedObject:representedObject];
	
	SCNMaterialProperty *materialProperty = (SCNMaterialProperty *)representedObject;
	
	if ([materialProperty.contents isKindOfClass:[NSImage class]]) {
		imageView.image = materialProperty.contents;
		
	} else if ([materialProperty.contents isKindOfClass:[NSColor class]]) {
		
		
		
	}
}








@end





