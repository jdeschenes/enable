# :Author:    Robert Kern
# :Copyright: 2004, 2007, Enthought, Inc.
# :License:   BSD Style


include "Python.pxi"
include "CoreFoundation.pxi"
include "CoreFoundationDef.pxi"
include "CoreGraphics.pxi"
include "QuickDraw.pxi"
include "ATS.pxi"
include "ATSUI.pxi"

cimport c_numpy

import warnings

from ATSFont import default_font_info

cdef extern from "math.h":
    double sqrt(double arg)


# Enumerations

class LineCap:
    butt = kCGLineCapButt
    round = kCGLineCapRound
    square = kCGLineCapSquare

class LineJoin:
    miter = kCGLineJoinMiter
    round = kCGLineJoinRound
    bevel = kCGLineJoinBevel

class PathDrawingMode:
    fill = kCGPathFill
    eof_fill = kCGPathEOFill
    stroke = kCGPathStroke
    fill_stroke = kCGPathFillStroke
    eof_fill_stroke = kCGPathEOFillStroke

class RectEdge:
    min_x_edge = CGRectMinXEdge
    min_y_edge = CGRectMinYEdge
    max_x_edge = CGRectMaxXEdge
    max_y_edge = CGRectMaxYEdge

class ColorRenderingIntent:
    default = kCGRenderingIntentDefault
    absolute_colorimetric = kCGRenderingIntentAbsoluteColorimetric
    realative_colorimetric = kCGRenderingIntentRelativeColorimetric
    perceptual = kCGRenderingIntentPerceptual
    saturation = kCGRenderingIntentSaturation

#class ColorSpaces:
#    gray = kCGColorSpaceUserGray
#    rgb = kCGColorSpaceUserRGB
#    cmyk = kCGColorSpaceUserCMYK

class FontEnum:
    index_max  = kCGFontIndexMax
    index_invalid  = kCGFontIndexInvalid
    glyph_max  = kCGGlyphMax

class TextDrawingMode:
    fill = kCGTextFill
    stroke = kCGTextStroke
    fill_stroke = kCGTextFillStroke
    invisible = kCGTextInvisible
    fill_clip = kCGTextFillClip
    stroke_clip = kCGTextStrokeClip
    fill_stroke_clip = kCGTextFillStrokeClip
    clip = kCGTextClip

class TextEncodings:
    font_specific = kCGEncodingFontSpecific
    mac_roman = kCGEncodingMacRoman

class ImageAlphaInfo:
    none = kCGImageAlphaNone
    premultiplied_last = kCGImageAlphaPremultipliedLast
    premultiplied_first = kCGImageAlphaPremultipliedFirst
    last = kCGImageAlphaLast
    first = kCGImageAlphaFirst
    none_skip_last = kCGImageAlphaNoneSkipLast
    none_skip_first = kCGImageAlphaNoneSkipFirst
    only = kCGImageAlphaOnly

class InterpolationQuality:
    default = kCGInterpolationDefault
    none = kCGInterpolationNone
    low = kCGInterpolationLow
    high = kCGInterpolationHigh

class PathElementType:
    move_to = kCGPathElementMoveToPoint,
    line_to = kCGPathElementAddLineToPoint,
    quad_curve_to = kCGPathElementAddQuadCurveToPoint,
    curve_to = kCGPathElementAddCurveToPoint,
    close_path = kCGPathElementCloseSubpath

class StringEncoding:
    mac_roman  = kCFStringEncodingMacRoman
    windows_latin1  = kCFStringEncodingWindowsLatin1
    iso_latin1  = kCFStringEncodingISOLatin1
    nextstep_latin  = kCFStringEncodingNextStepLatin
    ascii  = kCFStringEncodingASCII
    unicode  = kCFStringEncodingUnicode
    utf8  = kCFStringEncodingUTF8
    nonlossy_ascii  = kCFStringEncodingNonLossyASCII

class URLPathStyle:
    posix = kCFURLPOSIXPathStyle
    hfs = kCFURLHFSPathStyle
    windows = kCFURLWindowsPathStyle

c_numpy.import_array()
import numpy

from enthought.kiva import constants

cap_style = {}
cap_style[constants.CAP_ROUND]  = kCGLineCapRound
cap_style[constants.CAP_SQUARE] = kCGLineCapSquare
cap_style[constants.CAP_BUTT]   = kCGLineCapButt

join_style = {}
join_style[constants.JOIN_ROUND] = kCGLineJoinRound
join_style[constants.JOIN_BEVEL] = kCGLineJoinBevel
join_style[constants.JOIN_MITER] = kCGLineJoinMiter

draw_modes = {}
draw_modes[constants.FILL]            = kCGPathFill
draw_modes[constants.EOF_FILL]        = kCGPathEOFill
draw_modes[constants.STROKE]          = kCGPathStroke
draw_modes[constants.FILL_STROKE]     = kCGPathFillStroke
draw_modes[constants.EOF_FILL_STROKE] = kCGPathEOFillStroke

text_modes = {}
text_modes[constants.TEXT_FILL]             = kCGTextFill
text_modes[constants.TEXT_STROKE]           = kCGTextStroke
text_modes[constants.TEXT_FILL_STROKE]      = kCGTextFillStroke
text_modes[constants.TEXT_INVISIBLE]        = kCGTextInvisible
text_modes[constants.TEXT_FILL_CLIP]        = kCGTextFillClip
text_modes[constants.TEXT_STROKE_CLIP]      = kCGTextStrokeClip
text_modes[constants.TEXT_FILL_STROKE_CLIP] = kCGTextFillStrokeClip
text_modes[constants.TEXT_CLIP]             = kCGTextClip
# this last one doesn't exist in Quartz
text_modes[constants.TEXT_OUTLINE]          = kCGTextStroke

cdef class CGContext
cdef class CGContextInABox(CGContext)
cdef class CGImage
cdef class CGPDFDocument
cdef class Rect
cdef class CGLayerContext(CGContextInABox)
cdef class CGGLContext(CGContextInABox)
cdef class CGBitmapContext(CGContext)
cdef class CGPDFContext(CGContext)
cdef class CGImageMask(CGImage)
cdef class CGAffine
cdef class CGMutablePath
cdef class Shading

cdef class CGContext:
    cdef CGContextRef context
    cdef long can_release
    cdef object current_font
    cdef ATSUStyle current_style
    cdef CGAffineTransform text_matrix
    cdef object style_cache

    def __new__(self, *args, **kwds):
        self.context = NULL
        self.current_style = NULL
        self.can_release = 0
        self.text_matrix = CGAffineTransformMake(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)

    def __init__(self, long context, long can_release=0):
        self.context = <CGContextRef>context

        self.can_release = can_release

        self._setup_color_space()
        self._setup_fonts()

    def _setup_color_space(self):
        # setup an RGB color space
        cdef CGColorSpaceRef space

        space = CGColorSpaceCreateDeviceRGB()
        CGContextSetFillColorSpace(self.context, space)
        CGContextSetStrokeColorSpace(self.context, space)
        CGColorSpaceRelease(space)

    def _setup_fonts(self):
        self.style_cache = {}
        self.select_font("Times New Roman", 12)
        CGContextSetShouldSmoothFonts(self.context, 1)
        CGContextSetShouldAntialias(self.context, 1)

    #----------------------------------------------------------------
    # Coordinate Transform Matrix Manipulation
    #----------------------------------------------------------------

    def scale_ctm(self, float sx, float sy):
        """ Set the coordinate system scale to the given values, (sx,sy).

            sx:float -- The new scale factor for the x axis
            sy:float -- The new scale factor for the y axis
        """
        CGContextScaleCTM(self.context, sx, sy)

    def translate_ctm(self, float tx, float ty):
        """ Translate the coordinate system by the given value by (tx,ty)

            tx:float --  The distance to move in the x direction
            ty:float --   The distance to move in the y direction
        """
        CGContextTranslateCTM(self.context, tx, ty)

    def rotate_ctm(self, float angle):
        """ Rotates the coordinate space for drawing by the given angle.

            angle:float -- the angle, in radians, to rotate the coordinate
                           system
        """
        CGContextRotateCTM(self.context, angle)

    def concat_ctm(self, object transform):
        """ Concatenate the transform to current coordinate transform matrix.

            transform:affine_matrix -- the transform matrix to concatenate with
                                       the current coordinate matrix.
        """
        cdef float a,b,c,d,tx,ty
        ((a, b, _),
         (c, d, _),
         (tx, ty, _)) = transform

        cdef CGAffineTransform atransform
        atransform = CGAffineTransformMake(a,b,c,d,tx,ty)

        CGContextConcatCTM(self.context, atransform)

    def get_ctm(self):
        """ Return the current coordinate transform matrix.
        """
        cdef CGAffineTransform t
        t = CGContextGetCTM(self.context)
        return ((t.a, t.b, 0.0),
                (t.c, t.d, 0.0),
                (t.tx,t.ty,1.0))

    def get_ctm_scale(self):
        """ Returns the average scaling factor of the transform matrix.

        This isn't really part of the GC interface, but it is a convenience
        method to make up for us not having full AffineMatrix support in the
        Mac backend.
        """
        cdef CGAffineTransform t
        t = CGContextGetCTM(self.context)
        x = sqrt(2.0) / 2.0 * (t.a + t.b)
        y = sqrt(2.0) / 2.0 * (t.c + t.d)
        return sqrt(x*x + y*y)
    
        

    #----------------------------------------------------------------
    # Save/Restore graphics state.
    #----------------------------------------------------------------

    def save_state(self):
        """ Save the current graphic's context state.

            This should always be paired with a restore_state
        """
        CGContextSaveGState(self.context)

    def restore_state(self):
        """ Restore the previous graphics state.
        """
        CGContextRestoreGState(self.context)

    #----------------------------------------------------------------
    # Manipulate graphics state attributes.
    #----------------------------------------------------------------

    def set_antialias(self, bool value):
        """ Set/Unset antialiasing for bitmap graphics context.
        """
        CGContextSetShouldAntialias(self.context, value)

    def set_line_width(self, float width):
        """ Set the line width for drawing

            width:float -- The new width for lines in user space units.
        """
        CGContextSetLineWidth(self.context, width)

    def set_line_join(self, object style):
        """ Set style for joining lines in a drawing.

            style:join_style -- The line joining style.  The available
                                styles are JOIN_ROUND, JOIN_BEVEL, JOIN_MITER.
        """
        try:
            sjoin = join_style[style]
        except KeyError:
            msg = "Invalid line join style.  See documentation for valid styles"
            raise ValueError(msg)
        CGContextSetLineJoin(self.context, sjoin)

    def set_miter_limit(self, float limit):
        """ Specifies limits on line lengths for mitering line joins.

            If line_join is set to miter joins, the limit specifies which
            line joins should actually be mitered.  If lines aren't mitered,
            they are joined with a bevel.  The line width is divided by
            the length of the miter.  If the result is greater than the
            limit, the bevel style is used.

            limit:float -- limit for mitering joins.
        """
        CGContextSetMiterLimit(self.context, limit)

    def set_line_cap(self, object style):
        """ Specify the style of endings to put on line ends.

            style:cap_style -- the line cap style to use. Available styles
                               are CAP_ROUND,CAP_BUTT,CAP_SQUARE
        """
        try:
            scap = cap_style[style]
        except KeyError:
            msg = "Invalid line cap style.  See documentation for valid styles"
            raise ValueError(msg)
        CGContextSetLineCap(self.context, scap)

    def set_line_dash(self, object lengths, float phase=0.0):
        """
            lengths:float array -- An array of floating point values
                                   specifing the lengths of on/off painting
                                   pattern for lines.
            phase:float -- Specifies how many units into dash pattern
                           to start.  phase defaults to 0.
        """
        cdef int n
        cdef int i
        cdef float *flengths

        if lengths is None:
            # No dash; solid line.
            CGContextSetLineDash(self.context, 0.0, NULL, 0)
            return
        else:
            n = len(lengths)
            flengths = <float*>PyMem_Malloc(n*sizeof(float))
            if flengths == NULL:
                raise MemoryError("could not allocate %s floats" % n)
            for i from 0 <= i < n:
                flengths[i] = lengths[i]
            CGContextSetLineDash(self.context, phase, flengths, n)
            PyMem_Free(flengths)

    def set_flatness(self, float flatness):
        """
            It is device dependent and therefore not recommended by
            the PDF documentation.
        """
        CGContextSetFlatness(self.context, flatness)

    #----------------------------------------------------------------
    # Sending drawing data to a device
    #----------------------------------------------------------------

    def flush(self):
        """ Send all drawing data to the destination device.
        """
        CGContextFlush(self.context)

    def synchronize(self):
        """ Prepares drawing data to be updated on a destination device.
        """
        CGContextSynchronize(self.context)

    #----------------------------------------------------------------
    # Page Definitions
    #----------------------------------------------------------------

    def begin_page(self, media_box=None):
        """ Create a new page within the graphics context.
        """
        cdef CGRect mbox
        cdef CGRect* mbox_ptr
        if media_box is not None:
            mbox = CGRectMakeFromPython(media_box)
            mbox_ptr = &mbox
        else:
            mbox_ptr = NULL

        CGContextBeginPage(self.context, mbox_ptr)

    def end_page(self):
        """ End drawing in the current page of the graphics context.
        """
        CGContextEndPage(self.context)

    #----------------------------------------------------------------
    # Building paths (contours that are drawn)
    #
    # + Currently, nothing is drawn as the path is built.  Instead, the
    #   instructions are stored and later drawn.  Should this be changed?
    #   We will likely draw to a buffer instead of directly to the canvas
    #   anyway.
    #
    #   Hmmm. No.  We have to keep the path around for storing as a
    #   clipping region and things like that.
    #
    # + I think we should keep the current_path_point hanging around.
    #
    #----------------------------------------------------------------

    def begin_path(self):
        """ Clear the current drawing path and begin a new one.
        """
        CGContextBeginPath(self.context)

    def move_to(self, float x, float y):
        """ Start a new drawing subpath at place the current point at (x,y).
        """
        CGContextMoveToPoint(self.context, x,y)

    def line_to(self, float x, float y):
        """ Add a line from the current point to the given point (x,y).

            The current point is moved to (x,y).
        """
        CGContextAddLineToPoint(self.context, x,y)

    def lines(self, object points):
        """ Add a series of lines as a new subpath.

            Points is an Nx2 array of x,y pairs.

            current_point is moved to the last point in points
        """
        cdef int n
        n = len(points)
        cdef int i

        if n > 0:
            CGContextMoveToPoint(self.context, points[0][0], points[0][1])

            for i from 1 <= i < n:
                CGContextAddLineToPoint(self.context, points[i][0], points[i][1])

    def line_set(self, object starts, object ends):
        """ Adds a series of disconnected line segments as a new subpath.

            starts and ends are Nx2 arrays of (x,y) pairs indicating the
            starting and ending points of each line segment.

            current_point is moved to the last point in ends
        """
        cdef int n
        n = len(starts)
        if len(ends) < n:
            n = len(ends)

        cdef int i
        for i from 0 <= i < n:
            CGContextMoveToPoint(self.context, starts[i][0], starts[i][1])
            CGContextAddLineToPoint(self.context, ends[i][0], ends[i][1])

    def rect(self, float x, float y, float sx, float sy):
        """ Add a rectangle as a new subpath.
        """
        CGContextAddRect(self.context, CGRectMake(x,y,sx,sy))

    def rects(self, object rects):
        """ Add multiple rectangles as separate subpaths to the path.
        """
        cdef int n
        n = len(rects)
        cdef int i
        for i from 0 <= i < n:
            CGContextAddRect(self.context, CGRectMakeFromPython(rects[i]))

    def close_path(self):
        """ Close the path of the current subpath.
        """
        CGContextClosePath(self.context)

    def curve_to(self, float cp1x, float cp1y, float cp2x, float cp2y,
        float x, float y):
        """
        """
        CGContextAddCurveToPoint(self.context, cp1x, cp1y, cp2x, cp2y, x, y )

    def quad_curve_to(self, float cpx, float cpy, float x, float y):
        """
        """
        CGContextAddQuadCurveToPoint(self.context, cpx, cpy, x, y)

    def arc(self, float x, float y, float radius, float start_angle,
        float end_angle, bool clockwise=False):
        """
        """
        CGContextAddArc(self.context, x, y, radius, start_angle, end_angle,
                           clockwise)

    def arc_to(self, float x1, float y1, float x2, float y2, float radius):
        """
        """
        CGContextAddArcToPoint(self.context, x1, y1, x2, y2, radius)

    def add_path(self, CGMutablePath path not None):
        """
        """
        CGContextAddPath(self.context, path.path)

    #----------------------------------------------------------------
    # Getting information on paths
    #----------------------------------------------------------------

    def is_path_empty(self):
        """ Test to see if the current drawing path is empty
        """
        return CGContextIsPathEmpty(self.context)

    def get_path_current_point(self):
        """ Return the current point from the graphics context.

            Note: This should be a tuple or array.

        """
        cdef CGPoint result
        result = CGContextGetPathCurrentPoint(self.context)
        return result.x, result.y

    def get_path_bounding_box(self):
        """
            should return a tuple or array instead of a strange object.
        """
        cdef CGRect result
        result = CGContextGetPathBoundingBox(self.context)
        return (result.origin.x, result.origin.y,
                result.size.width, result.size.height)

    #----------------------------------------------------------------
    # Clipping path manipulation
    #----------------------------------------------------------------

    def clip(self):
        """
        """
        CGContextClip(self.context)

    def even_odd_clip(self):
        """
        """
        CGContextEOClip(self.context)

    def clip_to_rect(self, float x, float y, float width, float height):
        """ Clip context to the given rectangular region.
        """
        CGContextClipToRect(self.context, CGRectMake(x,y,width,height))

    def clip_to_rects(self, object rects):
        """
        """
        cdef int n
        n = len(rects)
        cdef int i
        cdef CGRect* cgrects

        cgrects = <CGRect*>PyMem_Malloc(n*sizeof(CGRect))
        if cgrects == NULL:
            raise MemoryError("could not allocate memory for CGRects")

        for i from 0 <= i < n:
            cgrects[i] = CGRectMakeFromPython(rects[i])
        CGContextClipToRects(self.context, cgrects, n)
        PyMem_Free(cgrects)


    #----------------------------------------------------------------
    # Color space manipulation
    #
    # I'm not sure we'll mess with these at all.  They seem to
    # be for setting the color system.  Hard coding to RGB or
    # RGBA for now sounds like a reasonable solution.
    #----------------------------------------------------------------

    def set_fill_color_space(self):
        """
        """
        msg = "set_fill_color_space not implemented on Macintosh yet."
        raise NotImplementedError(msg)

    def set_stroke_color_space(self):
        """
        """
        msg = "set_stroke_color_space not implemented on Macintosh yet."
        raise NotImplementedError(msg)

    def set_rendering_intent(self, intent):
        """
        """
        CGContextSetRenderingIntent(self.context, intent)

    #----------------------------------------------------------------
    # Color manipulation
    #----------------------------------------------------------------

    def set_fill_color(self, object color):
        """
        """
        r,g,b = color[:3]
        try:
            a = color[3]
        except IndexError:
            a = 1.0
        CGContextSetRGBFillColor(self.context, r, g, b, a)

    def set_stroke_color(self, object color):
        """
        """
        r,g,b = color[:3]
        try:
            a = color[3]
        except IndexError:
            a = 1.0
        CGContextSetRGBStrokeColor(self.context, r, g, b, a)

    def set_alpha(self, float alpha):
        """
        """
        CGContextSetAlpha(self.context, alpha)

    #def set_gray_fill_color(self):
    #    """
    #    """
    #    pass

    #def set_gray_stroke_color(self):
    #    """
    #    """
    #    pass

    #def set_rgb_fill_color(self):
    #    """
    #    """
    #    pass

    #def set_rgb_stroke_color(self):
    #    """
    #    """
    #    pass

    #def cmyk_fill_color(self):
    #    """
    #    """
    #    pass

    #def cmyk_stroke_color(self):
    #    """
    #    """
    #    pass

    #----------------------------------------------------------------
    # Drawing Images
    #----------------------------------------------------------------

    def draw_image(self, object image, object rect=None):
        """ Draw an image or another CGContext onto a region.
        """
        if rect is None:
            rect = (0, 0, self.width(), self.height())
        if isinstance(image, numpy.ndarray):
            self._draw_cgimage(CGImage(image), rect)
        elif isinstance(image, CGImage):
            self._draw_cgimage(image, rect)
        elif hasattr(image, 'bmp_array'):
            self._draw_cgimage(CGImage(image.bmp_array), rect)
        elif isinstance(image, CGLayerContext):
            self._draw_cglayer(image, rect)
        else:
            raise TypeError("could not recognize image %r" % type(image))

    def _draw_cgimage(self, CGImage image, object rect):
        """ Draw a CGImage into a region.
        """
        CGContextDrawImage(self.context, CGRectMakeFromPython(rect),
            image.image)

    def _draw_cglayer(self, CGLayerContext layer, object rect):
        """ Draw a CGLayer into a region.
        """
        CGContextDrawLayerInRect(self.context, CGRectMakeFromPython(rect),
            layer.layer)

    def set_interpolation_quality(self, quality):
        CGContextSetInterpolationQuality(self.context, quality)

    #----------------------------------------------------------------
    # Drawing PDF documents
    #----------------------------------------------------------------

    def draw_pdf_document(self, object rect, CGPDFDocument document not None,
        int page=1):
        """
            rect:(x,y,width,height) -- rectangle to draw into
            document:CGPDFDocument -- PDF file to read from
            page=1:int -- page number of PDF file
        """
        cdef CGRect cgrect
        cgrect = CGRectMakeFromPython(rect)

        CGContextDrawPDFDocument(self.context, cgrect, document.document, page)


    #----------------------------------------------------------------
    # Drawing Text
    #----------------------------------------------------------------

    def select_font(self, object name, float size, style='regular'):
        """
        """
        cdef ATSUStyle atsu_style

        key = (name, size, style)
        if key not in self.style_cache:
            font = default_font_info.lookup(name, style=style)
            self.current_font = font
            ps_name = font.postscript_name

            atsu_style = _create_atsu_style(ps_name, size)
            if atsu_style == NULL:
                raise RuntimeError("could not create style for font %r" % ps_name)
            self.style_cache[key] = PyCObject_FromVoidPtr(<void*>atsu_style,
                <cobject_destr>ATSUDisposeStyle)

        atsu_style = <ATSUStyle>PyCObject_AsVoidPtr(self.style_cache[key])
        self.current_style = atsu_style

    def set_font(self, font):
        """ Set the font for the current graphics context.

            I need to figure out this one.
        """

        style = {
            constants.NORMAL: 'regular',
            constants.BOLD: 'bold',
            constants.ITALIC: 'italic',
            constants.BOLD_ITALIC: 'bold italic',
        }[font.weight | font.style]
        self.select_font(font.face_name, font.size, style=style)

    def set_font_size(self, float size):
        """
        """
        cdef ATSUAttributeTag attr_tag
        cdef ByteCount attr_size
        cdef ATSUAttributeValuePtr attr_value
        cdef Fixed fixed_size
        cdef OSStatus err

        if self.current_style == NULL:
            return

        attr_tag = kATSUSizeTag
        attr_size = sizeof(Fixed)
        fixed_size = FloatToFixed(size)
        attr_value = <ATSUAttributeValuePtr>&fixed_size
        err = ATSUSetAttributes(self.current_style, 1, &attr_tag, &attr_size, &attr_value)
        if err:
            raise RuntimeError("could not set font size on current style")

    def set_character_spacing(self, float spacing):
        """
        """

        # XXX: This does not fit in with ATSUI, really.
        CGContextSetCharacterSpacing(self.context, spacing)

    def set_text_drawing_mode(self, object mode):
        """
        """
        try:
            cgmode = text_mode[mode]
        except KeyError:
            msg = "Invalid text drawing mode.  See documentation for valid modes"
            raise ValueError(msg)
        CGContextSetTextDrawingMode(self.context, cgmode)

    def set_text_position(self, float x,float y):
        """
        """
        self.text_matrix.tx = x
        self.text_matrix.ty = y

    def get_text_position(self):
        """
        """
        return self.text_matrix.tx, self.text_matrix.ty

    def set_text_matrix(self, object ttm):
        """
        """
        cdef float a,b,c,d,tx,ty
        ((a,  b,  _),
         (c,  d,  _),
         (tx, ty, _)) = ttm

        cdef CGAffineTransform transform
        transform = CGAffineTransformMake(a,b,c,d,tx,ty)
        self.text_matrix = transform

    def get_text_matrix(self):
        """
        """
        return ((self.text_matrix.a, self.text_matrix.b, 0.0),
                (self.text_matrix.c, self.text_matrix.d, 0.0),
                (self.text_matrix.tx,self.text_matrix.ty,1.0))

    def get_text_extent(self, object text):
        """ Measure the space taken up by given text using the current font.
        """
        cdef CGPoint start
        cdef CGPoint stop
        cdef ATSFontMetrics metrics
        cdef OSStatus status
        cdef ATSUTextLayout layout
        cdef double x1, x2, y1, y2
        cdef ATSUTextMeasurement before, after, ascent, descent
        cdef ByteCount actual_size

        layout = NULL
        try:
            if not text:
                # ATSUGetUnjustifiedBounds does not handle empty strings.
                text = " "
                empty = True
            else:
                empty = False
            _create_atsu_layout(text, self.current_style, &layout)
            status = ATSUGetUnjustifiedBounds(layout, 0, len(text), &before,
                &after, &ascent, &descent)
            if status:
                raise RuntimeError("could not calculate font metrics")

            if empty:
                x1 = 0.0
                x2 = 0.0
            else:
                x1 = FixedToFloat(before)
                x2 = FixedToFloat(after)

            y1 = -FixedToFloat(descent)
            y2 = -y1 + FixedToFloat(ascent)

        finally:
            if layout != NULL:
                ATSUDisposeTextLayout(layout)

        return x1, y1, x2, y2

    def get_full_text_extent(self, object text):
        """ Backwards compatibility API over .get_text_extent() for Enable.
        """

        x1, y1, x2, y2 = self.get_text_extent(text)

        return x2, y2, y1, x1


    def show_text(self, object text, object xy=None):
        """ Draw text on the device at current text position.

            This is also used for showing text at a particular point
            specified by xy == (x, y).
        """
        cdef float x
        cdef float y
        cdef CGAffineTransform text_matrix
        cdef ATSUTextLayout layout

        if not text:
            # I don't think we can draw empty strings using the ATSU API.
            return

        if xy is None:
            x = 0.0
            y = 0.0
        else:
            x = xy[0]
            y = xy[1]

        self.save_state()
        try:
            CGContextConcatCTM(self.context, self.text_matrix)
            _create_atsu_layout(text, self.current_style, &layout)
            _set_cgcontext_for_layout(self.context, layout)
            ATSUDrawText(layout, 0, len(text), FloatToFixed(x), FloatToFixed(y))
        finally:
            self.restore_state()
            if layout != NULL:
                ATSUDisposeTextLayout(layout)

    def show_text_at_point(self, object text, float x, float y):
        """ Draw text on the device at a given text position.
        """
        self.show_text(text, (x, y))

    def show_glyphs(self):
        """
        """
        msg = "show_glyphs not implemented on Macintosh yet."
        raise NotImplementedError(msg)

    #----------------------------------------------------------------
    # Painting paths (drawing and filling contours)
    #----------------------------------------------------------------

    def stroke_path(self):
        """
        """
        CGContextStrokePath(self.context)

    def fill_path(self):
        """
        """
        CGContextFillPath(self.context)

    def eof_fill_path(self):
        """
        """
        CGContextEOFillPath(self.context)

    def stroke_rect(self, object rect):
        """
        """
        CGContextStrokeRect(self.context, CGRectMakeFromPython(rect))

    def stroke_rect_with_width(self, object rect, float width):
        """
        """
        CGContextStrokeRectWithWidth(self.context, CGRectMakeFromPython(rect), width)

    def fill_rect(self, object rect):
        """
        """
        CGContextFillRect(self.context, CGRectMakeFromPython(rect))

    def fill_rects(self, object rects):
        """
        """
        cdef int n
        n = len(rects)
        cdef int i
        cdef CGRect* cgrects

        cgrects = <CGRect*>PyMem_Malloc(n*sizeof(CGRect))
        if cgrects == NULL:
            raise MemoryError("could not allocate memory for CGRects")

        for i from 0 <= i < n:
            cgrects[i] = CGRectMakeFromPython(rects[i])

        CGContextFillRects(self.context, cgrects, n)

    def clear_rect(self, object rect):
        """
        """
        CGContextClearRect(self.context, CGRectMakeFromPython(rect))

    def draw_path(self, object mode=constants.FILL_STROKE):
        """ Walk through all the drawing subpaths and draw each element.

            Each subpath is drawn separately.
        """

        cg_mode = draw_modes[mode]
        CGContextDrawPath(self.context, cg_mode)

    def draw_rect(self, rect, object mode=constants.FILL_STROKE):
        """ Draw a rectangle with the given mode.
        """

        self.save_state()
        CGContextBeginPath(self.context)
        CGContextAddRect(self.context, CGRectMakeFromPython(rect))
        cg_mode = draw_modes[mode]
        CGContextDrawPath(self.context, cg_mode)
        self.restore_state()

    def get_empty_path(self):
        """ Return a path object that can be built up and then reused.
        """

        return CGMutablePath()

    def draw_path_at_points(self, points, CGMutablePath marker not None,
        object mode=constants.FILL_STROKE):

        cdef int i
        cdef int n
        cdef c_numpy.ndarray apoints
        cdef float x, y

        apoints = <c_numpy.ndarray>(numpy.asarray(points, dtype=numpy.float32))

        if apoints.nd != 2 or apoints.dimensions[1] != 2:
            msg = "must pass array of 2-D points"
            raise ValueError(msg)

        cg_mode = draw_modes[mode]

        n = len(points)
        for i from 0 <= i < n:
            x = (<float*>c_numpy.PyArray_GETPTR2(apoints, i, 0))[0]
            y = (<float*>c_numpy.PyArray_GETPTR2(apoints, i, 1))[0]
            CGContextSaveGState(self.context)
            CGContextTranslateCTM(self.context, x, y)
            CGContextAddPath(self.context, marker.path)
            CGContextDrawPath(self.context, cg_mode)
            CGContextRestoreGState(self.context)

    def draw_shading(self, Shading shading not None):
        CGContextDrawShading(self.context, shading.shading)


    #----------------------------------------------------------------
    # Extra routines that aren't part of DisplayPDF
    #
    # Some access to font metrics are needed for laying out text.
    # Not sure how to handle this yet.  The candidates below are
    # from Piddle.  Perhaps there is another alternative?
    #
    #----------------------------------------------------------------

    #def font_height(self):
    #    '''Find the total height (ascent + descent) of the given font.'''
    #    #return self.font_ascent() + self.font_descent()

    #def font_ascent(self):
    #    '''Find the ascent (height above base) of the given font.'''
    #    pass

    #def font_descent(self):
    #    '''Find the descent (extent below base) of the given font.'''
    #    extents = self.dc.GetFullTextExtent(' ', wx_font)
    #    return extents[2]

    def __dealloc__(self):
        if self.context != NULL and self.can_release:
            CGContextRelease(self.context)
            self.context = NULL

    # The following are Quartz APIs not in Kiva

    def set_pattern_phase(self, float tx, float ty):
        """
            tx,ty:floats -- A translation in user-space to apply to a
                           pattern before it is drawn
        """
        CGContextSetPatternPhase(self.context, CGSizeMake(tx, ty))

    def set_should_smooth_fonts(self, bool value):
        """
            value:bool -- specify whether to enable font smoothing or not
        """
        CGContextSetShouldSmoothFonts(self.context, value)

cdef class CGContextInABox(CGContext):
    """ A CGContext that knows its size.
    """
    cdef readonly object size
    cdef readonly int _width
    cdef readonly int _height

    def __init__(self, long context, object size, long can_release=0):
        self.context = <CGContextRef>context

        self.can_release = can_release

        self._width, self._height = size

        self._setup_color_space()
        self._setup_fonts()

    def clear(self, object clear_color=(1.0,1.0,1.0,1.0)):
        self.save_state()
        # Reset the transformation matrix back to the identity.
        CGContextConcatCTM(self.context, 
            CGAffineTransformInvert(CGContextGetCTM(self.context)))
        self.set_fill_color(clear_color)
        CGContextFillRect(self.context, CGRectMake(0,0,self._width,self._height))
        self.restore_state()

    def width(self):
        return self._width

    def height(self):
        return self._height


cdef class CGLayerContext(CGContextInABox):
    cdef CGLayerRef layer
    cdef object gc

    def __init__(self, CGContext gc not None, object size):
        self.gc = <object>gc
        self.layer = CGLayerCreateWithContext(gc.context,
            CGSizeMake(size[0], size[1]), NULL)
        self.context = CGLayerGetContext(self.layer)
        self.size = size
        self._width, self._height = size
        self.can_release = 1

        self._setup_color_space()
        self._setup_fonts()

    def __dealloc__(self):
        if self.layer != NULL:
            CGLayerRelease(self.layer)
            self.layer = NULL
            # The documentation doesn't say whether I need to release the
            # context derived from the layer or not. I believe that means
            # I don't.
            self.context = NULL
        self.gc = None

    def save(self, object filename, file_format=None, pil_options=None):
        """ Save the GraphicsContext to a file.  Output files are always saved
        in RGB or RGBA format; if this GC is not in one of these formats, it is
        automatically converted.

        If filename includes an extension, the image format is inferred from it.
        file_format is only required if the format can't be inferred from the
        filename (e.g. if you wanted to save a PNG file as a .dat or .bin).

        filename may also be "file-like" object such as a StringIO, in which
        case a file_format must be supplied

        pil_options is a dict of format-specific options that are passed down to
        the PIL image file writer.  If a writer doesn't recognize an option, it
        is silently ignored.

        If the image has an alpha channel and the specified output file format
        does not support alpha, the image is saved in rgb24 format.
        """

        cdef CGBitmapContext bmp

        # Create a CGBitmapContext from this layer, draw to it, then let it save
        # itself out.
        rect = (0, 0) + self.size
        bmp = CGBitmapContext(self.size)
        CGContextDrawLayerInRect(bmp.context,  CGRectMakeFromPython(rect), self.layer)
        bmp.save(filename, file_format=file_format, pil_options=pil_options)


cdef class CGContextFromSWIG(CGContext):
    def __init__(self, swig_obj):
        self.can_release = False
        ptr = int(swig_obj.this.split('_')[1], 16)
        CGContext.__init__(self, ptr)

cdef class CGContextForPort(CGContextInABox):
    cdef readonly long port
    cdef readonly int _begun

    def __init__(self, long port):
        cdef OSStatus status

#        status = QDBeginCGContext(<CGrafPtr>port, &(self.context))
#        if status:
#            self.port = 0
#            raise RuntimeError("QuickDraw could not make CGContext")

        self.context = NULL
        self.can_release = 0
        self._begun = 0

        self.port = port

        cdef QDRect r
        GetPortBounds(<CGrafPtr>port, &r)

        self._width = r.right - r.left
        self._height = r.bottom - r.top
        self.size = (self._width, self._height)

        #self.begin()

    def begin(self):
        cdef OSStatus status
        cdef QDRect port_rect
        if not self._begun:
            status = QDBeginCGContext(<CGrafPtr>self.port, &(self.context))
            if status != noErr:
                raise RuntimeError("QuickDraw could not make CGContext")
            SyncCGContextOriginWithPort(self.context, <CGrafPtr>self.port)
            self._setup_color_space()
            self._setup_fonts()

            #GetPortBounds(<CGrafPtr>self.port, &port_rect)
            #CGContextTranslateCTM(self.context, 0, (port_rect.bottom - port_rect.top))
            #CGContextScaleCTM(self.context, 1.0, -1.0)
            self._begun = 1

    def end(self):
        if self.port and self.context and self._begun:
            CGContextFlush(self.context)
            QDEndCGContext(<CGrafPtr>(self.port), &(self.context))
            self._begun = 0

    def clear(self, object clear_color=(1.0,1.0,1.0,1.0)):
        already_begun = self._begun
        self.begin()
        CGContextInABox.clear(self, clear_color)
        if not already_begun:
            self.end()

    def __dealloc__(self):
        self.end()
        #if self.port and self.context and self._begun:
        #    QDEndCGContext(<CGrafPtr>(self.port), &(self.context))
        #if self.context and self.can_release:
        #    CGContextRelease(self.context)
        #    self.context = NULL



cdef class CGGLContext(CGContextInABox):
    cdef readonly long glcontext

    def __init__(self, long glcontext, int width, int height):
        if glcontext == 0:
            raise ValueError("Need a valid pointer")

        self.glcontext = glcontext

        self.context = CGGLContextCreate(<void*>glcontext,
            CGSizeMake(width, height), NULL)
        if self.context == NULL:
            raise RuntimeError("could not create CGGLContext")
        self.can_release = 1

        self._width = width
        self._height = height
        self.size = (self._width, self._height)

        self._setup_color_space()
        self._setup_fonts()


    def resize(self, int width, int height):
        CGGLContextUpdateViewportSize(self.context, CGSizeMake(width, height))
        self._width = width
        self._height = height
        self.size = (width, height)



cdef class CGPDFContext(CGContext):
    cdef readonly char* filename
    cdef CGRect media_box
    def __init__(self, char* filename, rect=None):
        cdef CFURLRef cfurl
        cfurl = url_from_filename(filename)
        cdef CGRect cgrect
        cdef CGRect* cgrect_ptr

        if rect is None:
            cgrect = CGRectMake(0,0,612,792)
            cgrect_ptr = &cgrect
        else:
            cgrect = CGRectMakeFromPython(rect)
            cgrect_ptr = &cgrect
        self.context = CGPDFContextCreateWithURL(cfurl, cgrect_ptr, NULL)
        CFRelease(cfurl)

        self.filename = filename
        self.media_box = cgrect

        if self.context == NULL:
            raise RuntimeError("could not create CGPDFContext")
        self.can_release = 1

        self._setup_color_space()
        self._setup_fonts()

        CGContextBeginPage(self.context, cgrect_ptr)

    def begin_page(self, media_box=None):
        cdef CGRect* box_ptr
        cdef CGRect box
        if media_box is None:
            box_ptr = &(self.media_box)
        else:
            box = CGRectMakeFromPython(media_box)
            box_ptr = &box
        CGContextBeginPage(self.context, box_ptr)

    def flush(self, end_page=True):
        if end_page:
            self.end_page()
        CGContextFlush(self.context)

    def begin_transparency_layer(self):
        CGContextBeginTransparencyLayer(self.context, NULL)

    def end_transparency_layer(self):
        CGContextEndTransparencyLayer(self.context)

cdef class CGBitmapContext(CGContext):
    cdef void* data

    def __new__(self, *args, **kwds):
        self.data = NULL

    def __init__(self, object size_or_array, bool grey_scale=0,
        int bits_per_component=8, int bytes_per_row=-1,
        alpha_info=kCGImageAlphaPremultipliedLast):

        cdef int bits_per_pixel
        cdef CGColorSpaceRef colorspace
        cdef void* dataptr

        if hasattr(size_or_array, '__array_interface__'):
            # It's an array.
            arr = numpy.asarray(size_or_array, order='C')
            typestr = arr.dtype.str
            if typestr != '|u1':
                raise ValueError("expecting an array of unsigned bytes; got %r"
                    % typestr)
            shape = arr.shape
            if len(shape) != 3 or shape[-1] not in (3, 4):
                raise ValueError("expecting a shape (width, height, depth) "
                    "with depth either 3 or 4; got %r" % shape)
            height, width, depth = shape
            if depth == 3:
                # Need to add an alpha channel.
                alpha = numpy.empty((height, width), dtype=numpy.uint8)
                alpha.fill(255)
                arr = numpy.dstack([arr, alpha])
                depth = 4
            ptr, readonly = arr.__array_interface__['data']
            dataptr = <void*><long>ptr
        else:
            # It's a size tuple.
            width, height = size_or_array
            arr = None

        if grey_scale:
            alpha_info = kCGImageAlphaNone
            bits_per_component = 8
            bits_per_pixel = 8
            colorspace = CGColorSpaceCreateDeviceGray()
        elif bits_per_component == 5:
            alpha_info = kCGImageAlphaNoneSkipFirst
            bits_per_pixel = 16
            colorspace = CGColorSpaceCreateDeviceRGB()
        elif bits_per_component == 8:
            if alpha_info not in (kCGImageAlphaNoneSkipFirst,
                                  kCGImageAlphaNoneSkipLast,
                                  kCGImageAlphaPremultipliedFirst,
                                  kCGImageAlphaPremultipliedLast):
                raise ValueError("not a valid alpha_info")
            bits_per_pixel = 32
            colorspace = CGColorSpaceCreateDeviceRGB()
        else:
            raise ValueError("bits_per_component must be 5 or 8")

        cdef int min_bytes
        min_bytes = (width*bits_per_pixel + 7) / 8
        if bytes_per_row < min_bytes:
            bytes_per_row = min_bytes

        self.data = PyMem_Malloc(height*bytes_per_row)
        if self.data == NULL:
            CGColorSpaceRelease(colorspace)
            raise MemoryError("could not allocate memory")
        if arr is not None:
            # Copy the data from the array.
            memcpy(self.data, dataptr, width*height*depth)

        self.context = CGBitmapContextCreate(self.data, width, height,
            bits_per_component, bytes_per_row, colorspace, alpha_info)
        CGColorSpaceRelease(colorspace)

        if self.context == NULL:
            raise RuntimeError("could not create CGBitmapContext")
        self.can_release = 1

        self._setup_fonts()


    def __dealloc__(self):
        if self.context != NULL and self.can_release:
            CGContextRelease(self.context)
            self.context = NULL
        if self.data != NULL:
            # Hmm, this could be tricky if anything in Quartz retained a
            # reference to self.context
            PyMem_Free(self.data)
            self.data = NULL

    property alpha_info:
        def __get__(self):
            return CGBitmapContextGetAlphaInfo(self.context)

    property bits_per_component:
        def __get__(self):
            return CGBitmapContextGetBitsPerComponent(self.context)

    property bits_per_pixel:
        def __get__(self):
            return CGBitmapContextGetBitsPerPixel(self.context)

    property bytes_per_row:
        def __get__(self):
            return CGBitmapContextGetBytesPerRow(self.context)

#    property colorspace:
#        def __get__(self):
#            return CGBitmapContextGetColorSpace(self.context)

    def height(self):
        return CGBitmapContextGetHeight(self.context)

    def width(self):
        return CGBitmapContextGetWidth(self.context)

    def __getsegcount__(self, int* lenp):
        if lenp != NULL:
            lenp[0] = self.height()*self.bytes_per_row
        return 1

    def __getreadbuffer__(self, int segment, void** ptr):
        # ignore invalid segment; the caller can't mean anything but the only
        # segment available; we're all adults
        ptr[0] = self.data
        return self.height()*self.bytes_per_row

    def __getwritebuffer__(self, int segment, void** ptr):
        # ignore invalid segment; the caller can't mean anything but the only
        # segment available; we're all adults
        ptr[0] = self.data
        return self.height()*self.bytes_per_row

    def __getcharbuffer__(self, int segment, char** ptr):
        # ignore invalid segment; the caller can't mean anything but the only
        # segment available; we're all adults
        ptr[0] = <char*>(self.data)
        return self.height()*self.bytes_per_row

    def clear(self, object clear_color=(1.0, 1.0, 1.0, 1.0)):
        """Paint over the whole image with a solid color.
        """

        self.save_state()
        # Reset the transformation matrix back to the identity.
        CGContextConcatCTM(self.context, 
            CGAffineTransformInvert(CGContextGetCTM(self.context)))
        
        self.set_fill_color(clear_color)
        CGContextFillRect(self.context, CGRectMake(0, 0, self.width(), self.height()))
        self.restore_state()

    def save(self, object filename, file_format=None, pil_options=None):
        """ Save the GraphicsContext to a file.  Output files are always saved
        in RGB or RGBA format; if this GC is not in one of these formats, it is
        automatically converted.

        If filename includes an extension, the image format is inferred from it.
        file_format is only required if the format can't be inferred from the
        filename (e.g. if you wanted to save a PNG file as a .dat or .bin).

        filename may also be "file-like" object such as a StringIO, in which
        case a file_format must be supplied

        pil_options is a dict of format-specific options that are passed down to
        the PIL image file writer.  If a writer doesn't recognize an option, it
        is silently ignored.

        If the image has an alpha channel and the specified output file format
        does not support alpha, the image is saved in rgb24 format.
        """

        try:
            import Image
        except ImportError:
            raise ImportError("need PIL to save images")

        if self.bits_per_pixel == 32:
            if self.alpha_info == kCGImageAlphaPremultipliedLast:
                mode = 'RGBA'
            elif self.alpha_info == kCGImageAlphaPremultipliedFirst:
                mode = 'ARGB'
            else:
                raise ValueError("cannot save this pixel format")
        elif self.bits_per_pixel == 8:
            mode = 'L'
        else:
            raise ValueError("cannot save this pixel format")

        img = Image.fromstring(mode, (self.width(), self.height()), self)
        img.save(filename, format=file_format, options=pil_options)

cdef class CGImage:
    cdef CGImageRef image
    cdef void* data
    cdef readonly c_numpy.ndarray bmp_array

    def __new__(self, *args, **kwds):
        self.image = NULL

    property width:
        def __get__(self):
            return CGImageGetWidth(self.image)

    property height:
        def __get__(self):
            return CGImageGetHeight(self.image)

    property bits_per_component:
        def __get__(self):
            return CGImageGetBitsPerComponent(self.image)

    property bits_per_pixel:
        def __get__(self):
            return CGImageGetBitsPerPixel(self.image)

    property bytes_per_row:
        def __get__(self):
            return CGImageGetBytesPerRow(self.image)

    property alpha_info:
        def __get__(self):
            return CGImageGetAlphaInfo(self.image)

    property should_interpolate:
        def __get__(self):
            return CGImageGetShouldInterpolate(self.image)

    property is_mask:
        def __get__(self):
            return CGImageIsMask(self.image)

    def __init__(self, object size_or_array, bool grey_scale=0,
        int bits_per_component=8, int bytes_per_row=-1,
        alpha_info=kCGImageAlphaPremultipliedLast, int should_interpolate=1):

        cdef int bits_per_pixel
        cdef CGColorSpaceRef colorspace

        if hasattr(size_or_array, '__array_interface__'):
            # It's an array.
            arr = size_or_array
            typestr = arr.__array_interface__['typestr']
            if typestr != '|u1':
                raise ValueError("expecting an array of unsigned bytes; got %r"
                    % typestr)
            shape = arr.__array_interface__['shape']
            if grey_scale:
                if (len(shape) == 3 and shape[-1] != 1) or (len(shape) != 2):
                    raise ValueError("with grey_scale, expecting a shape "
                        "(height, width) or (height, width, 1); got %r" % shape)
                height, width = shape[:2]
                depth = 1
            else:
                if len(shape) != 3 or shape[-1] not in (3, 4):
                    raise ValueError("expecting a shape (height, width, depth) "
                        "with depth either 3 or 4; got %r" % shape)
                height, width, depth = shape
            if depth in (1, 3):
                alpha_info = kCGImageAlphaNone
            else:
                # Make a copy.
                arr = numpy.array(arr)
                alpha_info = kCGImageAlphaPremultipliedLast
        else:
            # It's a size tuple.
            width, height = size_or_array
            if grey_scale:
                lastdim = 1
                alpha_info = kCGImageAlphaNone
            else:
                lastdim = 4
                alpha_info = kCGImageAlphaPremultipliedLast
            arr = numpy.zeros((height, width, lastdim), dtype=numpy.uint8)

        self.bmp_array = <c_numpy.ndarray>arr
        Py_INCREF(self.bmp_array)
        self.data = <void*>c_numpy.PyArray_DATA(self.bmp_array)

        if grey_scale:
            alpha_info = kCGImageAlphaNone
            bits_per_component = 8
            bits_per_pixel = 8
            colorspace = CGColorSpaceCreateDeviceGray()
        elif bits_per_component == 5:
            alpha_info = kCGImageAlphaNoneSkipFirst
            bits_per_pixel = 16
            colorspace = CGColorSpaceCreateDeviceRGB()
        elif bits_per_component == 8:
            if alpha_info in (kCGImageAlphaNoneSkipFirst,
                              kCGImageAlphaNoneSkipLast,
                              kCGImageAlphaPremultipliedFirst,
                              kCGImageAlphaPremultipliedLast):
                bits_per_pixel = 32
            elif alpha_info == kCGImageAlphaNone:
                bits_per_pixel = 24
            colorspace = CGColorSpaceCreateDeviceRGB()
        else:
            raise ValueError("bits_per_component must be 5 or 8")

        cdef int min_bytes
        min_bytes = (width*bits_per_pixel + 7) / 8
        if bytes_per_row < min_bytes:
            bytes_per_row = min_bytes

        cdef CGDataProviderRef provider
        provider = CGDataProviderCreateWithData(
            NULL, self.data, c_numpy.PyArray_SIZE(self.bmp_array), NULL)
        if provider == NULL:
            raise RuntimeError("could not make provider")

        cdef CGColorSpaceRef space
        space = CGColorSpaceCreateDeviceRGB()

        self.image = CGImageCreate(width, height, bits_per_component,
            bits_per_pixel, bytes_per_row, space, alpha_info, provider, NULL,
            should_interpolate, kCGRenderingIntentDefault)
        CGColorSpaceRelease(space)
        CGDataProviderRelease(provider)

        if self.image == NULL:
            raise RuntimeError("could not make image")

    def __dealloc__(self):
        if self.image != NULL:
            CGImageRelease(self.image)
            self.image = NULL
        Py_XDECREF(self.bmp_array)

cdef class CGImageFile(CGImage):
    def __init__(self, object image_or_filename, int should_interpolate=1):
        cdef int width, height, bits_per_component, bits_per_pixel, bytes_per_row
        cdef CGImageAlphaInfo alpha_info

        import Image
        import types

        if type(image_or_filename) is str:
            img = Image.open(filename)
            img.load()
        elif isinstance(image_or_filename, Image.Image):
            img = image_or_filename
        else:
            raise ValueError("need a PIL Image or a filename")

        width, height = img.size
        mode = img.mode

        if mode not in ["L", "RGB","RGBA"]:
            img = img.convert(mode="RGBA")
            mode = 'RGBA'

        bits_per_component = 8

        if mode == 'RGB':
            bits_per_pixel = 24
            alpha_info = kCGImageAlphaNone
        elif mode == 'RGBA':
            bits_per_pixel = 32
            alpha_info = kCGImageAlphaPremultipliedLast
        elif mode == 'L':
            bits_per_pixel = 8
            alpha_info = kCGImageAlphaNone

        bytes_per_row = (bits_per_pixel*width + 7)/ 8

        cdef char* data
        cdef char* py_data
        cdef int dims[3]
        dims[0] = height
        dims[1] = width
        dims[2] = bits_per_pixel/bits_per_component

        self.bmp_array = c_numpy.PyArray_SimpleNew(3, &(dims[0]), NPY_UBYTE)

        data = self.bmp_array.data
        s = img.tostring()
        py_data = PyString_AsString(s)

        memcpy(<void*>data, <void*>py_data, len(s))

        self.data = data

        cdef CGDataProviderRef provider
        provider = CGDataProviderCreateWithData(
            NULL, <void*>data, len(data), NULL)

        if provider == NULL:
            raise RuntimeError("could not make provider")

        cdef CGColorSpaceRef space
        space = CGColorSpaceCreateDeviceRGB()

        self.image = CGImageCreate(width, height, bits_per_component,
            bits_per_pixel, bytes_per_row, space, alpha_info, provider, NULL,
            should_interpolate, kCGRenderingIntentDefault)
        CGColorSpaceRelease(space)
        CGDataProviderRelease(provider)

        if self.image == NULL:
            raise RuntimeError("could not make image")

    def __dealloc__(self):
        if self.image != NULL:
            CGImageRelease(self.image)
            self.image = NULL
        Py_XDECREF(self.bmp_array)

cdef class CGImageMask(CGImage):
    def __init__(self, char* data, int width, int height,
        int bits_per_component, int bits_per_pixel, int bytes_per_row,
        int should_interpolate=1):

        cdef CGDataProviderRef provider
        provider = CGDataProviderCreateWithData(
            NULL, <void*>data, len(data), NULL)

        if provider == NULL:
            raise RuntimeError("could not make provider")

        self.image = CGImageMaskCreate(width, height, bits_per_component,
            bits_per_pixel, bytes_per_row, provider, NULL,
            should_interpolate)
        CGDataProviderRelease(provider)

        if self.image == NULL:
            raise RuntimeError("could not make image")

cdef class CGPDFDocument:
    cdef CGPDFDocumentRef document

    property number_of_pages:
        def __get__(self):
            return CGPDFDocumentGetNumberOfPages(self.document)

    property allows_copying:
        def __get__(self):
            return CGPDFDocumentAllowsCopying(self.document)

    property allows_printing:
        def __get__(self):
            return CGPDFDocumentAllowsPrinting(self.document)

    property is_encrypted:
        def __get__(self):
            return CGPDFDocumentIsEncrypted(self.document)

    property is_unlocked:
        def __get__(self):
            return CGPDFDocumentIsUnlocked(self.document)

    def __init__(self, char* filename):
        import os
        if not os.path.exists(filename) or not os.path.isfile(filename):
            raise ValueError("%s is not a file" % filename)

        cdef CFURLRef cfurl
        cfurl = url_from_filename(filename)

        self.document = CGPDFDocumentCreateWithURL(cfurl)
        CFRelease(cfurl)
        if self.document == NULL:
            raise RuntimeError("could not create CGPDFDocument")

    def unlock_with_password(self, char* password):
        return CGPDFDocumentUnlockWithPassword(self.document, password)

    def get_media_box(self, int page):
        cdef CGRect cgrect
        cgrect = CGPDFDocumentGetMediaBox(self.document, page)
        return (cgrect.origin.x, cgrect.origin.y,
                cgrect.size.width, cgrect.size.height)

    def get_crop_box(self, int page):
        cdef CGRect cgrect
        cgrect = CGPDFDocumentGetCropBox(self.document, page)
        return (cgrect.origin.x, cgrect.origin.y,
                cgrect.size.width, cgrect.size.height)

    def get_bleed_box(self, int page):
        cdef CGRect cgrect
        cgrect = CGPDFDocumentGetBleedBox(self.document, page)
        return (cgrect.origin.x, cgrect.origin.y,
                cgrect.size.width, cgrect.size.height)

    def get_trim_box(self, int page):
        cdef CGRect cgrect
        cgrect = CGPDFDocumentGetTrimBox(self.document, page)
        return (cgrect.origin.x, cgrect.origin.y,
                cgrect.size.width, cgrect.size.height)

    def get_art_box(self, int page):
        cdef CGRect cgrect
        cgrect = CGPDFDocumentGetArtBox(self.document, page)
        return (cgrect.origin.x, cgrect.origin.y,
                cgrect.size.width, cgrect.size.height)

    def get_rotation_angle(self, int page):
        cdef int angle
        angle = CGPDFDocumentGetRotationAngle(self.document, page)
        if angle == 0:
            raise ValueError("page %d does not exist" % page)

    def __dealloc__(self):
        if self.document != NULL:
            CGPDFDocumentRelease(self.document)
            self.document = NULL

cdef CGDataProviderRef CGDataProviderFromFilename(char* string) except NULL:
    cdef CFURLRef cfurl
    cdef CGDataProviderRef result

    cfurl = url_from_filename(string)
    if cfurl == NULL:
        raise RuntimeError("could not create CFURLRef")

    result = CGDataProviderCreateWithURL(cfurl)
    CFRelease(cfurl)
    if result == NULL:
        raise RuntimeError("could not create CGDataProviderRef")
    return result

cdef class CGAffine:
    cdef CGAffineTransform real_transform

    property a:
        def __get__(self):
            return self.real_transform.a
        def __set__(self, float value):
            self.real_transform.a = value

    property b:
        def __get__(self):
            return self.real_transform.b
        def __set__(self, float value):
            self.real_transform.b = value

    property c:
        def __get__(self):
            return self.real_transform.c
        def __set__(self, float value):
            self.real_transform.c = value

    property d:
        def __get__(self):
            return self.real_transform.d
        def __set__(self, float value):
            self.real_transform.d = value

    property tx:
        def __get__(self):
            return self.real_transform.tx
        def __set__(self, float value):
            self.real_transform.tx = value

    property ty:
        def __get__(self):
            return self.real_transform.ty
        def __set__(self, float value):
            self.real_transform.ty = value

    def __init__(self, float a=1.0, float b=0.0, float c=0.0, float d=1.0,
        float tx=0.0, float ty=0.0):
        self.real_transform = CGAffineTransformMake(a,b,c,d,tx,ty)

    def translate(self, float tx, float ty):
        self.real_transform = CGAffineTransformTranslate(self.real_transform,
            tx, ty)
        return self

    def rotate(self, float angle):
        self.real_transform = CGAffineTransformRotate(self.real_transform,
            angle)
        return self

    def scale(self, float sx, float sy):
        self.real_transform = CGAffineTransformScale(self.real_transform, sx,
            sy)
        return self

    def invert(self):
        self.real_transform = CGAffineTransformInvert(self.real_transform)
        return self

    def concat(self, CGAffine other not None):
        self.real_transform = CGAffineTransformConcat(self.real_transform,
            other.real_transform)
        return self

    def __mul__(CGAffine x not None, CGAffine y not None):
        cdef CGAffineTransform new_transform
        new_transform = CGAffineTransformConcat(x.real_transform,
            y.real_transform)
        new_affine = CGAffine()
        set_affine_transform(new_affine, new_transform)
        return new_affine

    cdef void init_from_cgaffinetransform(self, CGAffineTransform t):
        self.real_transform = t

    def __div__(CGAffine x not None, CGAffine y not None):
        cdef CGAffineTransform new_transform
        new_transform = CGAffineTransformInvert(y.real_transform)
        new_affine = CGAffine()
        set_affine_transform(new_affine, CGAffineTransformConcat(x.real_transform, new_transform))
        return new_affine

    def apply_to_point(self, float x, float y):
        cdef CGPoint oldpoint
        oldpoint = CGPointMake(x, y)
        cdef CGPoint newpoint
        newpoint = CGPointApplyAffineTransform(oldpoint,
            self.real_transform)
        return newpoint.x, newpoint.y

    def apply_to_size(self, float width, float height):
        cdef CGSize oldsize
        oldsize = CGSizeMake(width, height)
        cdef CGSize newsize
        newsize = CGSizeApplyAffineTransform(oldsize, self.real_transform)
        return newsize.width, newsize.height

    def __repr__(self):
        return "CGAffine(%r, %r, %r, %r, %r, %r)" % (self.a, self.b, self.c,
            self.d, self.tx, self.ty)

    def as_matrix(self):
        return ((self.a, self.b, 0.0),
                (self.c, self.d, 0.0),
                (self.tx,self.ty,1.0))

cdef set_affine_transform(CGAffine t, CGAffineTransform newt):
    t.init_from_cgaffinetransform(newt)

##cdef class Point:
##    cdef CGPoint real_point
##
##    property x:
##        def __get__(self):
##            return self.real_point.x
##        def __set__(self, float value):
##            self.real_point.x = value
##
##    property y:
##        def __get__(self):
##            return self.real_point.y
##        def __set__(self, float value):
##            self.real_point.y = value
##
##    def __init__(self, float x, float y):
##        self.real_point = CGPointMake(x, y)
##
##    def apply_transform(self, CGAffine transform not None):
##        self.real_point = CGPointApplyTransform(self.real_point,
##            transform.real_transform)

cdef class Rect:
    cdef CGRect real_rect

    property x:
        def __get__(self):
            return self.real_rect.origin.x
        def __set__(self, float value):
            self.real_rect.origin.x = value

    property y:
        def __get__(self):
            return self.real_rect.origin.y
        def __set__(self, float value):
            self.real_rect.origin.y = value

    property width:
        def __get__(self):
            return self.real_rect.size.width
        def __set__(self, float value):
            self.real_rect.size.width = value

    property height:
        def __get__(self):
            return self.real_rect.size.height
        def __set__(self, float value):
            self.real_rect.size.height = value

    property min_x:
        def __get__(self):
            return CGRectGetMinX(self.real_rect)

    property max_x:
        def __get__(self):
            return CGRectGetMaxX(self.real_rect)

    property min_y:
        def __get__(self):
            return CGRectGetMinY(self.real_rect)

    property max_y:
        def __get__(self):
            return CGRectGetMaxY(self.real_rect)

    property mid_x:
        def __get__(self):
            return CGRectGetMidX(self.real_rect)

    property mid_y:
        def __get__(self):
            return CGRectGetMidY(self.real_rect)

    property is_null:
        def __get__(self):
            return CGRectIsNull(self.real_rect)

    property is_empty:
        def __get__(self):
            return CGRectIsEmpty(self. real_rect)

    def __init__(self, float x=0.0, float y=0.0, float width=0.0, float
        height=0.0):
        self.real_rect = CGRectMake(x,y,width,height)

    def intersects(self, Rect other not None):
        return CGRectIntersectsRect(self.real_rect, other.real_rect)

    def contains_rect(self, Rect other not None):
        return CGRectContainsRect(self.real_rect, other.real_rect)

    def contains_point(self, float x, float y):
        return CGRectContainsPoint(self.real_rect, CGPointMake(x,y))

    def __richcmp__(Rect x not None, Rect y not None, int op):
        if op == 2:
            return CGRectEqualToRect(x.real_rect, y.real_rect)
        elif op == 3:
            return not CGRectEqualToRect(x.real_rect, y.real_rect)
        else:
            raise NotImplementedError("only (in)equality can be tested")

    def standardize(self):
        self.real_rect = CGRectStandardize(self.real_rect)
        return self

    def inset(self, float x, float y):
        cdef CGRect new_rect
        new_rect = CGRectInset(self.real_rect, x, y)
        rect = Rect()
        set_rect(rect, new_rect)
        return rect

    def offset(self, float x, float y):
        cdef CGRect new_rect
        new_rect = CGRectOffset(self.real_rect, x, y)
        rect = Rect()
        set_rect(rect, new_rect)
        return rect

    def integral(self):
        self.real_rect = CGRectIntegral(self.real_rect)
        return self

    def __add__(Rect x not None, Rect y not None):
        cdef CGRect new_rect
        new_rect = CGRectUnion(x.real_rect, y.real_rect)
        rect = Rect()
        set_rect(rect, new_rect)
        return rect

    def union(self, Rect other not None):
        cdef CGRect new_rect
        new_rect = CGRectUnion(self.real_rect, other.real_rect)
        rect = Rect()
        set_rect(rect, new_rect)
        return rect

    def intersection(self, Rect other not None):
        cdef CGRect new_rect
        new_rect = CGRectIntersection(self.real_rect, other.real_rect)
        rect = Rect()
        set_rect(rect, new_rect)
        return rect

    def divide(self, float amount, edge):
        cdef CGRect slice
        cdef CGRect remainder
        CGRectDivide(self.real_rect, &slice, &remainder, amount, edge)
        pyslice = Rect()
        set_rect(pyslice, slice)
        pyrem = Rect()
        set_rect(pyrem, remainder)
        return pyslice, pyrem

    cdef init_from_cgrect(self, CGRect cgrect):
        self.real_rect = cgrect

    def __repr__(self):
        return "Rect(%r, %r, %r, %r)" % (self.x, self.y, self.width,
            self.height)

cdef set_rect(Rect pyrect, CGRect cgrect):
    pyrect.init_from_cgrect(cgrect)

cdef class CGMutablePath:
    cdef CGMutablePathRef path

    def __init__(self, CGMutablePath path=None):
        if path is not None:
            self.path = CGPathCreateMutableCopy(path.path)
        else:
            self.path = CGPathCreateMutable()

    def begin_path(self):
        return

    def move_to(self, float x, float y, CGAffine transform=None):
        cdef CGAffineTransform *ptr
        ptr = NULL
        if transform is not None:
            ptr = &(transform.real_transform)
        CGPathMoveToPoint(self.path, ptr, x, y)

    def arc(self, float x, float y, float r, float startAngle, float endAngle,
        bool clockwise=False, CGAffine transform=None):

        cdef CGAffineTransform *ptr
        ptr = NULL
        if transform is not None:
            ptr = &(transform.real_transform)

        CGPathAddArc(self.path, ptr, x, y, r, startAngle, endAngle, clockwise)

    def arc_to(self, float x1, float y1, float x2, float y2, float r,
        CGAffine transform=None):

        cdef CGAffineTransform *ptr
        ptr = NULL
        if transform is not None:
            ptr = &(transform.real_transform)

        CGPathAddArcToPoint(self.path, ptr, x1,y1, x2,y2, r)

    def curve_to(self, float cx1, float cy1, float cx2, float cy2, float x,
        float y, CGAffine transform=None):

        cdef CGAffineTransform *ptr
        ptr = NULL
        if transform is not None:
            ptr = &(transform.real_transform)

        CGPathAddCurveToPoint(self.path, ptr, cx1, cy1, cx2, cy2, x, y)

    def line_to(self, float x, float y, CGAffine transform=None):
        cdef CGAffineTransform *ptr
        ptr = NULL
        if transform is not None:
            ptr = &(transform.real_transform)

        CGPathAddLineToPoint(self.path, ptr, x, y)

    def lines(self, points, CGAffine transform=None):
        cdef CGAffineTransform *ptr
        ptr = NULL
        if transform is not None:
            ptr = &(transform.real_transform)

        cdef int n
        n = len(points)
        cdef int i

        CGPathMoveToPoint(self.path, ptr, points[0][0], points[0][1])

        for i from 1 <= i < n:
            CGPathAddLineToPoint(self.path, ptr, points[i][0], points[i][1])

    def add_path(self, CGMutablePath other_path not None, CGAffine transform=None):
        cdef CGAffineTransform *ptr
        ptr = NULL
        if transform is not None:
            ptr = &(transform.real_transform)

        CGPathAddPath(self.path, ptr, other_path.path)

    def quad_curve_to(self, float cx, float cy, float x, float y, CGAffine transform=None):
        cdef CGAffineTransform *ptr
        ptr = NULL
        if transform is not None:
            ptr = &(transform.real_transform)

        CGPathAddQuadCurveToPoint(self.path, ptr, cx, cy, x, y)

    def rect(self, float x, float y, float sx, float sy, CGAffine transform=None):
        cdef CGAffineTransform *ptr
        ptr = NULL
        if transform is not None:
            ptr = &(transform.real_transform)

        CGPathAddRect(self.path, ptr, CGRectMake(x,y,sx,sy))

    def rects(self, rects, CGAffine transform=None):
        cdef CGAffineTransform *ptr
        ptr = NULL
        if transform is not None:
            ptr = &(transform.real_transform)

        cdef int n
        n = len(rects)
        cdef int i
        for i from 0 <= i < n:
            CGPathAddRect(self.path, ptr, CGRectMakeFromPython(rects[i]))

    def close_path(self):
        CGPathCloseSubpath(self.path)

    def is_empty(self):
        return CGPathIsEmpty(self.path)

    def get_current_point(self):
        cdef CGPoint point
        point = CGPathGetCurrentPoint(self.path)
        return point.x, point.y

    def get_bounding_box(self):
        cdef CGRect rect
        rect = CGPathGetBoundingBox(self.path)
        return (rect.origin.x, rect.origin.y,
                rect.size.width, rect.size.height)

    def __richcmp__(CGMutablePath x not None, CGMutablePath y not None, int op):
        if op == 2:
            # testing for equality
            return CGPathEqualToPath(x.path, y.path)
        elif op == 3:
            # testing for inequality
            return not CGPathEqualToPath(x.path, y.path)
        else:
            raise NotImplementedError("only (in)equality tests are allowed")

    def __dealloc__(self):
        if self.path != NULL:
            CGPathRelease(self.path)
            self.path = NULL

cdef class _Markers:

    def get_marker(self, int marker_type, float size=1.0):
        """ Return the CGMutablePath corresponding to the given marker
        enumeration.

          Marker.get_marker(marker_type, size=1.0)

        Parameters
        ----------
        marker_type : int
            One of the enumerated marker types in enthought.kiva.constants.
        size : float, optional
            The linear size in points of the marker. Some markers (e.g. dot)
            ignore this.

        Returns
        -------
        path : CGMutablePath
        """

        if marker_type == constants.NO_MARKER:
            return CGMutablePath()
        elif marker_type == constants.SQUARE_MARKER:
            return self.square(size)
        elif marker_type == constants.DIAMOND_MARKER:
            return self.diamond(size)
        elif marker_type == constants.CIRCLE_MARKER:
            return self.circle(size)
        elif marker_type == constants.CROSSED_CIRCLE_MARKER:
            raise NotImplementedError
        elif marker_type == constants.CROSS_MARKER:
            return self.cross(size)
        elif marker_type == constants.TRIANGLE_MARKER:
            raise NotImplementedError
        elif marker_type == constants.INVERTED_TRIANGLE_MARKER:
            raise NotImplementedError
        elif marker_type == constants.PLUS_MARKER:
            raise NotImplementedError
        elif marker_type == constants.DOT_MARKER:
            raise NotImplementedError
        elif marker_type == constants.PIXEL_MARKER:
            raise NotImplementedError


    def square(self, float size):
        cdef float half
        half = size / 2

        m = CGMutablePath()
        m.rect(-half,-half,size,size)
        return m

    def diamond(self, float size):
        cdef float half
        half = size / 2

        m = CGMutablePath()
        m.move_to(0.0, -half)
        m.line_to(-half, 0.0)
        m.line_to(0.0, half)
        m.line_to(half, 0.0)
        m.close_path()
        return m

    def x(self, float size):
        cdef float half
        half = size / 2

        m = CGMutablePath()
        m.move_to(-half,-half)
        m.line_to(half,half)
        m.move_to(-half,half)
        m.line_to(half,-half)
        return m

    def cross(self, float size):
        cdef float half
        half = size / 2

        m = CGMutablePath()
        m.move_to(0.0, -half)
        m.line_to(0.0, half)
        m.move_to(-half, 0.0)
        m.line_to(half, 0.0)
        return m

    def dot(self):
        m = CGMutablePath()
        m.rect(-0.5,-0.5,1.0,1.0)
        return m

    def circle(self, float size):
        cdef float half
        half = size / 2
        m = CGMutablePath()
        m.arc(0.0, 0.0, half, 0.0, 6.2831853071795862, 1)
        return m

Markers = _Markers()

cdef class ShadingFunction:
    cdef CGFunctionRef function

    cdef void _setup_function(self, CGFunctionEvaluateCallback callback):
        cdef int i
        cdef CGFunctionCallbacks callbacks
        callbacks.version = 0
        callbacks.releaseInfo = NULL
        callbacks.evaluate = <CGFunctionEvaluateCallback>callback

        cdef float domain_bounds[2]
        cdef float range_bounds[8]

        domain_bounds[0] = 0.0
        domain_bounds[1] = 1.0
        for i from 0 <= i < 4:
            range_bounds[2*i] = 0.0
            range_bounds[2*i+1] = 1.0

        self.function = CGFunctionCreate(<void*>self, 1, domain_bounds,
            4, range_bounds, &callbacks)
        if self.function == NULL:
            raise RuntimeError("could not make CGFunctionRef")

cdef void shading_callback(object self, float* in_data, float* out_data):
    cdef int i
    out = self(in_data[0])
    for i from 0 <= i < self.n_dims:
        outData[i] = out[i]

cdef class Shading:
    cdef CGShadingRef shading
    cdef public object function
    cdef int n_dims

    def __init__(self, ShadingFunction func not None):
        raise NotImplementedError("use AxialShading or RadialShading")

    def __dealloc__(self):
        if self.shading != NULL:
            CGShadingRelease(self.shading)

cdef class AxialShading(Shading):
    def __init__(self, ShadingFunction func not None, object start, object end,
        int extend_start=0, int extend_end=0):

        self.n_dims = 4

        cdef CGPoint start_point, end_point
        start_point = CGPointMake(start[0], start[1])
        end_point = CGPointMake(end[0], end[1])

        self.function = func

        cdef CGColorSpaceRef space
        space = CGColorSpaceCreateDeviceRGB()
        self.shading = CGShadingCreateAxial(space, start_point, end_point,
            func.function, extend_start, extend_end)
        CGColorSpaceRelease(space)
        if self.shading == NULL:
            raise RuntimeError("could not make CGShadingRef")

cdef class RadialShading(Shading):
    def __init__(self, ShadingFunction func not None, object start,
        float start_radius, object end, float end_radius, int extend_start=0,
        int extend_end=0):

        self.n_dims = 4

        cdef CGPoint start_point, end_point
        start_point = CGPointMake(start[0], start[1])
        end_point = CGPointMake(end[0], end[1])

        self.function = func

        cdef CGColorSpaceRef space
        space = CGColorSpaceCreateDeviceRGB()
        self.shading = CGShadingCreateRadial(space, start_point, start_radius,
            end_point, end_radius, func.function, extend_start, extend_end)
        CGColorSpaceRelease(space)
        if self.shading == NULL:
            raise RuntimeError("could not make CGShadingRef")

cdef void safe_free(void* mem):
    if mem != NULL:
        PyMem_Free(mem)

cdef class PiecewiseLinearColorFunction(ShadingFunction):
    cdef int num_stops
    cdef float* stops
    cdef float* red
    cdef float* green
    cdef float* blue
    cdef float* alpha

    def __init__(self, object stop_colors):
        cdef c_numpy.ndarray stop_array
        cdef int i

        stop_colors = numpy.array(stop_colors).astype(numpy.float32)

        if not (4 <= stop_colors.shape[0] <= 5) or len(stop_colors.shape) != 2:
            raise ValueError("need array [stops, red, green, blue[, alpha]]")

        if stop_colors[0,0] != 0.0 or stop_colors[0,-1] != 1.0:
            raise ValueError("stops need to start with 0.0 and end with 1.0")

        if not numpy.alltrue(stop_colors[0,1:] - stop_colors[0,:-1] >= 0):
            raise ValueError("stops must be sorted and unique")

        self.num_stops = stop_colors.shape[1]
        self.stops = <float*>PyMem_Malloc(sizeof(float)*self.num_stops)
        self.red = <float*>PyMem_Malloc(sizeof(float)*self.num_stops)
        self.green = <float*>PyMem_Malloc(sizeof(float)*self.num_stops)
        self.blue = <float*>PyMem_Malloc(sizeof(float)*self.num_stops)
        self.alpha = <float*>PyMem_Malloc(sizeof(float)*self.num_stops)

        stop_array = <c_numpy.ndarray>stop_colors
        memcpy(self.stops, stop_array.data, self.num_stops*sizeof(float))
        memcpy(self.red, stop_array.data+stop_array.strides[0],
            self.num_stops*sizeof(float))
        memcpy(self.green, stop_array.data+2*stop_array.strides[0],
            self.num_stops*sizeof(float))
        memcpy(self.blue, stop_array.data+3*stop_array.strides[0],
            self.num_stops*sizeof(float))
        if stop_colors.shape[0] == 5:
            memcpy(self.alpha, stop_array.data+4*stop_array.strides[0],
                self.num_stops*sizeof(float))
        else:
            for i from 0 <= i < self.num_stops:
                self.alpha[i] = 1.0

        self._setup_function(piecewise_callback)

    def __dealloc__(self):
        safe_free(self.stops)
        safe_free(self.red)
        safe_free(self.green)
        safe_free(self.blue)
        safe_free(self.alpha)


cdef int bisect_left(PiecewiseLinearColorFunction self, float t):
    cdef int lo, hi, mid
    cdef float stop

    hi = self.num_stops
    lo = 0
    while lo < hi:
        mid = (lo + hi)/2
        stop = self.stops[mid]
        if t < stop:
            hi = mid
        else:
            lo = mid + 1
    return lo

cdef void piecewise_callback(void* obj, float* t, float* out):
   cdef int i
   cdef float eps
   cdef PiecewiseLinearColorFunction self

   self = <PiecewiseLinearColorFunction>obj

   eps = 1e-6

   if fabs(t[0]) < eps:
       out[0] = self.red[0]
       out[1] = self.green[0]
       out[2] = self.blue[0]
       out[3] = self.alpha[0]
       return
   if fabs(t[0] - 1.0) < eps:
       i = self.num_stops - 1
       out[0] = self.red[i]
       out[1] = self.green[i]
       out[2] = self.blue[i]
       out[3] = self.alpha[i]
       return

   i = bisect_left(self, t[0])

   cdef float f, g, dx
   dx = self.stops[i] - self.stops[i-1]

   if dx > eps:
       f = (t[0]-self.stops[i-1])/dx
   else:
       f = 1.0

   g = 1.0 - f

   out[0] = f*self.red[i] + g*self.red[i-1]
   out[1] = f*self.green[i] + g*self.green[i-1]
   out[2] = f*self.blue[i] + g*self.blue[i-1]
   out[3] = f*self.alpha[i] + g*self.alpha[i-1]


#### Font utilities ####

cdef ATSUStyle _create_atsu_style(object postscript_name, float font_size):
    cdef OSStatus err
    cdef ATSUStyle atsu_style
    cdef ATSUFontID atsu_font
    cdef Fixed atsu_size
    cdef char* c_ps_name

    # Create the attribute arrays.
    cdef ATSUAttributeTag attr_tags[2]
    cdef ByteCount attr_sizes[2]
    cdef ATSUAttributeValuePtr attr_values[2]

    err = noErr
    atsu_style = NULL
    atsu_font = 0
    atsu_size = FloatToFixed(font_size)

    # Look up the ATSUFontID for the given PostScript name of the font.
    postscript_name = postscript_name.encode('utf-8')
    c_ps_name = PyString_AsString(postscript_name)
    err = ATSUFindFontFromName(<void*>c_ps_name, len(postscript_name),
        kFontPostscriptName, kFontNoPlatformCode, kFontNoScriptCode,
        kFontNoLanguageCode, &atsu_font)
    if err:
        return NULL

    # Set the ATSU font in the attribute arrays.
    attr_tags[0] = kATSUFontTag
    attr_sizes[0] = sizeof(ATSUFontID)
    attr_values[0] = &atsu_font

    # Set the font size in the attribute arrays.
    attr_tags[1] = kATSUSizeTag
    attr_sizes[1] = sizeof(Fixed)
    attr_values[1] = &atsu_size

    # Create the ATSU style.
    err = ATSUCreateStyle(&atsu_style)
    if err:
        if atsu_style != NULL:
            ATSUDisposeStyle(atsu_style)
        return NULL

    # Set the style attributes.
    err = ATSUSetAttributes(atsu_style, 2, attr_tags, attr_sizes, attr_values)
    if err:
        if atsu_style != NULL:
            ATSUDisposeStyle(atsu_style)
        return NULL

    return atsu_style


cdef object _create_atsu_layout(object the_string, ATSUStyle style, ATSUTextLayout* layout):
    cdef ATSUTextLayout atsu_layout
    cdef CFIndex text_length
    cdef OSStatus err
    cdef UniChar *uni_buffer
    cdef CFRange uni_range
    cdef CFStringRef cf_string
    cdef char* c_string

    layout[0] = atsu_layout = NULL
    if len(the_string) == 0:
        return

    err = noErr
    the_string = the_string.encode('utf-8')
    c_string = PyString_AsString(the_string)

    cf_string = CFStringCreateWithCString(NULL, c_string, kCFStringEncodingUTF8)
    text_length = CFStringGetLength(cf_string)

    # Extract the Unicode data from the CFStringRef.
    uni_range = CFRangeMake(0, text_length)
    uni_buffer = <UniChar*>PyMem_Malloc(text_length * sizeof(UniChar))
    if uni_buffer == NULL:
        raise MemoryError("could not allocate %d bytes of memory" % (text_length * sizeof(UniChar)))
    CFStringGetCharacters(cf_string, uni_range, uni_buffer)

    # Create the ATSUI layout.
    err = ATSUCreateTextLayoutWithTextPtr(<ConstUniCharArrayPtr>uni_buffer, 0, text_length, text_length, 1, <UniCharCount*>&text_length, &style, &atsu_layout)
    if err:
        PyMem_Free(uni_buffer)
        raise RuntimeError("could not create an ATSUI layout")

    layout[0] = atsu_layout
    return


cdef object _set_cgcontext_for_layout(CGContextRef context, ATSUTextLayout layout):
    cdef ATSUAttributeTag tag
    cdef ByteCount size
    cdef ATSUAttributeValuePtr value
    cdef OSStatus err

    tag = kATSUCGContextTag
    size = sizeof(CGContextRef)
    value = &context

    err = ATSUSetLayoutControls(layout, 1, &tag, &size, &value)
    if err:
        raise RuntimeError("could not assign the CGContextRef to the ATSUTextLayout")
    return


#### EOF #######################################################################
