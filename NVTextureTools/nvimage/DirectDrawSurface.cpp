// Copyright NVIDIA Corporation 2007 -- Ignacio Castano <icastano@nvidia.com>
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

#include "DirectDrawSurface.h"
#include "ColorBlock.h"
#include "Image.h"
#include "BlockDXT.h"
#include "PixelFormat.h"

#include "nvcore/Debug.h"
#include "nvcore/Utils.h" // max
#include "nvcore/StdStream.h"
#include "nvmath/Vector.inl"

#include <string.h> // memset


using namespace nv;

namespace
{

    static const uint DDSD_CAPS = 0x00000001U;
    static const uint DDSD_PIXELFORMAT = 0x00001000U;
    static const uint DDSD_WIDTH = 0x00000004U;
    static const uint DDSD_HEIGHT = 0x00000002U;
    static const uint DDSD_PITCH = 0x00000008U;
    static const uint DDSD_MIPMAPCOUNT = 0x00020000U;
    static const uint DDSD_LINEARSIZE = 0x00080000U;
    static const uint DDSD_DEPTH = 0x00800000U;

    static const uint DDSCAPS_COMPLEX = 0x00000008U;
    static const uint DDSCAPS_TEXTURE = 0x00001000U;
    static const uint DDSCAPS_MIPMAP = 0x00400000U;
    static const uint DDSCAPS2_VOLUME = 0x00200000U;
    static const uint DDSCAPS2_CUBEMAP = 0x00000200U;

    static const uint DDSCAPS2_CUBEMAP_POSITIVEX = 0x00000400U;
    static const uint DDSCAPS2_CUBEMAP_NEGATIVEX = 0x00000800U;
    static const uint DDSCAPS2_CUBEMAP_POSITIVEY = 0x00001000U;
    static const uint DDSCAPS2_CUBEMAP_NEGATIVEY = 0x00002000U;
    static const uint DDSCAPS2_CUBEMAP_POSITIVEZ = 0x00004000U;
    static const uint DDSCAPS2_CUBEMAP_NEGATIVEZ = 0x00008000U;
    static const uint DDSCAPS2_CUBEMAP_ALL_FACES = 0x0000FC00U;


    const char * getDxgiFormatString(DXGI_FORMAT dxgiFormat)
    {
#define CASE(format) case DXGI_FORMAT_##format: return #format
        switch(dxgiFormat)
        {
            CASE(UNKNOWN);

            CASE(R32G32B32A32_TYPELESS);
            CASE(R32G32B32A32_FLOAT);
            CASE(R32G32B32A32_UINT);
            CASE(R32G32B32A32_SINT);

            CASE(R32G32B32_TYPELESS);
            CASE(R32G32B32_FLOAT);
            CASE(R32G32B32_UINT);
            CASE(R32G32B32_SINT);

            CASE(R16G16B16A16_TYPELESS);
            CASE(R16G16B16A16_FLOAT);
            CASE(R16G16B16A16_UNORM);
            CASE(R16G16B16A16_UINT);
            CASE(R16G16B16A16_SNORM);
            CASE(R16G16B16A16_SINT);

            CASE(R32G32_TYPELESS);
            CASE(R32G32_FLOAT);
            CASE(R32G32_UINT);
            CASE(R32G32_SINT);

            CASE(R32G8X24_TYPELESS);
            CASE(D32_FLOAT_S8X24_UINT);
            CASE(R32_FLOAT_X8X24_TYPELESS);
            CASE(X32_TYPELESS_G8X24_UINT);

            CASE(R10G10B10A2_TYPELESS);
            CASE(R10G10B10A2_UNORM);
            CASE(R10G10B10A2_UINT);

            CASE(R11G11B10_FLOAT);

            CASE(R8G8B8A8_TYPELESS);
            CASE(R8G8B8A8_UNORM);
            CASE(R8G8B8A8_UNORM_SRGB);
            CASE(R8G8B8A8_UINT);
            CASE(R8G8B8A8_SNORM);
            CASE(R8G8B8A8_SINT);

            CASE(R16G16_TYPELESS);
            CASE(R16G16_FLOAT);
            CASE(R16G16_UNORM);
            CASE(R16G16_UINT);
            CASE(R16G16_SNORM);
            CASE(R16G16_SINT);

            CASE(R32_TYPELESS);
            CASE(D32_FLOAT);
            CASE(R32_FLOAT);
            CASE(R32_UINT);
            CASE(R32_SINT);

            CASE(R24G8_TYPELESS);
            CASE(D24_UNORM_S8_UINT);
            CASE(R24_UNORM_X8_TYPELESS);
            CASE(X24_TYPELESS_G8_UINT);

            CASE(R8G8_TYPELESS);
            CASE(R8G8_UNORM);
            CASE(R8G8_UINT);
            CASE(R8G8_SNORM);
            CASE(R8G8_SINT);

            CASE(R16_TYPELESS);
            CASE(R16_FLOAT);
            CASE(D16_UNORM);
            CASE(R16_UNORM);
            CASE(R16_UINT);
            CASE(R16_SNORM);
            CASE(R16_SINT);

            CASE(R8_TYPELESS);
            CASE(R8_UNORM);
            CASE(R8_UINT);
            CASE(R8_SNORM);
            CASE(R8_SINT);
            CASE(A8_UNORM);

            CASE(R1_UNORM);

            CASE(R9G9B9E5_SHAREDEXP);

            CASE(R8G8_B8G8_UNORM);
            CASE(G8R8_G8B8_UNORM);

            CASE(BC1_TYPELESS);
            CASE(BC1_UNORM);
            CASE(BC1_UNORM_SRGB);

            CASE(BC2_TYPELESS);
            CASE(BC2_UNORM);
            CASE(BC2_UNORM_SRGB);

            CASE(BC3_TYPELESS);
            CASE(BC3_UNORM);
            CASE(BC3_UNORM_SRGB);

            CASE(BC4_TYPELESS);
            CASE(BC4_UNORM);
            CASE(BC4_SNORM);

            CASE(BC5_TYPELESS);
            CASE(BC5_UNORM);
            CASE(BC5_SNORM);

            CASE(B5G6R5_UNORM);
            CASE(B5G5R5A1_UNORM);
            CASE(B8G8R8A8_UNORM);
            CASE(B8G8R8X8_UNORM);
			
			CASE(R10G10B10_XR_BIAS_A2_UNORM);
			CASE(B8G8R8A8_TYPELESS);
			CASE(B8G8R8A8_UNORM_SRGB);
			CASE(B8G8R8X8_TYPELESS);
			CASE(B8G8R8X8_UNORM_SRGB);
			
			CASE(BC6H_TYPELESS);
			CASE(BC6H_UF16);
			CASE(BC6H_SF16);
			
			CASE(BC7_TYPELESS);
			CASE(BC7_UNORM);
			CASE(BC7_UNORM_SRGB);
			
			CASE(AYUV);
			CASE(Y410);
			CASE(Y416);
			CASE(NV12);
			CASE(P010);
			CASE(P016);
			CASE(420_OPAQUE);
			CASE(YUY2);
			
			CASE(Y210);
			CASE(Y216);
			CASE(NV11);
			CASE(AI44);
			CASE(IA44);
			CASE(P8);
			CASE(A8P8);
			CASE(B4G4R4A4_UNORM);

        default: 
            return "UNKNOWN";
        }
#undef CASE
    }

    const char * getD3d10ResourceDimensionString(DDS_DIMENSION resourceDimension)
    {
        switch(resourceDimension)
        {
            default:
            case DDS_DIMENSION_UNKNOWN: return "UNKNOWN";
            case DDS_DIMENSION_BUFFER: return "BUFFER";
            case DDS_DIMENSION_TEXTURE1D: return "TEXTURE1D";
            case DDS_DIMENSION_TEXTURE2D: return "TEXTURE2D";
            case DDS_DIMENSION_TEXTURE3D: return "TEXTURE3D";
        }
    }

    static uint pixelSize(D3DFORMAT format) {
		switch (format) {
			case D3DFMT_A32B32G32R32F:
				return 8*16;
				
			case D3DFMT_G32R32F:
			case D3DFMT_A16B16G16R16F:
			case D3DFMT_A16B16G16R16:
				
			case D3DFMT_Q16W16V16U16:
				return 8*8;
				
				
			case D3DFMT_A8R8G8B8:
			case D3DFMT_X8R8G8B8:
			case D3DFMT_A2B10G10R10:
			case D3DFMT_A8B8G8R8:
			case D3DFMT_X8B8G8R8:
			case D3DFMT_G16R16:
			case D3DFMT_A2R10G10B10:
				
			case D3DFMT_R32F:
			case D3DFMT_G16R16F:
				
			case D3DFMT_X8L8V8U8:
			case D3DFMT_Q8W8V8U8:
			case D3DFMT_V16U16:
			case D3DFMT_A2W10V10U10:
				return 8*4;
				
				
			case D3DFMT_R8G8B8:
				return 8*3;
				
			case D3DFMT_R5G6B5:
			case D3DFMT_X1R5G5B5:
			case D3DFMT_A1R5G5B5:
			case D3DFMT_A4R4G4B4:
			case D3DFMT_A8R3G3B2:
			case D3DFMT_X4R4G4B4:
			case D3DFMT_A8P8:
			case D3DFMT_A8L8:
			case D3DFMT_L16:
			case D3DFMT_R16F:
				
			case D3DFMT_L6V5U5:
			case D3DFMT_V8U8:
				return 8*2;
				
			case D3DFMT_R3G3B2:
			case D3DFMT_A8:
			case D3DFMT_P8:
			case D3DFMT_L8:
			case D3DFMT_A4L4:
				return 8*1;
				
			case D3DFMT_UNKNOWN:
			default:
				return 0;
		}
        return 0;
    }

    static uint pixelSize(DXGI_FORMAT format) {
        switch(format) {
            case DXGI_FORMAT_R32G32B32A32_TYPELESS:
            case DXGI_FORMAT_R32G32B32A32_FLOAT:
            case DXGI_FORMAT_R32G32B32A32_UINT:
            case DXGI_FORMAT_R32G32B32A32_SINT:
                return 8*16;

            case DXGI_FORMAT_R32G32B32_TYPELESS:
            case DXGI_FORMAT_R32G32B32_FLOAT:
            case DXGI_FORMAT_R32G32B32_UINT:
            case DXGI_FORMAT_R32G32B32_SINT:
                return 8*12;

            case DXGI_FORMAT_R16G16B16A16_TYPELESS:
            case DXGI_FORMAT_R16G16B16A16_FLOAT:
            case DXGI_FORMAT_R16G16B16A16_UNORM:
            case DXGI_FORMAT_R16G16B16A16_UINT:
            case DXGI_FORMAT_R16G16B16A16_SNORM:
            case DXGI_FORMAT_R16G16B16A16_SINT:
            
            case DXGI_FORMAT_R32G32_TYPELESS:
            case DXGI_FORMAT_R32G32_FLOAT:
            case DXGI_FORMAT_R32G32_UINT:
            case DXGI_FORMAT_R32G32_SINT:

            case DXGI_FORMAT_R32G8X24_TYPELESS:
            case DXGI_FORMAT_D32_FLOAT_S8X24_UINT:
            case DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS:
            case DXGI_FORMAT_X32_TYPELESS_G8X24_UINT:
                return 8*8;

            case DXGI_FORMAT_R10G10B10A2_TYPELESS:
            case DXGI_FORMAT_R10G10B10A2_UNORM:
            case DXGI_FORMAT_R10G10B10A2_UINT:

            case DXGI_FORMAT_R11G11B10_FLOAT:

            case DXGI_FORMAT_R8G8B8A8_TYPELESS:
            case DXGI_FORMAT_R8G8B8A8_UNORM:
            case DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:
            case DXGI_FORMAT_R8G8B8A8_UINT:
            case DXGI_FORMAT_R8G8B8A8_SNORM:
            case DXGI_FORMAT_R8G8B8A8_SINT:

            case DXGI_FORMAT_R16G16_TYPELESS:
            case DXGI_FORMAT_R16G16_FLOAT:
            case DXGI_FORMAT_R16G16_UNORM:
            case DXGI_FORMAT_R16G16_UINT:
            case DXGI_FORMAT_R16G16_SNORM:
            case DXGI_FORMAT_R16G16_SINT:

            case DXGI_FORMAT_R32_TYPELESS:
            case DXGI_FORMAT_D32_FLOAT:
            case DXGI_FORMAT_R32_FLOAT:
            case DXGI_FORMAT_R32_UINT:
            case DXGI_FORMAT_R32_SINT:

            case DXGI_FORMAT_R24G8_TYPELESS:
            case DXGI_FORMAT_D24_UNORM_S8_UINT:
            case DXGI_FORMAT_R24_UNORM_X8_TYPELESS:
            case DXGI_FORMAT_X24_TYPELESS_G8_UINT:
                return 8*4;

            case DXGI_FORMAT_R8G8_TYPELESS:
            case DXGI_FORMAT_R8G8_UNORM:
            case DXGI_FORMAT_R8G8_UINT:
            case DXGI_FORMAT_R8G8_SNORM:
            case DXGI_FORMAT_R8G8_SINT:

            case DXGI_FORMAT_R16_TYPELESS:
            case DXGI_FORMAT_R16_FLOAT:
            case DXGI_FORMAT_D16_UNORM:
            case DXGI_FORMAT_R16_UNORM:
            case DXGI_FORMAT_R16_UINT:
            case DXGI_FORMAT_R16_SNORM:
            case DXGI_FORMAT_R16_SINT:
                return 8*2;

            case DXGI_FORMAT_R8_TYPELESS:
            case DXGI_FORMAT_R8_UNORM:
            case DXGI_FORMAT_R8_UINT:
            case DXGI_FORMAT_R8_SNORM:
            case DXGI_FORMAT_R8_SINT:
            case DXGI_FORMAT_A8_UNORM:
                return 8*1;

            case DXGI_FORMAT_R1_UNORM:
                return 1;

            case DXGI_FORMAT_R9G9B9E5_SHAREDEXP:
                return 8*4;

            case DXGI_FORMAT_R8G8_B8G8_UNORM:
            case DXGI_FORMAT_G8R8_G8B8_UNORM:
                return 8*4;

            case DXGI_FORMAT_B5G6R5_UNORM:
            case DXGI_FORMAT_B5G5R5A1_UNORM:
                return 8*2;
            
            case DXGI_FORMAT_B8G8R8A8_UNORM:
            case DXGI_FORMAT_B8G8R8X8_UNORM:
                return 8*4;

            case DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM:
            case DXGI_FORMAT_B8G8R8A8_TYPELESS:
            case DXGI_FORMAT_B8G8R8A8_UNORM_SRGB:
            case DXGI_FORMAT_B8G8R8X8_TYPELESS:
            case DXGI_FORMAT_B8G8R8X8_UNORM_SRGB:
                return 8*4;
                
			case DXGI_FORMAT_B4G4R4A4_UNORM:
				return 8*2;
				
            default:
                return 0;
        }
        nvUnreachable();
    }

} // namespace

namespace nv
{
    static Stream & operator<< (Stream & s, DDSPixelFormat & pf)
    {
        nvStaticCheck(sizeof(DDSPixelFormat) == 32);
        s << pf.size;
        s << pf.flags;
        s << pf.fourcc;
        s << pf.bitcount;
        s.serialize(&pf.rmask, sizeof(pf.rmask));
        s.serialize(&pf.gmask, sizeof(pf.gmask));
        s.serialize(&pf.bmask, sizeof(pf.bmask));
        s.serialize(&pf.amask, sizeof(pf.amask));
        // s << pf.rmask;
        // s << pf.gmask;
        // s << pf.bmask;
        // s << pf.amask;
        return s;
    }

    static Stream & operator<< (Stream & s, DDSCaps & caps)
    {
        nvStaticCheck(sizeof(DDSCaps) == 16);
        s << caps.caps1;
        s << caps.caps2;
        s << caps.caps3;
        s << caps.caps4;
        return s;
    }

    static Stream & operator<< (Stream & s, DDSHeader10 & header)
    {
        nvStaticCheck(sizeof(DDSHeader10) == 20);
        s << header.dxgiFormat;
        s << header.resourceDimension;
        s << header.miscFlag;
        s << header.arraySize;
        s << header.reserved;
        return s;
    }

    Stream & operator<< (Stream & s, DDSHeader & header)
    {
        nvStaticCheck(sizeof(DDSHeader) == 148);
        s << header.fourcc;
        s << header.size;
        s << header.flags;
        s << header.height;
        s << header.width;
        s << header.pitch;
        s << header.depth;
        s << header.mipmapcount;
        for (int i = 0; i < 11; i++) {
            s << header.reserved[i];
        }
        s << header.pf;
        s << header.caps;
        s << header.notused;

        if (header.hasDX10Header())
        {
            s << header.header10;
        }

        return s;
    }

} // nv namespace



namespace
{
    struct FormatDescriptor
    {
        uint format;
		uint pixelFormatFlags;
        uint bitcount;
        uint rmask;
        uint gmask;
        uint bmask;
        uint amask;
    };
	
    static const FormatDescriptor s_d3d9Formats[] =
	{
		{ D3DFMT_R8G8B8,		DDPF_RGB,				24,	0x00FF0000,		0x0000FF00,		0x000000FF,		0			},
		{ D3DFMT_A8R8G8B8,		DDPF_RGBA,				32,	0x00FF0000,		0x0000FF00,		0x000000FF,		0xFF000000	},	// DXGI_FORMAT_B8G8R8A8_UNORM
		{ D3DFMT_X8R8G8B8,		DDPF_RGB,				32,	0x00FF0000,		0x0000FF00,		0x000000FF,		0			},	// DXGI_FORMAT_B8G8R8X8_UNORM
	
		{ D3DFMT_R5G6B5,		DDPF_RGB,				16,	0x0000F800,		0x000007E0,		0x0000001F,		0			},	// DXGI_FORMAT_B5G6R5_UNORM
		{ D3DFMT_X1R5G5B5,		DDPF_RGB,				16,	0x00007C00,		0x000003E0,		0x0000001F,		0			},
		{ D3DFMT_A1R5G5B5,		DDPF_RGBA,				16,	0x00007C00,		0x000003E0,		0x0000001F,		0x00008000	},	// DXGI_FORMAT_B5G5R5A1_UNORM
		{ D3DFMT_A4R4G4B4,		DDPF_RGBA,				16,	0x00000F00,		0x000000F0,		0x0000000F,		0x0000F000	},	// DXGI_FORMAT_B4G4R4A4_UNORM
	
		{ D3DFMT_R3G3B2,		DDPF_RGB,				8,	0x000000E0,		0x0000001C,		0x00000003,		0			},
	
		{ D3DFMT_A8,			DDPF_ALPHA,				8,	0,				0,				0,				0x000000FF	},	// DXGI_FORMAT_A8_UNORM
	
		{ D3DFMT_A8R3G3B2,		DDPF_RGBA,				16,	0x000000E0,		0x0000001C,		0x00000003,		0x0000FF00	},
		{ D3DFMT_X4R4G4B4,		DDPF_RGB,				16,	0x00000F00,		0x000000F0,		0x0000000F,		0			},
		{ D3DFMT_A2B10G10R10,	DDPF_RGBA,				32,	0x000003FF,		0x000FFC00,		0x3FF00000,		0xC0000000	},	// DXGI_FORMAT_R10G10B10A2_UNORM
	
		{ D3DFMT_A8B8G8R8,		DDPF_RGBA,				32,	0x000000FF,		0x0000FF00,		0x00FF0000,		0xFF000000	},	// DXGI_FORMAT_R8G8B8A8_UNORM
		{ D3DFMT_X8B8G8R8,		DDPF_RGB,				32,	0x000000FF,		0x0000FF00,		0x00FF0000,		0			},
	
		{ D3DFMT_G16R16,		DDPF_RGB,				32,	0x0000FFFF,		0xFFFF0000,		0,				0			},	// DXGI_FORMAT_R16G16_UNORM
		{ D3DFMT_A2R10G10B10,	DDPF_RGBA,				32,	0x3FF00000,		0x000FFC00,		0x000003FF,		0xC0000000	},
//		{ D3DFMT_A2B10G10R10,	DDPF_RGBA,				32,	0x000003FF,		0x000FFC00,		0x3FF00000,		0xC0000000	},

		{ D3DFMT_L8,			DDPF_LUMINANCE,			8,	0x000000FF,		0,				0,				0			},	// DXGI_FORMAT_R8_UNORM 
		{ D3DFMT_L16,			DDPF_LUMINANCE,			16,	0x0000FFFF,		0,				0,				0			},	// DXGI_FORMAT_R16_UNORM
		{ D3DFMT_A8L8,			DDPF_LA,				16,	0x000000FF,		0,				0,				0x0000FF00	},	// DXGI_FORMAT_R8G8_UNORM?
	
		{ D3DFMT_A4L4,			DDPF_LA,				8,	0x0000000F,		0,				0,				0x000000F0	},	// none?
		
	
		{ D3DFMT_L6V5U5,		DDPF_BUMP_LUMINANCE,	16,	0x0000001F,		0x000003E0,		0x0000FC00,		0			},	// none?
		{ D3DFMT_V8U8,			DDPF_BUMP_DUDV,			16,	0x000000FF,		0x0000FF00,		0,				0			},	// none?
	
	
		{ D3DFMT_X8L8V8U8,		DDPF_BUMP_LUMINANCE,	32,	0x000000FF,		0x0000FF00,		0x00FF0000,		0			},	// same masks as D3DFMT_X8B8G8R8; none?
		{ D3DFMT_Q8W8V8U8,		DDPF_BUMP_DUDV,			32,	0x000000FF,		0x0000FF00,		0x00FF0000,		0xFF000000	},	// same masks as D3DFMT_A8B8G8R8; none?
	
		{ D3DFMT_V16U16,		DDPF_BUMP_DUDV,			32,	0x0000FFFF,		0xFFFF0000,		0,				0			},	// same masks as D3DFMT_G16R16; none?
		{ D3DFMT_A2W10V10U10,	DDPF_BUMP_DUDV_A,		32,	0x3FF00000,		0x000FFC00,		0x000003FF,		0xC0000000	},	// same masks as D3DFMT_A2R10G10B10; none?
	
    };

    static const uint s_d3d9FormatCount = NV_ARRAY_SIZE(s_d3d9Formats);
	
	
	static const FormatDescriptor s_DXGIFormats[] = {
		{ DXGI_FORMAT_B5G6R5_UNORM,		0,	16,	0x0000F800,		0x000007E0,		0x0000001F,		0			},
		{ DXGI_FORMAT_B5G5R5A1_UNORM,	0,	16,	0x00007C00,		0x000003E0,		0x0000001F,		0x00008000	},
		{ DXGI_FORMAT_B4G4R4A4_UNORM,	0,	16,	0x00000F00,		0x000000F0,		0x0000000F,		0x0000F000	},
	};
	
	static const uint s_DXGIFormatCount = NV_ARRAY_SIZE(s_DXGIFormats);
	
	
} // namespace

uint nv::findD3D9Format(uint pixelFormatFlags, uint bitcount, uint rmask, uint gmask, uint bmask, uint amask)
{
    for (int i = 0; i < s_d3d9FormatCount; i++)
    {
        if (s_d3d9Formats[i].bitcount == bitcount &&
            s_d3d9Formats[i].rmask == rmask &&
            s_d3d9Formats[i].gmask == gmask &&
            s_d3d9Formats[i].bmask == bmask &&
            s_d3d9Formats[i].amask == amask &&
			(s_d3d9Formats[i].pixelFormatFlags & pixelFormatFlags) == pixelFormatFlags)
        {
            return s_d3d9Formats[i].format;
        }
    }

    return 0;
}

static void findDXGIBitcountsAndMasks(DXGI_FORMAT dxgiFormat, uint &bitcount, uint &rmask, uint &gmask, uint &bmask, uint &amask) {
	for (int i = 0; i < s_DXGIFormatCount; i++) {
		if (s_DXGIFormats[i].format == dxgiFormat) {
			bitcount = s_DXGIFormats[i].bitcount;
			rmask = s_DXGIFormats[i].rmask;
			gmask = s_DXGIFormats[i].gmask;
			bmask = s_DXGIFormats[i].bmask;
			amask = s_DXGIFormats[i].amask;
			return;
		}
	}
	bitcount = rmask = gmask = bmask = amask = 0;
}


DDSHeader::DDSHeader()
{
    this->fourcc = FOURCC_DDS;
    this->size = 124;
    this->flags  = (DDSD_CAPS|DDSD_PIXELFORMAT);
    this->height = 0;
    this->width = 0;
    this->pitch = 0;
    this->depth = 0;
    this->mipmapcount = 0;
    memset(this->reserved, 0, sizeof(this->reserved));

    // Store version information on the reserved header attributes.
    this->reserved[9] = FOURCC_NVTT;
    this->reserved[10] = (2 << 16) | (1 << 8) | (0); // major.minor.revision

    this->pf.size = 32;
    this->pf.flags = 0;
    this->pf.fourcc = 0;
    this->pf.bitcount = 0;
    this->pf.rmask = 0;
    this->pf.gmask = 0;
    this->pf.bmask = 0;
    this->pf.amask = 0;
    this->caps.caps1 = DDSCAPS_TEXTURE;
    this->caps.caps2 = 0;
    this->caps.caps3 = 0;
    this->caps.caps4 = 0;
    this->notused = 0;

    this->header10.dxgiFormat = DXGI_FORMAT_UNKNOWN;
    this->header10.resourceDimension = DDS_DIMENSION_UNKNOWN;
    this->header10.miscFlag = 0;
    this->header10.arraySize = 0;
    this->header10.reserved = 0;
}

void DDSHeader::setWidth(uint w)
{
    this->flags |= DDSD_WIDTH;
    this->width = w;
}

void DDSHeader::setHeight(uint h)
{
    this->flags |= DDSD_HEIGHT;
    this->height = h;
}

void DDSHeader::setDepth(uint d)
{
    this->flags |= DDSD_DEPTH;
    this->depth = d;
}

void DDSHeader::setMipmapCount(uint count)
{
    if (count == 0 || count == 1)
    {
        this->flags &= ~DDSD_MIPMAPCOUNT;
        this->mipmapcount = 1;

        if (this->caps.caps2 == 0) {
            this->caps.caps1 = DDSCAPS_TEXTURE;
        }
        else {
            this->caps.caps1 = DDSCAPS_TEXTURE | DDSCAPS_COMPLEX;
        }
    }
    else
    {
        this->flags |= DDSD_MIPMAPCOUNT;
        this->mipmapcount = count;

        this->caps.caps1 |= DDSCAPS_COMPLEX | DDSCAPS_MIPMAP;
    }
}

void DDSHeader::setTexture2D()
{
    this->header10.resourceDimension = DDS_DIMENSION_TEXTURE2D;
    this->header10.miscFlag = 0;
    this->header10.arraySize = 1;
}

void DDSHeader::setTexture3D()
{
    this->caps.caps2 = DDSCAPS2_VOLUME;

    this->header10.resourceDimension = DDS_DIMENSION_TEXTURE3D;
    this->header10.miscFlag = 0;
    this->header10.arraySize = 1;
}

void DDSHeader::setTextureCube()
{
    this->caps.caps1 |= DDSCAPS_COMPLEX;
    this->caps.caps2 = DDSCAPS2_CUBEMAP | DDSCAPS2_CUBEMAP_ALL_FACES;

    this->header10.resourceDimension = DDS_DIMENSION_TEXTURE2D;
    this->header10.miscFlag = DDS_MISC_TEXTURECUBE;
    this->header10.arraySize = 1;
}

void DDSHeader::setLinearSize(uint size)
{
    this->flags &= ~DDSD_PITCH;
    this->flags |= DDSD_LINEARSIZE;
    this->pitch = size;
}

void DDSHeader::setPitch(uint pitch)
{
    this->flags &= ~DDSD_LINEARSIZE;
    this->flags |= DDSD_PITCH;
    this->pitch = pitch;
}

void DDSHeader::setFourCC(uint8 c0, uint8 c1, uint8 c2, uint8 c3)
{
    // set fourcc pixel format.
    this->pf.flags = DDPF_FOURCC;
    this->pf.fourcc = MAKEFOURCC(c0, c1, c2, c3);

    this->pf.bitcount = 0;
    this->pf.rmask = 0;
    this->pf.gmask = 0;
    this->pf.bmask = 0;
    this->pf.amask = 0;
}

void DDSHeader::setFormatCode(uint32 code)
{
    // set fourcc pixel format.
    this->pf.flags = DDPF_FOURCC;
    this->pf.fourcc = code;

    this->pf.bitcount = 0;
    this->pf.rmask = 0;
    this->pf.gmask = 0;
    this->pf.bmask = 0;
    this->pf.amask = 0;
}

void DDSHeader::setSwizzleCode(uint8 c0, uint8 c1, uint8 c2, uint8 c3)
{
    this->pf.bitcount = MAKEFOURCC(c0, c1, c2, c3);
}


void DDSHeader::setPixelFormat(uint bitcount, uint rmask, uint gmask, uint bmask, uint amask)
{
    // Make sure the masks are correct.
    nvCheck((rmask & gmask) == 0);
    nvCheck((rmask & bmask) == 0);
    nvCheck((rmask & amask) == 0);
    nvCheck((gmask & bmask) == 0);
    nvCheck((gmask & amask) == 0);
    nvCheck((bmask & amask) == 0);

    if (rmask != 0 || gmask != 0 || bmask != 0)
    {
        if (gmask == 0 && bmask == 0)
        {
            this->pf.flags = DDPF_LUMINANCE;
        }
        else
        {
            this->pf.flags = DDPF_RGB;
        }

        if (amask != 0) {
            this->pf.flags |= DDPF_ALPHAPIXELS;
        }
    }
    else if (amask != 0)
    {
        this->pf.flags |= DDPF_ALPHA;
    }

    if (bitcount == 0)
    {
        // Compute bit count from the masks.
        uint total = rmask | gmask | bmask | amask;
        while(total != 0) {
            bitcount++;
            total >>= 1;
        }
    }

    // D3DX functions do not like this:
    this->pf.fourcc = 0; //findD3D9Format(bitcount, rmask, gmask, bmask, amask);
    /*if (this->pf.fourcc) {
        this->pf.flags |= DDPF_FOURCC;
    }*/

    nvCheck(bitcount > 0 && bitcount <= 32);
    this->pf.bitcount = bitcount;
    this->pf.rmask = rmask;
    this->pf.gmask = gmask;
    this->pf.bmask = bmask;
    this->pf.amask = amask;
}

void DDSHeader::setDX10Format(uint format)
{
    this->pf.flags = DDPF_FOURCC;
    this->pf.fourcc = FOURCC_DX10;
    this->header10.dxgiFormat = format;
}

void DDSHeader::setNormalFlag(bool b)
{
    if (b) this->pf.flags |= DDPF_NORMAL;
    else this->pf.flags &= ~DDPF_NORMAL;
}

void DDSHeader::setSrgbFlag(bool b)
{
    if (b) this->pf.flags |= DDPF_SRGB;
    else this->pf.flags &= ~DDPF_SRGB;
}

void DDSHeader::setHasAlphaFlag(bool b)
{
    if (b) this->pf.flags |= DDPF_ALPHAPIXELS;
    else this->pf.flags &= ~DDPF_ALPHAPIXELS;
}

void DDSHeader::setUserVersion(int version)
{
    this->reserved[7] = FOURCC_UVER;
    this->reserved[8] = version;
}

void DDSHeader::swapBytes()
{
    this->fourcc = POSH_LittleU32(this->fourcc);
    this->size = POSH_LittleU32(this->size);
    this->flags = POSH_LittleU32(this->flags);
    this->height = POSH_LittleU32(this->height);
    this->width = POSH_LittleU32(this->width);
    this->pitch = POSH_LittleU32(this->pitch);
    this->depth = POSH_LittleU32(this->depth);
    this->mipmapcount = POSH_LittleU32(this->mipmapcount);

    for(int i = 0; i < 11; i++) {
        this->reserved[i] = POSH_LittleU32(this->reserved[i]);
    }

    this->pf.size = POSH_LittleU32(this->pf.size);
    this->pf.flags = POSH_LittleU32(this->pf.flags);
    this->pf.fourcc = POSH_LittleU32(this->pf.fourcc);
    this->pf.bitcount = POSH_LittleU32(this->pf.bitcount);
    this->pf.rmask = POSH_LittleU32(this->pf.rmask);
    this->pf.gmask = POSH_LittleU32(this->pf.gmask);
    this->pf.bmask = POSH_LittleU32(this->pf.bmask);
    this->pf.amask = POSH_LittleU32(this->pf.amask);
    this->caps.caps1 = POSH_LittleU32(this->caps.caps1);
    this->caps.caps2 = POSH_LittleU32(this->caps.caps2);
    this->caps.caps3 = POSH_LittleU32(this->caps.caps3);
    this->caps.caps4 = POSH_LittleU32(this->caps.caps4);
    this->notused = POSH_LittleU32(this->notused);

    this->header10.dxgiFormat = POSH_LittleU32(this->header10.dxgiFormat);
    this->header10.resourceDimension = POSH_LittleU32(this->header10.resourceDimension);
    this->header10.miscFlag = POSH_LittleU32(this->header10.miscFlag);
    this->header10.arraySize = POSH_LittleU32(this->header10.arraySize);
    this->header10.reserved = POSH_LittleU32(this->header10.reserved);
}

bool DDSHeader::hasDX10Header() const
{
    //if (pf.flags & DDPF_FOURCC) {
        return this->pf.fourcc == FOURCC_DX10;
    //}
    //return false;
}

uint DDSHeader::signature() const
{
    return this->reserved[9];
}

uint DDSHeader::toolVersion() const
{
    return this->reserved[10];
}

uint DDSHeader::userVersion() const
{
    if (this->reserved[7] == FOURCC_UVER) {
        return this->reserved[8];
    }
    return 0;
}

bool DDSHeader::isNormalMap() const
{
    return (pf.flags & DDPF_NORMAL) != 0;
}

bool DDSHeader::isSrgb() const
{
    return (pf.flags & DDPF_SRGB) != 0;
}

bool DDSHeader::hasAlpha() const
{
    return (pf.flags & DDPF_ALPHAPIXELS) != 0;
}

uint DDSHeader::d3d9Format() const
{
    if (pf.flags & DDPF_FOURCC) {
        return pf.fourcc;
    }
    else {
        return findD3D9Format(pf.flags, pf.bitcount, pf.rmask, pf.gmask, pf.bmask, pf.amask);
    }
}

uint DDSHeader::pixelSize() const
{
    if (hasDX10Header()) {
        return ::pixelSize((DXGI_FORMAT)header10.dxgiFormat);
    }
    else {
        if (pf.flags & DDPF_FOURCC) {
            return ::pixelSize((D3DFORMAT)pf.fourcc);
        }
        else {
            nvDebugCheck((pf.flags & DDPF_RGB) || (pf.flags & DDPF_LUMINANCE));
            return pf.bitcount;
        }
    }
}

uint DDSHeader::blockSize() const
{
    switch(pf.fourcc) 
    {
    case FOURCC_DXT1:
    case FOURCC_ATI1:
	case FOURCC_BC4U:
        return 8;
    case FOURCC_DXT2:
    case FOURCC_DXT3:
    case FOURCC_DXT4:
    case FOURCC_DXT5:
    case FOURCC_RXGB:
    case FOURCC_ATI2:
	case FOURCC_BC5U:
        return 16;
    case FOURCC_DX10:
        switch(header10.dxgiFormat)
        {
        case DXGI_FORMAT_BC1_TYPELESS:
        case DXGI_FORMAT_BC1_UNORM:
        case DXGI_FORMAT_BC1_UNORM_SRGB:
        case DXGI_FORMAT_BC4_TYPELESS:
        case DXGI_FORMAT_BC4_UNORM:
        case DXGI_FORMAT_BC4_SNORM:
            return 8;
        case DXGI_FORMAT_BC2_TYPELESS:
        case DXGI_FORMAT_BC2_UNORM:
        case DXGI_FORMAT_BC2_UNORM_SRGB:
        case DXGI_FORMAT_BC3_TYPELESS:
        case DXGI_FORMAT_BC3_UNORM:
        case DXGI_FORMAT_BC3_UNORM_SRGB:
        case DXGI_FORMAT_BC5_TYPELESS:
        case DXGI_FORMAT_BC5_UNORM:
        case DXGI_FORMAT_BC5_SNORM:
        case DXGI_FORMAT_BC6H_TYPELESS:
        case DXGI_FORMAT_BC6H_SF16:
        case DXGI_FORMAT_BC6H_UF16:
        case DXGI_FORMAT_BC7_TYPELESS:
        case DXGI_FORMAT_BC7_UNORM:
        case DXGI_FORMAT_BC7_UNORM_SRGB:
            return 16;
        };
    };

    // Not a block image.
    return 0;
}

bool DDSHeader::isBlockFormat() const
{
    return blockSize() != 0;
}





DirectDrawSurface::DirectDrawSurface() : stream(NULL)
{
}

DirectDrawSurface::DirectDrawSurface(const char * name) : stream(NULL)
{
    load(name);
}

DirectDrawSurface::DirectDrawSurface(Stream * s) : stream(NULL)
{
    load(s);
}

DirectDrawSurface::DirectDrawSurface(unsigned char *mem, uint size) : stream(NULL)
{
	load(new MemoryInputStream(mem, size));
}

DirectDrawSurface::~DirectDrawSurface()
{
    delete stream;
}

bool DirectDrawSurface::load(const char * filename)
{
    return load(new StdInputStream(filename));
}

bool DirectDrawSurface::load(Stream * stream)
{
    delete this->stream;
    this->stream = stream;

    if (!stream->isError())
    {
        (*stream) << header;
        return true;
    }

    return false;
}

bool DirectDrawSurface::isValid() const
{
    if (stream == NULL || stream->isError())
    {
        return false;
    }

    if (header.fourcc != FOURCC_DDS || header.size != 124)
    {
        return false;
    }

    const uint required = (DDSD_WIDTH|DDSD_HEIGHT/*|DDSD_CAPS|DDSD_PIXELFORMAT*/);
    if( (header.flags & required) != required ) {
        return false;
    }

    if (header.pf.size != 32) {
        return false;
    }

    if( !(header.caps.caps1 & DDSCAPS_TEXTURE) ) {
        return false;
    }

    return true;
}

bool DirectDrawSurface::isSupported() const
{
    nvDebugCheck(isValid());

    if (header.hasDX10Header())
    {
        if (header.header10.dxgiFormat == DXGI_FORMAT_BC1_UNORM ||
            header.header10.dxgiFormat == DXGI_FORMAT_BC2_UNORM ||
            header.header10.dxgiFormat == DXGI_FORMAT_BC3_UNORM ||
            header.header10.dxgiFormat == DXGI_FORMAT_BC4_UNORM ||
            header.header10.dxgiFormat == DXGI_FORMAT_BC5_UNORM ||
			header.header10.dxgiFormat == DXGI_FORMAT_BC6H_UF16 ||
			header.header10.dxgiFormat == DXGI_FORMAT_BC7_UNORM)
        {
            return true;
        }

        return false;
    }
    else
    {
        if (header.pf.flags & DDPF_FOURCC)
        {
            if (header.pf.fourcc != FOURCC_DXT1 &&
                header.pf.fourcc != FOURCC_DXT2 &&
                header.pf.fourcc != FOURCC_DXT3 &&
                header.pf.fourcc != FOURCC_DXT4 &&
                header.pf.fourcc != FOURCC_DXT5 &&
                header.pf.fourcc != FOURCC_RXGB &&
                header.pf.fourcc != FOURCC_ATI1 &&
                header.pf.fourcc != FOURCC_ATI2 &&
				header.pf.fourcc != FOURCC_BC4U &&
				header.pf.fourcc != FOURCC_BC5U)
            {
                // Unknown fourcc code.
                return false;
            }
        }
        else if ((header.pf.flags & DDPF_RGB) || (header.pf.flags & DDPF_LUMINANCE))
        {
            // All RGB and luminance formats are supported now.
        }
        else
        {
            return false;
        }

        if (isTextureCube()) {
            if (header.width != header.height) return false;

            if ((header.caps.caps2 & DDSCAPS2_CUBEMAP_ALL_FACES) != DDSCAPS2_CUBEMAP_ALL_FACES)
            {
                // Cubemaps must contain all faces.
                return false;
            }
        }
    }

    return true;
}

bool DirectDrawSurface::hasAlpha() const
{
    if (header.hasDX10Header())
    {
#pragma NV_MESSAGE("TODO: Update hasAlpha to handle all DX10 formats.")
        return 
            header.header10.dxgiFormat == DXGI_FORMAT_BC1_UNORM ||
            header.header10.dxgiFormat == DXGI_FORMAT_BC2_UNORM ||
            header.header10.dxgiFormat == DXGI_FORMAT_BC3_UNORM ||
	
			header.header10.dxgiFormat == DXGI_FORMAT_R32G32B32A32_TYPELESS ||
			header.header10.dxgiFormat == DXGI_FORMAT_R32G32B32A32_FLOAT ||
			header.header10.dxgiFormat == DXGI_FORMAT_R32G32B32A32_UINT ||
			header.header10.dxgiFormat == DXGI_FORMAT_R32G32B32A32_SINT ||
	
			header.header10.dxgiFormat == DXGI_FORMAT_R16G16B16A16_TYPELESS ||
			header.header10.dxgiFormat == DXGI_FORMAT_R16G16B16A16_FLOAT ||
			header.header10.dxgiFormat == DXGI_FORMAT_R16G16B16A16_UNORM ||
			header.header10.dxgiFormat == DXGI_FORMAT_R16G16B16A16_UINT ||
			header.header10.dxgiFormat == DXGI_FORMAT_R16G16B16A16_SNORM ||
			header.header10.dxgiFormat == DXGI_FORMAT_R16G16B16A16_SINT ||
	
			header.header10.dxgiFormat == DXGI_FORMAT_R10G10B10A2_TYPELESS ||
			header.header10.dxgiFormat == DXGI_FORMAT_R10G10B10A2_UNORM ||
			header.header10.dxgiFormat == DXGI_FORMAT_R10G10B10A2_UINT ||
	
			header.header10.dxgiFormat == DXGI_FORMAT_R8G8B8A8_TYPELESS ||
			header.header10.dxgiFormat == DXGI_FORMAT_R8G8B8A8_UNORM ||
			header.header10.dxgiFormat == DXGI_FORMAT_R8G8B8A8_UNORM_SRGB ||
			header.header10.dxgiFormat == DXGI_FORMAT_R8G8B8A8_UINT ||
			header.header10.dxgiFormat == DXGI_FORMAT_R8G8B8A8_SNORM ||
			header.header10.dxgiFormat == DXGI_FORMAT_R8G8B8A8_SINT ||
	
			header.header10.dxgiFormat == DXGI_FORMAT_A8_UNORM ||
	
			header.header10.dxgiFormat == DXGI_FORMAT_B5G5R5A1_UNORM ||
			header.header10.dxgiFormat == DXGI_FORMAT_B8G8R8A8_UNORM ||
	
			header.header10.dxgiFormat == DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM ||
	
			header.header10.dxgiFormat == DXGI_FORMAT_B8G8R8A8_TYPELESS ||
			header.header10.dxgiFormat == DXGI_FORMAT_B8G8R8A8_UNORM_SRGB ||
	
			header.header10.dxgiFormat == DXGI_FORMAT_BC7_TYPELESS ||
			header.header10.dxgiFormat == DXGI_FORMAT_BC7_UNORM ||
			header.header10.dxgiFormat == DXGI_FORMAT_BC7_UNORM_SRGB ||
	
			header.header10.dxgiFormat == DXGI_FORMAT_B4G4R4A4_UNORM;
    }
    else
    {
        if (header.pf.flags & DDPF_RGB) 
        {
            return header.pf.amask != 0;
        }
        else if (header.pf.flags & DDPF_FOURCC)
        {
            if (header.pf.fourcc == FOURCC_RXGB ||
                header.pf.fourcc == FOURCC_ATI1 ||
                header.pf.fourcc == FOURCC_ATI2 ||
				header.pf.fourcc == FOURCC_BC4U ||
				header.pf.fourcc == FOURCC_BC5U ||
                header.pf.flags & DDPF_NORMAL)
            {
                return false;
            }
            else
            {
                // @@ Here we could check the ALPHA_PIXELS flag, but nobody sets it. (except us?)
                return true;
            }
        }

        return false;
    }
}

uint DirectDrawSurface::mipmapCount() const
{
    nvDebugCheck(isValid());
    if (header.flags & DDSD_MIPMAPCOUNT) return header.mipmapcount;
    else return 1;
}


uint DirectDrawSurface::width() const
{
    nvDebugCheck(isValid());
    if (header.flags & DDSD_WIDTH) return header.width;
    else return 1;
}

uint DirectDrawSurface::height() const
{
    nvDebugCheck(isValid());
    if (header.flags & DDSD_HEIGHT) return header.height;
    else return 1;
}

uint DirectDrawSurface::depth() const
{
    nvDebugCheck(isValid());
    if (header.flags & DDSD_DEPTH) return header.depth;
    else return 1;
}

bool DirectDrawSurface::isTexture1D() const
{
    nvDebugCheck(isValid());
    if (header.hasDX10Header())
    {
        return header.header10.resourceDimension == DDS_DIMENSION_TEXTURE1D;
    }
    return false;
}

bool DirectDrawSurface::isTexture2D() const
{
    nvDebugCheck(isValid());
    if (header.hasDX10Header())
    {
        return header.header10.resourceDimension == DDS_DIMENSION_TEXTURE2D;
    }
    else
    {
        return !isTexture3D() && !isTextureCube();
    }
}

bool DirectDrawSurface::isTexture3D() const
{
    nvDebugCheck(isValid());
    if (header.hasDX10Header())
    {
        return header.header10.resourceDimension == DDS_DIMENSION_TEXTURE3D;
    }
    else
    {
        return (header.caps.caps2 & DDSCAPS2_VOLUME) != 0;
    }
}

bool DirectDrawSurface::isTextureCube() const
{
    nvDebugCheck(isValid());
    return (header.caps.caps2 & DDSCAPS2_CUBEMAP) != 0;
}

void DirectDrawSurface::setNormalFlag(bool b)
{
    nvDebugCheck(isValid());
    header.setNormalFlag(b);
}

void DirectDrawSurface::setHasAlphaFlag(bool b)
{
    nvDebugCheck(isValid());
    header.setHasAlphaFlag(b);
}

void DirectDrawSurface::setUserVersion(int version)
{
    nvDebugCheck(isValid());
    header.setUserVersion(version);
}

void DirectDrawSurface::mipmap(Image * img, uint face, uint mipmap)
{
    nvDebugCheck(isValid());

    stream->seek(offset(face, mipmap));

    uint w = width();
    uint h = height();
	uint d = depth();

    // Compute width and height.
    for (uint m = 0; m < mipmap; m++)
    {
        w = max(1U, w / 2);
        h = max(1U, h / 2);
		d = max(1U, d / 2);
    }

    img->allocate(w, h, d);

    if (hasAlpha())
    {
        img->setFormat(Image::Format_ARGB);
    }
    else
    {
        img->setFormat(Image::Format_RGB);
    }

    if (header.hasDX10Header())
    {
	
		switch (header.header10.dxgiFormat) {
				
			case DXGI_FORMAT_B5G6R5_UNORM:
			case DXGI_FORMAT_B5G5R5A1_UNORM:
			case DXGI_FORMAT_B4G4R4A4_UNORM:
				readLinearImage(img);
				break;
				
			default:
				// So far only block formats supported.
				readBlockImage(img);
		}
    }
    else
    {
        if (header.pf.flags & DDPF_RGB) 
        {
            readLinearImage(img);
        }
        else if (header.pf.flags & DDPF_FOURCC)
        {
            readBlockImage(img);
        }
    }
}

/*void * DirectDrawSurface::readData(uint * sizePtr)
{
    uint header_size = 128; // sizeof(DDSHeader);

    if (header.hasDX10Header())
    {
        header_size += 20; // sizeof(DDSHeader10);
    }

    stream->seek(header_size);

    int size = stream->size() - header_size;
    *sizePtr = size;

    void * data = new unsigned char [size];
    
    size = stream->serialize(data, size);
    nvDebugCheck(size == *sizePtr);

    return data;
}*/

/*uint DirectDrawSurface::surfaceSize(uint mipmap) const
{
    uint w = header.width();
    uint h = header.height();
    uint d = header.depth();
    for (int m = 0; m < mipmap; m++) {
        w = (w + 1) / 2;
        h = (h + 1) / 2;
        d = (d + 1) / 2;
    }
    
    bool isBlockFormat;
    uint blockOrPixelSize;

    if (header.hasDX10Header()) {
        blockOrPixelSize = blockSize(header10.dxgiFormat);
        isBlockFormat = (blockOrPixelSize != 0);
        if (isBlockFormat) {
            blockOrPixelSize = pixelSize(header10.dxgiFormat);
        }
    }
    else {
        header.pf.flags 
    }

    if (isBlockFormat) {
        w = (w + 3) / 4;
        h = (h + 3) / 4;
        d = (d + 3) / 4; // @@ Is it necessary to align the depths?
    }

    uint blockOrPixelCount = w * h * d;

    return blockCount = blockOrPixelSize;
}*/

bool DirectDrawSurface::readSurface(uint face, uint mipmap, void * data, uint size)
{
    if (size != surfaceSize(mipmap)) return false;

    stream->seek(offset(face, mipmap));
    if (stream->isError()) return false;

    return stream->serialize(data, size) == size;
}


void DirectDrawSurface::readLinearImage(Image * img)
{
    nvDebugCheck(stream != NULL);
    nvDebugCheck(img != NULL);

    const uint w = img->width();
    const uint h = img->height();
    const uint d = img->depth();
	
	
    uint rmask, rshift, rsize;
    uint gmask, gshift, gsize;
    uint bmask, bshift, bsize;
    uint amask, ashift, asize;
	
    uint byteCount = 0;
	
	if (header.hasDX10Header()) {
		uint bitcount;
		
		::findDXGIBitcountsAndMasks((DXGI_FORMAT)header.header10.dxgiFormat, bitcount, rmask, gmask, bmask, amask);
		
		PixelFormat::maskShiftAndSize(rmask, &rshift, &rsize);
		PixelFormat::maskShiftAndSize(gmask, &gshift, &gsize);
		PixelFormat::maskShiftAndSize(bmask, &bshift, &bsize);
		PixelFormat::maskShiftAndSize(amask, &ashift, &asize);
		
		byteCount = (bitcount + 7) / 8;
		
		
	} else {
		rmask = header.pf.rmask;
		gmask = header.pf.gmask;
		bmask = header.pf.bmask;
		amask = header.pf.amask;
		
		PixelFormat::maskShiftAndSize(header.pf.rmask, &rshift, &rsize);
		PixelFormat::maskShiftAndSize(header.pf.gmask, &gshift, &gsize);
		PixelFormat::maskShiftAndSize(header.pf.bmask, &bshift, &bsize);
		PixelFormat::maskShiftAndSize(header.pf.amask, &ashift, &asize);
		
		byteCount = (header.pf.bitcount + 7) / 8;
		
	}

#pragma NV_MESSAGE("TODO: Support floating point linear images and other FOURCC codes.")

    // Read linear RGB images.
    for (uint z = 0; z < d; z++)
    {
        for (uint y = 0; y < h; y++)
        {
            for (uint x = 0; x < w; x++)
            {
                uint c = 0;
                stream->serialize(&c, byteCount);

                Color32 pixel(0, 0, 0, 0xFF);
                pixel.r = PixelFormat::convert((c & rmask) >> rshift, rsize, 8);
                pixel.g = PixelFormat::convert((c & gmask) >> gshift, gsize, 8);
                pixel.b = PixelFormat::convert((c & bmask) >> bshift, bsize, 8);
                pixel.a = PixelFormat::convert((c & amask) >> ashift, asize, 8);

                img->pixel(x, y, z) = pixel;
            }
        }
    }
}

void DirectDrawSurface::readBlockImage(Image * img)
{
    nvDebugCheck(stream != NULL);
    nvDebugCheck(img != NULL);

    const uint w = img->width();
    const uint h = img->height();

    const uint bw = (w + 3) / 4;
    const uint bh = (h + 3) / 4;

    for (uint by = 0; by < bh; by++)
    {
        for (uint bx = 0; bx < bw; bx++)
        {
            ColorBlock block;

            // Read color block.
            readBlock(&block);

            // Write color block.
            for (uint y = 0; y < min(4U, h-4*by); y++)
            {
                for (uint x = 0; x < min(4U, w-4*bx); x++)
                {
                    img->pixel(4*bx+x, 4*by+y) = block.color(x, y);
                }
            }
        }
    }
}

static Color32 buildNormal(uint8 x, uint8 y)
{
    float nx = 2 * (x / 255.0f) - 1;
    float ny = 2 * (y / 255.0f) - 1;
    float nz = 0.0f;
    if (1 - nx*nx - ny*ny > 0) nz = sqrtf(1 - nx*nx - ny*ny);
    uint8 z = clamp(int(255.0f * (nz + 1) / 2.0f), 0, 255);

    return Color32(x, y, z);
}


void DirectDrawSurface::readBlock(ColorBlock * rgba)
{
    nvDebugCheck(stream != NULL);
    nvDebugCheck(rgba != NULL);

    uint fourcc = header.pf.fourcc;

    // Map DX10 block formats to fourcc codes.
    if (header.hasDX10Header())
    {
        if (header.header10.dxgiFormat == DXGI_FORMAT_BC1_UNORM) fourcc = FOURCC_DXT1;
        else if (header.header10.dxgiFormat == DXGI_FORMAT_BC2_UNORM) fourcc = FOURCC_DXT3;
        else if (header.header10.dxgiFormat == DXGI_FORMAT_BC3_UNORM) fourcc = FOURCC_DXT5;
        else if (header.header10.dxgiFormat == DXGI_FORMAT_BC4_UNORM) fourcc = FOURCC_ATI1;
        else if (header.header10.dxgiFormat == DXGI_FORMAT_BC5_UNORM) fourcc = FOURCC_ATI2;
    }
	
	if (fourcc == FOURCC_BC4U) fourcc = FOURCC_ATI1;
	else if (fourcc == FOURCC_BC5U) fourcc = FOURCC_ATI2;

    if (fourcc == FOURCC_DXT1)
    {
        BlockDXT1 block;
        *stream << block;
        block.decodeBlock(rgba);
    }
    else if (fourcc == FOURCC_DXT2 || fourcc == FOURCC_DXT3)
    {
        BlockDXT3 block;
        *stream << block;
        block.decodeBlock(rgba);
    }
    else if (fourcc == FOURCC_DXT4 || fourcc == FOURCC_DXT5 || fourcc == FOURCC_RXGB)
    {
        BlockDXT5 block;
        *stream << block;
        block.decodeBlock(rgba);

        if (fourcc == FOURCC_RXGB)
        {
            // Swap R & A.
            for (int i = 0; i < 16; i++)
            {
                Color32 & c = rgba->color(i);
                uint tmp = c.r;
                c.r = c.a;
                c.a = tmp;
            }
        }
    }
    else if (fourcc == FOURCC_ATI1)
    {
        BlockATI1 block;
        *stream << block;
        block.decodeBlock(rgba);
    }
    else if (fourcc == FOURCC_ATI2)
    {
        BlockATI2 block;
        *stream << block;
        block.decodeBlock(rgba);
    }
	else if (header.hasDX10Header() && header.header10.dxgiFormat == DXGI_FORMAT_BC6H_UF16)
	{
		BlockBC6 block;
		*stream << block;
		ColorSet set;
		block.decodeBlock(&set);

		// Clamp to [0, 1] and round to 8-bit
		for (int y = 0; y < 4; ++y)
		{
			for (int x = 0; x < 4; ++x)
			{
				Vector4 px = set.colors[y*4 + x];
				rgba->color(x, y).setRGBA(
									uint8(clamp(px.x, 0.0f, 1.0f) * 255.0f + 0.5f),
									uint8(clamp(px.y, 0.0f, 1.0f) * 255.0f + 0.5f),
									uint8(clamp(px.z, 0.0f, 1.0f) * 255.0f + 0.5f),
									uint8(clamp(px.w, 0.0f, 1.0f) * 255.0f + 0.5f));
			}
		}
	}
    else if (header.hasDX10Header() && header.header10.dxgiFormat == DXGI_FORMAT_BC7_UNORM)
    {
        BlockBC7 block;
        *stream << block;
        block.decodeBlock(rgba);
    }
	else
	{
		nvDebugCheck(false);
	}

    // If normal flag set, convert to normal.
    if (header.pf.flags & DDPF_NORMAL)
    {
        if (fourcc == FOURCC_ATI2)
        {
            for (int i = 0; i < 16; i++)
            {
                Color32 & c = rgba->color(i);
                c = buildNormal(c.r, c.g);
            }
        }
        else if (fourcc == FOURCC_DXT5)
        {
            for (int i = 0; i < 16; i++)
            {
                Color32 & c = rgba->color(i);
                c = buildNormal(c.a, c.g);
            }
        }
    }
}


static uint mipmapExtent(uint mipmap, uint x)
{
    for (uint m = 0; m < mipmap; m++) {
        x = max(1U, x / 2);
    }
    return x;
}

uint DirectDrawSurface::surfaceWidth(uint mipmap) const
{
    return mipmapExtent(mipmap, width());
}

uint DirectDrawSurface::surfaceHeight(uint mipmap) const
{
    return mipmapExtent(mipmap, height());
}

uint DirectDrawSurface::surfaceDepth(uint mipmap) const
{
    return mipmapExtent(mipmap, depth());
}

uint DirectDrawSurface::surfaceSize(uint mipmap) const
{
    uint w = surfaceWidth(mipmap);
    uint h = surfaceHeight(mipmap);
    uint d = surfaceDepth(mipmap);

    uint blockSize = header.blockSize();

    if (blockSize == 0) {
        uint bitCount = header.pixelSize();
        uint pitch = computeBytePitch(w, bitCount, 1); // Assuming 1 byte alignment, which is the same D3DX expects.
        return pitch * h * d;
    }
    else {
        w = (w + 3) / 4;
        h = (h + 3) / 4;
        d = d; // @@ How are 3D textures aligned?
        return blockSize * w * h * d;
    }
}

uint DirectDrawSurface::faceSize() const
{
    const uint count = mipmapCount();
    uint size = 0;

    for (uint m = 0; m < count; m++)
    {
        size += surfaceSize(m);
    }

    return size;
}

uint DirectDrawSurface::offset(const uint face, const uint mipmap)
{
    uint size = 128; // sizeof(DDSHeader);

    if (header.hasDX10Header())
    {
        size += 20; // sizeof(DDSHeader10);
    }

    if (face != 0)
    {
        size += face * faceSize();
    }

    for (uint m = 0; m < mipmap; m++)
    {
        size += surfaceSize(m);
    }

    return size;
}


void DirectDrawSurface::printInfo() const
{
    printf("\tFlags: 0x%.8X\n", header.flags);
    if (header.flags & DDSD_CAPS) printf("\t\tDDSD_CAPS\n");
    if (header.flags & DDSD_PIXELFORMAT) printf("\t\tDDSD_PIXELFORMAT\n");
    if (header.flags & DDSD_WIDTH) printf("\t\tDDSD_WIDTH\n");
    if (header.flags & DDSD_HEIGHT) printf("\t\tDDSD_HEIGHT\n");
    if (header.flags & DDSD_DEPTH) printf("\t\tDDSD_DEPTH\n");
    if (header.flags & DDSD_PITCH) printf("\t\tDDSD_PITCH\n");
    if (header.flags & DDSD_LINEARSIZE) printf("\t\tDDSD_LINEARSIZE\n");
    if (header.flags & DDSD_MIPMAPCOUNT) printf("\t\tDDSD_MIPMAPCOUNT\n");

    printf("\tHeight: %d\n", header.height);
    printf("\tWidth: %d\n", header.width);
    printf("\tDepth: %d\n", header.depth);
    if (header.flags & DDSD_PITCH) printf("\tPitch: %d\n", header.pitch);
    else if (header.flags & DDSD_LINEARSIZE) printf("\tLinear size: %d\n", header.pitch);
    printf("\tMipmap count: %d\n", header.mipmapcount);

    printf("\tPixel Format:\n");
    printf("\t\tFlags: 0x%.8X\n", header.pf.flags);
    if (header.pf.flags & DDPF_RGB) printf("\t\t\tDDPF_RGB\n");
    if (header.pf.flags & DDPF_LUMINANCE) printf("\t\t\tDDPF_LUMINANCE\n");
    if (header.pf.flags & DDPF_BUMP_LUMINANCE) printf("\t\t\tDDPF_BUMP_LUMINANCE\n");
    if (header.pf.flags & DDPF_BUMP_DUDV) printf("\t\t\tDDPF_BUMP_DUDV\n");
    if (header.pf.flags & DDPF_FOURCC) printf("\t\t\tDDPF_FOURCC\n");
    if (header.pf.flags & DDPF_ALPHAPIXELS) printf("\t\t\tDDPF_ALPHAPIXELS\n");
    if (header.pf.flags & DDPF_ALPHA) printf("\t\t\tDDPF_ALPHA\n");
    if (header.pf.flags & DDPF_PALETTEINDEXED1) printf("\t\t\tDDPF_PALETTEINDEXED1\n");
    if (header.pf.flags & DDPF_PALETTEINDEXED2) printf("\t\t\tDDPF_PALETTEINDEXED2\n");
    if (header.pf.flags & DDPF_PALETTEINDEXED4) printf("\t\t\tDDPF_PALETTEINDEXED4\n");
    if (header.pf.flags & DDPF_PALETTEINDEXED8) printf("\t\t\tDDPF_PALETTEINDEXED8\n");
    if (header.pf.flags & DDPF_ALPHAPREMULT) printf("\t\t\tDDPF_ALPHAPREMULT\n");
    if (header.pf.flags & DDPF_NORMAL) printf("\t\t\tDDPF_NORMAL\n");

    if (header.pf.fourcc != 0) { 
        // Display fourcc code even when DDPF_FOURCC flag not set.
        printf("\t\tFourCC: '%c%c%c%c' (0x%.8X)\n",
            ((header.pf.fourcc >> 0) & 0xFF),
            ((header.pf.fourcc >> 8) & 0xFF),
            ((header.pf.fourcc >> 16) & 0xFF),
            ((header.pf.fourcc >> 24) & 0xFF), 
            header.pf.fourcc);
    }

    if ((header.pf.flags & DDPF_FOURCC) && (header.pf.bitcount != 0))
    {
        printf("\t\tSwizzle: '%c%c%c%c' (0x%.8X)\n", 
            (header.pf.bitcount >> 0) & 0xFF,
            (header.pf.bitcount >> 8) & 0xFF,
            (header.pf.bitcount >> 16) & 0xFF,
            (header.pf.bitcount >> 24) & 0xFF,
            header.pf.bitcount);
    }
    else
    {
        printf("\t\tBit count: %d\n", header.pf.bitcount);
    }

    printf("\t\tRed mask:   0x%.8X\n", header.pf.rmask);
    printf("\t\tGreen mask: 0x%.8X\n", header.pf.gmask);
    printf("\t\tBlue mask:  0x%.8X\n", header.pf.bmask);
    printf("\t\tAlpha mask: 0x%.8X\n", header.pf.amask);

    printf("\tCaps:\n");
    printf("\t\tCaps 1: 0x%.8X\n", header.caps.caps1);
    if (header.caps.caps1 & DDSCAPS_COMPLEX) printf("\t\t\tDDSCAPS_COMPLEX\n");
    if (header.caps.caps1 & DDSCAPS_TEXTURE) printf("\t\t\tDDSCAPS_TEXTURE\n");
    if (header.caps.caps1 & DDSCAPS_MIPMAP) printf("\t\t\tDDSCAPS_MIPMAP\n");

    printf("\t\tCaps 2: 0x%.8X\n", header.caps.caps2);
    if (header.caps.caps2 & DDSCAPS2_VOLUME) printf("\t\t\tDDSCAPS2_VOLUME\n");
    else if (header.caps.caps2 & DDSCAPS2_CUBEMAP)
    {
        printf("\t\t\tDDSCAPS2_CUBEMAP\n");
        if ((header.caps.caps2 & DDSCAPS2_CUBEMAP_ALL_FACES) == DDSCAPS2_CUBEMAP_ALL_FACES) printf("\t\t\tDDSCAPS2_CUBEMAP_ALL_FACES\n");
        else {
            if (header.caps.caps2 & DDSCAPS2_CUBEMAP_POSITIVEX) printf("\t\t\tDDSCAPS2_CUBEMAP_POSITIVEX\n");
            if (header.caps.caps2 & DDSCAPS2_CUBEMAP_NEGATIVEX) printf("\t\t\tDDSCAPS2_CUBEMAP_NEGATIVEX\n");
            if (header.caps.caps2 & DDSCAPS2_CUBEMAP_POSITIVEY) printf("\t\t\tDDSCAPS2_CUBEMAP_POSITIVEY\n");
            if (header.caps.caps2 & DDSCAPS2_CUBEMAP_NEGATIVEY) printf("\t\t\tDDSCAPS2_CUBEMAP_NEGATIVEY\n");
            if (header.caps.caps2 & DDSCAPS2_CUBEMAP_POSITIVEZ) printf("\t\t\tDDSCAPS2_CUBEMAP_POSITIVEZ\n");
            if (header.caps.caps2 & DDSCAPS2_CUBEMAP_NEGATIVEZ) printf("\t\t\tDDSCAPS2_CUBEMAP_NEGATIVEZ\n");
        }
    }

    printf("\t\tCaps 3: 0x%.8X\n", header.caps.caps3);
    printf("\t\tCaps 4: 0x%.8X\n", header.caps.caps4);

    if (header.hasDX10Header())
    {
        printf("\tDX10 Header:\n");
        printf("\t\tDXGI Format: %u (%s)\n", header.header10.dxgiFormat, getDxgiFormatString((DXGI_FORMAT)header.header10.dxgiFormat));
        printf("\t\tResource dimension: %u (%s)\n", header.header10.resourceDimension, getD3d10ResourceDimensionString((DDS_DIMENSION)header.header10.resourceDimension));
        printf("\t\tMisc flag: %u\n", header.header10.miscFlag);
        printf("\t\tArray size: %u\n", header.header10.arraySize);
    }

    if (header.reserved[9] == FOURCC_NVTT)
    {
        int major = (header.reserved[10] >> 16) & 0xFF;
        int minor = (header.reserved[10] >> 8) & 0xFF;
        int revision= header.reserved[10] & 0xFF;

        printf("\tVersion:\n");
        printf("\t\tNVIDIA Texture Tools %d.%d.%d\n", major, minor, revision);
    }

    if (header.reserved[7] == FOURCC_UVER)
    {
        printf("\tUser Version: %d\n", header.reserved[8]);
    }
}

