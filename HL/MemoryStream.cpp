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
#include "MemoryStream.h"

using namespace HLLib;
using namespace HLLib::Streams;

CMemoryStream::CMemoryStream(hlVoid *lpData, hlULongLong ullBufferSize) : bOpened(hlFalse), uiMode(HL_MODE_INVALID), lpData(lpData), ullBufferSize(ullBufferSize), ullPointer(0), ullLength(0)
{

}

CMemoryStream::~CMemoryStream()
{

}

HLStreamType CMemoryStream::GetType() const
{
	return HL_STREAM_MEMORY;
}

const hlVoid *CMemoryStream::GetBuffer() const
{
	return this->lpData;
}

hlULongLong CMemoryStream::GetBufferSize() const
{
	return this->ullBufferSize;
}

const hlChar *CMemoryStream::GetFileName() const
{
	return "";
}

hlBool CMemoryStream::GetOpened() const
{
	return this->bOpened;
}

hlUInt CMemoryStream::GetMode() const
{
	return this->uiMode;
}

hlBool CMemoryStream::Open(hlUInt uiMode)
{
	if(this->ullBufferSize != 0 && this->lpData == 0)
	{
		LastError.SetErrorMessage("Memory stream is null.");
		return hlFalse;
	}

	if((uiMode & (HL_MODE_READ | HL_MODE_WRITE)) == 0)
	{
		LastError.SetErrorMessageFormated("Invalid open mode (%#.8x).", uiMode);
		return hlFalse;
	}

	this->ullPointer = 0;
	this->ullLength = (uiMode & HL_MODE_READ) ? this->ullBufferSize : 0;

	this->bOpened = hlTrue;
	this->uiMode = uiMode;

	return hlTrue;
}

hlVoid CMemoryStream::Close()
{
	this->bOpened = hlFalse;
	this->uiMode = HL_MODE_INVALID;
	this->ullPointer = 0;
	this->ullLength = 0;
}

hlULongLong CMemoryStream::GetStreamSize() const
{
	return this->ullLength;
}

hlULongLong CMemoryStream::GetStreamPointer() const
{
	return this->ullPointer;
}

hlULongLong CMemoryStream::Seek(hlLongLong llOffset, HLSeekMode eSeekMode)
{
	if(!this->bOpened)
	{
		return 0;
	}

	switch(eSeekMode)
	{
		case HL_SEEK_BEGINNING:
			this->ullPointer = 0;
			break;
		case HL_SEEK_CURRENT:

			break;
		case HL_SEEK_END:
			this->ullPointer = this->ullLength;
			break;
	}

	hlLongLong llPointer = static_cast<hlLongLong>(this->ullPointer) + llOffset;

	if(llPointer < 0)
	{
		llPointer = 0;
	}
	else if(llPointer > static_cast<hlLongLong>(this->ullLength))
	{
		llPointer = static_cast<hlLongLong>(this->ullLength);
	}

	this->ullPointer = static_cast<hlULongLong>(llPointer);

	return this->ullPointer;
}

hlBool CMemoryStream::Read(hlChar &cChar)
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

	if(this->ullPointer == this->ullLength)
	{
		return hlFalse;
	}
	else
	{
		cChar = *((hlChar *)this->lpData + this->ullPointer++);

		return hlTrue;
	}
}

hlULongLong CMemoryStream::Read(hlVoid *lpData, hlULongLong ullBytes)
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

	if(this->ullPointer == this->ullLength)
	{
		return 0;
	}
	else if(this->ullPointer + static_cast<hlULongLong>(ullBytes) > this->ullLength) // This right?
	{
		ullBytes = static_cast<hlULongLong>(this->ullLength - this->ullPointer);

		memcpy(lpData, (hlByte *)this->lpData + this->ullPointer, ullBytes);

		this->ullPointer = this->ullLength;

		return ullBytes;
	}
	else
	{
		memcpy(lpData, (hlByte *)this->lpData + this->ullPointer, ullBytes);

		this->ullPointer += static_cast<hlULongLong>(ullBytes);

		return ullBytes;
	}
}

hlBool CMemoryStream::Write(hlChar cChar)
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

	if(this->ullPointer == this->ullBufferSize)
	{
		return hlFalse;
	}
	else
	{
		*((hlChar *)this->lpData + this->ullPointer++) = cChar;

		if(this->ullPointer > this->ullLength)
		{
			this->ullLength = this->ullPointer;
		}

		return hlTrue;
	}
}

hlULongLong CMemoryStream::Write(const hlVoid *lpData, hlULongLong ullBytes)
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

	if(this->ullPointer == this->ullBufferSize)
	{
		return 0;
	}
	else if(this->ullPointer + static_cast<hlULongLong>(ullBytes) > this->ullBufferSize)
	{
		ullBytes = static_cast<hlULongLong>(this->ullBufferSize - this->ullPointer);

		memcpy((hlByte *)this->lpData + this->ullPointer, lpData, ullBytes);

		this->ullPointer = this->ullBufferSize;

		if(this->ullPointer > this->ullLength)
		{
			this->ullLength = this->ullPointer;
		}

		return ullBytes;
	}
	else
	{
		memcpy((hlByte *)this->lpData + this->ullPointer, lpData, ullBytes);

		this->ullPointer += static_cast<hlULongLong>(ullBytes);

		if(this->ullPointer > this->ullLength)
		{
			this->ullLength = this->ullPointer;
		}

		return ullBytes;
	}
}
