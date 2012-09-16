//
//  TKVector2.h
//  TextureKit
//
//  Created by Mark Douma on 12/7/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKMathBase.h>


#pragma mark -
#pragma mark Prototypes
#pragma mark -

TEXTUREKIT_INLINE NSString *NSStringFromVector2(TKVector2 vector);


TEXTUREKIT_INLINE TKVector2 TKVector2Make(float x, float y);
TEXTUREKIT_INLINE TKVector2 TKVector2MakeWithArray(float values[2]);

TEXTUREKIT_INLINE TKVector2 TKVector2Negate(TKVector2 vector);

TEXTUREKIT_INLINE TKVector2 TKVector2Add(TKVector2 vectorLeft, TKVector2 vectorRight);
TEXTUREKIT_INLINE TKVector2 TKVector2Subtract(TKVector2 vectorLeft, TKVector2 vectorRight);
TEXTUREKIT_INLINE TKVector2 TKVector2Multiply(TKVector2 vectorLeft, TKVector2 vectorRight);
TEXTUREKIT_INLINE TKVector2 TKVector2Divide(TKVector2 vectorLeft, TKVector2 vectorRight);

TEXTUREKIT_INLINE TKVector2 TKVector2AddScalar(TKVector2 vector, float value);
TEXTUREKIT_INLINE TKVector2 TKVector2SubtractScalar(TKVector2 vector, float value);
TEXTUREKIT_INLINE TKVector2 TKVector2MultiplyScalar(TKVector2 vector, float value);
TEXTUREKIT_INLINE TKVector2 TKVector2DivideScalar(TKVector2 vector, float value);


/* Returns a vector whose elements are the larger of the corresponding elements of the vector arguments. */
TEXTUREKIT_INLINE TKVector2 TKVector2Maximum(TKVector2 vectorLeft, TKVector2 vectorRight);

/* Returns a vector whose elements are the smaller of the corresponding elements of the vector arguments. */
TEXTUREKIT_INLINE TKVector2 TKVector2Minimum(TKVector2 vectorLeft, TKVector2 vectorRight);


/* Returns YES if all of the first vector's elements are equal to all of the second vector's arguments. */
TEXTUREKIT_INLINE BOOL TKVector2AllEqualToVector2(TKVector2 vectorLeft, TKVector2 vectorRight);


/* Returns YES if all of the vector's elements are equal to the provided value. */
TEXTUREKIT_INLINE BOOL TKVector2AllEqualToScalar(TKVector2 vector, float value);

/* Returns YES if all of the first vector's elements are greater than all of the second vector's arguments. */
TEXTUREKIT_INLINE BOOL TKVector2AllGreaterThanVector2(TKVector2 vectorLeft, TKVector2 vectorRight);


/* Returns YES if all of the vector's elements are greater than the provided value. */
TEXTUREKIT_INLINE BOOL TKVector2AllGreaterThanScalar(TKVector2 vector, float value);


/* Returns YES if all of the first vector's elements are greater than or equal to all of the second vector's arguments. */
TEXTUREKIT_INLINE BOOL TKVector2AllGreaterThanOrEqualToVector2(TKVector2 vectorLeft, TKVector2 vectorRight);


/* Returns YES if all of the vector's elements are greater than or equal to the provided value. */
TEXTUREKIT_INLINE BOOL TKVector2AllGreaterThanOrEqualToScalar(TKVector2 vector, float value);


TEXTUREKIT_INLINE TKVector2 TKVector2Normalize(TKVector2 vector);

TEXTUREKIT_INLINE float TKVector2DotProduct(TKVector2 vectorLeft, TKVector2 vectorRight);
TEXTUREKIT_INLINE float TKVector2Length(TKVector2 vector);
TEXTUREKIT_INLINE float TKVector2Distance(TKVector2 vectorStart, TKVector2 vectorEnd);

TEXTUREKIT_INLINE TKVector2 TKVector2Lerp(TKVector2 vectorStart, TKVector2 vectorEnd, float t);


/* Project the vector, vectorToProject, onto the vector, projectionVector. */
TEXTUREKIT_INLINE TKVector2 TKVector2Project(TKVector2 vectorToProject, TKVector2 projectionVector);



#pragma mark -
#pragma mark Implementations
#pragma mark -

TEXTUREKIT_INLINE NSString *NSStringFromVector2(TKVector2 vector) {
	return [NSString stringWithFormat:@"{%0.4f, %0.4f}", vector.x, vector.y];
}


TEXTUREKIT_INLINE TKVector2 TKVector2Make(float x, float y) {
	TKVector2 v = { x, y };
	return v;
}
	
TEXTUREKIT_INLINE TKVector2 TKVector2MakeWithArray(float values[2]) {
	TKVector2 v = { values[0], values[1] };
	return v;
}
	
TEXTUREKIT_INLINE TKVector2 TKVector2Negate(TKVector2 vector) {
	TKVector2 v = { -vector.v[0] , -vector.v[1] };
	return v;
}

TEXTUREKIT_INLINE TKVector2 TKVector2Add(TKVector2 vectorLeft, TKVector2 vectorRight) {
	TKVector2 v = { vectorLeft.v[0] + vectorRight.v[0],
					vectorLeft.v[1] + vectorRight.v[1] };
	return v;
}

TEXTUREKIT_INLINE TKVector2 TKVector2Subtract(TKVector2 vectorLeft, TKVector2 vectorRight) {
	TKVector2 v = { vectorLeft.v[0] - vectorRight.v[0],
					vectorLeft.v[1] - vectorRight.v[1] };
	return v;
}
	
TEXTUREKIT_INLINE TKVector2 TKVector2Multiply(TKVector2 vectorLeft, TKVector2 vectorRight) {
	TKVector2 v = { vectorLeft.v[0] * vectorRight.v[0],
					vectorLeft.v[1] * vectorRight.v[1] };
	return v;
}
	
TEXTUREKIT_INLINE TKVector2 TKVector2Divide(TKVector2 vectorLeft, TKVector2 vectorRight) {
	TKVector2 v = { vectorLeft.v[0] / vectorRight.v[0],
					vectorLeft.v[1] / vectorRight.v[1] };
	return v;
}

TEXTUREKIT_INLINE TKVector2 TKVector2AddScalar(TKVector2 vector, float value) {
	TKVector2 v = { vector.v[0] + value,
					vector.v[1] + value };
	return v;
}
	
TEXTUREKIT_INLINE TKVector2 TKVector2SubtractScalar(TKVector2 vector, float value) {
	TKVector2 v = { vector.v[0] - value,
					vector.v[1] - value };
	return v;
}
	
TEXTUREKIT_INLINE TKVector2 TKVector2MultiplyScalar(TKVector2 vector, float value) {
	TKVector2 v = { vector.v[0] * value,
					vector.v[1] * value };
	return v;
}
	
TEXTUREKIT_INLINE TKVector2 TKVector2DivideScalar(TKVector2 vector, float value) {
	TKVector2 v = { vector.v[0] / value,
					vector.v[1] / value };
	return v;
}
	
TEXTUREKIT_INLINE TKVector2 TKVector2Maximum(TKVector2 vectorLeft, TKVector2 vectorRight) {
	TKVector2 max = vectorLeft;
	if (vectorRight.v[0] > vectorLeft.v[0])
		max.v[0] = vectorRight.v[0];
	if (vectorRight.v[1] > vectorLeft.v[1])
		max.v[1] = vectorRight.v[1];
	return max;
}

TEXTUREKIT_INLINE TKVector2 TKVector2Minimum(TKVector2 vectorLeft, TKVector2 vectorRight) {
	TKVector2 min = vectorLeft;
	if (vectorRight.v[0] < vectorLeft.v[0])
		min.v[0] = vectorRight.v[0];
	if (vectorRight.v[1] < vectorLeft.v[1])
		min.v[1] = vectorRight.v[1];
	return min;
}

TEXTUREKIT_INLINE BOOL TKVector2AllEqualToVector2(TKVector2 vectorLeft, TKVector2 vectorRight) {
	BOOL compare = NO;
	if (vectorLeft.v[0] == vectorRight.v[0] &&
		vectorLeft.v[1] == vectorRight.v[1])
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector2AllEqualToScalar(TKVector2 vector, float value) {
	BOOL compare = NO;
	if (vector.v[0] == value &&
		vector.v[1] == value)
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector2AllGreaterThanVector2(TKVector2 vectorLeft, TKVector2 vectorRight) {
	BOOL compare = NO;
	if (vectorLeft.v[0] > vectorRight.v[0] &&
		vectorLeft.v[1] > vectorRight.v[1])
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector2AllGreaterThanScalar(TKVector2 vector, float value) {
	BOOL compare = NO;
	if (vector.v[0] > value &&
		vector.v[1] > value)
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector2AllGreaterThanOrEqualToVector2(TKVector2 vectorLeft, TKVector2 vectorRight) {
	BOOL compare = NO;
	if (vectorLeft.v[0] >= vectorRight.v[0] &&
		vectorLeft.v[1] >= vectorRight.v[1])
		compare = YES;
	return compare;
}

TEXTUREKIT_INLINE BOOL TKVector2AllGreaterThanOrEqualToScalar(TKVector2 vector, float value) {
	BOOL compare = NO;
	if (vector.v[0] >= value &&
		vector.v[1] >= value)
		compare = YES;
	return compare;
}
	
TEXTUREKIT_INLINE TKVector2 TKVector2Normalize(TKVector2 vector) {
	float scale = 1.0f / TKVector2Length(vector);
	TKVector2 v = TKVector2MultiplyScalar(vector, scale);
	return v;
}

TEXTUREKIT_INLINE float TKVector2DotProduct(TKVector2 vectorLeft, TKVector2 vectorRight) {
	return vectorLeft.v[0] * vectorRight.v[0] + vectorLeft.v[1] * vectorRight.v[1];
}

TEXTUREKIT_INLINE float TKVector2Length(TKVector2 vector) {
	return sqrt(vector.v[0] * vector.v[0] + vector.v[1] * vector.v[1]);
}

TEXTUREKIT_INLINE float TKVector2Distance(TKVector2 vectorStart, TKVector2 vectorEnd) {
	return TKVector2Length(TKVector2Subtract(vectorEnd, vectorStart));
}
	
TEXTUREKIT_INLINE TKVector2 TKVector2Lerp(TKVector2 vectorStart, TKVector2 vectorEnd, float t) {
	TKVector2 v = { vectorStart.v[0] + ((vectorEnd.v[0] - vectorStart.v[0]) * t),
					 vectorStart.v[1] + ((vectorEnd.v[1] - vectorStart.v[1]) * t) };
	return v;
}

TEXTUREKIT_INLINE TKVector2 TKVector2Project(TKVector2 vectorToProject, TKVector2 projectionVector) {
	float scale = TKVector2DotProduct(projectionVector, vectorToProject) / TKVector2DotProduct(projectionVector, projectionVector);
	TKVector2 v = TKVector2MultiplyScalar(projectionVector, scale);
	return v;
}


