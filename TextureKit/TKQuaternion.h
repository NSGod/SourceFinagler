//
//  TKQuaternion.h
//  TextureKit
//
//  Created by Mark Douma on 12/7/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKMathBase.h>
#import <TextureKit/TKVector3.h>
#import <TextureKit/TKVector4.h>


#pragma mark -
#pragma mark Prototypes
#pragma mark -


TEXTUREKIT_EXTERN const TKQuaternion TKQuaternionIdentity;


TEXTUREKIT_INLINE NSString *NSStringFromQuaternion(TKQuaternion quaternion);


/* x, y, and z represent the imaginary values. */
TEXTUREKIT_INLINE TKQuaternion TKQuaternionMake(float x, float y, float z, float w);


/* vector represents the imaginary values. */
TEXTUREKIT_INLINE TKQuaternion TKQuaternionMakeWithVector3(TKVector3 vector, float scalar);


/* values[0], values[1], and values[2] represent the imaginary values. */
TEXTUREKIT_INLINE TKQuaternion TKQuaternionMakeWithArray(float values[4]);


/* Assumes the axis is already normalized. */
TEXTUREKIT_INLINE TKQuaternion TKQuaternionMakeWithAngleAndAxis(float radians, float x, float y, float z);


/* Assumes the axis is already normalized. */
TEXTUREKIT_INLINE TKQuaternion TKQuaternionMakeWithAngleAndVector3Axis(float radians, TKVector3 axisVector);

TEXTUREKIT_EXTERN TKQuaternion TKQuaternionMakeWithMatrix3(TKMatrix3 matrix);
TEXTUREKIT_EXTERN TKQuaternion TKQuaternionMakeWithMatrix4(TKMatrix4 matrix);


/* Calculate and return the angle component of the angle and axis form. */
TEXTUREKIT_EXTERN float TKQuaternionAngle(TKQuaternion quaternion);


/* Calculate and return the axis component of the angle and axis form. */
TEXTUREKIT_EXTERN TKVector3 TKQuaternionAxis(TKQuaternion quaternion);


TEXTUREKIT_INLINE TKQuaternion TKQuaternionAdd(TKQuaternion quaternionLeft, TKQuaternion quaternionRight);
TEXTUREKIT_INLINE TKQuaternion TKQuaternionSubtract(TKQuaternion quaternionLeft, TKQuaternion quaternionRight);
TEXTUREKIT_INLINE TKQuaternion TKQuaternionMultiply(TKQuaternion quaternionLeft, TKQuaternion quaternionRight);

TEXTUREKIT_EXTERN TKQuaternion TKQuaternionSlerp(TKQuaternion quaternionStart, TKQuaternion quaternionEnd, float t);

TEXTUREKIT_INLINE float TKQuaternionLength(TKQuaternion quaternion);

TEXTUREKIT_INLINE TKQuaternion TKQuaternionConjugate(TKQuaternion quaternion);
TEXTUREKIT_INLINE TKQuaternion TKQuaternionInvert(TKQuaternion quaternion);
TEXTUREKIT_INLINE TKQuaternion TKQuaternionNormalize(TKQuaternion quaternion);

TEXTUREKIT_INLINE TKVector3 TKQuaternionRotateVector3(TKQuaternion quaternion, TKVector3 vector);
TEXTUREKIT_EXTERN void TKQuaternionRotateVector3Array(TKQuaternion quaternion, TKVector3 *vectors, size_t vectorCount);


/* The fourth component of the vector is ignored when calculating the rotation. */
TEXTUREKIT_INLINE TKVector4 TKQuaternionRotateVector4(TKQuaternion quaternion, TKVector4 vector);
TEXTUREKIT_EXTERN void TKQuaternionRotateVector4Array(TKQuaternion quaternion, TKVector4 *vectors, size_t vectorCount);
    
#pragma mark -
#pragma mark Implementations
#pragma mark -


TEXTUREKIT_INLINE NSString *NSStringFromQuaternion(TKQuaternion quaternion) {
	return [NSString stringWithFormat:@"{%0.4f, %0.4f, %0.4f}", quaternion.q[0], quaternion.q[1], quaternion.q[2]];
}


TEXTUREKIT_INLINE TKQuaternion TKQuaternionMake(float x, float y, float z, float w) {
    TKQuaternion q = { x, y, z, w };
    return q;
}

TEXTUREKIT_INLINE TKQuaternion TKQuaternionMakeWithVector3(TKVector3 vector, float scalar) {
    TKQuaternion q = { vector.v[0], vector.v[1], vector.v[2], scalar };
    return q;
}
    
TEXTUREKIT_INLINE TKQuaternion TKQuaternionMakeWithArray(float values[4]) {
    TKQuaternion q = { values[0], values[1], values[2], values[3] };
    return q;
}
    
TEXTUREKIT_INLINE TKQuaternion TKQuaternionMakeWithAngleAndAxis(float radians, float x, float y, float z) {
    float halfAngle = radians * 0.5f;
    float scale = sinf(halfAngle);
    TKQuaternion q = { scale * x, scale * y, scale * z, cosf(halfAngle) };
    return q;
}
    
TEXTUREKIT_INLINE TKQuaternion TKQuaternionMakeWithAngleAndVector3Axis(float radians, TKVector3 axisVector) {
    return TKQuaternionMakeWithAngleAndAxis(radians, axisVector.v[0], axisVector.v[1], axisVector.v[2]);
}
    
TEXTUREKIT_INLINE TKQuaternion TKQuaternionAdd(TKQuaternion quaternionLeft, TKQuaternion quaternionRight) {
    TKQuaternion q = { quaternionLeft.q[0] + quaternionRight.q[0],
                        quaternionLeft.q[1] + quaternionRight.q[1],
                        quaternionLeft.q[2] + quaternionRight.q[2],
                        quaternionLeft.q[3] + quaternionRight.q[3] };
    return q;
}

TEXTUREKIT_INLINE TKQuaternion TKQuaternionSubtract(TKQuaternion quaternionLeft, TKQuaternion quaternionRight) {
    TKQuaternion q = { quaternionLeft.q[0] - quaternionRight.q[0],
                        quaternionLeft.q[1] - quaternionRight.q[1],
                        quaternionLeft.q[2] - quaternionRight.q[2],
                        quaternionLeft.q[3] - quaternionRight.q[3] };
    return q;
}

TEXTUREKIT_INLINE TKQuaternion TKQuaternionMultiply(TKQuaternion quaternionLeft, TKQuaternion quaternionRight) {
    TKQuaternion q = { quaternionLeft.q[3] * quaternionRight.q[0] +
                        quaternionLeft.q[0] * quaternionRight.q[3] +
                        quaternionLeft.q[1] * quaternionRight.q[2] -
                        quaternionLeft.q[2] * quaternionRight.q[1],
        
                        quaternionLeft.q[3] * quaternionRight.q[1] +
                        quaternionLeft.q[1] * quaternionRight.q[3] +
                        quaternionLeft.q[2] * quaternionRight.q[0] -
                        quaternionLeft.q[0] * quaternionRight.q[2],
        
                        quaternionLeft.q[3] * quaternionRight.q[2] +
                        quaternionLeft.q[2] * quaternionRight.q[3] +
                        quaternionLeft.q[0] * quaternionRight.q[1] -
                        quaternionLeft.q[1] * quaternionRight.q[0],
        
                        quaternionLeft.q[3] * quaternionRight.q[3] -
                        quaternionLeft.q[0] * quaternionRight.q[0] -
                        quaternionLeft.q[1] * quaternionRight.q[1] -
                        quaternionLeft.q[2] * quaternionRight.q[2] };
    return q;
}
 
TEXTUREKIT_INLINE float TKQuaternionLength(TKQuaternion quaternion) {
    return sqrt(quaternion.q[0] * quaternion.q[0] + 
                quaternion.q[1] * quaternion.q[1] +
                quaternion.q[2] * quaternion.q[2] +
                quaternion.q[3] * quaternion.q[3]);
}
    
TEXTUREKIT_INLINE TKQuaternion TKQuaternionConjugate(TKQuaternion quaternion) {
    TKQuaternion q = { -quaternion.q[0], -quaternion.q[1], -quaternion.q[2], quaternion.q[3] };
    return q;
}
    
TEXTUREKIT_INLINE TKQuaternion TKQuaternionInvert(TKQuaternion quaternion) {
    float scale = 1.0f / (quaternion.q[0] * quaternion.q[0] + 
                          quaternion.q[1] * quaternion.q[1] +
                          quaternion.q[2] * quaternion.q[2] +
                          quaternion.q[3] * quaternion.q[3]);
    TKQuaternion q = { -quaternion.q[0] * scale, -quaternion.q[1] * scale, -quaternion.q[2] * scale, quaternion.q[3] * scale };
    return q;
}
    
TEXTUREKIT_INLINE TKQuaternion TKQuaternionNormalize(TKQuaternion quaternion) {
    float scale = 1.0f / TKQuaternionLength(quaternion);
    TKQuaternion q = { quaternion.q[0] * scale, quaternion.q[1] * scale, quaternion.q[2] * scale, quaternion.q[3] * scale };
    return q;
}
    
TEXTUREKIT_INLINE TKVector3 TKQuaternionRotateVector3(TKQuaternion quaternion, TKVector3 vector) {
    TKQuaternion rotatedQuaternion = TKQuaternionMake(vector.v[0], vector.v[1], vector.v[2], 0.0f);
    rotatedQuaternion = TKQuaternionMultiply(TKQuaternionMultiply(quaternion, rotatedQuaternion), TKQuaternionInvert(quaternion));
    
    return TKVector3Make(rotatedQuaternion.q[0], rotatedQuaternion.q[1], rotatedQuaternion.q[2]);
}
    
TEXTUREKIT_INLINE TKVector4 TKQuaternionRotateVector4(TKQuaternion quaternion, TKVector4 vector) {
    TKQuaternion rotatedQuaternion = TKQuaternionMake(vector.v[0], vector.v[1], vector.v[2], 0.0f);
    rotatedQuaternion = TKQuaternionMultiply(TKQuaternionMultiply(quaternion, rotatedQuaternion), TKQuaternionInvert(quaternion));
    
    return TKVector4Make(rotatedQuaternion.q[0], rotatedQuaternion.q[1], rotatedQuaternion.q[2], vector.v[3]);
}
    
