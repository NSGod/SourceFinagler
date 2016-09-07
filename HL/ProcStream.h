/*
 * HLLib
 * Copyright (C) 2006-2010 Ryan Gregg

 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later
 * version.
 */

#ifndef PROCSTREAM_H
#define PROCSTREAM_H

#include "stdafx.h"
#include "Stream.h"

namespace HLLib
{
	namespace Streams
	{
		class HLLIB_API CProcStream : public IStream
		{
		private:
			hlBool bOpened;
			hlUInt uiMode;

			hlVoid *pUserData;

		public:
			CProcStream(hlVoid *pUserData);
			~CProcStream();

			virtual HLStreamType GetType() const;

			virtual const hlChar *GetFileName() const;

			virtual hlBool GetOpened() const;
			virtual hlUInt GetMode() const;

			virtual hlBool Open(hlUInt uiMode);
			virtual hlVoid Close();

			virtual hlULongLong GetStreamSize() const;
			virtual hlULongLong GetStreamPointer() const;

			virtual hlULongLong Seek(hlLongLong iOffset, HLSeekMode eSeekMode);

			virtual hlBool Read(hlChar &cChar);
			virtual hlULongLong Read(hlVoid *lpData, hlULongLong ullBytes);

			virtual hlBool Write(hlChar cChar);
			virtual hlULongLong Write(const hlVoid *lpData, hlULongLong ullBytes);
		};
	}
}

#endif
