//
//  TKMatrix3.h
//  TextureKit
//
//  Created by Mark Douma on 12/7/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKMathBase.h>
#import <TextureKit/TKVector3.h>
#import <TextureKit/TKQuaternion.h>



#pragma mark -
#pragma mark Prototypes
#pragma mark -

TEXTUREKIT_EXTERN const TKMatrix3 TKMatrix3Identity;

TEXTUREKIT_INLINE NSString *NSStringFromMatrix3(TKMatrix3 matrix);


TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Make(float m00, float m01, float m02,
											float m10, float m11, float m12,
											float m20, float m21, float m22);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeAndTranspose(float m00, float m01, float m02,
														float m10, float m11, float m12,
														float m20, float m21, float m22);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeWithArray(float values[9]);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeWithArrayAndTranspose(float values[9]);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeWithRows(TKVector3 row0,
													TKVector3 row1, 
													TKVector3 row2);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeWithColumns(TKVector3 column0,
													   TKVector3 column1, 
													   TKVector3 column2);


/* The quaternion will be normalized before conversion. */
TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeWithQuaternion(TKQuaternion quaternion);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeScale(float sx, float sy, float sz);
TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeRotation(float radians, float x, float y, float z);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeXRotation(float radians);
TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeYRotation(float radians);
TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeZRotation(float radians);


/* Returns the upper left 2x2 portion of the 3x3 matrix. */
TEXTUREKIT_INLINE TKMatrix2 TKMatrix3GetMatrix2(TKMatrix3 matrix);

TEXTUREKIT_INLINE TKVector3 TKMatrix3GetRow(TKMatrix3 matrix, int row);
TEXTUREKIT_INLINE TKVector3 TKMatrix3GetColumn(TKMatrix3 matrix, int column);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3SetRow(TKMatrix3 matrix, int row, TKVector3 vector);
TEXTUREKIT_INLINE TKMatrix3 TKMatrix3SetColumn(TKMatrix3 matrix, int column, TKVector3 vector);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Transpose(TKMatrix3 matrix);

TEXTUREKIT_EXTERN TKMatrix3 TKMatrix3Invert(TKMatrix3 matrix, BOOL *isInvertible);

//TEXTUREKIT_EXTERN TKMatrix3 TKMatrix3InvertAndTranspose(TKMatrix3 matrix, BOOL *isInvertible);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Multiply(TKMatrix3 matrixLeft, TKMatrix3 matrixRight);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Add(TKMatrix3 matrixLeft, TKMatrix3 matrixRight);
TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Subtract(TKMatrix3 matrixLeft, TKMatrix3 matrixRight);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Scale(TKMatrix3 matrix, float sx, float sy, float sz);
TEXTUREKIT_INLINE TKMatrix3 TKMatrix3ScaleWithVector3(TKMatrix3 matrix, TKVector3 scaleVector);


/* The last component of the TKVector4, scaleVector, is ignored. */
TEXTUREKIT_INLINE TKMatrix3 TKMatrix3ScaleWithVector4(TKMatrix3 matrix, TKVector4 scaleVector);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Rotate(TKMatrix3 matrix, float radians, float x, float y, float z);
TEXTUREKIT_INLINE TKMatrix3 TKMatrix3RotateWithVector3(TKMatrix3 matrix, float radians, TKVector3 axisVector);


/* The last component of the TKVector4, axisVector, is ignored.	 */
TEXTUREKIT_INLINE TKMatrix3 TKMatrix3RotateWithVector4(TKMatrix3 matrix, float radians, TKVector4 axisVector);

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3RotateX(TKMatrix3 matrix, float radians);
TEXTUREKIT_INLINE TKMatrix3 TKMatrix3RotateY(TKMatrix3 matrix, float radians);
TEXTUREKIT_INLINE TKMatrix3 TKMatrix3RotateZ(TKMatrix3 matrix, float radians);

TEXTUREKIT_INLINE TKVector3 TKMatrix3MultiplyVector3(TKMatrix3 matrixLeft, TKVector3 vectorRight);

TEXTUREKIT_INLINE void TKMatrix3MultiplyVector3Array(TKMatrix3 matrix, TKVector3 *vectors, size_t vectorCount);

#pragma mark -
#pragma mark Implementations
#pragma mark -

TEXTUREKIT_INLINE NSString *NSStringFromMatrix3(TKMatrix3 matrix) {
	return [NSString stringWithFormat:@"[%0.4f, %0.4f, %0.4f,\n%0.4f, %0.4f, %0.4f,\n%0.4f, %0.4f, %0.4f\n]",
			matrix.m00, matrix.m01, matrix.m02,
			matrix.m10, matrix.m11, matrix.m12,
			matrix.m20, matrix.m21, matrix.m22];
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Make(float m00, float m01, float m02,
											float m10, float m11, float m12,
											float m20, float m21, float m22) {
	TKMatrix3 m = { m00, m01, m02,
					m10, m11, m12,
					m20, m21, m22 };
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeAndTranspose(float m00, float m01, float m02,
														float m10, float m11, float m12,
														float m20, float m21, float m22) {
	TKMatrix3 m = { m00, m10, m20,
					m01, m11, m21,
					m02, m12, m22};
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeWithArray(float values[9]) {
	TKMatrix3 m = { values[0], values[1], values[2],
					values[3], values[4], values[5],
					values[6], values[7], values[8] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeWithArrayAndTranspose(float values[9]) {
	TKMatrix3 m = { values[0], values[3], values[6],
					values[1], values[4], values[7],
					values[2], values[5], values[8] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeWithRows(TKVector3 row0,
													TKVector3 row1, 
													TKVector3 row2) {
	TKMatrix3 m = { row0.v[0], row1.v[0], row2.v[0],
					row0.v[1], row1.v[1], row2.v[1],
					row0.v[2], row1.v[2], row2.v[2] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeWithColumns(TKVector3 column0,
													   TKVector3 column1, 
													   TKVector3 column2) {
	TKMatrix3 m = { column0.v[0], column0.v[1], column0.v[2],
					column1.v[0], column1.v[1], column1.v[2],
					column2.v[0], column2.v[1], column2.v[2] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeWithQuaternion(TKQuaternion quaternion) {
	quaternion = TKQuaternionNormalize(quaternion);
	
	float x = quaternion.q[0];
	float y = quaternion.q[1];
	float z = quaternion.q[2];
	float w = quaternion.q[3];
	
	float _2x = x + x;
	float _2y = y + y;
	float _2z = z + z;
	float _2w = w + w;
	
	TKMatrix3 m = { 1.0f - _2y * y - _2z * z,
					_2x * y + _2w * z,
					_2x * z - _2w * y,

					_2x * y - _2w * z,
					1.0f - _2x * x - _2z * z,
					_2y * z + _2w * x,

					_2x * z + _2w * y,
					_2y * z - _2w * x,
					1.0f - _2x * x - _2y * y };
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeScale(float sx, float sy, float sz) {
	TKMatrix3 m = TKMatrix3Identity;
	m.m[0] = sx;
	m.m[4] = sy;
	m.m[8] = sz;
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeRotation(float radians, float x, float y, float z) {
	TKVector3 v = TKVector3Normalize(TKVector3Make(x, y, z));
	float cos = cosf(radians);
	float cosp = 1.0f - cos;
	float sin = sinf(radians);
	
	TKMatrix3 m = { cos + cosp * v.v[0] * v.v[0],
					cosp * v.v[0] * v.v[1] + v.v[2] * sin,
					cosp * v.v[0] * v.v[2] - v.v[1] * sin,

					cosp * v.v[0] * v.v[1] - v.v[2] * sin,
					cos + cosp * v.v[1] * v.v[1],
					cosp * v.v[1] * v.v[2] + v.v[0] * sin,

					cosp * v.v[0] * v.v[2] + v.v[1] * sin,
					cosp * v.v[1] * v.v[2] - v.v[0] * sin,
					cos + cosp * v.v[2] * v.v[2] };
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeXRotation(float radians) {
	float cos = cosf(radians);
	float sin = sinf(radians);
	
	TKMatrix3 m = { 1.0f, 0.0f, 0.0f,
					0.0f, cos, sin,
					0.0f, -sin, cos };
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeYRotation(float radians) {
	float cos = cosf(radians);
	float sin = sinf(radians);
	
	TKMatrix3 m = { cos, 0.0f, -sin,
					0.0f, 1.0f, 0.0f,
					sin, 0.0f, cos };
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3MakeZRotation(float radians) {
	float cos = cosf(radians);
	float sin = sinf(radians);
	
	TKMatrix3 m = { cos, sin, 0.0f,
					-sin, cos, 0.0f,
					0.0f, 0.0f, 1.0f };
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix2 TKMatrix3GetMatrix2(TKMatrix3 matrix) {
	TKMatrix2 m = { matrix.m[0], matrix.m[1],
					matrix.m[3], matrix.m[4] };
	return m;
}

TEXTUREKIT_INLINE TKVector3 TKMatrix3GetRow(TKMatrix3 matrix, int row) {
	TKVector3 v = { matrix.m[row], matrix.m[3 + row], matrix.m[6 + row] };
	return v;
}

TEXTUREKIT_INLINE TKVector3 TKMatrix3GetColumn(TKMatrix3 matrix, int column) {
	TKVector3 v = { matrix.m[column * 3 + 0], matrix.m[column * 3 + 1], matrix.m[column * 3 + 2] };
	return v;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3SetRow(TKMatrix3 matrix, int row, TKVector3 vector) {
	matrix.m[row] = vector.v[0];
	matrix.m[row + 3] = vector.v[1];
	matrix.m[row + 6] = vector.v[2];
	
	return matrix;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3SetColumn(TKMatrix3 matrix, int column, TKVector3 vector) {
	matrix.m[column * 3 + 0] = vector.v[0];
	matrix.m[column * 3 + 1] = vector.v[1];
	matrix.m[column * 3 + 2] = vector.v[2];
	
	return matrix;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Transpose(TKMatrix3 matrix) {
	TKMatrix3 m = { matrix.m[0], matrix.m[3], matrix.m[6],
					matrix.m[1], matrix.m[4], matrix.m[7],
					matrix.m[2], matrix.m[5], matrix.m[8] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Multiply(TKMatrix3 matrixLeft, TKMatrix3 matrixRight) {
	TKMatrix3 m;
	
	m.m[0] = matrixLeft.m[0] * matrixRight.m[0] + matrixLeft.m[3] * matrixRight.m[1] + matrixLeft.m[6] * matrixRight.m[2];
	m.m[3] = matrixLeft.m[0] * matrixRight.m[3] + matrixLeft.m[3] * matrixRight.m[4] + matrixLeft.m[6] * matrixRight.m[5];
	m.m[6] = matrixLeft.m[0] * matrixRight.m[6] + matrixLeft.m[3] * matrixRight.m[7] + matrixLeft.m[6] * matrixRight.m[8];
	
	m.m[1] = matrixLeft.m[1] * matrixRight.m[0] + matrixLeft.m[4] * matrixRight.m[1] + matrixLeft.m[7] * matrixRight.m[2];
	m.m[4] = matrixLeft.m[1] * matrixRight.m[3] + matrixLeft.m[4] * matrixRight.m[4] + matrixLeft.m[7] * matrixRight.m[5];
	m.m[7] = matrixLeft.m[1] * matrixRight.m[6] + matrixLeft.m[4] * matrixRight.m[7] + matrixLeft.m[7] * matrixRight.m[8];
	
	m.m[2] = matrixLeft.m[2] * matrixRight.m[0] + matrixLeft.m[5] * matrixRight.m[1] + matrixLeft.m[8] * matrixRight.m[2];
	m.m[5] = matrixLeft.m[2] * matrixRight.m[3] + matrixLeft.m[5] * matrixRight.m[4] + matrixLeft.m[8] * matrixRight.m[5];
	m.m[8] = matrixLeft.m[2] * matrixRight.m[6] + matrixLeft.m[5] * matrixRight.m[7] + matrixLeft.m[8] * matrixRight.m[8];
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Add(TKMatrix3 matrixLeft, TKMatrix3 matrixRight) {
	TKMatrix3 m;
	
	m.m[0] = matrixLeft.m[0] + matrixRight.m[0];
	m.m[1] = matrixLeft.m[1] + matrixRight.m[1];
	m.m[2] = matrixLeft.m[2] + matrixRight.m[2];
	
	m.m[3] = matrixLeft.m[3] + matrixRight.m[3];
	m.m[4] = matrixLeft.m[4] + matrixRight.m[4];
	m.m[5] = matrixLeft.m[5] + matrixRight.m[5];
	
	m.m[6] = matrixLeft.m[6] + matrixRight.m[6];
	m.m[7] = matrixLeft.m[7] + matrixRight.m[7];
	m.m[8] = matrixLeft.m[8] + matrixRight.m[8];
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Subtract(TKMatrix3 matrixLeft, TKMatrix3 matrixRight) {
	TKMatrix3 m;
	
	m.m[0] = matrixLeft.m[0] - matrixRight.m[0];
	m.m[1] = matrixLeft.m[1] - matrixRight.m[1];
	m.m[2] = matrixLeft.m[2] - matrixRight.m[2];
	
	m.m[3] = matrixLeft.m[3] - matrixRight.m[3];
	m.m[4] = matrixLeft.m[4] - matrixRight.m[4];
	m.m[5] = matrixLeft.m[5] - matrixRight.m[5];
	
	m.m[6] = matrixLeft.m[6] - matrixRight.m[6];
	m.m[7] = matrixLeft.m[7] - matrixRight.m[7];
	m.m[8] = matrixLeft.m[8] - matrixRight.m[8];
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Scale(TKMatrix3 matrix, float sx, float sy, float sz) {
	TKMatrix3 m = { matrix.m[0] * sx, matrix.m[1] * sx, matrix.m[2] * sx,
					matrix.m[3] * sy, matrix.m[4] * sy, matrix.m[5] * sy,
					matrix.m[6] * sz, matrix.m[7] * sz, matrix.m[8] * sz };
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3ScaleWithVector3(TKMatrix3 matrix, TKVector3 scaleVector) {
	TKMatrix3 m = { matrix.m[0] * scaleVector.v[0], matrix.m[1] * scaleVector.v[0], matrix.m[2] * scaleVector.v[0],
					matrix.m[3] * scaleVector.v[1], matrix.m[4] * scaleVector.v[1], matrix.m[5] * scaleVector.v[1],
					matrix.m[6] * scaleVector.v[2], matrix.m[7] * scaleVector.v[2], matrix.m[8] * scaleVector.v[2] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3ScaleWithVector4(TKMatrix3 matrix, TKVector4 scaleVector) {
	TKMatrix3 m = { matrix.m[0] * scaleVector.v[0], matrix.m[1] * scaleVector.v[0], matrix.m[2] * scaleVector.v[0],
					matrix.m[3] * scaleVector.v[1], matrix.m[4] * scaleVector.v[1], matrix.m[5] * scaleVector.v[1],
					matrix.m[6] * scaleVector.v[2], matrix.m[7] * scaleVector.v[2], matrix.m[8] * scaleVector.v[2] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3Rotate(TKMatrix3 matrix, float radians, float x, float y, float z) {
	TKMatrix3 rm = TKMatrix3MakeRotation(radians, x, y, z);
	return TKMatrix3Multiply(matrix, rm);
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3RotateWithVector3(TKMatrix3 matrix, float radians, TKVector3 axisVector) {
	TKMatrix3 rm = TKMatrix3MakeRotation(radians, axisVector.v[0], axisVector.v[1], axisVector.v[2]);
	return TKMatrix3Multiply(matrix, rm);
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3RotateWithVector4(TKMatrix3 matrix, float radians, TKVector4 axisVector) {
	TKMatrix3 rm = TKMatrix3MakeRotation(radians, axisVector.v[0], axisVector.v[1], axisVector.v[2]);
	return TKMatrix3Multiply(matrix, rm);
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3RotateX(TKMatrix3 matrix, float radians) {
	TKMatrix3 rm = TKMatrix3MakeXRotation(radians);
	return TKMatrix3Multiply(matrix, rm);
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3RotateY(TKMatrix3 matrix, float radians) {
	TKMatrix3 rm = TKMatrix3MakeYRotation(radians);
	return TKMatrix3Multiply(matrix, rm);
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix3RotateZ(TKMatrix3 matrix, float radians) {
	TKMatrix3 rm = TKMatrix3MakeZRotation(radians);
	return TKMatrix3Multiply(matrix, rm);
}

TEXTUREKIT_INLINE TKVector3 TKMatrix3MultiplyVector3(TKMatrix3 matrixLeft, TKVector3 vectorRight) {
	TKVector3 v = { matrixLeft.m[0] * vectorRight.v[0] + matrixLeft.m[3] * vectorRight.v[1] + matrixLeft.m[6] * vectorRight.v[2],
					matrixLeft.m[1] * vectorRight.v[0] + matrixLeft.m[4] * vectorRight.v[1] + matrixLeft.m[7] * vectorRight.v[2],
					matrixLeft.m[2] * vectorRight.v[0] + matrixLeft.m[5] * vectorRight.v[1] + matrixLeft.m[8] * vectorRight.v[2] };
	return v;
}

TEXTUREKIT_INLINE void TKMatrix3MultiplyVector3Array(TKMatrix3 matrix, TKVector3 *vectors, size_t vectorCount) {
	int i;
	for (i=0; i < vectorCount; i++)
		vectors[i] = TKMatrix3MultiplyVector3(matrix, vectors[i]);
}

