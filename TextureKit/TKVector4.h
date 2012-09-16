//
//  TKVector4.h
//  TextureKit
//
//  Created by Mark Douma on 12/7/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKMathBase.h>


#pragma mark -
#pragma mark Prototypes
#pragma mark -

TEXTUREKIT_INLINE NSString *NSStringFromVector4(TKVector4 vector);


TEXTUREKIT_INLINE TKVector4 TKVector4Make(float x, float y, float z, float w);
TEXTUREKIT_INLINE TKVector4 TKVector4MakeWithArray(float values[4]);
TEXTUREKIT_INLINE TKVector4 TKVector4MakeWithVector3(TKVector3 vector, float w);

TEXTUREKIT_INLINE TKVector4 TKVector4Negate(TKVector4 vector);

TEXTUREKIT_INLINE TKVector4 TKVector4Add(TKVector4 vectorLeft, TKVector4 vectorRight);
TEXTUREKIT_INLINE TKVector4 TKVector4Subtract(TKVector4 vectorLeft, TKVector4 vectorRight);
TEXTUREKIT_INLINE TKVector4 TKVector4Multiply(TKVector4 vectorLeft, TKVector4 vectorRight);
TEXTUREKIT_INLINE TKVector4 TKVector4Divide(TKVector4 vectorLeft, TKVector4 vectorRight);

TEXTUREKIT_INLINE TKVector4 TKVector4AddScalar(TKVector4 vector, float value);
TEXTUREKIT_INLINE TKVector4 TKVector4SubtractScalar(TKVector4 vector, float value);
TEXTUREKIT_INLINE TKVector4 TKVector4MultiplyScalar(TKVector4 vector, float value);
TEXTUREKIT_INLINE TKVector4 TKVector4DivideScalar(TKVector4 vector, float value);


/* Returns a vector whose elements are the larger of the corresponding elements of the vector arguments. */
TEXTUREKIT_INLINE TKVector4 TKVector4Maximum(TKVector4 vectorLeft, TKVector4 vectorRight);


/* Returns a vector whose elements are the smaller of the corresponding elements of the vector arguments. */
TEXTUREKIT_INLINE TKVector4 TKVector4Minimum(TKVector4 vectorLeft, TKVector4 vectorRight);


/* Returns YES if all of the first vector's elements are equal to all of the second vector's arguments. */
TEXTUREKIT_INLINE BOOL TKVector4AllEqualToVector4(TKVector4 vectorLeft, TKVector4 vectorRight);


/* Returns YES if all of the vector's elements are equal to the provided value. */
TEXTUREKIT_INLINE BOOL TKVector4AllEqualToScalar(TKVector4 vector, float value);


/* Returns YES if all of the first vector's elements are greater than all of the second vector's arguments. */
TEXTUREKIT_INLINE BOOL TKVector4AllGreaterThanVector4(TKVector4 vectorLeft, TKVector4 vectorRight);


/* Returns YES if all of the vector's elements are greater than the provided value. */
TEXTUREKIT_INLINE BOOL TKVector4AllGreaterThanScalar(TKVector4 vector, float value);


/* Returns YES if all of the first vector's elements are greater than or equal to all of the second vector's arguments. */
TEXTUREKIT_INLINE BOOL TKVector4AllGreaterThanOrEqualToVector4(TKVector4 vectorLeft, TKVector4 vectorRight);


/* Returns YES if all of the vector's elements are greater than or equal to the provided value. */
TEXTUREKIT_INLINE BOOL TKVector4AllGreaterThanOrEqualToScalar(TKVector4 vector, float value);



TEXTUREKIT_INLINE TKVector4 TKVector4Normalize(TKVector4 vector);

TEXTUREKIT_INLINE float TKVector4DotProduct(TKVector4 vectorLeft, TKVector4 vectorRight);
TEXTUREKIT_INLINE float TKVector4Length(TKVector4 vector);
TEXTUREKIT_INLINE float TKVector4Distance(TKVector4 vectorStart, TKVector4 vectorEnd);

TEXTUREKIT_INLINE TKVector4 TKVector4Lerp(TKVector4 vectorStart, TKVector4 vectorEnd, float t);


/* Performs a 3D cross product. The last component of the resulting cross product will be zeroed out. */
TEXTUREKIT_INLINE TKVector4 TKVector4CrossProduct(TKVector4 vectorLeft, TKVector4 vectorRight);


/* Project the vector, vectorToProject, onto the vector, projectionVector. */
TEXTUREKIT_INLINE TKVector4 TKVector4Project(TKVector4 vectorToProject, TKVector4 projectionVector);



#pragma mark -
#pragma mark Implementations
#pragma mark -


TEXTUREKIT_INLINE NSString *NSStringFromVector4(TKVector4 vector) {
	return [NSString stringWithFormat:@"{%0.4f, %0.4f, %0.4f, %0.4f}", vector.x, vector.y, vector.z, vector.w];
}

TEXTUREKIT_INLINE TKVector4 TKVector4Make(float x, float y, float z, float w) {
	TKVector4 v = { x, y, z, w };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKVector4MakeWithArray(float values[4]) {
	TKVector4 v = { values[0], values[1], values[2], values[3] };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKVector4MakeWithVector3(TKVector3 vector, float w) {
	TKVector4 v = { vector.v[0], vector.v[1], vector.v[2], w };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKVector4Negate(TKVector4 vector) {
	TKVector4 v = { -vector.v[0], -vector.v[1], -vector.v[2], -vector.v[3] };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKVector4Add(TKVector4 vectorLeft, TKVector4 vectorRight) {
	TKVector4 v = { vectorLeft.v[0] + vectorRight.v[0],
					vectorLeft.v[1] + vectorRight.v[1],
					vectorLeft.v[2] + vectorRight.v[2],
					vectorLeft.v[3] + vectorRight.v[3] };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKVector4Subtract(TKVector4 vectorLeft, TKVector4 vectorRight) {
	TKVector4 v = { vectorLeft.v[0] - vectorRight.v[0],
					vectorLeft.v[1] - vectorRight.v[1],
					vectorLeft.v[2] - vectorRight.v[2],
					vectorLeft.v[3] - vectorRight.v[3] };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKVector4Multiply(TKVector4 vectorLeft, TKVector4 vectorRight) {
	TKVector4 v = { vectorLeft.v[0] * vectorRight.v[0],
					vectorLeft.v[1] * vectorRight.v[1],
					vectorLeft.v[2] * vectorRight.v[2],
					vectorLeft.v[3] * vectorRight.v[3] };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKVector4Divide(TKVector4 vectorLeft, TKVector4 vectorRight) {
	TKVector4 v = { vectorLeft.v[0] / vectorRight.v[0],
					vectorLeft.v[1] / vectorRight.v[1],
					vectorLeft.v[2] / vectorRight.v[2],
					vectorLeft.v[3] / vectorRight.v[3] };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKVector4AddScalar(TKVector4 vector, float value) {
	TKVector4 v = { vector.v[0] + value,
					vector.v[1] + value,
					vector.v[2] + value,
					vector.v[3] + value };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKVector4SubtractScalar(TKVector4 vector, float value) {
	TKVector4 v = { vector.v[0] - value,
					vector.v[1] - value,
					vector.v[2] - value,
					vector.v[3] - value };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKVector4MultiplyScalar(TKVector4 vector, float value) {
	TKVector4 v = { vector.v[0] * value,
					vector.v[1] * value,
					vector.v[2] * value,
					vector.v[3] * value };
	return v;	
}

TEXTUREKIT_INLINE TKVector4 TKVector4DivideScalar(TKVector4 vector, float value) {
	TKVector4 v = { vector.v[0] / value,
					vector.v[1] / value,
					vector.v[2] / value,
					vector.v[3] / value };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKVector4Maximum(TKVector4 vectorLeft, TKVector4 vectorRight) {
	TKVector4 max = vectorLeft;
	if (vectorRight.v[0] > vectorLeft.v[0])
		max.v[0] = vectorRight.v[0];
	if (vectorRight.v[1] > vectorLeft.v[1])
		max.v[1] = vectorRight.v[1];
	if (vectorRight.v[2] > vectorLeft.v[2])
		max.v[2] = vectorRight.v[2];
	if (vectorRight.v[3] > vectorLeft.v[3])
		max.v[3] = vectorRight.v[3];
	return max;
}

TEXTUREKIT_INLINE TKVector4 TKVector4Minimum(TKVector4 vectorLeft, TKVector4 vectorRight) {
		TKVector4 min = vectorLeft;
		if (vectorRight.v[0] < vectorLeft.v[0])
			min.v[0] = vectorRight.v[0];
		if (vectorRight.v[1] < vectorLeft.v[1])
			min.v[1] = vectorRight.v[1];
		if (vectorRight.v[2] < vectorLeft.v[2])
			min.v[2] = vectorRight.v[2];
		if (vectorRight.v[3] < vectorLeft.v[3])
			min.v[3] = vectorRight.v[3];
		return min;
}

TEXTUREKIT_INLINE BOOL TKVector4AllEqualToVector4(TKVector4 vectorLeft, TKVector4 vectorRight) {
	BOOL compare = NO;
	if (vectorLeft.v[0] == vectorRight.v[0] &&
		vectorLeft.v[1] == vectorRight.v[1] &&
		vectorLeft.v[2] == vectorRight.v[2] &&
		vectorLeft.v[3] == vectorRight.v[3])
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector4AllEqualToScalar(TKVector4 vector, float value) {
	BOOL compare = NO;
	if (vector.v[0] == value &&
		vector.v[1] == value &&
		vector.v[2] == value &&
		vector.v[3] == value)
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector4AllGreaterThanVector4(TKVector4 vectorLeft, TKVector4 vectorRight) {
	BOOL compare = NO;
	if (vectorLeft.v[0] > vectorRight.v[0] &&
		vectorLeft.v[1] > vectorRight.v[1] &&
		vectorLeft.v[2] > vectorRight.v[2] &&
		vectorLeft.v[3] > vectorRight.v[3])
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector4AllGreaterThanScalar(TKVector4 vector, float value) {
	BOOL compare = NO;
	if (vector.v[0] > value &&
		vector.v[1] > value &&
		vector.v[2] > value &&
		vector.v[3] > value)
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector4AllGreaterThanOrEqualToVector4(TKVector4 vectorLeft, TKVector4 vectorRight) {
	BOOL compare = NO;
	if (vectorLeft.v[0] >= vectorRight.v[0] &&
		vectorLeft.v[1] >= vectorRight.v[1] &&
		vectorLeft.v[2] >= vectorRight.v[2] &&
		vectorLeft.v[3] >= vectorRight.v[3])
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector4AllGreaterThanOrEqualToScalar(TKVector4 vector, float value) {
	BOOL compare = NO;
	if (vector.v[0] >= value &&
		vector.v[1] >= value &&
		vector.v[2] >= value &&
		vector.v[3] >= value)
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE TKVector4 TKVector4Normalize(TKVector4 vector) {
	float scale = 1.0f / TKVector4Length(vector);
	TKVector4 v = TKVector4MultiplyScalar(vector, scale);
	return v;
}

TEXTUREKIT_INLINE float TKVector4DotProduct(TKVector4 vectorLeft, TKVector4 vectorRight) {
	return vectorLeft.v[0] * vectorRight.v[0] +
		   vectorLeft.v[1] * vectorRight.v[1] +
		   vectorLeft.v[2] * vectorRight.v[2] +
		   vectorLeft.v[3] * vectorRight.v[3];
}

TEXTUREKIT_INLINE float TKVector4Length(TKVector4 vector) {
	return sqrt(vector.v[0] * vector.v[0] +
				vector.v[1] * vector.v[1] +
				vector.v[2] * vector.v[2] +
				vector.v[3] * vector.v[3]);
}

TEXTUREKIT_INLINE float TKVector4Distance(TKVector4 vectorStart, TKVector4 vectorEnd) {
	return TKVector4Length(TKVector4Subtract(vectorEnd, vectorStart));
}

TEXTUREKIT_INLINE TKVector4 TKVector4Lerp(TKVector4 vectorStart, TKVector4 vectorEnd, float t) {
	TKVector4 v = { vectorStart.v[0] + ((vectorEnd.v[0] - vectorStart.v[0]) * t),
					vectorStart.v[1] + ((vectorEnd.v[1] - vectorStart.v[1]) * t),
					vectorStart.v[2] + ((vectorEnd.v[2] - vectorStart.v[2]) * t),
					vectorStart.v[3] + ((vectorEnd.v[3] - vectorStart.v[3]) * t) };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKVector4CrossProduct(TKVector4 vectorLeft, TKVector4 vectorRight) {
	TKVector4 v = { vectorLeft.v[1] * vectorRight.v[2] - vectorLeft.v[2] * vectorRight.v[1],
					vectorLeft.v[2] * vectorRight.v[0] - vectorLeft.v[0] * vectorRight.v[2],
					vectorLeft.v[0] * vectorRight.v[1] - vectorLeft.v[1] * vectorRight.v[0],
					0.0f };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKVector4Project(TKVector4 vectorToProject, TKVector4 projectionVector) {
	float scale = TKVector4DotProduct(projectionVector, vectorToProject) / TKVector4DotProduct(projectionVector, projectionVector);
	TKVector4 v = TKVector4MultiplyScalar(projectionVector, scale);
	return v;
}

