//
//  TKMatrix3.m
//  Texture Kit
//
//  Created by Mark Douma on 12/7/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKMatrix3.h>


#define TK_DEBUG 1


const TKMatrix3 TKMatrix3Identity = {	1.0f, 0.0f, 0.0f,
										0.0f, 1.0f, 0.0f,
										0.0f, 0.0f, 1.0f };



TKMatrix3 TKMatrix3Invert(TKMatrix3 source, BOOL *isInvertible) {
	float cpy[9];
	float det =
	        source.m[0] * (source.m[4] * source.m[8] - source.m[7] * source.m[5]) -
	        source.m[1] * (source.m[3] * source.m[8] - source.m[6] * source.m[5]) +
	        source.m[2] * (source.m[3] * source.m[7] - source.m[6] * source.m[4]);

	if (fabs(det) < 0.0005) {
		return TKMatrix3Identity;
	}
	memcpy(cpy, source.m, 9 * sizeof(float));
	
	TKMatrix3 returnMatrix = TKMatrix3Identity;
	
	returnMatrix.m[0] = cpy[4] * cpy[8] - cpy[5] * cpy[7] / det;
	returnMatrix.m[1] = -(cpy[1] * cpy[8] - cpy[7] * cpy[2]) / det;
	returnMatrix.m[2] = cpy[1] * cpy[5] - cpy[4] * cpy[2] / det;

	returnMatrix.m[3] = -(cpy[3] * cpy[8] - cpy[5] * cpy[6]) / det;
	returnMatrix.m[4] = cpy[0] * cpy[8] - cpy[6] * cpy[2] / det;
	returnMatrix.m[5] = -(cpy[0] * cpy[5] - cpy[3] * cpy[2]) / det;

	returnMatrix.m[6] = cpy[3] * cpy[7] - cpy[6] * cpy[4] / det;
	returnMatrix.m[7] = -(cpy[0] * cpy[7] - cpy[6] * cpy[1]) / det;
	returnMatrix.m[8] = cpy[0] * cpy[4] - cpy[1] * cpy[3] / det;
	
	return returnMatrix;
}





//TKMatrix3 TKMatrix3InvertAndTranspose(TKMatrix3 matrix, BOOL *isInvertible);







