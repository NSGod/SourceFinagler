/*
 * VTFLib
 * Copyright (C) 2005-2010 Neil Jedrzejewski & Ryan Gregg

 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later
 * version.
 */

#include "VTFLib.h"
#include "FileReader.h"

using namespace VTFLib;
using namespace VTFLib::IO::Readers;

CFileReader::CFileReader(const vlChar *cFileName)
{
#ifdef _WIN32
	this->hFile = NULL;
#else
	this->iFile = -1;
#endif

	this->cFileName = new vlChar[strlen(cFileName) + 1];
	strcpy(this->cFileName, cFileName);
}


CFileReader::~CFileReader()
{
	this->Close();
	delete []this->cFileName;
}


vlBool CFileReader::Opened() const
{
#ifdef _WIN32
	return this->hFile != NULL;
#else
	return this->iFile >= 0;
#endif
}


vlBool CFileReader::Open()
{
	this->Close();
	
#ifdef _WIN32

	this->hFile = CreateFile(this->cFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	
	if (this->hFile == INVALID_HANDLE_VALUE)
	{
		this->hFile = NULL;

		LastError.Set("Error opening file.", vlTrue);

		return vlFalse;
	}
#else
	this->iFile = open(this->cFileName, O_RDONLY);
	
	if (this->iFile < 0)
	{
		LastError.Set("Error opening file.", vlTrue);
		this->iFile = -1;
		return vlFalse;
	}
#endif

	return vlTrue;
}


vlVoid CFileReader::Close()
{
	
#ifdef _WIN32
	if (this->hFile != NULL)
	{
		CloseHandle(this->hFile);
		this->hFile = NULL;
	}
#else
	if (this->iFile >= 0)
	{
		close(this->iFile);
		this->iFile = -1;
	}
#endif
}


vlUInt CFileReader::GetStreamSize() const
{
	if (!this->Opened())
	{
		return 0;
	}
	
#ifdef _WIN32
	return GetFileSize(this->hFile, NULL);
#else
	struct stat Stat;
	return fstat(this->iFile, &Stat) < 0 ? 0 : Stat.st_size;
#endif
}


vlUInt CFileReader::GetStreamPointer() const
{
	if (!this->Opened())
	{
		return 0;
	}
	
#ifdef _WIN32
	return (vlUInt)SetFilePointer(this->hFile, 0, NULL, FILE_CURRENT);
#else
	return (vlUInt)lseek(this->iFile, 0, SEEK_CUR);
#endif
}


vlUInt CFileReader::Seek(vlLong lOffset, VLSeekMode uiMode)
{
	if (!this->Opened())
	{
		return 0;
	}
	
#ifdef _WIN32
	DWORD dwMode = FILE_BEGIN;
	switch (uiMode)
	{
//		case SEEK_MODE_BEGIN:
//			dwMode = FILE_BEGIN;
//			break;
		case SEEK_MODE_CURRENT:
			dwMode = FILE_CURRENT;
			break;
		case SEEK_MODE_END:
			dwMode = FILE_END;
			break;
	}
	return (vlUInt)SetFilePointer(this->hFile, lOffset, NULL, dwMode);
#else
	
	vlInt iMode = SEEK_SET;
	switch (uiMode)
	{
//		case SEEK_MODE_BEGIN:
//			iMode = SEEK_SET;
//			break;
		case SEEK_MODE_CURRENT:
			iMode = SEEK_CUR;
			break;
		case SEEK_MODE_END:
			iMode = SEEK_END;
			break;
	}
	return (vlUInt)lseek(this->iFile, lOffset, iMode);
#endif
}


vlBool CFileReader::Read(vlChar &cChar)
{
	if (!this->Opened())
	{
		return vlFalse;
	}
	
#ifdef _WIN32

	vlULong ulBytesRead = 0;
	if (!ReadFile(this->hFile, &cChar, 1, &ulBytesRead, NULL))
	{
		LastError.Set("ReadFile() failed.", vlTrue);
	}
	return ulBytesRead == 1;
#else
	vlLong lBytesRead = read(this->iFile, &cChar, 1);
	
	if (lBytesRead < 0)
	{
		LastError.Set("read() failed.", vlTrue);
	}
	return lBytesRead == 1;
#endif
}


vlUInt CFileReader::Read(vlVoid *vData, vlUInt uiBytes)
{
	if (!this->Opened())
	{
		return 0;
	}
		
#ifdef _WIN32

	vlULong ulBytesRead = 0;
	if (!ReadFile(this->hFile, vData, uiBytes, &ulBytesRead, NULL))
	{
		LastError.Set("ReadFile() failed.", vlTrue);
	}
	return (vlUInt)ulBytesRead;
#else
	vlLong lBytesRead = read(this->iFile, vData, uiBytes);
		
	if (lBytesRead < 0)
	{
		LastError.Set("read() failed.", vlTrue);
	}
	return (vlUInt)lBytesRead;
#endif
}


