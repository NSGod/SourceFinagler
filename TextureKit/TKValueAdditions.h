//
//  TKValueAdditions.h
//  TextureKit
//
//  Created by Mark Douma on 12/7/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <Foundation/NSValue.h>
#import <TextureKit/TKMatrix3.h>
#import <TextureKit/TKMatrix4.h>
#import <TextureKit/TKVector2.h>
#import <TextureKit/TKVector3.h>
#import <TextureKit/TKVector4.h>


@interface NSValue (TKValueAdditions)


+ (NSValue *)valueWithVector2:(TKVector2)vector2;
- (TKVector2)vector2Value;

+ (NSValue *)valueWithVector3:(TKVector3)vector3;
- (TKVector3)vector3Value;

+ (NSValue *)valueWithVector4:(TKVector4)vector4;
- (TKVector4)vector4Value;




+ (NSValue *)valueWithMatrix2:(TKMatrix2)matrix2;
- (TKMatrix2)matrix2Value;


+ (NSValue *)valueWithMatrix3:(TKMatrix3)matrix3;
- (TKMatrix3)matrix3Value;


+ (NSValue *)valueWithMatrix4:(TKMatrix4)matrix4;
- (TKMatrix4)matrix4Value;



@end

