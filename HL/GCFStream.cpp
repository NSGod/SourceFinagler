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
#include "GCFStream.h"

using namespace HLLib;
using namespace HLLib::Streams;

CGCFStream::CGCFStream(const CGCFFile &GCFFile, hlUInt uiFileID) : bOpened(hlFalse), uiMode(HL_MODE_INVALID), GCFFile(GCFFile), uiFileID(uiFileID), pView(0), ullPointer(0), ullLength(0)
{

}

CGCFStream::~CGCFStream()
{
	this->Close();
}

HLStreamType CGCFStream::GetType() const
{
	return HL_STREAM_GCF;
}

const CGCFFile &CGCFStream::GetPackage() const
{
	return this->GCFFile;
}

const hlChar *CGCFStream::GetFileName() const
{
	return this->GCFFile.lpDirectoryNames + this->GCFFile.lpDirectoryEntries[this->uiFileID].uiNameOffset;
}

hlBool CGCFStream::GetOpened() const
{
	return this->bOpened;
}

hlUInt CGCFStream::GetMode() const
{
	return this->uiMode;
}

hlBool CGCFStream::Open(hlUInt uiMode)
{
	this->Close();

	if(!this->GCFFile.GetOpened())
	{
		LastError.SetErrorMessage("GCF file not opened.");
		return hlFalse;
	}

	if((uiMode & (HL_MODE_READ | HL_MODE_WRITE)) == 0)
	{
		LastError.SetErrorMessageFormated("Invalid open mode (%#.8x).", uiMode);
		return hlFalse;
	}

	if((uiMode & HL_MODE_READ) != 0 && (this->GCFFile.pMapping->GetMode() & HL_MODE_READ) == 0)
	{
		LastError.SetErrorMessage("GCF file does not have read permissions.");
		return hlFalse;
	}

	if((uiMode & HL_MODE_WRITE) != 0 && (this->GCFFile.pMapping->GetMode() & HL_MODE_WRITE) == 0)
	{
		LastError.SetErrorMessage("GCF file does not have write permissions.");
		return hlFalse;
	}

	this->ullPointer = 0;
	this->ullLength = (uiMode & HL_MODE_READ) ? this->GCFFile.lpDirectoryEntries[this->uiFileID].uiItemSize : 0;

	this->bOpened = hlTrue;
	this->uiMode = uiMode;

	this->uiBlockEntryIndex = this->GCFFile.lpDirectoryMapEntries[this->uiFileID].uiFirstBlockIndex;
	this->ullBlockEntryOffset = 0;
	this->uiDataBlockIndex = this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFirstDataBlockIndex;
	this->ullDataBlockOffset = 0;

	return hlTrue;
}

hlVoid CGCFStream::Close()
{
	this->bOpened = hlFalse;
	this->uiMode = HL_MODE_INVALID;

	this->GCFFile.pMapping->Unmap(this->pView);

	this->ullPointer = 0;
	this->ullLength = 0;
}

hlULongLong CGCFStream::GetStreamSize() const
{
	return this->ullLength;
}

hlULongLong CGCFStream::GetStreamPointer() const
{
	return this->ullPointer;
}

hlULongLong CGCFStream::Seek(hlLongLong iOffset, HLSeekMode eSeekMode)
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

	hlLongLong llPointer = static_cast<hlLongLong>(this->ullPointer) + iOffset;

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

hlBool CGCFStream::Read(hlChar &cChar)
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

		hlULongLong ullViewPointer = this->ullPointer - (this->ullBlockEntryOffset + this->ullDataBlockOffset);
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

hlULongLong CGCFStream::Read(hlVoid *lpData, hlULongLong ullBytes)
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

			hlULongLong ullViewPointer = this->ullPointer - (this->ullBlockEntryOffset + this->ullDataBlockOffset);
			hlULongLong ullViewBytes = this->pView->GetLength() - ullViewPointer;

			if(ullViewBytes >= static_cast<hlULongLong>(ullBytes))
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
				ullBytes -= static_cast<hlUInt>(ullViewBytes);
			}
		}

		return static_cast<hlULongLong>(ullOffset);
	}
}

hlBool CGCFStream::Write(hlChar cChar)
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

	if(this->ullPointer < this->GCFFile.lpDirectoryEntries[this->uiFileID].uiItemSize)
	{
		if(!this->Map(this->ullPointer))
		{
			return 0;
		}

		hlULongLong ullViewPointer = this->ullPointer - (this->ullBlockEntryOffset + this->ullDataBlockOffset);
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

hlULongLong CGCFStream::Write(const hlVoid *lpData, hlULongLong ullBytes)
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

	if(this->ullPointer == this->GCFFile.lpDirectoryEntries[this->uiFileID].uiItemSize)
	{
		return 0;
	}
	else
	{
		hlULongLong ullOffset = 0;
		while(ullBytes && this->ullPointer < this->GCFFile.lpDirectoryEntries[this->uiFileID].uiItemSize)
		{
			if(!this->Map(this->ullPointer))
			{
				break;
			}

			hlULongLong ullViewPointer = this->ullPointer - (this->ullBlockEntryOffset + this->ullDataBlockOffset);
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
				ullBytes -= static_cast<hlUInt>(ullViewBytes);
			}
		}

		if(this->ullPointer > this->ullLength)
		{
			this->ullLength = this->ullPointer;
		}

		return static_cast<hlULongLong>(ullOffset);
	}
}

hlBool CGCFStream::Map(hlULongLong ullPointer)
{
	if(ullPointer < this->ullBlockEntryOffset + this->ullDataBlockOffset)
	{
		this->uiBlockEntryIndex = this->GCFFile.lpDirectoryMapEntries[this->uiFileID].uiFirstBlockIndex;
		this->ullBlockEntryOffset = 0;
		this->uiDataBlockIndex = this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFirstDataBlockIndex;
		this->ullDataBlockOffset = 0;
	}

	hlULongLong ullLength = this->ullDataBlockOffset + this->GCFFile.pDataBlockHeader->uiBlockSize > this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFileDataSize ? this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFileDataSize - this->ullDataBlockOffset : this->GCFFile.pDataBlockHeader->uiBlockSize;
	//hlUInt uiDataBlockTerminator = this->pDataBlockHeader->uiBlockCount >= 0x0000ffff ? 0xffffffff : 0x0000ffff;
	hlUInt uiDataBlockTerminator = this->GCFFile.pFragmentationMapHeader->uiTerminator == 0 ? 0x0000ffff : 0xffffffff;

	while((ullPointer >= this->ullBlockEntryOffset + this->ullDataBlockOffset + ullLength) && (this->uiBlockEntryIndex != this->GCFFile.pDataBlockHeader->uiBlockCount))
	{
		// Loop through each data block fragment.
		while((ullPointer >= this->ullBlockEntryOffset + this->ullDataBlockOffset + ullLength) && (this->uiDataBlockIndex < uiDataBlockTerminator && this->ullDataBlockOffset < this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFileDataSize))
		{
			// Get the next data block fragment.
			this->uiDataBlockIndex = this->GCFFile.lpFragmentationMap[this->uiDataBlockIndex].uiNextDataBlockIndex;
			this->ullDataBlockOffset += static_cast<hlULongLong>(this->GCFFile.pDataBlockHeader->uiBlockSize);

			ullLength = this->ullDataBlockOffset + this->GCFFile.pDataBlockHeader->uiBlockSize > this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFileDataSize ? static_cast<hlULongLong>(this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFileDataSize) - this->ullDataBlockOffset : static_cast<hlULongLong>(this->GCFFile.pDataBlockHeader->uiBlockSize);
		}

		if(this->ullDataBlockOffset >= static_cast<hlULongLong>(this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFileDataSize))
		{
			// Get the next data block.
			this->ullBlockEntryOffset += static_cast<hlULongLong>(this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFileDataSize);
			this->uiBlockEntryIndex = this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiNextBlockEntryIndex;

			this->ullDataBlockOffset = 0;
			if(this->uiBlockEntryIndex != this->GCFFile.pDataBlockHeader->uiBlockCount)
			{
				this->uiDataBlockIndex = this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFirstDataBlockIndex;
			}

			ullLength = this->ullDataBlockOffset + this->GCFFile.pDataBlockHeader->uiBlockSize > this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFileDataSize ? static_cast<hlULongLong>(this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFileDataSize) - this->ullDataBlockOffset : static_cast<hlULongLong>(this->GCFFile.pDataBlockHeader->uiBlockSize);
		}
	}

	if(this->uiBlockEntryIndex == this->GCFFile.pDataBlockHeader->uiBlockCount || this->uiDataBlockIndex >= uiDataBlockTerminator)
	{
		if(this->ullBlockEntryOffset + this->ullDataBlockOffset < static_cast<hlULongLong>(this->GCFFile.lpDirectoryEntries[this->uiFileID].uiItemSize))
		{
#ifdef _WIN32
			LastError.SetErrorMessageFormated("Unexpected end of GCF stream (%I64u B of %u B).  Has the GCF file been completely acquired?", this->ullBlockEntryOffset + this->ullDataBlockOffset, this->GCFFile.lpDirectoryEntries[this->uiFileID].uiItemSize);
#else
			LastError.SetErrorMessageFormated("Unexpected end of GCF stream (%llu B of %u B).  Has the GCF file been completely acquired?", this->ullBlockEntryOffset + this->ullDataBlockOffset, this->GCFFile.lpDirectoryEntries[this->uiFileID].uiItemSize);
#endif
		}

		this->GCFFile.pMapping->Unmap(this->pView);
		return hlFalse;
	}

	if(this->pView)
	{
		if(this->pView->GetAllocationOffset() == this->GCFFile.pDataBlockHeader->uiFirstBlockOffset + this->uiDataBlockIndex * this->GCFFile.pDataBlockHeader->uiBlockSize)
		{
			return hlTrue;
		}
	}
	//uiLength = this->uiDataBlockOffset + this->GCFFile.pDataBlockHeader->uiBlockSize > this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFileDataSize ? this->GCFFile.lpBlockEntries[this->uiBlockEntryIndex].uiFileDataSize - this->uiDataBlockOffset : this->GCFFile.pDataBlockHeader->uiBlockSize;

	return this->GCFFile.pMapping->Map(this->pView, static_cast<hlULongLong>(this->GCFFile.pDataBlockHeader->uiFirstBlockOffset) + static_cast<hlULongLong>(this->uiDataBlockIndex) * static_cast<hlULongLong>(this->GCFFile.pDataBlockHeader->uiBlockSize), ullLength);
}
