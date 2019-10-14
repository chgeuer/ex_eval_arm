json
    element

value
    object
    array
    string
    number
    boolean
    null

object
    '{' ws '}'
    '{' members '}'

members
    member
    member ',' members

member
    ws string ws ':' element


string
    '"' characters '"'
 
characters
    ""
    character characters

character
    '0020' . '10ffff' - '"' - '\'
     \"  \\  \/  \b  \f  \n  \r  \t  \uFFFF

hex
    digit
    'A' . 'F'
    'a' . 'f'

############

sign
    ""
    '+'
    '-'

onenine
    '1' . '9'

digit
    '0'
    onenine

digits
    digit
    digit digits

fraction
    ""
    '.' digits

integer
    digit
    onenine digits
    '-' digit
    '-' onenine digits

exponent
    ""
    'E' sign digits
    'e' sign digits

number
    integer fraction exponent

element
    ws value ws

elements
    element
    element ',' elements

array
    '[' ws ']'
    '[' elements ']'

ws
    ""
    '0020' ws
    '000D' ws
    '000A' ws
    '0009' ws

boolean
    "true"
    "false"

null
    "null"

