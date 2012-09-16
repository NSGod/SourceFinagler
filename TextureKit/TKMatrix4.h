//
//  TKMatrix4.h
//  TextureKit
//
//  Created by Mark Douma on 12/7/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKMathBase.h>
#import <TextureKit/TKVector3.h>
#import <TextureKit/TKVector4.h>
#import <TextureKit/TKQuaternion.h>


#pragma mark -
#pragma mark Prototypes
#pragma mark -

TEXTUREKIT_EXTERN const TKMatrix4 TKMatrix4Identity;


TEXTUREKIT_INLINE NSString *NSStringFromMatrix4(TKMatrix4 matrix);


/* m30, m31, and m32 correspond to the translation values tx, ty, tz, respectively. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Make(float m00, float m01, float m02, float m03,
										  float m10, float m11, float m12, float m13,
										  float m20, float m21, float m22, float m23,
										  float m30, float m31, float m32, float m33);


/* m03, m13, and m23 correspond to the translation values tx, ty, tz, respectively. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeAndTranspose(float m00, float m01, float m02, float m03,
													  float m10, float m11, float m12, float m13,
													  float m20, float m21, float m22, float m23,
													  float m30, float m31, float m32, float m33);


/* m[12], m[13], and m[14] correspond to the translation values tx, ty, and tz, respectively. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeWithArray(float values[16]);


/* m[3], m[7], and m[11] correspond to the translation values tx, ty, and tz, respectively. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeWithArrayAndTranspose(float values[16]);


/* row0, row1, and row2's last component should correspond to the translation values tx, ty, and tz, respectively. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeWithRows(TKVector4 row0,
												  TKVector4 row1, 
												  TKVector4 row2,
												  TKVector4 row3);


/* column3's first three components should correspond to the translation values tx, ty, and tz. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeWithColumns(TKVector4 column0,
													 TKVector4 column1, 
													 TKVector4 column2,
													 TKVector4 column3);


/* The quaternion will be normalized before conversion. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeWithQuaternion(TKQuaternion quaternion);
	
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeTranslation(float tx, float ty, float tz);
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeScale(float sx, float sy, float sz);
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeRotation(float radians, float x, float y, float z);

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeXRotation(float radians);
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeYRotation(float radians);
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeZRotation(float radians);


/* Equivalent to gluPerspective. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakePerspective(float fovyRadians, float aspect, float nearZ, float farZ);


/* Equivalent to glFrustum. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeFrustum(float left, float right,
												 float bottom, float top,
												 float nearZ, float farZ);

/* Equivalent to glOrtho. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeOrtho(float left, float right,
											   float bottom, float top,
											   float nearZ, float farZ);

/* Equivalent to gluLookAt. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeLookAt(float eyeX,		float eyeY,		float eyeZ,
												float centerX,	float centerY,	float centerZ,
												float upX,		float upY,		float upZ);


/* Returns the upper left 3x3 portion of the 4x4 matrix. */
TEXTUREKIT_INLINE TKMatrix3 TKMatrix4GetMatrix3(TKMatrix4 matrix);


/* Returns the upper left 2x2 portion of the 4x4 matrix. */
TEXTUREKIT_INLINE TKMatrix2 TKMatrix4GetMatrix2(TKMatrix4 matrix);


/* TKMatrix4GetRow returns vectors for rows 0, 1, and 2 whose last component will be the translation value tx, ty, and tz, respectively.
 Valid row values range from 0 to 3, inclusive. */
TEXTUREKIT_INLINE TKVector4 TKMatrix4GetRow(TKMatrix4 matrix, int row);


/* TKMatrix4GetColumn returns a vector for column 3 whose first three components will be the translation values tx, ty, and tz.
 Valid column values range from 0 to 3, inclusive. */
TEXTUREKIT_INLINE TKVector4 TKMatrix4GetColumn(TKMatrix4 matrix, int column);


/* TKMatrix4SetRow expects that the vector for row 0, 1, and 2 will have a translation value as its last component.
 Valid row values range from 0 to 3, inclusive. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4SetRow(TKMatrix4 matrix, int row, TKVector4 vector);


/* TKMatrix4SetColumn expects that the vector for column 3 will contain the translation values tx, ty, and tz as its first three components, respectively.
 Valid column values range from 0 to 3, inclusive. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4SetColumn(TKMatrix4 matrix, int column, TKVector4 vector);


TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Transpose(TKMatrix4 matrix);


TEXTUREKIT_EXTERN TKMatrix4 TKMatrix4Invert(TKMatrix4 matrix, BOOL *isInvertible);

//TEXTUREKIT_EXTERN TKMatrix4 TKMatrix4InvertAndTranspose(TKMatrix4 matrix, BOOL *isInvertible);


#ifndef __clang__
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Multiply(TKMatrix4 matrixLeft, TKMatrix4 matrixRight);
#else
static TKMatrix4 TKMatrix4Multiply(TKMatrix4 matrixLeft, TKMatrix4 matrixRight);
#endif

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Add(TKMatrix4 matrixLeft, TKMatrix4 matrixRight);
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Subtract(TKMatrix4 matrixLeft, TKMatrix4 matrixRight);

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Translate(TKMatrix4 matrix, float tx, float ty, float tz);
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4TranslateWithVector3(TKMatrix4 matrix, TKVector3 translationVector);


/* The last component of the TKVector4, translationVector, is ignored. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4TranslateWithVector4(TKMatrix4 matrix, TKVector4 translationVector);

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Scale(TKMatrix4 matrix, float sx, float sy, float sz);
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4ScaleWithVector3(TKMatrix4 matrix, TKVector3 scaleVector);


/* The last component of the TKVector4, scaleVector, is ignored. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4ScaleWithVector4(TKMatrix4 matrix, TKVector4 scaleVector);

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Rotate(TKMatrix4 matrix, float radians, float x, float y, float z);
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4RotateWithVector3(TKMatrix4 matrix, float radians, TKVector3 axisVector);


/* The last component of the TKVector4, axisVector, is ignored. */
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4RotateWithVector4(TKMatrix4 matrix, float radians, TKVector4 axisVector);

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4RotateX(TKMatrix4 matrix, float radians);
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4RotateY(TKMatrix4 matrix, float radians);
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4RotateZ(TKMatrix4 matrix, float radians);


/* Assumes 0 in the w component. */
TEXTUREKIT_INLINE TKVector3 TKMatrix4MultiplyVector3(TKMatrix4 matrixLeft, TKVector3 vectorRight);


/* Assumes 1 in the w component. */
TEXTUREKIT_INLINE TKVector3 TKMatrix4MultiplyVector3WithTranslation(TKMatrix4 matrixLeft, TKVector3 vectorRight);


/* Assumes 1 in the w component and divides the resulting vector by w before returning. */
TEXTUREKIT_INLINE TKVector3 TKMatrix4MultiplyAndProjectVector3(TKMatrix4 matrixLeft, TKVector3 vectorRight);


/* Assumes 0 in the w component. */
TEXTUREKIT_INLINE void TKMatrix4MultiplyVector3Array(TKMatrix4 matrix, TKVector3 *vectors, size_t vectorCount);


/* Assumes 1 in the w component. */
TEXTUREKIT_INLINE void TKMatrix4MultiplyVector3ArrayWithTranslation(TKMatrix4 matrix, TKVector3 *vectors, size_t vectorCount);


/* Assumes 1 in the w component and divides the resulting vector by w before returning. */
TEXTUREKIT_INLINE void TKMatrix4MultiplyAndProjectVector3Array(TKMatrix4 matrix, TKVector3 *vectors, size_t vectorCount);

TEXTUREKIT_INLINE TKVector4 TKMatrix4MultiplyVector4(TKMatrix4 matrixLeft, TKVector4 vectorRight);

TEXTUREKIT_INLINE void TKMatrix4MultiplyVector4Array(TKMatrix4 matrix, TKVector4 *vectors, size_t vectorCount);

#pragma mark -
#pragma mark Implementations
#pragma mark -


TEXTUREKIT_INLINE NSString *NSStringFromMatrix4(TKMatrix4 matrix) {
	return [NSString stringWithFormat:@"[%0.4f, %0.4f, %0.4f, %0.4f,\n%0.4f, %0.4f, %0.4f, %0.4f,\n%0.4f, %0.4f, %0.4f, %0.4f,\n%0.4f, %0.4f, %0.4f, %0.4f\n]",
			matrix.m00, matrix.m01, matrix.m02, matrix.m03,
			matrix.m10, matrix.m11, matrix.m12, matrix.m13,
			matrix.m20, matrix.m21, matrix.m22, matrix.m23,
			matrix.m30, matrix.m31, matrix.m32, matrix.m33];
	
}


TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Make(float m00, float m01, float m02, float m03,
										  float m10, float m11, float m12, float m13,
										  float m20, float m21, float m22, float m23,
										  float m30, float m31, float m32, float m33) {
	TKMatrix4 m = { m00, m01, m02, m03,
					m10, m11, m12, m13,
					m20, m21, m22, m23,
					m30, m31, m32, m33 };
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeAndTranspose(float m00, float m01, float m02, float m03,
														float m10, float m11, float m12, float m13,
														float m20, float m21, float m22, float m23,
														float m30, float m31, float m32, float m33) {
	TKMatrix4 m = { m00, m10, m20, m30,
					m01, m11, m21, m31,
					m02, m12, m22, m32,
					m03, m13, m23, m33 };
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeWithArray(float values[16]) {
	TKMatrix4 m = { values[0], values[1], values[2], values[3],
					values[4], values[5], values[6], values[7],
					values[8], values[9], values[10], values[11],
					values[12], values[13], values[14], values[15] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeWithArrayAndTranspose(float values[16]) {
	TKMatrix4 m = { values[0], values[4], values[8], values[12],
					values[1], values[5], values[9], values[13],
					values[2], values[6], values[10], values[14],
					values[3], values[7], values[11], values[15] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeWithRows(TKVector4 row0,
												  TKVector4 row1, 
												  TKVector4 row2,
												  TKVector4 row3) {
	
	TKMatrix4 m = { row0.v[0], row1.v[0], row2.v[0], row3.v[0],
					row0.v[1], row1.v[1], row2.v[1], row3.v[1],
					row0.v[2], row1.v[2], row2.v[2], row3.v[2],
					row0.v[3], row1.v[3], row2.v[3], row3.v[3] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeWithColumns(TKVector4 column0,
													 TKVector4 column1, 
													 TKVector4 column2,
													 TKVector4 column3) {
	
	TKMatrix4 m = { column0.v[0], column0.v[1], column0.v[2], column0.v[3],
					 column1.v[0], column1.v[1], column1.v[2], column1.v[3],
					 column2.v[0], column2.v[1], column2.v[2], column2.v[3],
					 column3.v[0], column3.v[1], column3.v[2], column3.v[3] };
	return m;
}
	
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeWithQuaternion(TKQuaternion quaternion) {
	quaternion = TKQuaternionNormalize(quaternion);
	
	float x = quaternion.q[0];
	float y = quaternion.q[1];
	float z = quaternion.q[2];
	float w = quaternion.q[3];
	
	float _2x = x + x;
	float _2y = y + y;
	float _2z = z + z;
	float _2w = w + w;
	
	TKMatrix4 m = { 1.0f - _2y * y - _2z * z,
					 _2x * y + _2w * z,
					 _2x * z - _2w * y,
					 0.0f,
					 _2x * y - _2w * z,
					 1.0f - _2x * x - _2z * z,
					 _2y * z + _2w * x,
					 0.0f,
					 _2x * z + _2w * y,
					 _2y * z - _2w * x,
					 1.0f - _2x * x - _2y * y,
					 0.0f,
					 0.0f,
					 0.0f,
					 0.0f,
					 1.0f };
	
	return m;
}
	
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeTranslation(float tx, float ty, float tz) {
	TKMatrix4 m = TKMatrix4Identity;
	m.m[12] = tx;
	m.m[13] = ty;
	m.m[14] = tz;
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeScale(float sx, float sy, float sz) {
	TKMatrix4 m = TKMatrix4Identity;
	m.m[0] = sx;
	m.m[5] = sy;
	m.m[10] = sz;
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeRotation(float radians, float x, float y, float z) {
	TKVector3 v = TKVector3Normalize(TKVector3Make(x, y, z));
	float cos = cosf(radians);
	float cosp = 1.0f - cos;
	float sin = sinf(radians);
	
	TKMatrix4 m = { cos + cosp * v.v[0] * v.v[0],
					cosp * v.v[0] * v.v[1] + v.v[2] * sin,
					cosp * v.v[0] * v.v[2] - v.v[1] * sin,
					0.0f,
					cosp * v.v[0] * v.v[1] - v.v[2] * sin,
					cos + cosp * v.v[1] * v.v[1],
					cosp * v.v[1] * v.v[2] + v.v[0] * sin,
					0.0f,
					cosp * v.v[0] * v.v[2] + v.v[1] * sin,
					cosp * v.v[1] * v.v[2] - v.v[0] * sin,
					cos + cosp * v.v[2] * v.v[2],
					0.0f,
					0.0f,
					0.0f,
					0.0f,
					1.0f };

	return m;
}
   
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeXRotation(float radians) {
	float cos = cosf(radians);
	float sin = sinf(radians);
	
	TKMatrix4 m = { 1.0f, 0.0f, 0.0f, 0.0f,
					 0.0f, cos, sin, 0.0f,
					 0.0f, -sin, cos, 0.0f,
					 0.0f, 0.0f, 0.0f, 1.0f };
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeYRotation(float radians) {
	float cos = cosf(radians);
	float sin = sinf(radians);
	
	TKMatrix4 m = { cos, 0.0f, -sin, 0.0f,
					0.0f, 1.0f, 0.0f, 0.0f,
					sin, 0.0f, cos, 0.0f,
					0.0f, 0.0f, 0.0f, 1.0f };
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeZRotation(float radians) {
	float cos = cosf(radians);
	float sin = sinf(radians);
	
	TKMatrix4 m = { cos, sin, 0.0f, 0.0f,
					-sin, cos, 0.0f, 0.0f,
					0.0f, 0.0f, 1.0f, 0.0f,
					0.0f, 0.0f, 0.0f, 1.0f };
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakePerspective(float fovyRadians, float aspect, float nearZ, float farZ) {
	float cotan = 1.0f / tanf(fovyRadians / 2.0f);
	
	TKMatrix4 m = { cotan / aspect, 0.0f, 0.0f, 0.0f,
					0.0f, cotan, 0.0f, 0.0f,
					0.0f, 0.0f, (farZ + nearZ) / (nearZ - farZ), -1.0f,
					0.0f, 0.0f, (2.0f * farZ * nearZ) / (nearZ - farZ), 0.0f };
	
	return m;
}
	
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeFrustum(float left, float right,
												   float bottom, float top,
												   float nearZ, float farZ) {
	float ral = right + left;
	float rsl = right - left;
	float tsb = top - bottom;
	float tab = top + bottom;
	float fan = farZ + nearZ;
	float fsn = farZ - nearZ;
	
	TKMatrix4 m = { 2.0f * nearZ / rsl, 0.0f, 0.0f, 0.0f,
					 0.0f, 2.0f * nearZ / tsb, 0.0f, 0.0f,
					 ral / rsl, tab / tsb, -fan / fsn, -1.0f,
					 0.0f, 0.0f, (-2.0f * farZ * nearZ) / fsn, 0.0f };
	
	return m;
}
	
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeOrtho(float left, float right,
											   float bottom, float top,
											   float nearZ, float farZ) {
	float ral = right + left;
	float rsl = right - left;
	float tab = top + bottom;
	float tsb = top - bottom;
	float fan = farZ + nearZ;
	float fsn = farZ - nearZ;
	
	TKMatrix4 m = { 2.0f / rsl, 0.0f, 0.0f, 0.0f,
					0.0f, 2.0f / tsb, 0.0f, 0.0f,
					0.0f, 0.0f, -2.0f / fsn, 0.0f,
					-ral / rsl, -tab / tsb, -fan / fsn, 1.0f };
					
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4MakeLookAt(float eyeX, float eyeY, float eyeZ,
												float centerX, float centerY, float centerZ,
												float upX, float upY, float upZ) {
	
	TKVector3 ev = { eyeX, eyeY, eyeZ };
	TKVector3 cv = { centerX, centerY, centerZ };
	TKVector3 uv = { upX, upY, upZ };
	TKVector3 n = TKVector3Normalize(TKVector3Add(ev, TKVector3Negate(cv)));
	TKVector3 u = TKVector3Normalize(TKVector3CrossProduct(uv, n));
	TKVector3 v = TKVector3CrossProduct(n, u);
	
	TKMatrix4 m = { u.v[0], v.v[0], n.v[0], 0.0f,
					u.v[1], v.v[1], n.v[1], 0.0f,
					u.v[2], v.v[2], n.v[2], 0.0f,
					TKVector3DotProduct(TKVector3Negate(u), ev),
					TKVector3DotProduct(TKVector3Negate(v), ev),
					TKVector3DotProduct(TKVector3Negate(n), ev),
					1.0f };
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix3 TKMatrix4GetMatrix3(TKMatrix4 matrix) {
	TKMatrix3 m = { matrix.m[0], matrix.m[1], matrix.m[2],
					matrix.m[4], matrix.m[5], matrix.m[6],
					matrix.m[8], matrix.m[9], matrix.m[10] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix2 TKMatrix4GetMatrix2(TKMatrix4 matrix) {
	TKMatrix2 m = { matrix.m[0], matrix.m[1],
					 matrix.m[4], matrix.m[5] };
	return m;
}

TEXTUREKIT_INLINE TKVector4 TKMatrix4GetRow(TKMatrix4 matrix, int row) {
	TKVector4 v = { matrix.m[row], matrix.m[4 + row], matrix.m[8 + row], matrix.m[12 + row] };
	return v;
}

TEXTUREKIT_INLINE TKVector4 TKMatrix4GetColumn(TKMatrix4 matrix, int column) {
	TKVector4 v = { matrix.m[column * 4 + 0], matrix.m[column * 4 + 1], matrix.m[column * 4 + 2], matrix.m[column * 4 + 3] };
	return v;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4SetRow(TKMatrix4 matrix, int row, TKVector4 vector) {
	matrix.m[row] = vector.v[0];
	matrix.m[row + 4] = vector.v[1];
	matrix.m[row + 8] = vector.v[2];
	matrix.m[row + 12] = vector.v[3];
	
	return matrix;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4SetColumn(TKMatrix4 matrix, int column, TKVector4 vector) {
	matrix.m[column * 4 + 0] = vector.v[0];
	matrix.m[column * 4 + 1] = vector.v[1];
	matrix.m[column * 4 + 2] = vector.v[2];
	matrix.m[column * 4 + 3] = vector.v[3];
	return matrix;
}
	
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Transpose(TKMatrix4 matrix) {
	TKMatrix4 m = { matrix.m[0], matrix.m[4], matrix.m[8], matrix.m[12],
					matrix.m[1], matrix.m[5], matrix.m[9], matrix.m[13],
					matrix.m[2], matrix.m[6], matrix.m[10], matrix.m[14],
					matrix.m[3], matrix.m[7], matrix.m[11], matrix.m[15] };
	return m;
}

#ifndef __clang__
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Multiply(TKMatrix4 matrixLeft, TKMatrix4 matrixRight)
#else
static TKMatrix4 TKMatrix4Multiply(TKMatrix4 matrixLeft, TKMatrix4 matrixRight)
#endif
{
	TKMatrix4 m;
	
	m.m[0]	= matrixLeft.m[0] * matrixRight.m[0]  + matrixLeft.m[4] * matrixRight.m[1]	+ matrixLeft.m[8] * matrixRight.m[2]   + matrixLeft.m[12] * matrixRight.m[3];
	m.m[4]	= matrixLeft.m[0] * matrixRight.m[4]  + matrixLeft.m[4] * matrixRight.m[5]	+ matrixLeft.m[8] * matrixRight.m[6]   + matrixLeft.m[12] * matrixRight.m[7];
	m.m[8]	= matrixLeft.m[0] * matrixRight.m[8]  + matrixLeft.m[4] * matrixRight.m[9]	+ matrixLeft.m[8] * matrixRight.m[10]  + matrixLeft.m[12] * matrixRight.m[11];
	m.m[12] = matrixLeft.m[0] * matrixRight.m[12] + matrixLeft.m[4] * matrixRight.m[13] + matrixLeft.m[8] * matrixRight.m[14]  + matrixLeft.m[12] * matrixRight.m[15];
	
	m.m[1]	= matrixLeft.m[1] * matrixRight.m[0]  + matrixLeft.m[5] * matrixRight.m[1]	+ matrixLeft.m[9] * matrixRight.m[2]   + matrixLeft.m[13] * matrixRight.m[3];
	m.m[5]	= matrixLeft.m[1] * matrixRight.m[4]  + matrixLeft.m[5] * matrixRight.m[5]	+ matrixLeft.m[9] * matrixRight.m[6]   + matrixLeft.m[13] * matrixRight.m[7];
	m.m[9]	= matrixLeft.m[1] * matrixRight.m[8]  + matrixLeft.m[5] * matrixRight.m[9]	+ matrixLeft.m[9] * matrixRight.m[10]  + matrixLeft.m[13] * matrixRight.m[11];
	m.m[13] = matrixLeft.m[1] * matrixRight.m[12] + matrixLeft.m[5] * matrixRight.m[13] + matrixLeft.m[9] * matrixRight.m[14]  + matrixLeft.m[13] * matrixRight.m[15];
	
	m.m[2]	= matrixLeft.m[2] * matrixRight.m[0]  + matrixLeft.m[6] * matrixRight.m[1]	+ matrixLeft.m[10] * matrixRight.m[2]  + matrixLeft.m[14] * matrixRight.m[3];
	m.m[6]	= matrixLeft.m[2] * matrixRight.m[4]  + matrixLeft.m[6] * matrixRight.m[5]	+ matrixLeft.m[10] * matrixRight.m[6]  + matrixLeft.m[14] * matrixRight.m[7];
	m.m[10] = matrixLeft.m[2] * matrixRight.m[8]  + matrixLeft.m[6] * matrixRight.m[9]	+ matrixLeft.m[10] * matrixRight.m[10] + matrixLeft.m[14] * matrixRight.m[11];
	m.m[14] = matrixLeft.m[2] * matrixRight.m[12] + matrixLeft.m[6] * matrixRight.m[13] + matrixLeft.m[10] * matrixRight.m[14] + matrixLeft.m[14] * matrixRight.m[15];
	
	m.m[3]	= matrixLeft.m[3] * matrixRight.m[0]  + matrixLeft.m[7] * matrixRight.m[1]	+ matrixLeft.m[11] * matrixRight.m[2]  + matrixLeft.m[15] * matrixRight.m[3];
	m.m[7]	= matrixLeft.m[3] * matrixRight.m[4]  + matrixLeft.m[7] * matrixRight.m[5]	+ matrixLeft.m[11] * matrixRight.m[6]  + matrixLeft.m[15] * matrixRight.m[7];
	m.m[11] = matrixLeft.m[3] * matrixRight.m[8]  + matrixLeft.m[7] * matrixRight.m[9]	+ matrixLeft.m[11] * matrixRight.m[10] + matrixLeft.m[15] * matrixRight.m[11];
	m.m[15] = matrixLeft.m[3] * matrixRight.m[12] + matrixLeft.m[7] * matrixRight.m[13] + matrixLeft.m[11] * matrixRight.m[14] + matrixLeft.m[15] * matrixRight.m[15];
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Add(TKMatrix4 matrixLeft, TKMatrix4 matrixRight) {
	TKMatrix4 m;
	
	m.m[0] = matrixLeft.m[0] + matrixRight.m[0];
	m.m[1] = matrixLeft.m[1] + matrixRight.m[1];
	m.m[2] = matrixLeft.m[2] + matrixRight.m[2];
	m.m[3] = matrixLeft.m[3] + matrixRight.m[3];
	
	m.m[4] = matrixLeft.m[4] + matrixRight.m[4];
	m.m[5] = matrixLeft.m[5] + matrixRight.m[5];
	m.m[6] = matrixLeft.m[6] + matrixRight.m[6];
	m.m[7] = matrixLeft.m[7] + matrixRight.m[7];
	
	m.m[8] = matrixLeft.m[8] + matrixRight.m[8];
	m.m[9] = matrixLeft.m[9] + matrixRight.m[9];
	m.m[10] = matrixLeft.m[10] + matrixRight.m[10];
	m.m[11] = matrixLeft.m[11] + matrixRight.m[11];
	
	m.m[12] = matrixLeft.m[12] + matrixRight.m[12];
	m.m[13] = matrixLeft.m[13] + matrixRight.m[13];
	m.m[14] = matrixLeft.m[14] + matrixRight.m[14];
	m.m[15] = matrixLeft.m[15] + matrixRight.m[15];
	
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Subtract(TKMatrix4 matrixLeft, TKMatrix4 matrixRight) {
	TKMatrix4 m;
	
	m.m[0] = matrixLeft.m[0] - matrixRight.m[0];
	m.m[1] = matrixLeft.m[1] - matrixRight.m[1];
	m.m[2] = matrixLeft.m[2] - matrixRight.m[2];
	m.m[3] = matrixLeft.m[3] - matrixRight.m[3];
	
	m.m[4] = matrixLeft.m[4] - matrixRight.m[4];
	m.m[5] = matrixLeft.m[5] - matrixRight.m[5];
	m.m[6] = matrixLeft.m[6] - matrixRight.m[6];
	m.m[7] = matrixLeft.m[7] - matrixRight.m[7];
	
	m.m[8] = matrixLeft.m[8] - matrixRight.m[8];
	m.m[9] = matrixLeft.m[9] - matrixRight.m[9];
	m.m[10] = matrixLeft.m[10] - matrixRight.m[10];
	m.m[11] = matrixLeft.m[11] - matrixRight.m[11];
	
	m.m[12] = matrixLeft.m[12] - matrixRight.m[12];
	m.m[13] = matrixLeft.m[13] - matrixRight.m[13];
	m.m[14] = matrixLeft.m[14] - matrixRight.m[14];
	m.m[15] = matrixLeft.m[15] - matrixRight.m[15];
	
	return m;
}
	
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Translate(TKMatrix4 matrix, float tx, float ty, float tz) {
	TKMatrix4 m = { matrix.m[0], matrix.m[1], matrix.m[2], matrix.m[3],
					matrix.m[4], matrix.m[5], matrix.m[6], matrix.m[7],
					matrix.m[8], matrix.m[9], matrix.m[10], matrix.m[11],
					matrix.m[0] * tx + matrix.m[4] * ty + matrix.m[8] * tz + matrix.m[12],
					matrix.m[1] * tx + matrix.m[5] * ty + matrix.m[9] * tz + matrix.m[13],
					matrix.m[2] * tx + matrix.m[6] * ty + matrix.m[10] * tz + matrix.m[14],
					matrix.m[15] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4TranslateWithVector3(TKMatrix4 matrix, TKVector3 translationVector) {
	TKMatrix4 m = { matrix.m[0], matrix.m[1], matrix.m[2], matrix.m[3],
					matrix.m[4], matrix.m[5], matrix.m[6], matrix.m[7],
					matrix.m[8], matrix.m[9], matrix.m[10], matrix.m[11],
					matrix.m[0] * translationVector.v[0] + matrix.m[4] * translationVector.v[1] + matrix.m[8] * translationVector.v[2] + matrix.m[12],
					matrix.m[1] * translationVector.v[0] + matrix.m[5] * translationVector.v[1] + matrix.m[9] * translationVector.v[2] + matrix.m[13],
					matrix.m[2] * translationVector.v[0] + matrix.m[6] * translationVector.v[1] + matrix.m[10] * translationVector.v[2] + matrix.m[14],
					matrix.m[15] };
	return m;
}
	
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4TranslateWithVector4(TKMatrix4 matrix, TKVector4 translationVector) {
	TKMatrix4 m = { matrix.m[0], matrix.m[1], matrix.m[2], matrix.m[3],
					matrix.m[4], matrix.m[5], matrix.m[6], matrix.m[7],
					matrix.m[8], matrix.m[9], matrix.m[10], matrix.m[11],
					matrix.m[0] * translationVector.v[0] + matrix.m[4] * translationVector.v[1] + matrix.m[8] * translationVector.v[2] + matrix.m[12],
					matrix.m[1] * translationVector.v[0] + matrix.m[5] * translationVector.v[1] + matrix.m[9] * translationVector.v[2] + matrix.m[13],
					matrix.m[2] * translationVector.v[0] + matrix.m[6] * translationVector.v[1] + matrix.m[10] * translationVector.v[2] + matrix.m[14],
					matrix.m[15] };
	return m;
}
	
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Scale(TKMatrix4 matrix, float sx, float sy, float sz) {
	TKMatrix4 m = { matrix.m[0] * sx, matrix.m[1] * sx, matrix.m[2] * sx, matrix.m[3] * sx,
					matrix.m[4] * sy, matrix.m[5] * sy, matrix.m[6] * sy, matrix.m[7] * sy,
					matrix.m[8] * sz, matrix.m[9] * sz, matrix.m[10] * sz, matrix.m[11] * sz,
					matrix.m[12], matrix.m[13], matrix.m[14], matrix.m[15] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4ScaleWithVector3(TKMatrix4 matrix, TKVector3 scaleVector) {
	TKMatrix4 m = { matrix.m[0] * scaleVector.v[0], matrix.m[1] * scaleVector.v[0], matrix.m[2] * scaleVector.v[0], matrix.m[3] * scaleVector.v[0],
					matrix.m[4] * scaleVector.v[1], matrix.m[5] * scaleVector.v[1], matrix.m[6] * scaleVector.v[1], matrix.m[7] * scaleVector.v[1],
					matrix.m[8] * scaleVector.v[2], matrix.m[9] * scaleVector.v[2], matrix.m[10] * scaleVector.v[2], matrix.m[11] * scaleVector.v[2],
					matrix.m[12], matrix.m[13], matrix.m[14], matrix.m[15] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4ScaleWithVector4(TKMatrix4 matrix, TKVector4 scaleVector) {
	TKMatrix4 m = { matrix.m[0] * scaleVector.v[0], matrix.m[1] * scaleVector.v[0], matrix.m[2] * scaleVector.v[0], matrix.m[3] * scaleVector.v[0],
					matrix.m[4] * scaleVector.v[1], matrix.m[5] * scaleVector.v[1], matrix.m[6] * scaleVector.v[1], matrix.m[7] * scaleVector.v[1],
					matrix.m[8] * scaleVector.v[2], matrix.m[9] * scaleVector.v[2], matrix.m[10] * scaleVector.v[2], matrix.m[11] * scaleVector.v[2],
					matrix.m[12], matrix.m[13], matrix.m[14], matrix.m[15] };
	return m;
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4Rotate(TKMatrix4 matrix, float radians, float x, float y, float z) {
	TKMatrix4 rm = TKMatrix4MakeRotation(radians, x, y, z);
	return TKMatrix4Multiply(matrix, rm);
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4RotateWithVector3(TKMatrix4 matrix, float radians, TKVector3 axisVector) {
	TKMatrix4 rm = TKMatrix4MakeRotation(radians, axisVector.v[0], axisVector.v[1], axisVector.v[2]);
	return TKMatrix4Multiply(matrix, rm);
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4RotateWithVector4(TKMatrix4 matrix, float radians, TKVector4 axisVector) {
	TKMatrix4 rm = TKMatrix4MakeRotation(radians, axisVector.v[0], axisVector.v[1], axisVector.v[2]);
	return TKMatrix4Multiply(matrix, rm);	 
}
	
TEXTUREKIT_INLINE TKMatrix4 TKMatrix4RotateX(TKMatrix4 matrix, float radians) {
	TKMatrix4 rm = TKMatrix4MakeXRotation(radians);
	return TKMatrix4Multiply(matrix, rm);
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4RotateY(TKMatrix4 matrix, float radians) {
	TKMatrix4 rm = TKMatrix4MakeYRotation(radians);
	return TKMatrix4Multiply(matrix, rm);
}

TEXTUREKIT_INLINE TKMatrix4 TKMatrix4RotateZ(TKMatrix4 matrix, float radians) {
	TKMatrix4 rm = TKMatrix4MakeZRotation(radians);
	return TKMatrix4Multiply(matrix, rm);
}
	
TEXTUREKIT_INLINE TKVector3 TKMatrix4MultiplyVector3(TKMatrix4 matrixLeft, TKVector3 vectorRight) {
	TKVector4 v4 = TKMatrix4MultiplyVector4(matrixLeft, TKVector4Make(vectorRight.v[0], vectorRight.v[1], vectorRight.v[2], 0.0f));
	return TKVector3Make(v4.v[0], v4.v[1], v4.v[2]);
}

TEXTUREKIT_INLINE TKVector3 TKMatrix4MultiplyVector3WithTranslation(TKMatrix4 matrixLeft, TKVector3 vectorRight) {
	TKVector4 v4 = TKMatrix4MultiplyVector4(matrixLeft, TKVector4Make(vectorRight.v[0], vectorRight.v[1], vectorRight.v[2], 1.0f));
	return TKVector3Make(v4.v[0], v4.v[1], v4.v[2]);
}
	
TEXTUREKIT_INLINE TKVector3 TKMatrix4MultiplyAndProjectVector3(TKMatrix4 matrixLeft, TKVector3 vectorRight) {
	TKVector4 v4 = TKMatrix4MultiplyVector4(matrixLeft, TKVector4Make(vectorRight.v[0], vectorRight.v[1], vectorRight.v[2], 1.0f));
	return TKVector3MultiplyScalar(TKVector3Make(v4.v[0], v4.v[1], v4.v[2]), 1.0f / v4.v[3]);
}

TEXTUREKIT_INLINE void TKMatrix4MultiplyVector3Array(TKMatrix4 matrix, TKVector3 *vectors, size_t vectorCount) {
	int i;
	for (i=0; i < vectorCount; i++)
		vectors[i] = TKMatrix4MultiplyVector3(matrix, vectors[i]);
}

TEXTUREKIT_INLINE void TKMatrix4MultiplyVector3ArrayWithTranslation(TKMatrix4 matrix, TKVector3 *vectors, size_t vectorCount) {
	int i;
	for (i=0; i < vectorCount; i++)
		vectors[i] = TKMatrix4MultiplyVector3WithTranslation(matrix, vectors[i]);
}
	
TEXTUREKIT_INLINE void TKMatrix4MultiplyAndProjectVector3Array(TKMatrix4 matrix, TKVector3 *vectors, size_t vectorCount) {
	int i;
	for (i=0; i < vectorCount; i++)
		vectors[i] = TKMatrix4MultiplyAndProjectVector3(matrix, vectors[i]);
}

TEXTUREKIT_INLINE TKVector4 TKMatrix4MultiplyVector4(TKMatrix4 matrixLeft, TKVector4 vectorRight) {
	TKVector4 v = { matrixLeft.m[0] * vectorRight.v[0] + matrixLeft.m[4] * vectorRight.v[1] + matrixLeft.m[8] * vectorRight.v[2] + matrixLeft.m[12] * vectorRight.v[3],
					matrixLeft.m[1] * vectorRight.v[0] + matrixLeft.m[5] * vectorRight.v[1] + matrixLeft.m[9] * vectorRight.v[2] + matrixLeft.m[13] * vectorRight.v[3],
					matrixLeft.m[2] * vectorRight.v[0] + matrixLeft.m[6] * vectorRight.v[1] + matrixLeft.m[10] * vectorRight.v[2] + matrixLeft.m[14] * vectorRight.v[3],
					matrixLeft.m[3] * vectorRight.v[0] + matrixLeft.m[7] * vectorRight.v[1] + matrixLeft.m[11] * vectorRight.v[2] + matrixLeft.m[15] * vectorRight.v[3] };
	return v;
}

TEXTUREKIT_INLINE void TKMatrix4MultiplyVector4Array(TKMatrix4 matrix, TKVector4 *vectors, size_t vectorCount) {
	int i;
	for (i=0; i < vectorCount; i++)
		vectors[i] = TKMatrix4MultiplyVector4(matrix, vectors[i]);
}

