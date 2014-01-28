//
//  TKVMTMaterialDocument.h
//  Source Finagler
//
//  Created by Mark Douma on 1/10/2012.
//  Copyright (c) 2012 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TKVMTMaterial;


@interface TKVMTMaterialDocument : NSDocument {
	IBOutlet NSWindow				*vmtWindow;
	IBOutlet NSTextView				*textView;
	
	
	TKVMTMaterial					*material;
	
	
	NSMutableAttributedString		*materialString;
	
}

@property (retain) TKVMTMaterial *material;

@property (retain) NSMutableAttributedString *materialString;



@end



