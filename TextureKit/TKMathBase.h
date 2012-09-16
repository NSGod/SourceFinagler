//
//  TKMathBase.h
//  TextureKit
//
//  Created by Mark Douma on 12/7/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//


#import <TextureKit/TextureKitDefines.h>


TEXTUREKIT_INLINE float TKMathDegreesToRadians(float degrees) {
	return degrees * (M_PI / 180.0);
}

TEXTUREKIT_INLINE float TKMathRadiansToDegrees(float radians) {
	return radians * (180.0 / M_PI);
}

union _TKMatrix2 {
    struct {
        float m00, m01;
        float m10, m11;
    };
    float m2[2][2];
    float m[4];
};
typedef union _TKMatrix2 TKMatrix2;


TEXTUREKIT_INLINE NSString *NSStringFromMatrix2(TKMatrix2 matrix);


union _TKMatrix3 {
    struct {
        float m00, m01, m02;
        float m10, m11, m12;
        float m20, m21, m22;
    };
    float m[9];
};
typedef union _TKMatrix3 TKMatrix3;


/* m30, m31, and m32 correspond to the translation values tx, ty, and tz, respectively.
 m[12], m[13], and m[14] correspond to the translation values tx, ty, and tz, respectively.  */
union _TKMatrix4 {
    struct {
        float m00, m01, m02, m03;
        float m10, m11, m12, m13;
        float m20, m21, m22, m23;
        float m30, m31, m32, m33;
    };
    float m[16];
} __attribute__((aligned(16)));
typedef union _TKMatrix4 TKMatrix4;




union _TKVector2 {
    struct { float x, y; };
    struct { float s, t; };
    float v[2];
};
typedef union _TKVector2 TKVector2;
    

union _TKVector3 {
    struct { float x, y, z; };
    struct { float r, g, b; };
    struct { float s, t, p; };
	struct { float pitch, yaw, roll; };
	struct { float xRotation, yRotation, zRotation; };
    float v[3];
};
typedef union _TKVector3 TKVector3;


union _TKVector4 {
    struct { float x, y, z, w; };
    struct { float r, g, b, a; };
    struct { float s, t, p, q; };
    float v[4];
} __attribute__((aligned(16)));

typedef union _TKVector4 TKVector4;


/*
 x, y, and z represent the imaginary values.
 Vector v represents the imaginary values.
 q[0], q[1], and q[2] represent the imaginary values.
 */

union _TKQuaternion {
    struct { TKVector3 v; float s; };
    struct { float x, y, z, w; };
    float q[4];
} __attribute__((aligned(16)));

typedef union _TKQuaternion TKQuaternion;


TEXTUREKIT_INLINE NSString *NSStringFromMatrix2(TKMatrix2 matrix) {
	return [NSString stringWithFormat:@"[%0.4f, %0.4f,\n%0.4f, %0.4f\n]", matrix.m00, matrix.m01, matrix.m10, matrix.m11];
}


