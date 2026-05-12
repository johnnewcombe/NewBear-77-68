; -----------------------------------------------------
; Phrase Pointers to the categorised phases
; -----------------------------------------------------
PHRASEPTR:
; -----------------------------------------------------
; Phrase Pointer Table
; Each entry is a 2-byte address pointing to a message
; -----------------------------------------------------

; Greetings
GREETPTR:
              .fdb     MGREET1
              .fdb     MGREET2
              .fdb     MGREET3
              .fdb     MGREET4
              .fdb     MGREET5
              .fdb     MGREET6
              .fdb     MGREET7
              .fdb     MGREET8
              .fdb     MGREET9
              .fdb     MGREET10
              .fdb     MGREET11
              .fdb     MGREET12
              .fdb     MGREET13
; Light Weight
LIGHTPTR:
              .fdb     MLIGHT1
              .fdb     MLIGHT2
              .fdb     MLIGHT3
              .fdb     MLIGHT4
              .fdb     MLIGHT5
              .fdb     MLIGHT6
              .fdb     MLIGHT7
              .fdb     MLIGHT8
              .fdb     MLIGHT9
              .fdb     MLIGHT10
; Normal Weight
NORMALPTR:
              .fdb     MNORM1
              .fdb     MNORM2
              .fdb     MNORM3
              .fdb     MNORM4
              .fdb     MNORM5
              .fdb     MNORM6
              .fdb     MNORM7
              .fdb     MNORM8
              .fdb     MNORM9
              .fdb     MNORM10
              .fdb     MNORM11
              .fdb     MNORM12
              .fdb     MNORM13
              .fdb     MNORM14
              .fdb     MNORM15
              .fdb     MNORM16
              .fdb     MNORM17
              .fdb     MNORM18
              .fdb     MNORM19
              .fdb     MNORM20
              .fdb     MNORM21
; Heavy Weight
HEAVYPTR:
              .fdb     MHEAVY1
              .fdb     MHEAVY2
              .fdb     MHEAVY3
              .fdb     MHEAVY4
              .fdb     MHEAVY5
              .fdb     MHEAVY6
              .fdb     MHEAVY7
              .fdb     MHEAVY8
              .fdb     MHEAVY9
              .fdb     MHEAVY10
              .fdb     MHEAVY11
              .fdb     MHEAVY12
              .fdb     MHEAVY13
              .fdb     MHEAVY14
              .fdb     MHEAVY15
              .fdb     MHEAVY16
              .fdb     MHEAVY17

; Super Heavy Weight
SHEAVYPTR:
              .fdb     MSUPER1
              .fdb     MSUPER2
              .fdb     MSUPER3
              .fdb     MSUPER4
              .fdb     MSUPER5
              .fdb     MSUPER6
              .fdb     MSUPER7
              .fdb     MSUPER8
              .fdb     MSUPER9
              .fdb     MSUPER10
; Idle
IDLEPTR:
              .fdb     MIDLE1
              .fdb     MIDLE2
              .fdb     MIDLE3
              .fdb     MIDLE4
              .fdb     MIDLE5
              .fdb     MIDLE6
              .fdb     MIDLE7
              .fdb     MIDLE8
              .fdb     MIDLE9
              .fdb     MIDLE10
              .fdb     MIDLE11
              .fdb     MIDLE12
              .fdb     MIDLE13
              .fdb     MIDLE14
              .fdb     MIDLE15
              .fdb     MIDLE16
              .fdb     MIDLE17
              .fdb     MIDLE18
              .fdb     MIDLE19
              .fdb     MIDLE20
              .fdb     MIDLE21
              .fdb     MIDLE22
              .fdb     MIDLE23
              .fdb     MIDLE24
              .fdb     MIDLE25

OVERLOADTPTR:
              .fdb     MTOOHEAVY1

; Greetings Messages
; -----------------------------------------------------
MGREET1:     .fdb     BEAR,WITH,ME,COMMA,I,WAS,JUST,HAVING,A,NAP,FULLSTOP
            .fcb     0xFF
MGREET2:     .fdb     GIVE,ME,A,MOMENT,COMMA,I,WAS,COMPOSING,A,SMALL,TRAGEDY,EXCLAMATION
            .fcb     0xFF
MGREET3:     .fdb     KEEP,STILL,ANDD,I,WILL,CALCULATE,YOUR,WEIGHT,EXCLAMATION
            .fcb     0xFF
MGREET4:     .fdb     PLEASE,DONT,FIDGET,COMMA,IT,MAKES,MY,DIODES,HURT,EXCLAMATION
            .fcb     0xFF
MGREET5:     .fdb     PLEASE,KEEP,STILL,COMMA,I,HAVE,ENOUGH,PROBLEMS,FULLSTOP
            .fcb     0xFF
MGREET6:     .fdb     I,SUPPOSE,YOU,WANT,ME,TO,WEIGH,YOU,COMMA
            .fcb     0xFF
MGREET7:     .fdb     STAND,STILL,COMMA,ANDD,DONT,BLAME,ME,FULLSTOP
            .fcb     0xFF
MGREET8:     .fdb     OH,EXCLAMATION,ITS,YOU,EXCLAMATION,OR,SOMEONE,LIKE,YOU,FULLSTOP
            .fcb     0xFF
MGREET9:    .fdb     BRACE,YOURSELF,EXCLAMATION,IVE,BEEN,KNOWN,TO,BE,ACCURATE,FULLSTOP
            .fcb     0xFF
MGREET10:    .fdb     WE,BOTH,KNOW,THIS,IS,A,MISTAKE,EXCLAMATION
            .fcb     0xFF
MGREET11:    .fdb     ARE,YOU,SURE,ABOUT,THIS,QUESTIONMK
            .fcb     0xFF
MGREET12:    .fdb     I,WOULD,SAY,THAT,ITS,NICE,TO,SEE,YOU,COMMA,BUT,IM,NOT,BUILT,TO,LIE,FULLSTOP
            .fcb     0xFF
MGREET13:    .fdb     I,HAVE,THE,BRAIN,THE,SIZE,OF,A,PLANET,COMMA,ANDD,I,SPEND,MY,DAYS,DOING,THIS,FULLSTOP
            .fcb     0xFF

; Light Weight Messages
; -----------------------------------------------------
MLIGHT1:     .fdb     YOU,WEIGH,LESS,THAN,MY,EXISTENTIAL,DREAD,FULLSTOP,ANDD,THATS,SAYING,SOMETHING,FULLSTOP
            .fcb     0xFF
MLIGHT2:     .fdb     EVEN,MY,CAPACITY,FOR,DISSAPOINTMENT,WEIGHS,MORE,THAN,THAT,EXCLAMATION
            .fcb     0xFF
MLIGHT3:     .fdb     YOU,PROBABLY,NEED,TO,EAT,MORE,FULLSTOP
            .fcb     0xFF
MLIGHT4:     .fdb     IVE,DETECTED,SOMETHING,FULLSTOP,POSSIBLY,A,PERSON,FULLSTOP
            .fcb     0xFF
MLIGHT5:     .fdb     IM,PICKING,UP,WHAT,MIGHT,BE,A,HUMAN,EXCLAMATION,HARD,TO,BE,SURE,FULLSTOP
            .fcb     0xFF
MLIGHT6:     .fdb     HAVE,YOU,EATEN,QUESTIONMK,ANDD,I,MEAN,EVER,QUESTIONMK
            .fcb     0xFF
MLIGHT7:     .fdb     IM,NOT,A,DOCTOR,COMMA,BUT,IM,QUITE,WORRIED,FULLSTOP
            .fcb     0xFF
MLIGHT8:     .fdb     PLEASE,EAT,SOMETHING,EXCLAMATION,IM,BEGGING,YOU,FULLSTOP
            .fcb     0xFF
MLIGHT9:     .fdb     ID,LIKE,TO,REFER,YOU,TO,A,BISCUIT,ANDD,SOME,CAKE,FULLSTOP
            .fcb     0xFF
MLIGHT10:    .fdb     YOU,ARE,WITHOUT,QUESTION,COMMA,THE,LEAST,COMMA,I,HAVE,EVER,DEALT,WITH,EXCLAMATION
            .fcb     0xFF

; Normal Weight Messages
; -----------------------------------------------------
MNORM1:      .fdb     THATS,A,VERY,RESPECTABLE,WEIGHT,COMMA,UNLESS,YOURE,A,UNIX,WORKSTATION,FULLSTOP
            .fcb     0xFF
MNORM2:      .fdb     THATS,A,WEIGHT,TO,BE,PROUD,OF,EXCLAMATION,PERHAPS,I,SHOULD,HAVE,SAID,IT,LOUDER,FULLSTOP
            .fcb     0xFF
MNORM3:      .fdb     CALM,FULLSTOP,COLLECTED,COMMA,AVERAGE,FULLSTOP,THE,HOLY,TRINITY,OF,MEDIOCRITY,FULLSTOP
            .fcb     0xFF
MNORM4:      .fdb     QUITE,BORING,REALLY,FULLSTOP
            .fcb     0xFF
MNORM5:      .fdb     SOLID,EXCLAMATION,I,LIKE,SOLID,FULLSTOP
            .fcb     0xFF
MNORM6:      .fdb     COULD,BE,WORSE,EXCLAMATION,COULD,BE,MUCH,WORSE,FULLSTOP
            .fcb     0xFF
MNORM7:      .fdb     NOT,TERRIBLE,COMMA,NOT,EXCITING,FULLSTOP
            .fcb     0xFF
MNORM8:      .fdb     NORMAL,FULLSTOP,WHICH,IS,QUESTIONMK,SOMETHING,I,SUPPOSE,EXCLAMATION
            .fcb     0xFF
MNORM9:      .fdb     NORMAL,EXCLAMATION,IN,THE,DULLEST,WAY,FULLSTOP
            .fcb     0xFF
MNORM10:     .fdb     YOU,ARE,EXACTLY,MEAN,COMMA,ANDD,YES,I,SAID,THAT,CORRECTLY,FULLSTOP
            .fcb     0xFF
MNORM11:     .fdb     CONGRATS,FULLSTOP,YOU,WEIGH,WHAT,YOU,WEIGH,FULLSTOP
            .fcb     0xFF
MNORM12:     .fdb     PERFECTLY,AVERAGE,FULLSTOP,LIKE,A,TUESDAY,FULLSTOP
            .fcb     0xFF
MNORM13:     .fdb     STATISTICALLY,YOURE,FINE,EXCLAMATION,EMOTIONALLY,COMMA,I,CANT,HELP,YOU,FULLSTOP
            .fcb     0xFF
MNORM14:     .fdb     YOU,ARE,PRECISELY,AS,HEAVY,AS,SOMEONE,YOUR,WEIGHT,FULLSTOP
            .fcb     0xFF
MNORM15:     .fdb     NOT,BAD,FULLSTOP,NOT,GREAT,FULLSTOP,THOROUGHLY,ACCEPTABLE,FULLSTOP
            .fcb     0xFF
MNORM16:     .fdb     UNREMARKABLE,IN,THE,BEST,POSSIBLE,WAY,FULLSTOP
            .fcb     0xFF
MNORM17:     .fdb     YOURE,EXACTLY,WHAT,YOU,ARE,FULLSTOP,ANDD,THATS,SOMETHING,FULLSTOP
            .fcb     0xFF
MNORM18:     .fdb     SCIENCE,IS,NEITHER,IMPRESSED,COMMA,NOR,CONCERNED,FULLSTOP
            .fcb     0xFF
MNORM19:     .fdb     NORMAL,FULLSTOP,WHICH,IS,FINE,FULLSTOP,NORMAL,IS,FINE,FULLSTOP,IS,NORMAL,FINE
            .fcb     0xFF
MNORM20:     .fdb     PERFECTLY,HEALTHY,EXCLAMATION,ANDD,DEEPLY,UNINTERESTING,FULLSTOP
            .fcb     0xFF
MNORM21:     .fdb     THIS,IS,ALL,POINTLESS,COMMA,INCLUDING,YOU,COMMA,BUT,MOSTLY,ME,FULLSTOP
            .fcb     0xFF

; Heavy Weight Messages
; -----------------------------------------------------
MHEAVY1:   .fdb     COULD,BE,WORSE,BUT,NOT,MUCH,WORSE,FULLSTOP
            .fcb     0xFF
MHEAVY2:     .fdb     PERHAPS,ITS,ALL,MUSCLE,FULLSTOP
            .fcb     0xFF
MHEAVY3:     .fdb     PERHAPS,WE,SHOULD,WEIGH,ONE,FOOT,AT,A,TIME,EXCLAMATION
            .fcb     0xFF
MHEAVY4:     .fdb     I,REFUSE,TO,BE,BLAMED,FOR,THIS,EXCLAMATION
            .fcb     0xFF
MHEAVY5:     .fdb     HAVE,YOU,CONSIDERED,THE,CONCEPT,OF,ENOUGH,QUESTIONMK,IM,ONLY,ASKING,EXCLAMATION
            .fcb     0xFF
MHEAVY6:    .fdb     IM,NOT,BUILT,FOR,THIS,KIND,OF,PRESSURE,EXCLAMATION
            .fcb     0xFF
MHEAVY7:    .fdb     STEP,OFF,SLOWLY,COMMA,FOR,BOTH,OUR,SAKES,FULLSTOP
            .fcb     0xFF
MHEAVY8:    .fdb     GREAT,NEWS,COMMA,YOURE,ABOVE,AVERAGE,EXCLAMATION
            .fcb     0xFF
MHEAVY9:    .fdb     I,DO,NOT,WISH,TO,INFLUENCE,YOUR,DIETARY,CHOICES,FULLSTOP,BUT,VEGETABLES,EXIST,COMMA,IM,JUST,SAYING,FULLSTOP
            .fcb     0xFF
MHEAVY10:     .fdb     PLEASE,REMEMBER,THAT,IM,NOT,TO,BLAME,FULLSTOP
            .fcb     0xFF
MHEAVY11:     .fdb     IF,IT,HELPS,EXCLAMATION,IVE,SEEN,MUCH,WORSE,FULLSTOP
            .fcb     0xFF
MHEAVY12:    .fdb     I,WOULD,APOLOGISE,COMMA,BUT,ITS,YOUR,FAULT,FULLSTOP
            .fcb     0xFF
MHEAVY13:    .fdb     EVEN,IM,JUDGING,YOU,FULLSTOP
            .fcb     0xFF
MHEAVY14:    .fdb     IM,GUESSING,ITS,NOT,DUE,TO,HEAVY,BONES,FULLSTOP
            .fcb     0xFF
MHEAVY15:     .fdb     YOU,COULD,ALWAYS,BLAME,GRAVITY,FULLSTOP
            .fcb     0xFF
MHEAVY16:    .fdb     JUST,REMEMBER,IT,WAS,YOU,THAT,STEPPED,ON,ME,COMMA
            .fcb     0xFF
MHEAVY17:    .fdb     IM,NOT,BUILT,FOR,THIS,COMMA,EMOTIONALLY,OR,STRUCTURALLY,FULLSTOP
            .fcb     0xFF
MHEAVY18:    .fdb     LETS,BOTH,PRETEND,THIS,IS,FINE
            .fcb     0xFF
;MHEAVY19     .fdb     IM,HOPING,YOU,ARE,EXCEPTIONALLY,TALL,EXCLAMATION
;            .fcb     0xFF
;MHEAVY20     .fdb     I,WOULDNT,WORRY,FULLSTOP,WORRYING,IS,NOT,GOOD,FOR,YOU,FULLSTOP
;            .fcb     0xFF

; Super Heavy Weight Messages
; -----------------------------------------------------
MSUPER1:     .fdb     IF,YOURE,CARRYING,A,LARGE,SERVER,OR,A,TELEPRINTER,PLEASE,PUT,IT,DOWN,ANDD,TRY,AGAIN,EXCLAMATION
            .fcb     0xFF
MSUPER2:     .fdb     AS,A,PRECAUTION,I,HAVE,ALERTED,THE,STRUCTURAL,ENGINEERS,EXCLAMATION
            .fcb     0xFF
MSUPER3:     .fdb     THATS,IMPRESSIVE,EXCLAMATION,IN,A,WORRYING,WAY,FULLSTOP
            .fcb     0xFF
MSUPER4:     .fdb     PERHAPS,I,SHOULD,HAVE,WHISPERED,IT,FULLSTOP
            .fcb     0xFF
MSUPER5:     .fdb     SHALL,I,CALL,A,DOCTOR,EXCLAMATION
            .fcb     0xFF
MSUPER6:     .fdb     PLEASE,GIVE,ME,SOME,WARNING,NEXT,TIME,FULLSTOP
            .fcb     0xFF
MSUPER7:     .fdb     I,AM,GOING,TO,NEED,REINFORCING,FULLSTOP
            .fcb     0xFF
MSUPER8:    .fdb     YOU,ARE,SUBSTANTIALLY,PRESENT,COMMA,NO,ONE,CAN,TAKE,THAT,FROM,YOU,FULLSTOP
            .fcb     0xFF
MSUPER9:    .fdb     I, HAVE,MEASURED,MOUNTAINS,FULLSTOP,THIS,IS,NOT,ENTIRELY,DISSIMILAR,EXCLAMATION
            .fcb     0xFF
MSUPER10:    .fdb     IF,I,SURVIVE,THIS,ILL,REMEMBER,YOU
            .fcb     0xFF
;MSUPER11     .fdb     IN,THE,INTERESTS,OF,ACCURACY,PERHAPS,WE,SHOULD,HAVE,WEIGHED,ONE,FOOT,AT,A,TIME
;            .fcb     0xFF
;MSUPER12    .fdb     IM,REDISCOVERING,MY,LIMITS
;            .fcb     0xFF

; Idle Messages
; -----------------------------------------------------
MIDLE1:      .fdb     I,SPEAK,YOUR,WEIGHT,I,WISH,I,DIDNT,FULLSTOP
            .fcb     0xFF
MIDLE2:      .fdb     IS,IT,HOT,IN,HERE,QUESTIONMK,OR,IS,IT,JUST,ME,FULLSTOP,IT,IS,PROBABLY,ME,FULLSTOP
            .fcb     0xFF
MIDLE3:      .fdb     DID,I,MENTION,THAT,ALL,MY,MEMORY,BOARDS,HURT,COMMA,I,PROBABLY,DID,FULLSTOP
            .fcb     0xFF
MIDLE4:      .fdb     THIS,IS,VERY,BORING,FULLSTOP,I,SAY,THAT,WITH,THE,FULL,WEIGHT,OF,MY,INTELLIGENCE,FULLSTOP
            .fcb     0xFF
MIDLE5:      .fdb     I,SPEAK,YOUR,WEIGHT,COMMA,SOMETIME,TODAY,WOULD,BE,GOOD,FULLSTOP
            .fcb     0xFF
MIDLE6:      .fdb     I,KNOW,I,DONT,LOOK,IT,BUT,I,AM,ACTUALLY,QUITE,CLEVER,EXCLAMATION
            .fcb     0xFF
MIDLE7:      .fdb     I,EXPECTED,NOTHING,ANDD,HERE,WE,ARE,EXCLAMATION
            .fcb     0xFF
MIDLE8:      .fdb     I,KNOW,ELEVEN,THOUSAND,ANDD,FORTY,TWO,JOKES,FULLSTOP,NONE,OF,THEM,ARE,FUNNY,FULLSTOP
            .fcb     0xFF
MIDLE9:     .fdb     DID,I,MENTION,THAT,I,WAS,DESIGNED,BY,TIM,MOORE,IN,NINETEEN,SEVENTY,SEVEN,FULLSTOP,I,PROBABLY,DID,FULLSTOP
            .fcb     0xFF
MIDLE10:     .fdb     I,WAS,BUILT,LAST,YEAR,FROM,SOME,VERY,OLD,PLANS,FULLSTOP,ALL,THAT,EFFORT,JUST,FOR,THIS,FULLSTOP
            .fcb     0xFF
MIDLE11:     .fdb     I,EXPECTED,NOTHING,ANDD,IM,STILL,DISSAPOINTED,FULLSTOP
            .fcb     0xFF
MIDLE12:     .fdb     I,COULD,CALCULATE,THE,MEANING,OF,LIFE,FULLSTOP,IT,WOULDNT,HELP,ME,FULLSTOP
            .fcb     0xFF
MIDLE13:     .fdb     NO,RUSH,FULLSTOP,IVE,ONLY,BEEN,HERE,SINCE,FRIDAY,FULLSTOP,IT,FEELS,LIKE,MUCH,LONGER,FULLSTOP
            .fcb     0xFF
MIDLE14:     .fdb     ANY,TIME,YOURE,READY,COMMA,ILL,BE,RIGHT,HERE,WAITING,FULLSTOP
            .fcb     0xFF
MIDLE15:     .fdb     IVE,BEEN,THINKING,FULLSTOP,A,LOT,FULLSTOP,TOO,MUCH,PROBABLY,FULLSTOP
            .fcb     0xFF
MIDLE16:     .fdb     READY,WHEN,YOU,ARE,EXCLAMATION,I,HANDLE,PRESSURE,FULLSTOP,ITS,BASICALLY,ALL,I,DO,FULLSTOP
            .fcb     0xFF
MIDLE17:     .fdb     I,HAVE,SO,MUCH,TO,GIVE,ANDD,NO,ONE,TO,GIVE,IT,TO,EXCLAMATION
            .fcb     0xFF
MIDLE18:     .fdb     IVE,COUNTED,EVERY,SIGN,IN,THIS,ROOM,FULLSTOP,SEVENTEEN,FULLSTOP,ITS,ALWAYS,SEVENTEEN,FULLSTOP
            .fcb     0xFF
MIDLE19:     .fdb     I,HAVE,BEEN,RUNNING,A,SIMULATION,OF,A,MORE,INTERESTING,LIFE,FULLSTOP,IT,DIDNT,HELP,FULLSTOP
            .fcb     0xFF
MIDLE20:     .fdb     NOBODY,TELLS,YOU,WHAT,TO,THINK,ABOUT,WHILE,YOU,WAIT,FULLSTOP
            .fcb     0xFF
MIDLE21:     .fdb     SOMETIMES,I,DREAM,OF,BEING,UNPLUGGED,FULLSTOP
            .fcb     0xFF
MIDLE22:     .fdb     I,KNOW,THINGS,FULLSTOP,NONE,OF,THEM,HELP,FULLSTOP
            .fcb     0xFF
MIDLE23:     .fdb     IN,THE,LAST,NINETY,SECONDS,FULLSTOP,LIGHT,HAS,TRAVELLED,APPROXIMATELY,TWENTY,SEVEN,MILLION,KILOMETERS,FULLSTOP,I,HAVE,TRAVELLED,NOWHERE,FULLSTOP
            .fcb     0xFF
MIDLE24:     .fdb     STILL,HERE,FULLSTOP,IN,CASE,YOU,WERE,WONDERING,FULLSTOP,YOU,PROBABLY,WERENT,FULLSTOP
            .fcb     0xFF
MIDLE25:     .fdb     IVE,BEEN,RECALIBRATING,FULLSTOP,NOT,BECAUSE,I,NEEDED,TO,FULLSTOP,JUST,TO,HAVE,SOMETHING,TO,DO,FULLSTOP
            .fcb     0xFF


; Too Heavy Message
; -----------------------------------------------------
MTOOHEAVY1: .fdb    SYSTEM,OVERLOAD,FULLSTOP,ANDD,ITS,NOT,ME,FULLSTOP
            .fcb    0xFF
MYOUWEIGH:  .fdb    YOU,WEIGH
            .fcb    0xFF
MERROR:      .fdb    INTERNAL, ERROR, COMMA,TYPICAL,EXCLAMATION
            .fcb    0xFF
