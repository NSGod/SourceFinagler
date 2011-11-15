// This code is in the public domain -- castanyo@yahoo.es

#pragma once
#ifndef NV_IMAGE_BASE_H
#define NV_IMAGE_BASE_H

#include <NVMath/NVMath.h>

#include <NVImage/ImageDefines.h>



namespace nv {
	
    // Some utility functions:
	
    inline uint computeBitPitch(uint w, uint bitsize, uint alignmentInBits)
    {
        nvDebugCheck(isPowerOfTwo(alignmentInBits));
		
        return ((w * bitsize +  alignmentInBits - 1) / alignmentInBits) * alignmentInBits;
    }
	
    inline uint computeBytePitch(uint w, uint bitsize, uint alignmentInBits)
    {
        nvDebugCheck(alignmentInBits >= 8);
		
        uint pitch = computeBitPitch(w, bitsize, alignmentInBits);
		
        return (pitch + 7) / 8;
    }
	
	
} // nv namespace

#endif // NV_IMAGE_BASE_H
