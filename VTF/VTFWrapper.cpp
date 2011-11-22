/*
 * VTFLib
 * Copyright (C) 2005-2010 Neil Jedrzejewski & Ryan Gregg

 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later
 * version.
 */

#include <VTF/VTFLib.h>
#include <VTF/VTFWrapper.h>
#include <VTF/VTFFile.h>


using namespace VTFLib;

//
// vlImageBound()
// Returns true if an lpImage is bound, false otherwise.
//
VTFLIB_API vlBool vlImageIsBound() {
	if (!bInitialized) {
		LastError.Set("VTFLib not initialized.");
		return vlFalse;
	}
	return lpImage != 0;
}


//
// vlBindImage()
// Bind an image to operate on.
// All library routines will use this image.
//
VTFLIB_API vlBool vlBindImage(vlUInt uiImage) {
	if (!bInitialized) {
		LastError.Set("VTFLib not initialized.");
		return vlFalse;
	}
	if (uiImage >= lpImageVector->size() || (*lpImageVector)[uiImage] == 0) {
		LastError.Set("Invalid image.");
		return vlFalse;
	}
	if (lpImage == (*lpImageVector)[uiImage]) {  // If it is already bound do nothing.
		return vlTrue;
	}
	lpImage = (*lpImageVector)[uiImage];

	return vlTrue;
}


//
// vlCreateImage()
// Create an image to work on.
//
VTFLIB_API vlBool vlCreateImage(vlUInt *uiImage) {
	if (!bInitialized) {
		LastError.Set("VTFLib not initialized.");
		return vlFalse;
	}
	lpImageVector->push_back(new CVTFFile());
	*uiImage = (vlUInt)lpImageVector->size() - 1;

	return vlTrue;
}


//
// vlDeleteImage()
// Delete an image and all resources associated with it.
//
VTFLIB_API vlVoid vlDeleteImage(vlUInt uiImage) {
	if (!bInitialized) {
		return;
	}
	if (uiImage >= lpImageVector->size()) {
		return;
	}
	if ((*lpImageVector)[uiImage] == 0) {
		return;
	}
	if ((*lpImageVector)[uiImage] == lpImage) {
		lpImage = 0;
	}
	delete (*lpImageVector)[uiImage];
	(*lpImageVector)[uiImage] = 0;
}


VTFLIB_API vlVoid vlImageCreateDefaultCreateStructure(SVTFCreateOptions *VTFCreateOptions) {
	VTFCreateOptions->uiVersion[0] = VTF_MAJOR_VERSION;
	VTFCreateOptions->uiVersion[1] = VTF_MINOR_VERSION;

	VTFCreateOptions->ImageFormat = IMAGE_FORMAT_RGBA8888;

	VTFCreateOptions->uiFlags = 0;
	VTFCreateOptions->uiStartFrame = 0;
	VTFCreateOptions->sBumpScale = 1.0f;
	VTFCreateOptions->sReflectivity[0] = 1.0f;
	VTFCreateOptions->sReflectivity[1] = 1.0f;
	VTFCreateOptions->sReflectivity[2] = 1.0f;

	VTFCreateOptions->bMipmaps = vlTrue;
	VTFCreateOptions->MipmapFilter = MIPMAP_FILTER_BOX;
	VTFCreateOptions->MipmapSharpenFilter = SHARPEN_FILTER_DEFAULT;

	VTFCreateOptions->bResize = vlFalse;
	VTFCreateOptions->ResizeMethod = RESIZE_NEAREST_POWER2;
	VTFCreateOptions->ResizeFilter = MIPMAP_FILTER_TRIANGLE;
	VTFCreateOptions->ResizeSharpenFilter = SHARPEN_FILTER_DEFAULT;
	VTFCreateOptions->uiResizeWidth = 0;
	VTFCreateOptions->uiResizeHeight = 0;

	VTFCreateOptions->bResizeClamp = vlTrue;
	VTFCreateOptions->uiResizeClampWidth = 4096;
	VTFCreateOptions->uiResizeClampHeight = 4096;

	VTFCreateOptions->bThumbnail = vlTrue;
	VTFCreateOptions->bReflectivity = vlTrue;

	VTFCreateOptions->bGammaCorrection = vlFalse;
	VTFCreateOptions->sGammaCorrection = 2.0f;

	VTFCreateOptions->bNormalMap = vlFalse;
	VTFCreateOptions->KernelFilter = KERNEL_FILTER_3X3;
	VTFCreateOptions->HeightConversionMethod = HEIGHT_CONVERSION_METHOD_DEFAULT;
	VTFCreateOptions->NormalAlphaResult = NORMAL_ALPHA_RESULT_DEFAULT;
	VTFCreateOptions->bNormalMinimumZ = 0;
	VTFCreateOptions->sNormalScale = 2.0f;
	VTFCreateOptions->bNormalWrap = vlFalse;
	VTFCreateOptions->bNormalInvertX = vlFalse;
	VTFCreateOptions->bNormalInvertY = vlFalse;
	VTFCreateOptions->bNormalInvertZ = vlFalse;

	VTFCreateOptions->bSphereMap = vlTrue;
//	VTFCreateOptions->bSphereMap = vlFalse;
}


VTFLIB_API vlBool vlImageCreate(vlUInt uiWidth, vlUInt uiHeight, vlUInt uiFrames, vlUInt uiFaces, vlUInt uiSlices, VTFImageFormat ImageFormat, vlBool bThumbnail, vlBool bMipmaps, vlBool bNullImageData) {
	if (lpImage == 0) {
		LastError.Set("No image bound.");
		return vlFalse;
	}
	return lpImage->Create(uiWidth, uiHeight, uiFrames, uiFaces, uiSlices, ImageFormat, bThumbnail, bMipmaps, bNullImageData);
}


VTFLIB_API vlBool vlImageCreateSingle(vlUInt uiWidth, vlUInt uiHeight, vlByte *lpImageDataRGBA8888, SVTFCreateOptions *VTFCreateOptions) {
	if (lpImage == 0) {
		LastError.Set("No image bound.");
		return vlFalse;
	}
	return lpImage->Create(uiWidth, uiHeight, lpImageDataRGBA8888, *VTFCreateOptions);
}


VTFLIB_API vlBool vlImageCreateMultiple(vlUInt uiWidth, vlUInt uiHeight, vlUInt uiFrames, vlUInt uiFaces, vlUInt uiSlices, vlByte * *lpImageDataRGBA8888, SVTFCreateOptions *VTFCreateOptions) {
	if (lpImage == 0) {
		LastError.Set("No image bound.");
		return vlFalse;
	}
	return lpImage->Create(uiWidth, uiHeight, uiFrames, uiFaces, uiSlices, lpImageDataRGBA8888, *VTFCreateOptions);
}


VTFLIB_API vlVoid vlImageDestroy() {
	if (lpImage == 0) {
		return;
	}
	lpImage->Destroy();
}


VTFLIB_API vlBool vlImageIsLoaded() {
	if (lpImage == 0) {
		LastError.Set("No image bound.");
		return vlFalse;
	}
	return lpImage->IsLoaded();
}


VTFLIB_API vlBool vlImageLoad(const vlChar *cFileName, vlBool bHeaderOnly) {
	if (lpImage == 0) {
		LastError.Set("No image bound.");
		return vlFalse;
	}
	return lpImage->Load(cFileName, bHeaderOnly);
}


VTFLIB_API vlBool vlImageLoadLump(const vlVoid *lpData, vlUInt uiBufferSize, vlBool bHeaderOnly) {
	if (lpImage == 0) {
		LastError.Set("No image bound.");
		return vlFalse;
	}
	return lpImage->Load(lpData, uiBufferSize, bHeaderOnly);
}


VTFLIB_API vlBool vlImageLoadProc(vlVoid *pUserData, vlBool bHeaderOnly) {
	if (lpImage == 0) {
		LastError.Set("No image bound.");
		return vlFalse;
	}
	return lpImage->Load(pUserData, bHeaderOnly);
}


VTFLIB_API vlBool vlImageSave(const vlChar *cFileName) {
	if (lpImage == 0) {
		LastError.Set("No image bound.");
		return vlFalse;
	}
	return lpImage->Save(cFileName);
}


VTFLIB_API vlBool vlImageSaveLump(vlVoid *lpData, vlUInt uiBufferSize, vlUInt *uiSize) {
	if (lpImage == 0) {
		LastError.Set("No image bound.");
		return vlFalse;
	}
	return lpImage->Save(lpData, uiBufferSize, *uiSize);
}


VTFLIB_API vlBool vlImageSaveProc(vlVoid *pUserData) {
	if (lpImage == 0) {
		LastError.Set("No image bound.");
		return vlFalse;
	}
	return lpImage->Save(pUserData);
}


VTFLIB_API vlUInt vlImageGetMajorVersion() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetMajorVersion();
}


VTFLIB_API vlUInt vlImageGetMinorVersion() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetMinorVersion();
}


VTFLIB_API vlUInt vlImageGetSize() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetSize();
}

VTFLIB_API vlUInt vlImageGetHasImage() {
	if (lpImage == 0) {
		return vlFalse;
	}
	return lpImage->GetHasImage();
}


VTFLIB_API vlUInt vlImageGetWidth() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetWidth();
}


VTFLIB_API vlUInt vlImageGetHeight() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetHeight();
}


VTFLIB_API vlUInt vlImageGetDepth() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetDepth();
}


VTFLIB_API vlUInt vlImageGetFrameCount() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetFrameCount();
}


VTFLIB_API vlUInt vlImageGetFaceCount() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetFaceCount();
}


VTFLIB_API vlUInt vlImageGetMipmapCount() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetMipmapCount();
}


VTFLIB_API vlUInt vlImageGetStartFrame() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetStartFrame();
}


VTFLIB_API vlVoid vlImageSetStartFrame(vlUInt uiStartFrame) {
	if (lpImage == 0) {
		return;
	}
	lpImage->SetStartFrame(uiStartFrame);
}


VTFLIB_API vlUInt vlImageGetFlags() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetFlags();
}


VTFLIB_API vlVoid vlImageSetFlags(vlUInt uiFlags) {
	if (lpImage == 0) {
		return;
	}
	lpImage->SetFlags(uiFlags);
}


VTFLIB_API vlBool vlImageGetFlag(VTFImageFlag ImageFlag) {
	if (lpImage == 0) {
		return vlFalse;
	}
	return lpImage->GetFlag(ImageFlag);
}


VTFLIB_API vlVoid vlImageSetFlag(VTFImageFlag ImageFlag, vlBool bState) {
	if (lpImage == 0) {
		return;
	}
	lpImage->SetFlag(ImageFlag, bState);
}


VTFLIB_API vlSingle vlImageGetBumpmapScale() {
	if (lpImage == 0) {
		return 0.0f;
	}
	return lpImage->GetBumpmapScale();
}


VTFLIB_API vlVoid vlImageSetBumpmapScale(vlSingle sBumpmapScale) {
	if (lpImage == 0) {
		return;
	}
	lpImage->SetBumpmapScale(sBumpmapScale);
}


VTFLIB_API vlVoid vlImageGetReflectivity(vlSingle *sX, vlSingle *sY, vlSingle *sZ) {
	if (lpImage == 0) {
		return;
	}
	lpImage->GetReflectivity(*sX, *sY, *sZ);
}


VTFLIB_API vlVoid vlImageSetReflectivity(vlSingle sX, vlSingle sY, vlSingle sZ) {
	if (lpImage == 0) {
		return;
	}
	lpImage->SetReflectivity(sX, sY, sZ);
}


VTFLIB_API VTFImageFormat vlImageGetFormat() {
	if (lpImage == 0) {
		return IMAGE_FORMAT_NONE;
	}
	return lpImage->GetFormat();
}


VTFLIB_API vlByte *vlImageGetData(vlUInt uiFrame, vlUInt uiFace, vlUInt uiSlice, vlUInt uiMipmapLevel) {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetData(uiFrame, uiFace, uiSlice, uiMipmapLevel);
}


VTFLIB_API vlVoid vlImageSetData(vlUInt uiFrame, vlUInt uiFace, vlUInt uiSlice, vlUInt uiMipmapLevel, vlByte *lpData) {
	if (lpImage == 0) {
		return;
	}
	lpImage->SetData(uiFrame, uiFace, uiSlice, uiMipmapLevel, lpData);
}


VTFLIB_API vlBool vlImageGetHasThumbnail() {
	if (lpImage == 0) {
		return vlFalse;
	}
	return lpImage->GetHasThumbnail();
}


VTFLIB_API vlUInt vlImageGetThumbnailWidth() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetThumbnailWidth();
}


VTFLIB_API vlUInt vlImageGetThumbnailHeight() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetThumbnailHeight();
}


VTFLIB_API VTFImageFormat vlImageGetThumbnailFormat() {
	if (lpImage == 0) {
		return IMAGE_FORMAT_NONE;
	}
	return lpImage->GetThumbnailFormat();
}


VTFLIB_API vlByte *vlImageGetThumbnailData() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetThumbnailData();
}


VTFLIB_API vlVoid vlImageSetThumbnailData(vlByte *lpData) {
	if (lpImage == 0) {
		return;
	}
	lpImage->SetThumbnailData(lpData);
}


VTFLIB_API vlBool vlImageGetSupportsResources() {
	if (lpImage == 0) {
		return vlFalse;
	}
	return lpImage->GetSupportsResources();
}


VTFLIB_API vlUInt vlImageGetResourceCount() {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetResourceCount();
}


VTFLIB_API vlUInt vlImageGetResourceType(vlUInt uiIndex) {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetResourceType(uiIndex);
}


VTFLIB_API vlBool vlImageGetHasResource(vlUInt uiType) {
	if (lpImage == 0) {
		return vlFalse;
	}
	return lpImage->GetHasResource(uiType);
}


VTFLIB_API vlVoid *vlImageGetResourceData(vlUInt uiType, vlUInt *uiSize) {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->GetResourceData(uiType, *uiSize);
}


VTFLIB_API vlVoid *vlImageSetResourceData(vlUInt uiType, vlUInt uiSize, vlVoid *lpData) {
	if (lpImage == 0) {
		return 0;
	}
	return lpImage->SetResourceData(uiType, uiSize, lpData);
}


VTFLIB_API vlBool vlImageGenerateMipmaps(vlUInt uiFace, vlUInt uiFrame, VTFMipmapFilter MipmapFilter, VTFSharpenFilter SharpenFilter) {
	if (lpImage == 0) {
		return vlFalse;
	}
	return lpImage->GenerateMipmaps(uiFace, uiFrame, MipmapFilter, SharpenFilter);
}


VTFLIB_API vlBool vlImageGenerateAllMipmaps(VTFMipmapFilter MipmapFilter, VTFSharpenFilter SharpenFilter) {
	if (lpImage == 0) {
		return vlFalse;
	}
	return lpImage->GenerateMipmaps(MipmapFilter, SharpenFilter);
}


VTFLIB_API vlBool vlImageGenerateThumbnail() {
	if (lpImage == 0) {
		return vlFalse;
	}
	return lpImage->GenerateThumbnail();
}


VTFLIB_API vlBool vlImageGenerateNormalMap(vlUInt uiFrame, VTFKernelFilter KernelFilter, VTFHeightConversionMethod HeightConversionMethod, VTFNormalAlphaResult NormalAlphaResult) {
	if (lpImage == 0) {
		return vlFalse;
	}
	return lpImage->GenerateNormalMap(uiFrame, KernelFilter, HeightConversionMethod, NormalAlphaResult);
}


VTFLIB_API vlBool vlImageGenerateAllNormalMaps(VTFKernelFilter KernelFilter, VTFHeightConversionMethod HeightConversionMethod, VTFNormalAlphaResult NormalAlphaResult) {
	if (lpImage == 0) {
		return vlFalse;
	}
	return lpImage->GenerateNormalMap(KernelFilter, HeightConversionMethod, NormalAlphaResult);
}


VTFLIB_API vlBool vlImageGenerateSphereMap() {
	if (lpImage == 0) {
		return vlFalse;
	}
	return lpImage->GenerateSphereMap();
}


VTFLIB_API vlBool vlImageComputeReflectivity() {
	if (lpImage == 0) {
		return vlFalse;
	}
	return lpImage->ComputeReflectivity();
}


VTFLIB_API SVTFImageFormatInfo const *vlImageGetImageFormatInfo(VTFImageFormat ImageFormat) {
	return &CVTFFile::GetImageFormatInfo(ImageFormat);
}


VTFLIB_API vlBool vlImageGetImageFormatInfoEx(VTFImageFormat ImageFormat, SVTFImageFormatInfo *VTFImageFormatInfo) {
	if (ImageFormat >= 0 && ImageFormat < IMAGE_FORMAT_COUNT) {
		memcpy(VTFImageFormatInfo, &CVTFFile::GetImageFormatInfo(ImageFormat), sizeof(SVTFImageFormatInfo));
		return vlTrue;
	}
	return vlFalse;
}


VTFLIB_API vlUInt vlImageComputeImageSize(vlUInt uiWidth, vlUInt uiHeight, vlUInt uiDepth, vlUInt uiMipmaps, VTFImageFormat ImageFormat) {
	return CVTFFile::ComputeImageSize(uiWidth, uiHeight, uiDepth, uiMipmaps, ImageFormat);
}


VTFLIB_API vlUInt vlImageComputeMipmapCount(vlUInt uiWidth, vlUInt uiHeight, vlUInt uiDepth) {
	return CVTFFile::ComputeMipmapCount(uiWidth, uiHeight, uiDepth);
}


VTFLIB_API vlVoid vlImageComputeMipmapDimensions(vlUInt uiWidth, vlUInt uiHeight, vlUInt uiDepth, vlUInt uiMipmapLevel, vlUInt *uiMipmapWidth, vlUInt *uiMipmapHeight, vlUInt *uiMipmapDepth) {
	CVTFFile::ComputeMipmapDimensions(uiWidth, uiHeight, uiDepth, uiMipmapLevel, *uiMipmapWidth, *uiMipmapHeight, *uiMipmapDepth);
}


VTFLIB_API vlUInt vlImageComputeMipmapSize(vlUInt uiWidth, vlUInt uiHeight, vlUInt uiDepth, vlUInt uiMipmapLevel, VTFImageFormat ImageFormat) {
	return CVTFFile::ComputeMipmapSize(uiWidth, uiHeight, uiDepth, uiMipmapLevel, ImageFormat);
}


VTFLIB_API vlBool vlImageConvertToRGBA8888(vlByte *lpSource, vlByte *lpDest, vlUInt uiWidth, vlUInt uiHeight, VTFImageFormat SourceFormat) {
	return CVTFFile::ConvertToRGBA8888(lpSource, lpDest, uiWidth, uiHeight, SourceFormat);
}


VTFLIB_API vlBool vlImageConvertFromRGBA8888(vlByte *lpSource, vlByte *lpDest, vlUInt uiWidth, vlUInt uiHeight, VTFImageFormat DestFormat) {
	return CVTFFile::ConvertFromRGBA8888(lpSource, lpDest, uiWidth, uiHeight, DestFormat);
}


VTFLIB_API vlBool vlImageConvert(vlByte *lpSource, vlByte *lpDest, vlUInt uiWidth, vlUInt uiHeight, VTFImageFormat SourceFormat, VTFImageFormat DestFormat) {
	return CVTFFile::Convert(lpSource, lpDest, uiWidth, uiHeight, SourceFormat, DestFormat);
}


VTFLIB_API vlBool vlImageConvertToNormalMap(vlByte *lpSourceRGBA8888, vlByte *lpDestRGBA8888, vlUInt uiWidth, vlUInt uiHeight, VTFKernelFilter KernelFilter, VTFHeightConversionMethod HeightConversionMethod, VTFNormalAlphaResult NormalAlphaResult, vlByte bMinimumZ, vlSingle sScale, vlBool bWrap, vlBool bInvertX, vlBool bInvertY) {
	return CVTFFile::ConvertToNormalMap(lpSourceRGBA8888, lpDestRGBA8888, uiWidth, uiHeight, KernelFilter, HeightConversionMethod, NormalAlphaResult, bMinimumZ, sScale, bWrap, bInvertX, bInvertY);
}


VTFLIB_API vlBool vlImageResize(vlByte *lpSourceRGBA8888, vlByte *lpDestRGBA8888, vlUInt uiSourceWidth, vlUInt uiSourceHeight, vlUInt uiDestWidth, vlUInt uiDestHeight, VTFMipmapFilter ResizeFilter, VTFSharpenFilter SharpenFilter) {
	return CVTFFile::Resize(lpSourceRGBA8888, lpDestRGBA8888, uiSourceWidth, uiSourceHeight, uiDestWidth, uiDestHeight, ResizeFilter, SharpenFilter);
}


VTFLIB_API vlVoid vlImageCorrectImageGamma(vlByte *lpImageDataRGBA8888, vlUInt uiWidth, vlUInt uiHeight, vlSingle sGammaCorrection) {
	CVTFFile::CorrectImageGamma(lpImageDataRGBA8888, uiWidth, uiHeight, sGammaCorrection);
}


VTFLIB_API vlVoid vlImageComputeImageReflectivity(vlByte *lpImageDataRGBA8888, vlUInt uiWidth, vlUInt uiHeight, vlSingle *sX, vlSingle *sY, vlSingle *sZ) {
	CVTFFile::ComputeImageReflectivity(lpImageDataRGBA8888, uiWidth, uiHeight, *sX, *sY, *sZ);
}


VTFLIB_API vlVoid vlImageFlipImage(vlByte *lpImageDataRGBA8888, vlUInt uiWidth, vlUInt uiHeight) {
	CVTFFile::FlipImage(lpImageDataRGBA8888, uiWidth, uiHeight);
}


VTFLIB_API vlVoid vlImageMirrorImage(vlByte *lpImageDataRGBA8888, vlUInt uiWidth, vlUInt uiHeight) {
	CVTFFile::FlipImage(lpImageDataRGBA8888, uiWidth, uiHeight);
}


