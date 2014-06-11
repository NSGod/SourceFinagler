//
//  HKPrivateInterfaces.h
//  HLKit
//
//  Created by Mark Douma on 12/16/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <HL/HL.h>

#import <HLKit/HLKitDefines.h>
#import <HLKit/HKFolder.h>
#import <HLKit/HKFile.h>
#import <HLKit/HKArchiveFile.h>


using namespace HLLib;




@interface HKFolder (HKPrivateInterfaces)

- (id)initWithParent:(HKFolder *)aParent directoryFolder:(const CDirectoryFolder *)aFolder showInvisibleItems:(BOOL)showInvisibles sortDescriptors:(NSArray *)aSortDescriptors container:(id)aContainer;

@end


@interface HKFile (HKPrivateInterfaces)

- (id)initWithParent:(HKFolder *)aParent directoryFile:(const CDirectoryFile *)aFile container:(id)aContainer;

@end

@interface HKArchiveFile (HKPrivateInterfaces)

- (id)initWithContentsOfFile:(NSString *)aPath mode:(HLFileMode)permission showInvisibleItems:(BOOL)showInvisibleItems sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)outError;

@end
