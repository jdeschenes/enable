"""
Define the base Enable object traits
"""

# Major library imports
from numpy import arange, array
from types import ListType, TupleType

# Enthought library imports
from enable.kiva.trait_defs.kiva_font_trait import KivaFont
from traits.api import Trait, Range, TraitPrefixList, TraitPrefixMap, \
    List, TraitFactory
from traitsui.api import ImageEnumEditor, EnumEditor
# Try to get the CList trait; for traits 2 backwards compatibility, fall back
# to a normal List trait if we can't import it
try:
    from traits.api import CList
except ImportError:
    CList = List

# Relative imports
import base
from base import default_font_name

#------------------------------------------------------------------------------
#  Constants:
#------------------------------------------------------------------------------

# numpy 'array' type:
ArrayType = type( arange( 1.0 ) )

# Basic sequence types:
basic_sequence_types = ( ListType, TupleType )

# Sequence types:
sequence_types = [ ArrayType, ListType, TupleType ]

# Valid pointer shape names:
pointer_shapes = [
   'arrow', 'right arrow', 'blank', 'bullseye', 'char', 'cross', 'hand',
   'ibeam', 'left button', 'magnifier', 'middle button', 'no entry',
   'paint brush', 'pencil', 'point left', 'point right', 'question arrow',
   'right button', 'size top', 'size bottom', 'size left', 'size right',
   'size top right', 'size bottom left', 'size top left', 'size bottom right',
   'sizing', 'spray can', 'wait', 'watch', 'arrow wait'
]

# Cursor styles:
CURSOR_X = 1
CURSOR_Y = 2

cursor_styles = {
    'default':    -1,
    'none':       0,
    'horizontal': CURSOR_Y,
    'vertical':   CURSOR_X,
    'both':       CURSOR_X | CURSOR_Y
}

border_size_editor = ImageEnumEditor(
                         values = [ x for x in range( 9 ) ],
                         suffix = '_weight',
                         cols   = 3,
                         module = base )


#-------------------------------------------------------------------------------
# LineStyle trait
#-------------------------------------------------------------------------------

# Privates used for specification of line style trait.
__line_style_trait_values = {
    'solid':     None,
    'dot dash':  array( [ 3.0, 5.0, 9.0, 5.0 ] ),
    'dash':      array( [ 6.0, 6.0 ] ),
    'dot':       array( [ 2.0, 2.0 ] ),
    'long dash': array( [ 9.0, 5.0 ] )
}
__line_style_trait_map_keys = __line_style_trait_values.keys()
LineStyleEditor = EnumEditor( values=__line_style_trait_map_keys)

def __line_style_trait( value='solid', **metadata ):
    return Trait( value, __line_style_trait_values,
                    editor=LineStyleEditor, **metadata)

# A mapped trait for use in specification of line style attributes.
LineStyle = TraitFactory( __line_style_trait )


#-------------------------------------------------------------------------------
#  Trait definitions:
#-------------------------------------------------------------------------------

# Font trait:
font_trait = KivaFont(default_font_name)

# Bounds trait
bounds_trait = CList( [0.0, 0.0] )      # (w,h)
coordinate_trait = CList( [0.0, 0.0] )  # (x,y)

#bounds_trait = Trait((0.0, 0.0, 20.0, 20.0), valid_bounds, editor=bounds_editor)

# Component minimum size trait
# PZW: Make these just floats, or maybe remove them altogether.
ComponentMinSize = Range(0.0, 99999.0)
ComponentMaxSize = ComponentMinSize(99999.0)

# Pointer shape trait:
Pointer = Trait('arrow', TraitPrefixList(pointer_shapes))

# Cursor style trait:
cursor_style_trait = Trait('default', TraitPrefixMap(cursor_styles))

spacing_trait = Range(0, 63, value = 4)
padding_trait = Range(0, 63, value = 4)
margin_trait = Range(0, 63)
border_size_trait = Range(0,  8, editor = border_size_editor)

# Time interval trait:
TimeInterval = Trait(None, None, Range(0.0, 3600.0))

# Stretch traits:
Stretch = Range(0.0, 1.0, value = 1.0)
NoStretch = Stretch(0.0)
