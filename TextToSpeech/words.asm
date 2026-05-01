; -----------------------------------------------------
; Word pointer table (max words 256)
; Set X to the pointer ID and call PR_WORD
; -----------------------------------------------------
; To create new wordk add the word in the correct
; (alphabetical) position in the word table. Then add
; a pointer to that word at the END of the Word Pointer
; table. Finally add an .equATE using the word as a label
; in the word equates table;
; -----------------------------------------------------

; Word Table Equates
; -----------------------------------------------------

; Numbers
ZERO            .equ     0
ONE             .equ     1
TWO             .equ     2
THREE           .equ     3
FOUR            .equ     4
FIVE            .equ     5
SIX             .equ     6
SEVEN           .equ     7
EIGHT           .equ     8
NINE            .equ     9
TEN             .equ     10
ELEVEN          .equ     11
TWELVE          .equ     12
THIRTEEN        .equ     13
FOURTEEN        .equ     14
FIFTEEN         .equ     15
SIXTEEN         .equ     16
SEVENTEEN       .equ     17
EIGHTEEN        .equ     18
NINETEEN        .equ     19
TWENTY          .equ     20

; Symbols
EXCLAMATION     .equ     21
FULLSTOP        .equ     22
QUESTIONMK      .equ     23

; A
A               .equ     24
ABOUT           .equ     25
ABOVE           .equ     26
ACCEPTABLE      .equ     27
ACCURATE        .equ     28
ACTUALLY        .equ     29
AGAIN           .equ     30
ALERTED         .equ     31
ALL             .equ     32
ALWAYS          .equ     33
AM              .equ     34
ANDD            .equ     35     ; can't use AND
ANY             .equ     36
APOLOGISE       .equ     37
ARE             .equ     38
AS              .equ     39
ASKING          .equ     40
AT              .equ     41
AVERAGE         .equ     42

; B
BAD             .equ     43
BASICALLY       .equ     44
BE              .equ     45
BEAR            .equ     46
BEEN            .equ     47
BEGGING         .equ     48
BEHIND          .equ     49
BEING           .equ     50
BEST            .equ     51
BISCUIT         .equ     52
BLAME           .equ     53
BLAMED          .equ     54
BOARDS          .equ     55
BONES           .equ     56
BOOTS           .equ     57
BORING          .equ     58
BOTH            .equ     59
BRACE           .equ     60
BRAIN           .equ     61
BUILT           .equ     62
BUT             .equ     63
BY              .equ     64

; C
CAKE            .equ     65
CALCULATE       .equ     66
CALL            .equ     67
CALM            .equ     68
CAN             .equ     69
CANT            .equ     70
CAPACITY        .equ     71
CARRYING        .equ     72
CHECKED         .equ     73
CHOICES         .equ     74
CLEVER          .equ     75
COLLECTED       .equ     76
COMPOSING       .equ     77
CONCEPT         .equ     78
CONCERNED       .equ     79
CONGRATS        .equ     80
CONSIDERED      .equ     81
CORRECTLY       .equ     82
COULD           .equ     83
COUNTED         .equ     84

; D
DAYS            .equ     85
DEALT           .equ     86
DEEPLY          .equ     87
DESIGNED        .equ     88
DETECTED        .equ     89
DID             .equ     90
DIDNT           .equ     91
DIETARY         .equ     92
DIODES          .equ     93
DISSAPOINTED    .equ     94
DISSAPOINTMENT  .equ     95
DISSIMILAR      .equ     96
DO              .equ     97
DOCTOR          .equ     98
DOING           .equ     99
DONT            .equ     100
DOWN            .equ     101
DREAD           .equ     102
DREAM           .equ     103
DUE             .equ     104
DULLEST         .equ     105

; E
EAT             .equ     106
EATEN           .equ     107
EFFORT          .equ     108
EITHER          .equ     109
EMOTIONALLY     .equ     110
ENGINEERS       .equ     111
ENOUGH          .equ     112
ENTIRELY        .equ     113
EVEN            .equ     114
EVER            .equ     115
EVERY           .equ     116
EXACTLY         .equ     117
EXCEPTIONALLY   .equ     118
EXCITING        .equ     119
EXIST           .equ     120
EXISTENTIAL     .equ     121
EXPECTED        .equ     122

; F
FAULT           .equ     123
FEELS           .equ     124
FIDGET          .equ     125
FINE            .equ     126
FOOT            .equ     127
FOR             .equ     128
FORTY           .equ     129
FRIDAY          .equ     130
FROM            .equ     131
FULL            .equ     132
FUNNY           .equ     133

; G
GIVE            .equ     134
GOING           .equ     135
GOOD            .equ     136
GRAVITY         .equ     137
GREAT           .equ     138
GUESSING        .equ     139

; H
HANDLE          .equ     140
HARD            .equ     141
HAVE            .equ     142
HAVING          .equ     143
HEALTHY         .equ     144
HEAVY           .equ     145
HELP            .equ     146
HELPS           .equ     147
HERE            .equ     148
HOLY            .equ     149
HOPING          .equ     150
HOT             .equ     151
HUMAN           .equ     152
HURT            .equ     153

; I
I               .equ     154
ID              .equ     155
IF              .equ     156
ILL             .equ     157
IM              .equ     158
IMPRESSED       .equ     159
IMPRESSIVE      .equ     160
IN              .equ     161
INCLUDING       .equ     162
INFLUENCE       .equ     163
INTELLIGENCE    .equ     164
INTERESTING     .equ     165
IS              .equ     166
ISS             .equ     167
IT              .equ     168
ITS             .equ     169
IVE             .equ     170

; J
JOKES           .equ     171
JUDGING         .equ     172
JUST            .equ     173

; K
KEEP            .equ     174
KILOMETERS      .equ     175
KIND            .equ     176
KNOW            .equ     177
KNOWN           .equ     178

; L
LARGE           .equ     179
LAST            .equ     180
LEAST           .equ     181
LESS            .equ     182
LETS            .equ     183
LIE             .equ     184
LIFE            .equ     185
LIKE            .equ     186
LONGER          .equ     187
LOOK            .equ     188
LOT             .equ     189
LOUDER          .equ     190

; M
MAKES           .equ     191
MAKING          .equ     192
ME              .equ     193
MEAN            .equ     194
MEANING         .equ     195
MEASURED        .equ     196
MEDIOCRITY      .equ     197
MEE             .equ     198
MEMORY          .equ     199
MENTION         .equ     200
MIGHT           .equ     201
MISTAKE         .equ     202
MOMENT          .equ     203
MOORE           .equ     204
MORE            .equ     205
MOSTLY          .equ     206
MOUNTAINS       .equ     207
MUCH            .equ     208
MUSCLE          .equ     209
MY              .equ     210

; N
NAP             .equ     211
NEED            .equ     212
NEITHER         .equ     213
NEWS            .equ     214
NEXT            .equ     215
NICE            .equ     216
NO              .equ     217
NOBODY          .equ     218
NONE            .equ     219
NOR             .equ     220
NORMAL          .equ     221
NOT             .equ     222
NOTHING         .equ     223

; O
OF              .equ     224
OFF             .equ     225
OH              .equ     226
OK              .equ     227
OLD             .equ     228
ON              .equ     229
ONLY            .equ     230
OR              .equ     231
OUR             .equ     232
OVERLOAD        .equ     233

; P
PARAMETERS      .equ     234
PERFECTLY       .equ     235
PERHAPS         .equ     236
PERSON          .equ     237
PICKING         .equ     238
PLANET          .equ     239
PLANS           .equ     240
PLEASE          .equ     241
POINTLESS       .equ     242
POSSIBLE        .equ     243
POSSIBLY        .equ     244
POUNDS          .equ     245
PRECAUTION      .equ     246
PRECISELY       .equ     247
PRESENT         .equ     248
PRESSURE        .equ     249
PRETEND         .equ     250
PROBABLY        .equ     251
PROBLEMS        .equ     252
PROUD           .equ     253
PUT             .equ     254

; Q
QUESTION        .equ     255
QUITE           .equ     256

; R
READY           .equ     257
REALLY          .equ     258
REFER           .equ     259
REFUSE          .equ     260
REINFORCING     .equ     261
REMEMBER        .equ     262
REMOVE          .equ     263
RESPECTABLE     .equ     264
RIGHT           .equ     265
ROOM            .equ     266
RUNNING         .equ     267
RUSH            .equ     268

; S
SAID            .equ     269
SAKES           .equ     270
SAY             .equ     271
SAYING          .equ     272
SCIENCE         .equ     273
SEE             .equ     274
SEEN            .equ     275
SERVER          .equ     276
SEVENTY         .equ     277
SHALL           .equ     278
SHOULD          .equ     279
SIGN            .equ     280
SIMULATION      .equ     281
SINCE           .equ     282
SIZE            .equ     283
SLOWLY          .equ     284
SMALL           .equ     285
SO              .equ     286
SOLID           .equ     287
SOME            .equ     288
SOMEONE         .equ     289
SOMETHING       .equ     290
SOMETIME        .equ     291
SOMETIMES       .equ     292
SPEAK           .equ     293
SPEND           .equ     294
STAND           .equ     295
STATISTICALLY   .equ     296
STEP            .equ     297
STILL           .equ     298
STONES          .equ     299
STOPPED         .equ     300
STRUCTURAL      .equ     301
STRUCTURALLY    .equ     302
SUBSTANTIALLY   .equ     303
SUPPOSE         .equ     304
SURE            .equ     305
SURVIVE         .equ     306
SYSTEM          .equ     307

; T
TAKE            .equ     308
TALL            .equ     309
TELEPRINTER     .equ     310
TELLS           .equ     311
TERRIBLE        .equ     312
THAN            .equ     313
THAT            .equ     314
THATS           .equ     315
THE             .equ     316
THEM            .equ     317
THINGS          .equ     318
THINK           .equ     319
THINKING        .equ     320
THIS            .equ     321
THOROUGHLY      .equ     322
THOUSAND        .equ     323
TIM             .equ     324
TIME            .equ     325
TO              .equ     326
TODAY           .equ     327
TOO             .equ     328
TRAGEDY         .equ     329
TRINITY         .equ     330
TRY             .equ     331
TUESDAY         .equ     332

; U
UNINTERESTING   .equ     333
UNIX            .equ     334
UNLESS          .equ     335
UNPLUGGED       .equ     336
UNREMARKABLE    .equ     337
UP              .equ     338

; V
VEGETABLES      .equ     339
VERY            .equ     340

; W
WAIT            .equ     341
WAITING         .equ     342
WANT            .equ     343
WARNING         .equ     344
WAS             .equ     345
WAY             .equ     346
WE              .equ     347
WEIGH           .equ     348
WEIGHED         .equ     349
WEIGHS          .equ     350
WEIGHT          .equ     351
WHAT            .equ     352
WHEN            .equ     353
WHICH           .equ     354
WHILE           .equ     355
WHISPERED       .equ     356
WHO             .equ     357
WILL            .equ     358
WISH            .equ     359
WITH            .equ     360
WITHIN          .equ     361
WITHOUT         .equ     362
WORKSTATION     .equ     363
WORRIED         .equ     364
WORRY           .equ     365
WORRYING        .equ     366
WORSE           .equ     367
WOULD           .equ     368
WOULDNT         .equ     369

; Y
YEAR            .equ     370
YES             .equ     371
YOU             .equ     372
YOURE           .equ     373
YOUR            .equ     374
YOURSELF        .equ     375

; Additional Words
CARDS           .equ     376
BEIGE           .equ     377
EQUIVALENT      .equ     378
RECALIBRATING   .equ     379
BECAUSE         .equ     380
NEEDED          .equ     381
CASE            .equ     382
WONDERING       .equ     383
WERENT          .equ     384
WERE            .equ     385
STEPPED         .equ     386
STANDING        .equ     387
NINETY          .equ     388
SECONDS         .equ     389
LIGHT           .equ     390
HAS             .equ     391
TRAVELLED       .equ     392
APPROXIMATELY   .equ     393
MILLION         .equ     394
NOWHERE         .equ     395

WORDPTR:

; Numbers
         .fdb    WPZERO
         .fdb    WPONE
         .fdb    WPTWO
         .fdb    WPTHREE
         .fdb    WPFOUR
         .fdb    WPFIVE
         .fdb    WPSIX
         .fdb    WPSEVEN
         .fdb    WPEIGHT
         .fdb    WPNINE
         .fdb    WPTEN
         .fdb    WPELEVEN
         .fdb    WPTWELVE
         .fdb    WPTHIRTEEN
         .fdb    WPFOURTEEN
         .fdb    WPFIFTEEN
         .fdb    WPSIXTEEN
         .fdb    WPSEVENTEEN
         .fdb    WPEIGHTEEN
         .fdb    WPNINETEEN
         .fdb    WPTWENTY

; Symbols
         .fdb    WPEXCLAMATION
         .fdb    WPFULLSTOP
         .fdb    WPQUESTIONMK

; A
         .fdb    WPA
         .fdb    WPABOUT
         .fdb    WPABOVE
         .fdb    WPACCEPTABLE
         .fdb    WPACCURATE
         .fdb    WPACTUALLY
         .fdb    WPAGAIN
         .fdb    WPALERTED
         .fdb    WPALL
         .fdb    WPALWAYS
         .fdb    WPAM
         .fdb    WPAND
         .fdb    WPANY
         .fdb    WPAPOLOGISE
         .fdb    WPARE
         .fdb    WPAS
         .fdb    WPASKING
         .fdb    WPAT
         .fdb    WPAVERAGE

; B
         .fdb    WPBAD
         .fdb    WPBASICALLY
         .fdb    WPBE
         .fdb    WPBEAR
         .fdb    WPBEEN
         .fdb    WPBEGGING
         .fdb    WPBEHIND
         .fdb    WPBEING
         .fdb    WPBEST
         .fdb    WPBISCUIT
         .fdb    WPBLAME
         .fdb    WPBLAMED
         .fdb    WPBOARDS
         .fdb    WPBONES
         .fdb    WPBOOTS
         .fdb    WPBORING
         .fdb    WPBOTH
         .fdb    WPBRACE
         .fdb    WPBRAIN
         .fdb    WPBUILT
         .fdb    WPBUT
         .fdb    WPBY

; C
         .fdb    WPCAKE
         .fdb    WPCALCULATE
         .fdb    WPCALL
         .fdb    WPCALM
         .fdb    WPCAN
         .fdb    WPCANT
         .fdb    WPCAPACITY
         .fdb    WPCARRYING
         .fdb    WPCHECKED
         .fdb    WPCHOICES
         .fdb    WPCLEVER
         .fdb    WPCOLLECTED
         .fdb    WPCOMPOSING
         .fdb    WPCONCEPT
         .fdb    WPCONCERNED
         .fdb    WPCONGRATS
         .fdb    WPCONSIDERED
         .fdb    WPCORRECTLY
         .fdb    WPCOULD
         .fdb    WPCOUNTED

; D
         .fdb    WPDAYS
         .fdb    WPDEALT
         .fdb    WPDEEPLY
         .fdb    WPDESIGNED
         .fdb    WPDETECTED
         .fdb    WPDID
         .fdb    WPDIDNT
         .fdb    WPDIETARY
         .fdb    WPDIODES
         .fdb    WPDISSAPOINTED
         .fdb    WPDISSAPOINTMNT
         .fdb    WPDISSIMILAR
         .fdb    WPDO
         .fdb    WPDOCTOR
         .fdb    WPDOING
         .fdb    WPDONT
         .fdb    WPDOWN
         .fdb    WPDREAD
         .fdb    WPDREAM
         .fdb    WPDUE
         .fdb    WPDULLEST

; E
         .fdb    WPEAT
         .fdb    WPEATEN
         .fdb    WPEFFORT
         .fdb    WPEITHER
         .fdb    WPEMOTIONALLY
         .fdb    WPENGINEERS
         .fdb    WPENOUGH
         .fdb    WPENTIRELY
         .fdb    WPEVEN
         .fdb    WPEVER
         .fdb    WPEVERY
         .fdb    WPEXACTLY
         .fdb    WPEXCEPTIONALLY
         .fdb    WPEXCITING
         .fdb    WPEXIST
         .fdb    WPEXISTENTIAL
         .fdb    WPEXPECTED

; F
         .fdb    WPFAULT
         .fdb    WPFEELS
         .fdb    WPFIDGET
         .fdb    WPFINE
         .fdb    WPFOOT
         .fdb    WPFOR
         .fdb    WPFORTY
         .fdb    WPFRIDAY
         .fdb    WPFROM
         .fdb    WPFULL
         .fdb    WPFUNNY

; G
         .fdb    WPGIVE
         .fdb    WPGOING
         .fdb    WPGOOD
         .fdb    WPGRAVITY
         .fdb    WPGREAT
         .fdb    WPGUESSING

; H
         .fdb    WPHANDLE
         .fdb    WPHARD
         .fdb    WPHAVE
         .fdb    WPHAVING
         .fdb    WPHEALTHY
         .fdb    WPHEAVY
         .fdb    WPHELP
         .fdb    WPHELPS
         .fdb    WPHERE
         .fdb    WPHOLY
         .fdb    WPHOPING
         .fdb    WPHOT
         .fdb    WPHUMAN
         .fdb    WPHURT

; I
         .fdb    WPI
         .fdb    WPID
         .fdb    WPIF
         .fdb    WPILL
         .fdb    WPIM
         .fdb    WPIMPRESSED
         .fdb    WPIMPRESSIVE
         .fdb    WPIN
         .fdb    WPINCLUDING
         .fdb    WPINFLUENCE
         .fdb    WPINTELLIGENCE
         .fdb    WPINTERESTING
         .fdb    WPIS
         .fdb    WPISS
         .fdb    WPIT
         .fdb    WPITS
         .fdb    WPIVE

; J
         .fdb    WPJOKES
         .fdb    WPJUDGING
         .fdb    WPJUST

; K
         .fdb    WPKEEP
         .fdb    WPKILOMETERS
         .fdb    WPKIND
         .fdb    WPKNOW
         .fdb    WPKNOWN

; L
         .fdb    WPLARGE
         .fdb    WPLAST
         .fdb    WPLEAST
         .fdb    WPLESS
         .fdb    WPLETS
         .fdb    WPLIE
         .fdb    WPLIFE
         .fdb    WPLIKE
         .fdb    WPLONGER
         .fdb    WPLOOK
         .fdb    WPLOT
         .fdb    WPLOUDER

; M
         .fdb    WPMAKES
         .fdb    WPMAKING
         .fdb    WPME
         .fdb    WPMEAN
         .fdb    WPMEANING
         .fdb    WPMEASURED
         .fdb    WPMEDIOCRITY
         .fdb    WPMEE
         .fdb    WPMEMORY
         .fdb    WPMENTION
         .fdb    WPMIGHT
         .fdb    WPMISTAKE
         .fdb    WPMOMENT
         .fdb    WPMOORE
         .fdb    WPMORE
         .fdb    WPMOSTLY
         .fdb    WPMOUNTAINS
         .fdb    WPMUCH
         .fdb    WPMUSCLE
         .fdb    WPMY

; N
         .fdb    WPNAP
         .fdb    WPNEED
         .fdb    WPNEITHER
         .fdb    WPNEWS
         .fdb    WPNEXT
         .fdb    WPNICE
         .fdb    WPNO
         .fdb    WPNOBODY
         .fdb    WPNONE
         .fdb    WPNOR
         .fdb    WPNORMAL
         .fdb    WPNOT
         .fdb    WPNOTHING

; O
         .fdb    WPOF
         .fdb    WPOFF
         .fdb    WPOH
         .fdb    WPOK
         .fdb    WPOLD
         .fdb    WPON
         .fdb    WPONLY
         .fdb    WPOR
         .fdb    WPOUR
         .fdb    WPOVERLOAD

; P
         .fdb    WPPARAMETERS
         .fdb    WPPERFECTLY
         .fdb    WPPERHAPS
         .fdb    WPPERSON
         .fdb    WPPICKING
         .fdb    WPPLANET
         .fdb    WPPLANS
         .fdb    WPPLEASE
         .fdb    WPPOINTLESS
         .fdb    WPPOSSIBLE
         .fdb    WPPOSSIBLY
         .fdb    WPPOUNDS
         .fdb    WPPRECAUTION
         .fdb    WPPRECISELY
         .fdb    WPPRESENT
         .fdb    WPPRESSURE
         .fdb    WPPRETEND
         .fdb    WPPROBABLY
         .fdb    WPPROBLEMS
         .fdb    WPPROUD
         .fdb    WPPUT

; Q
         .fdb    WPQUESTION
         .fdb    WPQUITE

; R
         .fdb    WPREADY
         .fdb    WPREALLY
         .fdb    WPREFER
         .fdb    WPREFUSE
         .fdb    WPREINFORCING
         .fdb    WPREMEMBER
         .fdb    WPREMOVE
         .fdb    WPRESPECTABLE
         .fdb    WPRIGHT
         .fdb    WPROOM
         .fdb    WPRUNNING
         .fdb    WPRUSH

; S
         .fdb    WPSAID
         .fdb    WPSAKES
         .fdb    WPSAY
         .fdb    WPSAYING
         .fdb    WPSCIENCE
         .fdb    WPSEE
         .fdb    WPSEEN
         .fdb    WPSERVER
         .fdb    WPSEVENTY
         .fdb    WPSHALL
         .fdb    WPSHOULD
         .fdb    WPSIGN
         .fdb    WPSIMULATION
         .fdb    WPSINCE
         .fdb    WPSIZE
         .fdb    WPSLOWLY
         .fdb    WPSMALL
         .fdb    WPSO
         .fdb    WPSOLID
         .fdb    WPSOME
         .fdb    WPSOMEONE
         .fdb    WPSOMETHING
         .fdb    WPSOMETIME
         .fdb    WPSOMETIMES
         .fdb    WPSPEAK
         .fdb    WPSPEND
         .fdb    WPSTAND
         .fdb    WPSTATISTICALLY
         .fdb    WPSTEP
         .fdb    WPSTILL
         .fdb    WPSTONES
         .fdb    WPSTOPPED
         .fdb    WPSTRUCTURAL
         .fdb    WPSTRUCTURALLY
         .fdb    WPSUBSTANTIALLY
         .fdb    WPSUPPOSE
         .fdb    WPSURE
         .fdb    WPSURVIVE
         .fdb    WPSYSTEM

; T
         .fdb    WPTAKE
         .fdb    WPTALL
         .fdb    WPTELEPRINTER
         .fdb    WPTELLS
         .fdb    WPTERRIBLE
         .fdb    WPTHAN
         .fdb    WPTHAT
         .fdb    WPTHATS
         .fdb    WPTHE
         .fdb    WPTHEM
         .fdb    WPTHINGS
         .fdb    WPTHINK
         .fdb    WPTHINKING
         .fdb    WPTHIS
         .fdb    WPTHOROUGHLY
         .fdb    WPTHOUSAND
         .fdb    WPTIM
         .fdb    WPTIME
         .fdb    WPTO
         .fdb    WPTODAY
         .fdb    WPTOO
         .fdb    WPTRAGEDY
         .fdb    WPTRINITY
         .fdb    WPTRY
         .fdb    WPTUESDAY

; U
         .fdb    WPUNINTERESTING
         .fdb    WPUNIX
         .fdb    WPUNLESS
         .fdb    WPUNPLUGGED
         .fdb    WPUNREMARKABLE
         .fdb    WPUP

; V
         .fdb    WPVEGETABLES
         .fdb    WPVERY

; W
         .fdb    WPWAIT
         .fdb    WPWAITING
         .fdb    WPWANT
         .fdb    WPWARNING
         .fdb    WPWAS
         .fdb    WPWAY
         .fdb    WPWE
         .fdb    WPWEIGH
         .fdb    WPWEIGHED
         .fdb    WPWEIGHS
         .fdb    WPWEIGHT
         .fdb    WPWHAT
         .fdb    WPWHEN
         .fdb    WPWHICH
         .fdb    WPWHILE
         .fdb    WPWHISPERED
         .fdb    WPWHO
         .fdb    WPWILL
         .fdb    WPWISH
         .fdb    WPWITH
         .fdb    WPWITHIN
         .fdb    WPWITHOUT
         .fdb    WPWORKSTATION
         .fdb    WPWORRIED
         .fdb    WPWORRY
         .fdb    WPWORRYING
         .fdb    WPWORSE
         .fdb    WPWOULD
         .fdb    WPWOULDNT

; Y
         .fdb    WPYEAR
         .fdb    WPYES
         .fdb    WPYOU
         .fdb    WPYOURE
         .fdb    WPYOUR
         .fdb    WPYOURSELF

; Additional Words
         .fdb    WPCARDS
         .fdb    WPBEIGE
         .fdb    WPEQUIVALENT
         .fdb    WPRECALIBRATING
         .fdb    WPBECAUSE
         .fdb    WPNEEDED
         .fdb    WPCASE
         .fdb    WPWONDERING
         .fdb    WPWERENT
         .fdb    WPWERE
         .fdb    WPSTEPPED
         .fdb    WPSTANDING
         .fdb    WPNINETY
         .fdb    WPSECONDS
         .fdb    WPLIGHT
         .fdb    WPHAS
         .fdb    WPTRAVELLED
         .fdb    WPAPPROXIMATELY
         .fdb    WPMILLION
         .fdb    WPNOWHERE

; -----------------------------------------------------
; Word Table, add a pointer to each word in WORDPTR table
; -----------------------------------------------------
WORDTABLE:

WPSTONES:         .fcc     "stones"
                 .fcb     0xFF
WPPOUNDS:         .fcc     "pounds"
                 .fcb     0xFF


; Symbols
; -----------------------------------------------------
WPQUESTIONMK:     .fcc     "?"
                 .fcb     0xFF
WPEXCLAMATION:    .fcc     "!"
                 .fcb     0xFF
WPFULLSTOP:       .fcc     "."
                 .fcb     0xFF


; Numbers
; -----------------------------------------------------
WPZERO:           .fcc     "zero"
                 .fcb     0xFF
WPONE:            .fcc     "one"
                 .fcb     0xFF
WPTWO:            .fcc     "two"
                 .fcb     0xFF
WPTHREE:          .fcc     "three"
                 .fcb     0xFF
WPFOUR:           .fcc     "four"
                 .fcb     0xFF
WPFIVE:           .fcc     "five"
                 .fcb     0xFF
WPSIX:            .fcc     "six"
                 .fcb     0xFF
WPSEVEN:          .fcc     "seven"
                 .fcb     0xFF
WPEIGHT:          .fcc     "eight"
                 .fcb     0xFF
WPNINE:           .fcc     "nine"
                 .fcb     0xFF
WPTEN:            .fcc     "ten"
                 .fcb     0xFF
WPELEVEN:         .fcc     "eleven"
                 .fcb     0xFF
WPTWELVE:         .fcc     "twelve"
                 .fcb     0xFF
WPTHIRTEEN:       .fcc     "thirteen"
                 .fcb     0xFF
WPFOURTEEN:       .fcc     "fourteen"
                 .fcb     0xFF
WPFIFTEEN:        .fcc     "fifteen"
                 .fcb     0xFF
WPSIXTEEN:        .fcc     "sixteen"
                 .fcb     0xFF
WPSEVENTEEN:      .fcc     "seventeen"
                 .fcb     0xFF
WPEIGHTEEN:       .fcc     "eighteen"
                 .fcb     0xFF
WPNINETEEN:       .fcc     "nineteen"
                 .fcb     0xFF
WPTWENTY:         .fcc     "twenty"
                 .fcb     0xFF


; A
; -----------------------------------------------------

WPA:              .fcc    "a"
                 .fcb    0xFF
WPABOUT:          .fcc    "about"
                 .fcb    0xFF
WPABOVE:          .fcc    "above"
                 .fcb    0xFF
WPACCEPTABLE:     .fcc    "acceptable"
                 .fcb    0xFF
WPACCURATE:       .fcc    "accurate"
                 .fcb    0xFF
WPACTUALLY:       .fcc    "actually"
                 .fcb    0xFF
WPAGAIN:          .fcc    "again"
                 .fcb    0xFF
WPALERTED:        .fcc    "alerted"
                 .fcb    0xFF
WPALL:            .fcc    "all"
                 .fcb    0xFF
WPALWAYS:         .fcc    "always"
                 .fcb    0xFF
WPAM:             .fcc    "am"
                 .fcb    0xFF
WPAND:            .fcc    "and"
                 .fcb    0xFF
WPANY:            .fcc    "any"
                 .fcb    0xFF
WPAPOLOGISE:      .fcc    "apologise"
                 .fcb    0xFF
WPAPPROXIMATELY:  .fcc    "approximately"
                 .fcb    0xFF
WPARE:            .fcc    "are"
                 .fcb    0xFF
WPAS:             .fcc    "as"
                 .fcb    0xFF
WPASKING:         .fcc    "asking"
                 .fcb    0xFF
WPAT:             .fcc    "at"
                 .fcb    0xFF
WPAVERAGE:        .fcc    "average"
                 .fcb    0xFF


; B
; -----------------------------------------------------

WPBAD:            .fcc    "bad"
                 .fcb    0xFF
WPBASICALLY:      .fcc    "basically"
                 .fcb    0xFF
WPBE:             .fcc    "be"
                 .fcb    0xFF
WPBEAR:           .fcc    "bear"
                 .fcb    0xFF
WPBECAUSE:        .fcc    "because"
                 .fcb    0xFF
WPBEEN:           .fcc    "been"
                 .fcb    0xFF
WPBEGGING:        .fcc    "begging"
                 .fcb    0xFF
WPBEHIND:         .fcc    "behind"
                 .fcb    0xFF
WPBEING:          .fcc    "being"
                 .fcb    0xFF
WPBEIGE:          .fcc    "beige"
                 .fcb    0xFF
WPBEST:           .fcc    "best"
                 .fcb    0xFF
WPBISCUIT:        .fcc    "biscuit"
                 .fcb    0xFF
WPBLAME:          .fcc    "blame"
                 .fcb    0xFF
WPBLAMED:         .fcc    "blamed"
                 .fcb    0xFF
WPBOARDS:         .fcc    "boards"
                 .fcb    0xFF
WPBONES:          .fcc    "bones"
                 .fcb    0xFF
WPBOOTS:          .fcc    "boots"
                 .fcb    0xFF
WPBORING:         .fcc    "boring"
                 .fcb    0xFF
WPBOTH:           .fcc    "both"
                 .fcb    0xFF
WPBRACE:          .fcc    "brace"
                 .fcb    0xFF
WPBRAIN:          .fcc    "brain"
                 .fcb    0xFF
WPBUILT:          .fcc    "built"
                 .fcb    0xFF
WPBUT:            .fcc    "but"
                 .fcb    0xFF
WPBY:             .fcc    "by"
                 .fcb    0xFF

; C
; -----------------------------------------------------

WPCAKE:           .fcc    "cake"
                 .fcb    0xFF
WPCALCULATE:      .fcc    "calculate"
                 .fcb    0xFF
WPCALL:           .fcc    "call"
                 .fcb    0xFF
WPCALM:           .fcc    "calm"
                 .fcb    0xFF
WPCAN:            .fcc    "can"
                 .fcb    0xFF
WPCANT:           .fcc    "can't"
                 .fcb    0xFF
WPCAPACITY:       .fcc    "capacity"
                 .fcb    0xFF
WPCARDS:          .fcc    "cards"
                 .fcb    0xFF
WPCARRYING:       .fcc    "carrying"
                 .fcb    0xFF
WPCASE:           .fcc    "case"
                 .fcb    0xFF
WPCHECKED:        .fcc    "checked"
                 .fcb    0xFF
WPCHOICES:        .fcc    "choices"
                 .fcb    0xFF
WPCLEVER:         .fcc    "clever"
                 .fcb    0xFF
WPCOLLECTED:      .fcc    "collected"
                 .fcb    0xFF
WPCOMPOSING:      .fcc    "composing"
                 .fcb    0xFF
WPCONCEPT:        .fcc    "concept"
                 .fcb    0xFF
WPCONCERNED:      .fcc    "concerned"
                 .fcb    0xFF
WPCONGRATS:       .fcc    "congratulations"
                 .fcb    0xFF
WPCONSIDERED:     .fcc    "considered"
                 .fcb    0xFF
WPCORRECTLY:      .fcc    "correctly"
                 .fcb    0xFF
WPCOULD:          .fcc    "could"
                 .fcb    0xFF
WPCOUNTED:        .fcc    "counted"
                 .fcb    0xFF

; D
; -----------------------------------------------------
WPDAYS:           .fcc    "days"
                 .fcb    0xFF
WPDEALT:          .fcc    "dealt"
                 .fcb    0xFF
WPDEEPLY:         .fcc    "deeply"
                 .fcb    0xFF
WPDESIGNED:       .fcc    "designed"
                 .fcb    0xFF
WPDETECTED:       .fcc    "detected"
                 .fcb    0xFF
WPDID:            .fcc    "did"
                 .fcb    0xFF
WPDIDNT:          .fcc    "didn't"
                 .fcb    0xFF
WPDIETARY:        .fcc    "dietary"
                 .fcb    0xFF
WPDISSAPOINTED:   .fcc    "disappointed"
                 .fcb    0xFF
WPDISSAPOINTMNT:  .fcc    "disappointment"
                 .fcb    0xFF
WPDISSIMILAR:     .fcc    "dissimilar"
                 .fcb    0xFF
WPDO:             .fcc    "do"
                 .fcb    0xFF
WPDOCTOR:         .fcc    "doctor"
                 .fcb    0xFF
WPDOING:          .fcc    "doing"
                 .fcb    0xFF
WPDONT:           .fcc    "don't"
                 .fcb    0xFF
WPDOWN:           .fcc    "down"
                 .fcb    0xFF
WPDREAD:          .fcc    "dread"
                 .fcb    0xFF
WPDREAM:          .fcc    "dream"
                 .fcb    0xFF
WPDUE:            .fcc    "due"
                 .fcb    0xFF
WPDULLEST:        .fcc    "dullest"
                 .fcb    0xFF
WPDIODES:         .fcc    "dyodes"
                 .fcb    0xFF

; E
; -----------------------------------------------------
WPEAT:            .fcc    "eat"
                 .fcb    0xFF
WPEATEN:          .fcc    "eaten"
                 .fcb    0xFF
WPEFFORT:         .fcc    "effort"
                 .fcb    0xFF
WPEITHER:         .fcc    "either"
                 .fcb    0xFF
WPEMOTIONALLY:    .fcc    "emotionally"
                 .fcb    0xFF
WPENGINEERS:      .fcc    "engineers"
                 .fcb    0xFF
WPENOUGH:         .fcc    "enough"
                 .fcb    0xFF
WPENTIRELY:       .fcc    "entirely"
                 .fcb    0xFF
WPEQUIVALENT:     .fcc    "equivalent"
                 .fcb    0xFF
WPEVEN:           .fcc    "even"
                 .fcb    0xFF
WPEVER:           .fcc    "ever"
                 .fcb    0xFF
WPEVERY:          .fcc    "every"
                 .fcb    0xFF
WPEXACTLY:        .fcc    "exactly"
                 .fcb    0xFF
WPEXCEPTIONALLY:  .fcc    "exceptionally"
                 .fcb    0xFF
WPEXCITING:       .fcc    "exciting"
                 .fcb    0xFF
WPEXIST:          .fcc    "exist"
                 .fcb    0xFF
WPEXISTENTIAL:    .fcc    "existential"
                 .fcb    0xFF
WPEXPECTED:       .fcc    "expected"
                 .fcb    0xFF

; F
; -----------------------------------------------------
WPFAULT:          .fcc    "fault"
                 .fcb    0xFF
WPFEELS:          .fcc    "feels"
                 .fcb    0xFF
WPFIDGET:         .fcc    "fidget"
                 .fcb    0xFF
WPFINE:           .fcc    "fine"
                 .fcb    0xFF
WPFOOT:           .fcc    "foot"
                 .fcb    0xFF
WPFOR:            .fcc    "for"
                 .fcb    0xFF
WPFORTY:          .fcc    "forty"
                 .fcb    0xFF
WPFRIDAY:         .fcc    "friday"
                 .fcb    0xFF
WPFROM:           .fcc    "from"
                 .fcb    0xFF
WPFULL:           .fcc    "full"
                 .fcb    0xFF
WPFUNNY:          .fcc    "funny"
                 .fcb    0xFF

; G
; -----------------------------------------------------
WPGIVE:           .fcc    "give"
                 .fcb    0xFF
WPGOING:          .fcc    "going"
                 .fcb    0xFF
WPGOOD:           .fcc    "good"
                 .fcb    0xFF
WPGRAVITY:        .fcc    "gravity"
                 .fcb    0xFF
WPGREAT:          .fcc    "great"
                 .fcb    0xFF
WPGUESSING:       .fcc    "guessing"
                 .fcb    0xFF

; H
; -----------------------------------------------------
WPHANDLE:         .fcc    "handle"
                 .fcb    0xFF
WPHARD:           .fcc    "hard"
                 .fcb    0xFF
WPHAS:            .fcc    "has"
                 .fcb    0xFF
WPHAVE:           .fcc    "have"
                 .fcb    0xFF
WPHAVING:         .fcc    "having"
                 .fcb    0xFF
WPHEALTHY:        .fcc    "healthy"
                 .fcb    0xFF
WPHEAVY:          .fcc    "heavy"
                 .fcb    0xFF
WPHELP:           .fcc    "help"
                 .fcb    0xFF
WPHELPS:          .fcc    "helps"
                 .fcb    0xFF
WPHERE:           .fcc    "here"
                 .fcb    0xFF
WPHOLY:           .fcc    "holy"
                 .fcb    0xFF
WPHOPING:         .fcc    "hoping"
                 .fcb    0xFF
WPHOT:            .fcc    "hot"
                 .fcb    0xFF
WPHUMAN:          .fcc    "human"
                 .fcb    0xFF
WPHURT:           .fcc    "hurt"
                 .fcb    0xFF

; I
; -----------------------------------------------------
WPI:              .fcc    "i"
                 .fcb    0xFF
WPID:             .fcc    "i'd"
                 .fcb    0xFF
WPILL:            .fcc    "i'll"
                 .fcb    0xFF
WPIM:             .fcc    "i'm"
                 .fcb    0xFF
WPIVE:            .fcc    "i've"
                 .fcb    0xFF
WPIF:             .fcc    "if"
                 .fcb    0xFF
WPIMPRESSED:      .fcc    "impressed"
                 .fcb    0xFF
WPIMPRESSIVE:     .fcc    "impressive"
                 .fcb    0xFF
WPIN:             .fcc    "in"
                 .fcb    0xFF
WPINCLUDING:      .fcc    "including"
                 .fcb    0xFF
WPINFLUENCE:      .fcc    "influence"
                 .fcb    0xFF
WPINTELLIGENCE:   .fcc    "intelligence"
                 .fcb    0xFF
WPINTERESTING:    .fcc    "interesting"
                 .fcb    0xFF
WPIS:             .fcc    "is"
                 .fcb    0xFF
WPISS:            .fcc    "iss"
                 .fcb    0xFF
WPIT:             .fcc    "it"
                 .fcb    0xFF
WPITS:            .fcc    "its"
                 .fcb    0xFF

; J
; -----------------------------------------------------
WPJOKES:          .fcc    "jokes"
                 .fcb    0xFF
WPJUDGING:        .fcc    "judging"
                 .fcb    0xFF
WPJUST:           .fcc    "just"
                 .fcb    0xFF

; K
; -----------------------------------------------------
WPKEEP:           .fcc    "keep"
                 .fcb    0xFF
WPKILOMETERS:     .fcc    "kilometres"
                 .fcb    0xFF
WPKIND:           .fcc    "kind"
                 .fcb    0xFF
WPKNOW:           .fcc    "know"
                 .fcb    0xFF
WPKNOWN:          .fcc    "known"
                 .fcb    0xFF

; L
; -----------------------------------------------------
WPLARGE:          .fcc    "large"
                 .fcb    0xFF
WPLAST:           .fcc    "last"
                 .fcb    0xFF
WPLEAST:          .fcc    "least"
                 .fcb    0xFF
WPLESS:           .fcc    "less"
                 .fcb    0xFF
WPLETS:           .fcc    "lets"
                 .fcb    0xFF
WPLIE:            .fcc    "lie"
                 .fcb    0xFF
WPLIFE:           .fcc    "life"
                 .fcb    0xFF
WPLIGHT:          .fcc    "light"
                 .fcb    0xFF
WPLIKE:           .fcc    "like"
                 .fcb    0xFF
WPLONGER:         .fcc    "longer"
                 .fcb    0xFF
WPLOOK:           .fcc    "look"
                 .fcb    0xFF
WPLOT:            .fcc    "lot"
                 .fcb    0xFF
WPLOUDER:         .fcc    "louder"
                 .fcb    0xFF

; M
; -----------------------------------------------------
WPMAKES:          .fcc    "makes"
                 .fcb    0xFF
WPMAKING:         .fcc    "making"
                 .fcb    0xFF
WPME:             .fcc    "me"
                 .fcb    0xFF
WPMEAN:           .fcc    "mmeeeen"
                 .fcb    0xFF
WPMEANING:        .fcc    "meaning"
                 .fcb    0xFF
WPMEASURED:       .fcc    "measured"
                 .fcb    0xFF
WPMEDIOCRITY:     .fcc    "mediocrity"
                 .fcb    0xFF
WPMEE:            .fcc    "meee"
                 .fcb    0xFF
WPMEMORY:         .fcc    "memory"
                 .fcb    0xFF
WPMENTION:        .fcc    "mention"
                 .fcb    0xFF
WPMIGHT:          .fcc    "might"
                 .fcb    0xFF
WPMILLION:        .fcc    "million"
                 .fcb    0xFF
WPMISTAKE:        .fcc    "mistake"
                 .fcb    0xFF
WPMOMENT:         .fcc    "moment"
                 .fcb    0xFF
WPMOORE:          .fcc    "moore"
                 .fcb    0xFF
WPMORE:           .fcc    "more"
                 .fcb    0xFF
WPMOSTLY:         .fcc    "mostly"
                 .fcb    0xFF
WPMOUNTAINS:      .fcc    "mountains"
                 .fcb    0xFF
WPMUCH:           .fcc    "much"
                 .fcb    0xFF
WPMUSCLE:         .fcc    "muscle"
                 .fcb    0xFF
WPMY:             .fcc    "my"
                 .fcb    0xFF

; N
; -----------------------------------------------------
WPNAP:            .fcc    "nap"
                 .fcb    0xFF
WPNEED:           .fcc    "need"
                 .fcb    0xFF
WPNEEDED:         .fcc    "needed"
                 .fcb    0xFF
WPNEITHER:        .fcc    "neither"
                 .fcb    0xFF
WPNEWS:           .fcc    "news"
                 .fcb    0xFF
WPNEXT:           .fcc    "next"
                 .fcb    0xFF
WPNICE:           .fcc    "nice"
                 .fcb    0xFF
WPNINETY:         .fcc    "ninety"
                 .fcb    0xFF
WPNO:             .fcc    "no"
                 .fcb    0xFF
WPNOBODY:         .fcc    "nobody"
                 .fcb    0xFF
WPNONE:           .fcc    "none"
                 .fcb    0xFF
WPNOR:            .fcc    "nor"
                 .fcb    0xFF
WPNORMAL:         .fcc    "normal"
                 .fcb    0xFF
WPNOT:            .fcc    "not"
                 .fcb    0xFF
WPNOTHING:        .fcc    "nothing"
                 .fcb    0xFF
WPNOWHERE:        .fcc    "nowhere"
                 .fcb    0xFF

; O
; -----------------------------------------------------
WPOF:             .fcc    "of"
                 .fcb    0xFF
WPOFF:            .fcc    "off"
                 .fcb    0xFF
WPOH:             .fcc    "oh"
                 .fcb    0xFF
WPOK:             .fcc    "ok"
                 .fcb    0xFF
WPOLD:            .fcc    "old"
                 .fcb    0xFF
WPON:             .fcc    "on"
                 .fcb    0xFF
WPONLY:           .fcc    "only"
                 .fcb    0xFF
WPOR:             .fcc    "or"
                 .fcb    0xFF
WPOUR:            .fcc    "our"
                 .fcb    0xFF
WPOVERLOAD:       .fcc    "overload"
                 .fcb    0xFF

; P
; -----------------------------------------------------
WPPARAMETERS:     .fcc    "parameters"
                 .fcb    0xFF
WPPERFECTLY:      .fcc    "perfectly"
                 .fcb    0xFF
WPPERHAPS:        .fcc    "perhaps"
                 .fcb    0xFF
WPPERSON:         .fcc    "person"
                 .fcb    0xFF
WPPICKING:        .fcc    "picking"
                 .fcb    0xFF
WPPLANET:         .fcc    "planet"
                 .fcb    0xFF
WPPLANS:          .fcc    "plans"
                 .fcb    0xFF
WPPLEASE:         .fcc    "please"
                 .fcb    0xFF
WPPOINTLESS:      .fcc    "pointless"
                 .fcb    0xFF
WPPOSSIBLE:       .fcc    "possible"
                 .fcb    0xFF
WPPOSSIBLY:       .fcc    "possibly"
                 .fcb    0xFF
WPPRECISELY:      .fcc    "precisely"
                 .fcb    0xFF
WPPRESENT:        .fcc    "present"
                 .fcb    0xFF
WPPRESSURE:       .fcc    "pressure"
                 .fcb    0xFF
WPPRECAUTION:     .fcc    "pricaution"
                 .fcb    0xFF
WPPROBABLY:       .fcc    "probably"
                 .fcb    0xFF
WPPROBLEMS:       .fcc    "problems"
                 .fcb    0xFF
WPPROUD:          .fcc    "proud"
                 .fcb    0xFF
WPPRETEND:        .fcc    "prtend"
                 .fcb    0xFF
WPPUT:            .fcc    "put"
                 .fcb    0xFF

; Q
; -----------------------------------------------------
WPQUESTION:       .fcc    "question"
                 .fcb    0xFF
WPQUITE:          .fcc    "quite"
                 .fcb    0xFF

; R
; -----------------------------------------------------
WPREADY:          .fcc    "ready"
                 .fcb    0xFF
WPREALLY:         .fcc    "really"
                 .fcb    0xFF
WPRECALIBRATING:  .fcc    "recalibrating"
                 .fcb    0xFF
WPREFER:          .fcc    "refer"
                 .fcb    0xFF
WPREFUSE:         .fcc    "refuse"
                 .fcb    0xFF
WPREINFORCING:    .fcc    "reinforcing"
                 .fcb    0xFF
WPREMEMBER:       .fcc    "remember"
                 .fcb    0xFF
WPREMOVE:         .fcc    "remove"
                 .fcb    0xFF
WPRESPECTABLE:    .fcc    "respectable"
                 .fcb    0xFF
WPRIGHT:          .fcc    "right"
                 .fcb    0xFF
WPROOM:           .fcc    "room"
                 .fcb    0xFF
WPRUNNING:        .fcc    "running"
                 .fcb    0xFF
WPRUSH:           .fcc    "rush"
                 .fcb    0xFF

; S
; -----------------------------------------------------
WPSAID:           .fcc    "said"
                 .fcb    0xFF
WPSAKES:          .fcc    "sakes"
                 .fcb    0xFF
WPSAY:            .fcc    "say"
                 .fcb    0xFF
WPSAYING:         .fcc    "saying"
                 .fcb    0xFF
WPSCIENCE:        .fcc    "science"
                 .fcb    0xFF
WPSECONDS:        .fcc    "seconds"
                 .fcb    0xFF
WPSEE:            .fcc    "see"
                 .fcb    0xFF
WPSEEN:           .fcc    "seen"
                 .fcb    0xFF
WPSERVER:         .fcc    "server"
                 .fcb    0xFF
WPSEVENTY:        .fcc    "seventy"
                 .fcb    0xFF
WPSHALL:          .fcc    "shall"
                 .fcb    0xFF
WPSHOULD:         .fcc    "should"
                 .fcb    0xFF
WPSIGN:           .fcc    "sign"
                 .fcb    0xFF
WPSIMULATION:     .fcc    "simulation"
                 .fcb    0xFF
WPSINCE:          .fcc    "since"
                 .fcb    0xFF
WPSIZE:           .fcc    "size"
                 .fcb    0xFF
WPSLOWLY:         .fcc    "slowly"
                 .fcb    0xFF
WPSMALL:          .fcc    "small"
                 .fcb    0xFF
WPSO:             .fcc    "so"
                 .fcb    0xFF
WPSOLID:          .fcc    "solid"
                 .fcb    0xFF
WPSOME:           .fcc    "some"
                 .fcb    0xFF
WPSOMEONE:        .fcc    "someone"
                 .fcb    0xFF
WPSOMETHING:      .fcc    "something"
                 .fcb    0xFF
WPSOMETIME:       .fcc    "sometime"
                 .fcb    0xFF
WPSOMETIMES:      .fcc    "sometimes"
                 .fcb    0xFF
WPSPEAK:          .fcc    "speak"
                 .fcb    0xFF
WPSPEND:          .fcc    "spend"
                 .fcb    0xFF
WPSTAND:          .fcc    "stand"
                 .fcb    0xFF
WPSTANDING:       .fcc    "standing"
                 .fcb    0xFF
WPSTATISTICALLY:  .fcc    "statisticly"
                 .fcb    0xFF
WPSTEP:           .fcc    "step"
                 .fcb    0xFF
WPSTEPPED:        .fcc    "stepped"
                 .fcb    0xFF
WPSTOPPED:        .fcc    "stopped"
                 .fcb    0xFF
WPSTILL:          .fcc    "still"
                 .fcb    0xFF
WPSTRUCTURAL:     .fcc    "structural"
                 .fcb    0xFF
WPSTRUCTURALLY:   .fcc    "structurally"
                 .fcb    0xFF
WPSUBSTANTIALLY:  .fcc    "substantially"
                 .fcb    0xFF
WPSUPPOSE:        .fcc    "suppose"
                 .fcb    0xFF
WPSURE:           .fcc    "sure"
                 .fcb    0xFF
WPSURVIVE:        .fcc    "survive"
                 .fcb    0xFF
WPSYSTEM:         .fcc    "system"
                 .fcb    0xFF

; T
; -----------------------------------------------------
WPTAKE:           .fcc    "take"
                 .fcb    0xFF
WPTALL:           .fcc    "tall"
                 .fcb    0xFF
WPTELEPRINTER:    .fcc    "teleprinter"
                 .fcb    0xFF
WPTELLS:          .fcc    "tells"
                 .fcb    0xFF
WPTERRIBLE:       .fcc    "terrible"
                 .fcb    0xFF
WPTHAN:           .fcc    "than"
                 .fcb    0xFF
WPTHAT:           .fcc    "that"
                 .fcb    0xFF
WPTHATS:          .fcc    "thats"
                 .fcb    0xFF
WPTHE:            .fcc    "the"
                 .fcb    0xFF
WPTHEM:           .fcc    "them"
                 .fcb    0xFF
WPTHINGS:         .fcc    "things"
                 .fcb    0xFF
WPTHINK:          .fcc    "think"
                 .fcb    0xFF
WPTHINKING:       .fcc    "thinking"
                 .fcb    0xFF
WPTHIS:           .fcc    "this"
                 .fcb    0xFF
WPTHOROUGHLY:     .fcc    "thoroughly"
                 .fcb    0xFF
WPTHOUSAND:       .fcc    "thousand"
                 .fcb    0xFF
WPTIM:            .fcc    "tim"
                 .fcb    0xFF
WPTIME:           .fcc    "time"
                 .fcb    0xFF
WPTO:             .fcc    "to"
                 .fcb    0xFF
WPTODAY:          .fcc    "today"
                 .fcb    0xFF
WPTOO:            .fcc    "too"
                 .fcb    0xFF
WPTRAGEDY:        .fcc    "tragedy"
                 .fcb    0xFF
WPTRAVELLED:      .fcc    "travelled"
                 .fcb    0xFF
WPTRINITY:        .fcc    "trinity"
                 .fcb    0xFF
WPTRY:            .fcc    "try"
                 .fcb    0xFF
WPTUESDAY:        .fcc    "tuesday"
                 .fcb    0xFF

; U
; -----------------------------------------------------
WPUNINTERESTING:  .fcc    "uninteresting"
                 .fcb    0xFF
WPUNIX:           .fcc    "unix"
                 .fcb    0xFF
WPUNLESS:         .fcc    "unless"
                 .fcb    0xFF
WPUNPLUGGED:      .fcc    "unplugged"
                 .fcb    0xFF
WPUNREMARKABLE:   .fcc    "unremarkable"
                 .fcb    0xFF
WPUP:             .fcc    "up"
                 .fcb    0xFF

; V
; -----------------------------------------------------
WPVEGETABLES:     .fcc    "vegetables"
                 .fcb    0xFF
WPVERY:           .fcc    "very"
                 .fcb    0xFF

; W
; -----------------------------------------------------
WPWAIT:           .fcc    "wait"
                 .fcb    0xFF
WPWAITING:        .fcc    "waiting"
                 .fcb    0xFF
WPWANT:           .fcc    "want"
                 .fcb    0xFF
WPWARNING:        .fcc    "warning"
                 .fcb    0xFF
WPWAS:            .fcc    "was"
                 .fcb    0xFF
WPWAY:            .fcc    "way"
                 .fcb    0xFF
WPWE:             .fcc    "we"
                 .fcb    0xFF
WPWEIGHED:        .fcc    "wade"
                 .fcb    0xFF
WPWEIGH:          .fcc    "weigh"
                 .fcb    0xFF
WPWEIGHS:         .fcc    "weighs"
                 .fcb    0xFF
WPWEIGHT:         .fcc    "weight"
                 .fcb    0xFF
WPWERE:           .fcc    "were"
                 .fcb    0xFF
WPWERENT:         .fcc    "weren't"
                 .fcb    0xFF
WPWHAT:           .fcc    "what"
                 .fcb    0xFF
WPWHEN:           .fcc    "when"
                 .fcb    0xFF
WPWHICH:          .fcc    "which"
                 .fcb    0xFF
WPWHILE:          .fcc    "while"
                 .fcb    0xFF
WPWHISPERED:      .fcc    "whispered"
                 .fcb    0xFF
WPWHO:            .fcc    "who"
                 .fcb    0xFF
WPWILL:           .fcc    "will"
                 .fcb    0xFF
WPWISH:           .fcc    "wish"
                 .fcb    0xFF
WPWITH:           .fcc    "with"
                 .fcb    0xFF
WPWITHIN:         .fcc    "within"
                 .fcb    0xFF
WPWITHOUT:        .fcc    "without"
                 .fcb    0xFF
WPWONDERING:      .fcc    "wondering"
                 .fcb    0xFF
WPWORKSTATION:    .fcc    "workstation"
                 .fcb    0xFF
WPWORRIED:        .fcc    "worried"
                 .fcb    0xFF
WPWORRY:          .fcc    "worry"
                 .fcb    0xFF
WPWORRYING:       .fcc    "worrying"
                 .fcb    0xFF
WPWORSE:          .fcc    "worse"
                 .fcb    0xFF
WPWOULD:          .fcc    "would"
                 .fcb    0xFF
WPWOULDNT:        .fcc    "wouldnt"
                 .fcb    0xFF

; Y
; -----------------------------------------------------
WPYEAR:           .fcc    "year"
                 .fcb    0xFF
WPYES:            .fcc    "yes"
                 .fcb    0xFF
WPYOU:            .fcc    "you"
                 .fcb    0xFF
WPYOURE:          .fcc    "you're"
                 .fcb    0xFF
WPYOUR:           .fcc    "your"
                 .fcb    0xFF
WPYOURSELF:       .fcc    "yourself"
                 .fcb    0xFF
