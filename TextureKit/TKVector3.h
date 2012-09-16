//
//  TKVector3.h
//  TextureKit
//
//  Created by Mark Douma on 12/7/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKMathBase.h>


#pragma mark -
#pragma mark Prototypes
#pragma mark -

TEXTUREKIT_INLINE NSString *NSStringFromVector3(TKVector3 vector);

TEXTUREKIT_INLINE TKVector3 TKVector3Make(float x, float y, float z);
TEXTUREKIT_INLINE TKVector3 TKVector3MakeWithArray(float values[3]);

TEXTUREKIT_INLINE TKVector3 TKVector3Negate(TKVector3 vector);

TEXTUREKIT_INLINE TKVector3 TKVector3Add(TKVector3 vectorLeft, TKVector3 vectorRight);
TEXTUREKIT_INLINE TKVector3 TKVector3Subtract(TKVector3 vectorLeft, TKVector3 vectorRight);
TEXTUREKIT_INLINE TKVector3 TKVector3Multiply(TKVector3 vectorLeft, TKVector3 vectorRight);
TEXTUREKIT_INLINE TKVector3 TKVector3Divide(TKVector3 vectorLeft, TKVector3 vectorRight);

TEXTUREKIT_INLINE TKVector3 TKVector3AddScalar(TKVector3 vector, float value);
TEXTUREKIT_INLINE TKVector3 TKVector3SubtractScalar(TKVector3 vector, float value);
TEXTUREKIT_INLINE TKVector3 TKVector3MultiplyScalar(TKVector3 vector, float value);
TEXTUREKIT_INLINE TKVector3 TKVector3DivideScalar(TKVector3 vector, float value);


/* Returns a vector whose elements are the larger of the corresponding elements of the vector arguments. */
TEXTUREKIT_INLINE TKVector3 TKVector3Maximum(TKVector3 vectorLeft, TKVector3 vectorRight);


/* Returns a vector whose elements are the smaller of the corresponding elements of the vector arguments. */
TEXTUREKIT_INLINE TKVector3 TKVector3Minimum(TKVector3 vectorLeft, TKVector3 vectorRight);


/* Returns YES if all of the first vector's elements are equal to all of the second vector's arguments. */
TEXTUREKIT_INLINE BOOL TKVector3AllEqualToVector3(TKVector3 vectorLeft, TKVector3 vectorRight);


/* Returns YES if all of the vector's elements are equal to the provided value. */
TEXTUREKIT_INLINE BOOL TKVector3AllEqualToScalar(TKVector3 vector, float value);


/* Returns YES if all of the first vector's elements are greater than all of the second vector's arguments. */
TEXTUREKIT_INLINE BOOL TKVector3AllGreaterThanVector3(TKVector3 vectorLeft, TKVector3 vectorRight);


/* Returns YES if all of the vector's elements are greater than the provided value. */
TEXTUREKIT_INLINE BOOL TKVector3AllGreaterThanScalar(TKVector3 vector, float value);


/* Returns YES if all of the first vector's elements are greater than or equal to all of the second vector's arguments. */
TEXTUREKIT_INLINE BOOL TKVector3AllGreaterThanOrEqualToVector3(TKVector3 vectorLeft, TKVector3 vectorRight);


/* Returns YES if all of the vector's elements are greater than or equal to the provided value. */
TEXTUREKIT_INLINE BOOL TKVector3AllGreaterThanOrEqualToScalar(TKVector3 vector, float value);

TEXTUREKIT_INLINE TKVector3 TKVector3Normalize(TKVector3 vector);

TEXTUREKIT_INLINE float TKVector3DotProduct(TKVector3 vectorLeft, TKVector3 vectorRight);
TEXTUREKIT_INLINE float TKVector3Length(TKVector3 vector);
TEXTUREKIT_INLINE float TKVector3Distance(TKVector3 vectorStart, TKVector3 vectorEnd);

TEXTUREKIT_INLINE TKVector3 TKVector3Lerp(TKVector3 vectorStart, TKVector3 vectorEnd, float t);

TEXTUREKIT_INLINE TKVector3 TKVector3CrossProduct(TKVector3 vectorLeft, TKVector3 vectorRight);


/* Project the vector, vectorToProject, onto the vector, projectionVector. */
TEXTUREKIT_INLINE TKVector3 TKVector3Project(TKVector3 vectorToProject, TKVector3 projectionVector);

#pragma mark -
#pragma mark Implementations
#pragma mark -

TEXTUREKIT_INLINE NSString *NSStringFromVector3(TKVector3 vector) {
	return [NSString stringWithFormat:@"{%0.4f, %0.4f, %0.4f}", vector.x, vector.y, vector.z];
}


TEXTUREKIT_INLINE TKVector3 TKVector3Make(float x, float y, float z) {
	TKVector3 v = { x, y, z };
	return v;
}

TEXTUREKIT_INLINE TKVector3 TKVector3MakeWithArray(float values[3]) {
	TKVector3 v = { values[0], values[1], values[2] };
	return v;
}

TEXTUREKIT_INLINE TKVector3 TKVector3Negate(TKVector3 vector) {
	TKVector3 v = { -vector.v[0], -vector.v[1], -vector.v[2] };
	return v;
}
	
TEXTUREKIT_INLINE TKVector3 TKVector3Add(TKVector3 vectorLeft, TKVector3 vectorRight) {
	TKVector3 v = { vectorLeft.v[0] + vectorRight.v[0],
					vectorLeft.v[1] + vectorRight.v[1],
					vectorLeft.v[2] + vectorRight.v[2] };
	return v;
}

TEXTUREKIT_INLINE TKVector3 TKVector3Subtract(TKVector3 vectorLeft, TKVector3 vectorRight) {
	TKVector3 v = { vectorLeft.v[0] - vectorRight.v[0],
					vectorLeft.v[1] - vectorRight.v[1],
					vectorLeft.v[2] - vectorRight.v[2] };
	return v;
}

TEXTUREKIT_INLINE TKVector3 TKVector3Multiply(TKVector3 vectorLeft, TKVector3 vectorRight) {
	TKVector3 v = { vectorLeft.v[0] * vectorRight.v[0],
					vectorLeft.v[1] * vectorRight.v[1],
					vectorLeft.v[2] * vectorRight.v[2] };
	return v;
}

TEXTUREKIT_INLINE TKVector3 TKVector3Divide(TKVector3 vectorLeft, TKVector3 vectorRight) {
	TKVector3 v = { vectorLeft.v[0] / vectorRight.v[0],
					vectorLeft.v[1] / vectorRight.v[1],
					vectorLeft.v[2] / vectorRight.v[2] };
	return v;
}

TEXTUREKIT_INLINE TKVector3 TKVector3AddScalar(TKVector3 vector, float value) {
	TKVector3 v = { vector.v[0] + value,
					vector.v[1] + value,
					vector.v[2] + value };
	return v;
}

TEXTUREKIT_INLINE TKVector3 TKVector3SubtractScalar(TKVector3 vector, float value) {
	TKVector3 v = { vector.v[0] - value,
					vector.v[1] - value,
					vector.v[2] - value };
	return v;
}

TEXTUREKIT_INLINE TKVector3 TKVector3MultiplyScalar(TKVector3 vector, float value) {
	TKVector3 v = { vector.v[0] * value,
					vector.v[1] * value,
					vector.v[2] * value };
	return v;	
}

TEXTUREKIT_INLINE TKVector3 TKVector3DivideScalar(TKVector3 vector, float value) {
	TKVector3 v = { vector.v[0] / value,
					vector.v[1] / value,
					vector.v[2] / value };
	return v;
}

TEXTUREKIT_INLINE TKVector3 TKVector3Maximum(TKVector3 vectorLeft, TKVector3 vectorRight) {
	TKVector3 max = vectorLeft;
	if (vectorRight.v[0] > vectorLeft.v[0])
		max.v[0] = vectorRight.v[0];
	if (vectorRight.v[1] > vectorLeft.v[1])
		max.v[1] = vectorRight.v[1];
	if (vectorRight.v[2] > vectorLeft.v[2])
		max.v[2] = vectorRight.v[2];
	return max;
}

TEXTUREKIT_INLINE TKVector3 TKVector3Minimum(TKVector3 vectorLeft, TKVector3 vectorRight) {
	TKVector3 min = vectorLeft;
	if (vectorRight.v[0] < vectorLeft.v[0])
		min.v[0] = vectorRight.v[0];
	if (vectorRight.v[1] < vectorLeft.v[1])
		min.v[1] = vectorRight.v[1];
	if (vectorRight.v[2] < vectorLeft.v[2])
		min.v[2] = vectorRight.v[2];
	return min;
}

TEXTUREKIT_INLINE BOOL TKVector3AllEqualToVector3(TKVector3 vectorLeft, TKVector3 vectorRight) {
	BOOL compare = NO;
	if (vectorLeft.v[0] == vectorRight.v[0] &&
		vectorLeft.v[1] == vectorRight.v[1] &&
		vectorLeft.v[2] == vectorRight.v[2])
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector3AllEqualToScalar(TKVector3 vector, float value) {
	BOOL compare = NO;
	if (vector.v[0] == value &&
		vector.v[1] == value &&
		vector.v[2] == value)
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector3AllGreaterThanVector3(TKVector3 vectorLeft, TKVector3 vectorRight) {
	BOOL compare = NO;
	if (vectorLeft.v[0] > vectorRight.v[0] &&
		vectorLeft.v[1] > vectorRight.v[1] &&
		vectorLeft.v[2] > vectorRight.v[2])
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector3AllGreaterThanScalar(TKVector3 vector, float value) {
	BOOL compare = NO;
	if (vector.v[0] > value &&
		vector.v[1] > value &&
		vector.v[2] > value)
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector3AllGreaterThanOrEqualToVector3(TKVector3 vectorLeft, TKVector3 vectorRight) {
	BOOL compare = NO;
	if (vectorLeft.v[0] >= vectorRight.v[0] &&
		vectorLeft.v[1] >= vectorRight.v[1] &&
		vectorLeft.v[2] >= vectorRight.v[2])
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector3AllGreaterThanOrEqualToScalar(TKVector3 vector, float value) {
	BOOL compare = NO;
	if (vector.v[0] >= value &&
		vector.v[1] >= value &&
		vector.v[2] >= value)
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE TKVector3 TKVector3Normalize(TKVector3 vector) {
	float scale = 1.0f / TKVector3Length(vector);
	TKVector3 v = { vector.v[0] * scale, vector.v[1] * scale, vector.v[2] * scale };
	return v;
}

TEXTUREKIT_INLINE float TKVector3DotProduct(TKVector3 vectorLeft, TKVector3 vectorRight) {
	return vectorLeft.v[0] * vectorRight.v[0] + vectorLeft.v[1] * vectorRight.v[1] + vectorLeft.v[2] * vectorRight.v[2];
}

TEXTUREKIT_INLINE float TKVector3Length(TKVector3 vector) {
	return sqrt(vector.v[0] * vector.v[0] + vector.v[1] * vector.v[1] + vector.v[2] * vector.v[2]);
}

TEXTUREKIT_INLINE float TKVector3Distance(TKVector3 vectorStart, TKVector3 vectorEnd) {
	return TKVector3Length(TKVector3Subtract(vectorEnd, vectorStart));
}

TEXTUREKIT_INLINE TKVector3 TKVector3Lerp(TKVector3 vectorStart, TKVector3 vectorEnd, float t) {
	TKVector3 v = { vectorStart.v[0] + ((vectorEnd.v[0] - vectorStart.v[0]) * t),
					vectorStart.v[1] + ((vectorEnd.v[1] - vectorStart.v[1]) * t),
					vectorStart.v[2] + ((vectorEnd.v[2] - vectorStart.v[2]) * t) };
	return v;
}

TEXTUREKIT_INLINE TKVector3 TKVector3CrossProduct(TKVector3 vectorLeft, TKVector3 vectorRight) {
	TKVector3 v = { vectorLeft.v[1] * vectorRight.v[2] - vectorLeft.v[2] * vectorRight.v[1],
					vectorLeft.v[2] * vectorRight.v[0] - vectorLeft.v[0] * vectorRight.v[2],
					vectorLeft.v[0] * vectorRight.v[1] - vectorLeft.v[1] * vectorRight.v[0] };
	return v;
}

TEXTUREKIT_INLINE TKVector3 TKVector3Project(TKVector3 vectorToProject, TKVector3 projectionVector) {
	float scale = TKVector3DotProduct(projectionVector, vectorToProject) / TKVector3DotProduct(projectionVector, projectionVector);
	TKVector3 v = TKVector3MultiplyScalar(projectionVector, scale);
	return v;
}
	
