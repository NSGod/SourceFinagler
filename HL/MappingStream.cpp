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
#include "MappingStream.h"

using namespace HLLib;
using namespace HLLib::Streams;

CMappingStream::CMappingStream(Mapping::CMapping &Mapping, hlULongLong ullMappingOffset, hlULongLong ullMappingSize, hlULongLong ullViewSize) : bOpened(hlFalse), uiMode(HL_MODE_INVALID), Mapping(Mapping), ullMappingOffset(ullMappingOffset), ullMappingSize(ullMappingSize), ullViewSize(ullViewSize), pView(0), ullPointer(0), ullLength(0)
{
	if(this->ullViewSize == 0)
	{
		switch(this->Mapping.GetType())
		{
		case HL_MAPPING_FILE:
			if(this->Mapping.GetMode() & HL_MODE_QUICK_FILEMAPPING)
			{
		case HL_MAPPING_MEMORY:
				this->ullViewSize = this->ullMappingSize;
				break;
			}
		default:
			this->ullViewSize = HL_DEFAULT_VIEW_SIZE;
			break;
		}
	}
}

CMappingStream::~CMappingStream()
{
	this->Close();
}

HLStreamType CMappingStream::GetType() const
{
	return HL_STREAM_MAPPING;
}

const Mapping::CMapping &CMappingStream::GetMapping() const
{
	return this->Mapping;
}

const hlChar *CMappingStream::GetFileName() const
{
	return "";
}

hlBool CMappingStream::GetOpened() const
{
	return this->bOpened;
}

hlUInt CMappingStream::GetMode() const
{
	return this->uiMode;
}

hlBool CMappingStream::Open(hlUInt uiMode)
{
	this->Close();

	if((uiMode & (HL_MODE_READ | HL_MODE_WRITE)) == 0)
	{
		LastError.SetErrorMessageFormated("Invalid open mode (%#.8x).", uiMode);
		return hlFalse;
	}

	if((uiMode & HL_MODE_READ) != 0 && (this->Mapping.GetMode() & HL_MODE_READ) == 0)
	{
		LastError.SetErrorMessage("Mapping does not have read permissions.");
		return hlFalse;
	}

	if((uiMode & HL_MODE_WRITE) != 0 && (this->Mapping.GetMode() & HL_MODE_WRITE) == 0)
	{
		LastError.SetErrorMessage("Mapping does not have write permissions.");
		return hlFalse;
	}

	this->ullPointer = 0;
	this->ullLength = (uiMode & HL_MODE_READ) ? this->ullMappingSize : 0;

	this->bOpened = hlTrue;
	this->uiMode = uiMode;

	return hlTrue;
}

hlVoid CMappingStream::Close()
{
	this->bOpened = hlFalse;
	this->uiMode = HL_MODE_INVALID;

	this->Mapping.Unmap(this->pView);

	this->ullPointer = 0;
	this->ullLength = 0;
}

hlULongLong CMappingStream::GetStreamSize() const
{
	return this->ullLength;
}

hlULongLong CMappingStream::GetStreamPointer() const
{
	return this->ullPointer;
}

hlULongLong CMappingStream::Seek(hlLongLong llOffset, HLSeekMode eSeekMode)
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

hlBool CMappingStream::Read(hlChar &cChar)
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

	if(this->ullPointer < this->ullLength)
	{
		if(!this->Map(this->ullPointer))
		{
			return 0;
		}

		hlULongLong ullViewPointer = this->ullPointer - (this->pView->GetAllocationOffset() + this->pView->GetOffset() - this->ullMappingOffset);
		hlULongLong ullViewBytes = this->pView->GetLength() - ullViewPointer;

		if(ullViewBytes >= 1)
		{
			cChar = *(static_cast<const hlChar *>(this->pView->GetView()) + ullViewPointer);
			this->ullPointer++;
			return 1;
		}
	}

	return 0;
}

hlULongLong CMappingStream::Read(hlVoid *lpData, hlULongLong ullBytes)
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
	else
	{
		hlULongLong ullOffset = 0;
		while(ullBytes && this->ullPointer < this->ullLength)
		{
			if(!this->Map(this->ullPointer))
			{
				break;
			}

			hlULongLong ullViewPointer = this->ullPointer - (this->pView->GetAllocationOffset() + this->pView->GetOffset() - this->ullMappingOffset);
			hlULongLong ullViewBytes = this->pView->GetLength() - ullViewPointer;

			if(ullViewBytes >= ullBytes)
			{
				memcpy(static_cast<hlByte *>(lpData) + ullOffset, static_cast<const hlByte *>(this->pView->GetView()) + ullViewPointer, ullBytes);
				this->ullPointer += static_cast<hlULongLong>(ullBytes);
				ullOffset += ullBytes;
				break;
			}
			else
			{
				memcpy(static_cast<hlByte *>(lpData) + ullOffset, static_cast<const hlByte *>(this->pView->GetView()) + ullViewPointer, static_cast<size_t>(ullViewBytes));
				this->ullPointer += ullViewBytes;
				ullOffset += ullViewBytes;
				ullBytes -= static_cast<hlULongLong>(ullViewBytes);
			}
		}

		return static_cast<hlULongLong>(ullOffset);
	}
}

hlBool CMappingStream::Write(hlChar cChar)
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

	if(this->ullPointer < this->ullMappingSize)
	{
		if(!this->Map(this->ullPointer))
		{
			return 0;
		}

		hlULongLong ullViewPointer = this->ullPointer - (this->pView->GetAllocationOffset() + this->pView->GetOffset() - this->ullMappingOffset);
		hlULongLong ullViewBytes = this->pView->GetLength() - ullViewPointer;

		if(ullViewBytes >= 1)
		{
			*(static_cast<hlChar *>(const_cast<hlVoid *>(this->pView->GetView())) + ullViewPointer) = cChar;
			this->ullPointer++;

			if(this->ullPointer > this->ullLength)
			{
				this->ullLength = this->ullPointer;
			}

			return 1;
		}
	}

	return 0;
}

hlULongLong CMappingStream::Write(const hlVoid *lpData, hlULongLong ullBytes)
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

	if(this->ullPointer == this->ullMappingSize)
	{
		return 0;
	}
	else
	{
		hlULongLong ullOffset = 0;
		while(ullBytes && this->ullPointer < this->ullMappingSize)
		{
			if(!this->Map(this->ullPointer))
			{
				break;
			}

			hlULongLong ullViewPointer = this->ullPointer - (this->pView->GetAllocationOffset() + this->pView->GetOffset() - this->ullMappingOffset);
			hlULongLong ullViewBytes = this->pView->GetLength() - ullViewPointer;

			if(ullViewBytes >= ullBytes)
			{
				memcpy(static_cast<hlByte *>(const_cast<hlVoid *>(this->pView->GetView())) + ullViewPointer, static_cast<const hlByte *>(lpData) + ullOffset, ullBytes);
				this->ullPointer += static_cast<hlULongLong>(ullBytes);
				ullOffset += ullBytes;
				break;
			}
			else
			{
				memcpy(static_cast<hlByte *>(const_cast<hlVoid *>(this->pView->GetView())) + ullViewPointer, static_cast<const hlByte *>(lpData) + ullOffset, static_cast<size_t>(ullViewBytes));
				this->ullPointer += ullViewBytes;
				ullOffset += ullViewBytes;
				ullBytes -= static_cast<hlULongLong>(ullViewBytes);
			}
		}

		if(this->ullPointer > this->ullLength)
		{
			this->ullLength = this->ullPointer;
		}

		return static_cast<hlULongLong>(ullOffset);
	}
}

hlBool CMappingStream::Map(hlULongLong ullPointer)
{
	ullPointer = (ullPointer / this->ullViewSize) * this->ullViewSize;

	if(this->pView)
	{
		if(this->pView->GetAllocationOffset() - this->ullMappingOffset == ullPointer)
		{
			return hlTrue;
		}
	}

	hlULongLong ullLength = ullPointer + this->ullViewSize > this->ullMappingSize ? this->ullMappingSize - ullPointer : this->ullViewSize;

	return this->Mapping.Map(this->pView, this->ullMappingOffset + ullPointer, ullLength);
}
