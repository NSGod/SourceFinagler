// This code is in the public domain -- castanyo@yahoo.es

#pragma once
#ifndef NV_IMAGE_BASE_H
#define NV_IMAGE_BASE_H

#include <NVMath/NVMath.h>

#include <NVImage/ImageDefines.h>


inline uint computePitch(uint w, uint bitsize, uint alignment)
{
	return ((w * bitsize + 8 * alignment - 1) / (8 * alignment)) * alignment;
}



#endif // NV_IMAGE_BASE_H
