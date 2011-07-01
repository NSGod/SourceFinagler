// Copyright (c) 2009-2011 Ignacio Castano <castano@gmail.com>
// Copyright (c) 2007-2009 NVIDIA Corporation -- Ignacio Castano <icastano@nvidia.com>
// 
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

#pragma once
#ifndef NVTT_DEFINES_H
#define NVTT_DEFINES_H

// Function linkage
#if NVTT_SHARED

#if defined _WIN32 || defined WIN32 || defined __NT__ || defined __WIN32__ || defined __MINGW32__
#  ifdef NVTT_EXPORTS
#    define NVTT_API __declspec(dllexport)
#  else
#    define NVTT_API __declspec(dllimport)
#  endif
#endif

#if defined __GNUC__ >= 4
#  ifdef NVTT_EXPORTS
#    define NVTT_API __attribute__((visibility("default")))
#  endif
#endif

#endif // NVTT_SHARED

#if !defined NVTT_API
#  define NVTT_API
#endif

#define NVTT_FORBID_COPY(Class) \
    private: \
        Class(const Class &); \
        void operator=(const Class &); \
    public:

#define NVTT_DECLARE_PIMPL(Class) \
    public: \
        struct Private; \
        Private & m


#endif // NVTT_DEFINES_H
