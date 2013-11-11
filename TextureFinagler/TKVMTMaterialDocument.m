//
//  TKVMTMaterialDocument.m
//  Source Finagler
//
//  Created by Mark Douma on 1/10/2012.
//  Copyright (c) 2012 Mark Douma LLC. All rights reserved.
//

#import "TKVMTMaterialDocument.h"
#import <TextureKit/TextureKit.h>


#define TK_DEBUG 1




static NSMutableDictionary *materialAttributes = nil;



@implementation TKVMTMaterialDocument


@synthesize material;

@synthesize materialString;


+ (void)initialize {
	@synchronized(self) {
		if (materialAttributes == nil) {
			materialAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName, nil];
		}
	}
}



- (id)init {
    if ((self = [super init])) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, return nil.
    }
    return self;
}


- (void)dealloc {
    [material release];
    [super dealloc];
}


- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"TKVMTMaterialDocument";
}



- (BOOL)readFromURL:(NSURL *)absURL ofType:(NSString *)typeName error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
#endif
	
	material = [[TKVMTMaterial alloc] initWithContentsOfURL:absURL error:outError];
	
	NSString *vmtString = [NSString stringWithContentsOfURL:absURL usedEncoding:NULL error:outError];
	
	if (vmtString == nil) {
		
		
		return material != nil;
	}
	
	
	materialString = [[NSMutableAttributedString alloc] initWithString:vmtString attributes:materialAttributes];
	
	
	return material != nil;
}



- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
#endif
	
	
	
	
	return NO;
}



- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	
	
#if TK_DEBUG
	NSLog(@"[%@ %@] material == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), material);
#endif
	
	
}



//- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
//    /*
//     Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
//    You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
//    */
//    if (outError) {
//        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
//    }
//    return nil;
//}
//
//- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
//    /*
//    Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
//    You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
//    If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
//    */
//    if (outError) {
//        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
//    }
//    return YES;
//}

+ (BOOL)autosavesInPlace {
    return YES;
}

@end
