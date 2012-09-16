//
//  TKValueAdditions.m
//  TextureKit
//
//  Created by Mark Douma on 12/7/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKValueAdditions.h>
#import <objc/runtime.h>



//#define _C_VECTOR2			'2'
//#define _C_VECTOR3			'3'
//#define _C_VECTOR4			'4'
//
//#define _C_MATRIX2			'5'
//#define _C_MATRIX3			'6'
//#define _C_MATRIX4			'7'



@implementation NSValue (TKValueAdditions)


+ (NSValue *)valueWithVector2:(TKVector2)vector2 {
	return [NSValue valueWithBytes:&vector2 objCType:@encode(TKVector2)];
}

- (TKVector2)vector2Value {
	const char *objCType = @encode(TKVector2);
	if ([[NSString stringWithUTF8String:[self objCType]] isEqualToString:[NSString stringWithUTF8String:objCType]]) {
		TKVector2 vector2;
		[self getValue:&vector2];
		return vector2;
	}
	NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:@"not a valid TKVector2" userInfo:nil];
	[exception raise];
	return TKVector2Make(0.0, 0.0);
}


+ (NSValue *)valueWithVector3:(TKVector3)vector3 {
	return [NSValue valueWithBytes:&vector3 objCType:@encode(TKVector3)];
}


- (TKVector3)vector3Value {
	const char *objCType = @encode(TKVector3);
	if ([[NSString stringWithUTF8String:[self objCType]] isEqualToString:[NSString stringWithUTF8String:objCType]]) {
		TKVector3 vector3;
		[self getValue:&vector3];
		return vector3;
	}
	NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:@"not a valid TKVector3" userInfo:nil];
	[exception raise];
	return TKVector3Make(0.0, 0.0, 0.0);
}


+ (NSValue *)valueWithVector4:(TKVector4)vector4 {
	return [NSValue valueWithBytes:&vector4 objCType:@encode(TKVector4)];
}


- (TKVector4)vector4Value {
	const char *objCType = @encode(TKVector4);
	if ([[NSString stringWithUTF8String:[self objCType]] isEqualToString:[NSString stringWithUTF8String:objCType]]) {
		TKVector4 vector4;
		[self getValue:&vector4];
		return vector4;
	}
	NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:@"not a valid TKVector4" userInfo:nil];
	[exception raise];
	return TKVector4Make(0.0, 0.0, 0.0, 0.0);
}



+ (NSValue *)valueWithMatrix2:(TKMatrix2)matrix2 {
	return [NSValue valueWithBytes:&matrix2 objCType:@encode(TKMatrix2)];
}


- (TKMatrix2)matrix2Value {
	const char *objCType = @encode(TKMatrix2);
	if ([[NSString stringWithUTF8String:[self objCType]] isEqualToString:[NSString stringWithUTF8String:objCType]]) {
		TKMatrix2 matrix2;
		[self getValue:&matrix2];
		return matrix2;
	}
	NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:@"not a valid TKMatrix2" userInfo:nil];
	[exception raise];
	return TKMatrix3GetMatrix2(TKMatrix3Identity);

}



+ (NSValue *)valueWithMatrix3:(TKMatrix3)matrix3 {
	return [NSValue valueWithBytes:&matrix3 objCType:@encode(TKMatrix3)];
}


- (TKMatrix3)matrix3Value {
	const char *objCType = @encode(TKMatrix3);
	if ([[NSString stringWithUTF8String:[self objCType]] isEqualToString:[NSString stringWithUTF8String:objCType]]) {
		TKMatrix3 matrix3;
		[self getValue:&matrix3];
		return matrix3;
	}
	NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:@"not a valid TKMatrix3" userInfo:nil];
	[exception raise];
	return TKMatrix3Identity;
}


+ (NSValue *)valueWithMatrix4:(TKMatrix4)matrix4 {
	return [NSValue valueWithBytes:&matrix4 objCType:@encode(TKMatrix4)];
}

- (TKMatrix4)matrix4Value {
	const char *objCType = @encode(TKMatrix4);
	if ([[NSString stringWithUTF8String:[self objCType]] isEqualToString:[NSString stringWithUTF8String:objCType]]) {
		TKMatrix4 matrix4;
		[self getValue:&matrix4];
		return matrix4;
	}
	NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:@"not a valid TKMatrix4" userInfo:nil];
	[exception raise];
	return TKMatrix4Identity;

}



@end

