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
#include "FileWriter.h"

#ifndef _WIN32
#	include <fcntl.h>
#endif

using namespace VTFLib;
using namespace VTFLib::IO::Writers;


CFileWriter::CFileWriter(const vlChar *cFileName)
{
#ifdef _WIN32
	this->hFile = NULL;
#else
	this->iFile = -1;
#endif
	this->cFileName = new vlChar[strlen(cFileName) + 1];
	strcpy(this->cFileName, cFileName);
}

CFileWriter::~CFileWriter()
{
	this->Close();

	delete []this->cFileName;
}


vlBool CFileWriter::Opened() const
{
#ifdef _WIN32
	return this->hFile != NULL;
#else
	return this->iFile >= 0;
#endif
}

vlBool CFileWriter::Open()
{
	this->Close();

#ifdef _WIN32
	this->hFile = CreateFile(this->cFileName, GENERIC_WRITE, NULL, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);

	if(this->hFile == INVALID_HANDLE_VALUE)
	{
		this->hFile = NULL;

		LastError.Set("Error opening file.", vlTrue);

		return vlFalse;
	}
#else
	this->iFile = open(this->cFileName, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
	if (this->iFile < 0)
	{
		LastError.Set("Error opening file.", vlTrue);
		this->iFile = -1;
		return vlFalse;
	}
#endif
	return vlTrue;
}


vlVoid CFileWriter::Close()
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


vlUInt CFileWriter::GetStreamSize() const
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


vlUInt CFileWriter::GetStreamPointer() const
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


vlUInt CFileWriter::Seek(vlLong lOffset, VLSeekMode uiMode)
{
	if (!this->Opened())
	{
		return 0;
	}
#ifdef _WIN32

	DWORD dwMode = FILE_BEGIN;
	switch (uiMode) {
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
	switch (uiMode) {
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


vlBool CFileWriter::Write(vlChar cChar)
{
	if (!this->Opened()) {
		return vlFalse;
	}
#ifdef _WIN32
	vlULong ulBytesWritten = 0;
	
	if (!WriteFile(this->hFile, &cChar, 1, &ulBytesWritten, NULL))
	{
		LastError.Set("WriteFile() failed.", vlTrue);
	}
	return ulBytesWritten == 1;
#else
	vlLong lBytesWritten = write(this->iFile, &cChar, 1);
	if (lBytesWritten < 0)
	{
		LastError.Set("write() failed", vlTrue);
	}
	return lBytesWritten == 1;
#endif
}


vlUInt CFileWriter::Write(vlVoid *vData, vlUInt uiBytes)
{
	if (!this->Opened())
	{
		return 0;
	}
#ifdef _WIN32
	vlULong ulBytesWritten = 0;
	
	if (!WriteFile(this->hFile, vData, uiBytes, &ulBytesWritten, NULL))
	{
		LastError.Set("WriteFile() failed.", vlTrue);
	}
	return (vlUInt)ulBytesWritten;
#else
	vlLong lBytesWritten = write(this->iFile, vData, uiBytes);
	if (lBytesWritten < 0)
	{
		LastError.Set("write() failed", vlTrue);
	}	
	return (vlUInt)lBytesWritten;
#endif
}







