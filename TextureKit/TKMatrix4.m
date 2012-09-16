//
//  TKMatrix4.m
//  Texture Kit
//
//  Created by Mark Douma on 12/7/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKMatrix4.h>


#define TK_DEBUG 1


	// [ 0 4  8 12 ]
	// [ 1 5  9 13 ]
	// [ 2 6 10 14 ]
	// [ 3 7 11 15 ]
const TKMatrix4 TKMatrix4Identity = {	1.0f, 0.0f, 0.0f, 0.0f,
										0.0f, 1.0f, 0.0f, 0.0f,
										0.0f, 0.0f, 1.0f, 0.0f,
										0.0f, 0.0f, 0.0f, 1.0f};


TKMatrix4 TKMatrix4Invert(TKMatrix4 source, BOOL *isInvertible) {
	TKMatrix4 tmp = TKMatrix4Transpose(source);
	
	float val, val2, val_inv, zero, one;
	int i, j, i4, i8, i12, ind;
	
	TKMatrix4 returnMatrix = TKMatrix4Identity;
	
	for (i = 0; i != 4; i++) {
		val = tmp.m[(i << 2) + i];
		ind = i;
		
		i4  = i + 4;
		i8  = i + 8;
		i12 = i + 12;
		for (j = i + 1; j != 4; j++) {
			if (fabsf(tmp.m[(i << 2) + j]) > fabsf(val)) {
				ind = j;
				val = tmp.m[(i << 2) + j];
			}
		}
		
		if (ind != i) {
			val2					= returnMatrix.m[i];
			returnMatrix.m[i]		= returnMatrix.m[ind];
			returnMatrix.m[ind]		= val2;
			
			val2      = tmp.m[i];
			tmp.m[i]    = tmp.m[ind];
			tmp.m[ind]  = val2;
			
			ind += 4;
			
			val2				 = returnMatrix.m[i4];
			returnMatrix.m[i4]   = returnMatrix.m[ind];
			returnMatrix.m[ind]  = val2;
			
			val2      = tmp.m[i4];
			tmp.m[i4]   = tmp.m[ind];
			tmp.m[ind]  = val2;
			
			ind += 4;
			
			val2      = returnMatrix.m[i8];
			returnMatrix.m[i8]   = returnMatrix.m[ind];
			returnMatrix.m[ind]  = val2;
			
			val2      = tmp.m[i8];
			tmp.m[i8]   = tmp.m[ind];
			tmp.m[ind]  = val2;
			
			ind += 4;
			
			val2					= returnMatrix.m[i12];
			returnMatrix.m[i12]		= returnMatrix.m[ind];
			returnMatrix.m[ind]		= val2;
			
			val2      = tmp.m[i12];
			tmp.m[i12]  = tmp.m[ind];
			tmp.m[ind]  = val2;
		}
		
		if (val == zero) {
			return TKMatrix4Identity;
		}
		
		val_inv = one / val;
		
		tmp.m[i]   *= val_inv;
		returnMatrix.m[i]   *= val_inv;
		
		tmp.m[i4]  *= val_inv;
		returnMatrix.m[i4]  *= val_inv;
		
		tmp.m[i8]  *= val_inv;
		returnMatrix.m[i8]  *= val_inv;
		
		tmp.m[i12] *= val_inv;
		returnMatrix.m[i12] *= val_inv;
		
		if (i != 0) {
			val = tmp.m[i << 2];
			
			tmp.m[0]  -= tmp.m[i] * val;
			returnMatrix.m[0]  -= returnMatrix.m[i] * val;
			
			tmp.m[4]  -= tmp.m[i4] * val;
			returnMatrix.m[4]  -= returnMatrix.m[i4] * val;
			
			tmp.m[8]  -= tmp.m[i8] * val;
			returnMatrix.m[8]  -= returnMatrix.m[i8] * val;
			
			tmp.m[12] -= tmp.m[i12] * val;
			returnMatrix.m[12] -= returnMatrix.m[i12] * val;
		}
		if (i != 1) {
			val = tmp.m[(i << 2) + 1];
			
			tmp.m[1]  -= tmp.m[i] * val;
			returnMatrix.m[1]  -= returnMatrix.m[i] * val;
			
			tmp.m[5]  -= tmp.m[i4] * val;
			returnMatrix.m[5]  -= returnMatrix.m[i4] * val;
			
			tmp.m[9]  -= tmp.m[i8] * val;
			returnMatrix.m[9]  -= returnMatrix.m[i8] * val;
			
			tmp.m[13] -= tmp.m[i12] * val;
			returnMatrix.m[13] -= returnMatrix.m[i12] * val;
		}
		if (i != 2) {
			val = tmp.m[(i << 2) + 2];
			
			tmp.m[2]  -= tmp.m[i] * val;
			returnMatrix.m[2]  -= returnMatrix.m[i] * val;
			
			tmp.m[6]  -= tmp.m[i4] * val;
			returnMatrix.m[6]  -= returnMatrix.m[i4] * val;
			
			tmp.m[10] -= tmp.m[i8] * val;
			returnMatrix.m[10] -= returnMatrix.m[i8] * val;
			
			tmp.m[14] -= tmp.m[i12] * val;
			returnMatrix.m[14] -= returnMatrix.m[i12] * val;
		}
		if (i != 3) {
			val = tmp.m[(i << 2) + 3];
			
			tmp.m[3]  -= tmp.m[i] * val;
			returnMatrix.m[3]  -= returnMatrix.m[i] * val;
			
			tmp.m[7]  -= tmp.m[i4] * val;
			returnMatrix.m[7]  -= returnMatrix.m[i4] * val;
			
			tmp.m[11] -= tmp.m[i8] * val;
			returnMatrix.m[11] -= returnMatrix.m[i8] * val;
			
			tmp.m[15] -= tmp.m[i12] * val;
			returnMatrix.m[15] -= returnMatrix.m[i12] * val;
		}
	}
	return returnMatrix;
}




//TKMatrix4 TKMatrix4InvertAndTranspose(TKMatrix4 matrix, BOOL *isInvertible);






