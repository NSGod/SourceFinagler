//
//  TKQuaternion.m
//  Texture Kit
//
//  Created by Mark Douma on 12/7/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKQuaternion.h>


#define TK_DEBUG 1


const TKQuaternion TKQuaternionIdentity = {1.0f, 1.0f, 1.0f, 1.0f};



TKQuaternion TKQuaternionMakeWithMatrix3(TKMatrix3 matrix);
TKQuaternion TKQuaternionMakeWithMatrix4(TKMatrix4 matrix);


/* Calculate and return the angle component of the angle and axis form. */
float TKQuaternionAngle(TKQuaternion quaternion);

/* Calculate and return the axis component of the angle and axis form. */
TKVector3 TKQuaternionAxis(TKQuaternion quaternion);
    

TKQuaternion TKQuaternionSlerp(TKQuaternion quaternionStart, TKQuaternion quaternionEnd, float t);


void TKQuaternionRotateVector3Array(TKQuaternion quaternion, TKVector3 *vectors, size_t vectorCount);


void TKQuaternionRotateVector4Array(TKQuaternion quaternion, TKVector4 *vectors, size_t vectorCount);


