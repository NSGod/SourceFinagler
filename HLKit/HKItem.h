//
//  HKItem.h
//  HLKit
//
//  Created by Mark Douma on 11/20/2009.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

//  Based, in part, on "TreeNode":

/*
    TreeNode.m
    Copyright (c) 2001-2006, Apple Computer, Inc., all rights reserved.
    Author: Chuck Pisula

    Milestones:
    * 03-01-2001: Initial creation by Chuck Pisula
    * 02-17-2006: Cleaned up the code. Corbin Dunn.

    Generic Tree node structure (TreeNode).
    
    TreeNode is a node in a doubly linked tree data structure.  TreeNode's have weak references to their parent (to avoid retain 
    cycles since parents retain their children).  Each node has 0 or more children and a reference to a piece of node data. The TreeNode provides method to manipulate and extract structural information about a tree.  For instance, TreeNode implements: insertChild:atIndex:, removeChild:, isDescendantOfNode:, and other useful operations on tree nodes.
    TreeNode provides the structure and common functionality of trees and is expected to be subclassed.
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import <HLKit/HKNode.h>
#import <HLKit/HLKitDefines.h>


enum {
	HKErrorNotExtractable = 1
};

enum {
	HKFileTypeNone				= 0,
	HKFileTypeHTML				= 1,
	HKFileTypeText				= 2,
	HKFileTypeImage				= 3,
	HKFileTypeSound				= 4,
	HKFileTypeMovie				= 5,
	HKFileTypeOther				= 6,
	HKFileTypeNotExtractable	= 7
};
typedef NSUInteger HKFileType;


HLKIT_EXTERN NSString * const HKErrorDomain;
HLKIT_EXTERN NSString * const HKErrorMessageKey;
HLKIT_EXTERN NSString * const HKSystemErrorMessageKey;


@interface HKItem : HKNode {
	NSString			*name;
	NSString			*nameExtension;
	NSString			*kind;
	NSNumber			*size;
	
	NSString			*path;
	
	// for images
	NSString			*dimensions;
	NSString			*version;
	NSString			*compression;
	NSString			*hasAlpha;
	NSString			*hasMipmaps;
	
	
	NSString			*type; // UTI
	HKFileType			fileType;
	
	BOOL				isExtractable;
	BOOL				isEncrypted;
	
}

+ (NSImage *)iconForItem:(HKItem *)anItem;
+ (NSImage *)copiedImageForItem:(HKItem *)anItem;

- (BOOL)writeToFile:(NSString *)aPath assureUniqueFilename:(BOOL)assureUniqueFilename resultingPath:(NSString **)resultingPath error:(NSError **)outError;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *nameExtension;
@property (nonatomic, retain) NSString *kind;
@property (nonatomic, retain) NSNumber *size;

@property (nonatomic, retain) NSString *path;

@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *dimensions;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSString *compression;
@property (nonatomic, retain, setter=setAlpha:) NSString *hasAlpha;
@property (nonatomic, retain) NSString *hasMipmaps;

@property (nonatomic, assign, setter=setExtractable:) BOOL isExtractable;
@property (nonatomic, assign, setter=setEncrypted:) BOOL isEncrypted;
@property (nonatomic, assign) HKFileType fileType;


- (NSString *)pathRelativeToItem:(HKItem *)anItem;

- (NSArray *)descendants;
- (NSArray *)visibleDescendants;

//- (id)parentFromArray:(NSArray *)array;
//- (NSIndexPath *)indexPathInArray:(NSArray *)array;

@end


