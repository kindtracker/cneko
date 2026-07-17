if exists("b:current_syntax")
    finish
endif

syntax keyword cnekoKeyword fn if else switch case default for while break continue return const static extern struct union enum typedef import

syntax keyword cnekoType bool ichar char short ushort int uint long ulong iptr uptr sz usz float double void

syntax keyword cnekoConstant true false null

syntax match cnekoComment "//.*$"
syntax region cnekoComment start="/\*" end="\*/"

syntax region cnekoString start=+"+ skip=+\\\\\|\\"+ end=+"+
syntax region cnekoChar start=+'+ skip=+\\\\\|\\'+ end=+'+
syntax match cnekoEscape "\\[ntrbfv0\\\"']" contained

syntax match cnekoNumber "\<0[xX][0-9A-Fa-f]\+\([uUlLsSfFdD]*\)\?\>"
syntax match cnekoNumber "\<[0-9]\+\(\.[0-9]\+\)\?\([uUlLsSfFdD]*\)\?\>"

syntax match cnekoFunction "\<[A-Za-z_][A-Za-z0-9_]*\ze\s*("

syntax match cnekoOperator "[+\-*/%^<>!=&|~]"
syntax match cnekoDelimiter "[(){}\[\]]"
syntax match cnekoPunctuation "[,;:.]"

highlight default link cnekoKeyword Keyword
highlight default link cnekoType Type
highlight default link cnekoConstant Constant
highlight default link cnekoComment Comment
highlight default link cnekoString String
highlight default link cnekoChar Character
highlight default link cnekoEscape SpecialChar
highlight default link cnekoNumber Number
highlight default link cnekoFunction Function
highlight default link cnekoOperator Operator
highlight default link cnekoDelimiter Delimiter
highlight default link cnekoPunctuation Delimiter

let b:current_syntax = "cneko"
