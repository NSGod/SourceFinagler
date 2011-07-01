/*
 * HLLib
 * Copyright (C) 2006-2010 Ryan Gregg

 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later
 * version.
 */

#ifndef MAPPINGSTREAM_H
#define MAPPINGSTREAM_H

#include "stdafx.h"
#include "Stream.h"
#include "Mapping.h"

namespace HLLib
{
	namespace Streams
	{
		class HLLIB_API CMappingStream : public IStream
		{
		private:
			hlBool bOpened;
			hlUInt uiMode;

			Mapping::CMapping &Mapping;
			Mapping::CView *pView;

			hlULongLong ullMappingOffset;
			hlULongLong ullMappingSize;
			hlULongLong ullViewSize;

			hlULongLong ullPointer;
			hlULongLong ullLength;

		public:
			CMappingStream(Mapping::CMapping &Mapping, hlULongLong uiMappingOffset, hlULongLong uiMappingSize, hlULongLong uiViewSize = 0);
			~CMappingStream();

			virtual HLStreamType GetType() const;

			const Mapping::CMapping &GetMapping() const;
			virtual const hlChar *GetFileName() const;

			virtual hlBool GetOpened() const;
			virtual hlUInt GetMode() const;

			virtual hlBool Open(hlUInt uiMode);
			virtual hlVoid Close();

			virtual hlULongLong GetStreamSize() const;
			virtual hlULongLong GetStreamPointer() const;

			virtual hlULongLong Seek(hlLongLong llOffset, HLSeekMode eSeekMode);

			virtual hlBool Read(hlChar &cChar);
			virtual hlULongLong Read(hlVoid *lpData, hlULongLong ullBytes);

			virtual hlBool Write(hlChar cChar);
			virtual hlULongLong Write(const hlVoid *lpData, hlULongLong ullBytes);

		private:
			hlBool Map(hlULongLong uiPointer);
		};
	}
}

#endif
