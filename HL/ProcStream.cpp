/*
 * HLLib
 * Copyright (C) 2006-2010 Ryan Gregg

 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later
 * version.
 */

#include "HLLib.h"
#include "ProcStream.h"

using namespace HLLib;
using namespace HLLib::Streams;

CProcStream::CProcStream(hlVoid *pUserData) : bOpened(hlFalse), uiMode(HL_MODE_INVALID), pUserData(pUserData)
{

}

CProcStream::~CProcStream()
{
	this->Close();
}

HLStreamType CProcStream::GetType() const
{
	return HL_STREAM_PROC;
}

const hlChar *CProcStream::GetFileName() const
{
	return "";
}

hlBool CProcStream::GetOpened() const
{
	return this->bOpened;
}

hlUInt CProcStream::GetMode() const
{
	return this->uiMode;
}

hlBool CProcStream::Open(hlUInt uiMode)
{
	this->Close();

	if(pOpenProc == 0)
	{
		LastError.SetErrorMessage("pOpenProc not set.");
		return hlFalse;
	}

	if(!pOpenProc(uiMode, this->pUserData))
	{
		LastError.SetErrorMessage("pOpenProc() failed.");
		return hlFalse;
	}

	this->bOpened = hlTrue;
	this->uiMode = uiMode;

	return hlTrue;
}

hlVoid CProcStream::Close()
{
	if(this->bOpened)
	{
		if(pCloseProc != 0)
		{
			pCloseProc(this->pUserData);
		}
		this->bOpened = hlFalse;
		this->uiMode = HL_MODE_INVALID;
	}
}

hlULongLong CProcStream::GetStreamSize() const
{
	if(!this->bOpened)
	{
		return 0;
	}

	if(pSizeExProc != 0)
	{
		return pSizeExProc(this->pUserData);
	}
	else if(pSizeProc != 0)
	{
		return static_cast<hlULongLong>(pSizeProc(this->pUserData));
	}

	LastError.SetErrorMessage("pSizeProc not set.");
	return 0;
}

hlULongLong CProcStream::GetStreamPointer() const
{
	if(!this->bOpened)
	{
		return 0;
	}

	if(pTellExProc != 0)
	{
		return pTellExProc(this->pUserData);
	}
	else if(pTellProc != 0)
	{
		return static_cast<hlULongLong>(pTellProc(this->pUserData));
	}

	LastError.SetErrorMessage("pTellProc not set.");
	return 0;
}

hlULongLong CProcStream::Seek(hlLongLong iOffset, HLSeekMode eSeekMode)
{
	if(!this->bOpened)
	{
		return 0;
	}

	if(pSeekExProc != 0)
	{
		return pSeekExProc(iOffset, eSeekMode, this->pUserData);
	}
	else if(pSeekProc != 0)
	{
		return static_cast<hlULongLong>(pSeekProc(iOffset, eSeekMode, this->pUserData));
	}

	LastError.SetErrorMessage("pSeekProc not set.");
	return 0;
}

hlBool CProcStream::Read(hlChar &cChar)
{
	if(!this->bOpened)
	{
		return hlFalse;
	}

	if((this->uiMode & HL_MODE_READ) == 0)
	{
		LastError.SetErrorMessage("Stream not in read mode.");
		return hlFalse;
	}

	if (pReadProc == 0)
	{
		LastError.SetErrorMessage("pReadProc not set.");
		return hlFalse;
	}

	hlULongLong ullBytesRead = pReadProc(&cChar, 1, this->pUserData);
	
	if(ullBytesRead == 0)
	{
		LastError.SetErrorMessage("pReadProc() failed.");
	}

	return ullBytesRead == 1;
}

hlULongLong CProcStream::Read(hlVoid *lpData, hlULongLong ullBytes)
{
	if(!this->bOpened)
	{
		return 0;
	}

	if((this->uiMode & HL_MODE_READ) == 0)
	{
		LastError.SetErrorMessage("Stream not in read mode.");
		return 0;
	}

	if(pReadProc == 0)
	{
		LastError.SetErrorMessage("pReadProc not set.");
		return 0;
	}

	hlULongLong ullBytesRead = pReadProc(lpData, ullBytes, this->pUserData);

	if(ullBytesRead == 0)
	{
		LastError.SetErrorMessage("pReadProc() failed.");
	}

	return ullBytesRead;
}

hlBool CProcStream::Write(hlChar cChar)
{
	if(!this->bOpened)
	{
		return hlFalse;
	}

	if((this->uiMode & HL_MODE_WRITE) == 0)
	{
		LastError.SetErrorMessage("Stream not in write mode.");
		return hlFalse;
	}

	if(pWriteProc == 0)
	{
		LastError.SetErrorMessage("pWriteProc not set.");
		return hlFalse;
	}

	hlULongLong ullBytesWritten = pWriteProc(&cChar, 1, this->pUserData);

	if(ullBytesWritten == 0)
	{
		LastError.SetErrorMessage("pWriteProc() failed.");
	}

	return ullBytesWritten == 1;
}

hlULongLong CProcStream::Write(const hlVoid *lpData, hlULongLong ullBytes)
{
	if(!this->bOpened)
	{
		return 0;
	}

	if((this->uiMode & HL_MODE_WRITE) == 0)
	{
		LastError.SetErrorMessage("Stream not in write mode.");
		return 0;
	}

	if(pWriteProc == 0)
	{
		LastError.SetErrorMessage("pWriteProc not set.");
		return 0;
	}

	hlULongLong ullBytesWritten = pWriteProc(lpData, ullBytes, this->pUserData);

	if(ullBytesWritten == 0)
	{
		LastError.SetErrorMessage("pWriteProc() failed.");
	}

	return ullBytesWritten;
}
