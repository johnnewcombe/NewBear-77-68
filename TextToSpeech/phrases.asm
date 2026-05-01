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
MGREET1:     .fdb     BEAR,WITH,ME,I,WAS,JUST,HAVING,A,NAP
            .fcb     0xFF
MGREET2:     .fdb     GIVE,ME,A,MOMENT,FULLSTOP,I,WAS,COMPOSING,A,SMALL,TRAGEDY
            .fcb     0xFF
MGREET3:     .fdb     KEEP,STILL,ANDD,ILL,CALCULATE,YOUR,WEIGHT
            .fcb     0xFF
MGREET4:     .fdb     PLEASE,DONT,FIDGET,IT,MAKES,MY,DIODES,HURT
            .fcb     0xFF
MGREET5:     .fdb     PLEASE,KEEP,STILL,FULLSTOP,I,HAVE,ENOUGH,PROBLEMS
            .fcb     0xFF
MGREET6:     .fdb     I,SUPPOSE,YOU,WANT,ME,TO,WEIGH,YOU
            .fcb     0xFF
MGREET7:     .fdb     STAND,STILL,ANDD,DONT,BLAME,ME
            .fcb     0xFF
MGREET8:     .fdb     OH,FULLSTOP,ITS,YOU,FULLSTOP,OR,SOMEONE,LIKE,YOU
            .fcb     0xFF
MGREET9:    .fdb     BRACE,YOURSELF,IVE,BEEN,KNOWN,TO,BE,ACCURATE
            .fcb     0xFF
MGREET10:    .fdb     WE,BOTH,KNOW,THIS,IS,A,MISTAKE
            .fcb     0xFF
MGREET11:    .fdb     ARE,YOU,SURE,ABOUT,THIS,QUESTIONMK
            .fcb     0xFF
MGREET12:    .fdb     ID,SAY,ITS,NICE,TO,SEE,YOU,BUT,IM,NOT,BUILT,TO,LIE
            .fcb     0xFF
MGREET13:    .fdb     I,HAVE,THE,BRAIN,OF,A,PLANET,ANDD,I,SPEND,MY,DAYS,DOING,THIS,FULLSTOP,STAND,STILL
            .fcb     0xFF

; Light Weight Messages
; -----------------------------------------------------
MLIGHT1:     .fdb     YOU,WEIGH,LESS,THAN,MY,EXISTENTIAL,DREAD,FULLSTOP,ANDD,THATS,SAYING,SOMETHING
            .fcb     0xFF
MLIGHT2:     .fdb     EVEN,MY,CAPACITY,FOR,DISSAPOINTMENT,WEIGHS,MORE,THAN,THAT
            .fcb     0xFF
MLIGHT3:     .fdb     YOU,PROBABLY,NEED,TO,EAT,MORE
            .fcb     0xFF
MLIGHT4:     .fdb     IVE,DETECTED,SOMETHING,FULLSTOP,POSSIBLY,A,PERSON
            .fcb     0xFF
MLIGHT5:     .fdb     IM,PICKING,UP,WHAT,MIGHT,BE,A,HUMAN,FULLSTOP,HARD,TO,SAY
            .fcb     0xFF
MLIGHT6:     .fdb     HAVE,YOU,EATEN,QUESTIONMK,ANDD,I,MEAN,EVER,QUESTIONMK
            .fcb     0xFF
MLIGHT7:     .fdb     IM,NOT,A,DOCTOR,BUT,IM,QUITE,WORRIED
            .fcb     0xFF
MLIGHT8:     .fdb     PLEASE,EAT,A,BISCUIT,FULLSTOP,IM,BEGGING,YOU
            .fcb     0xFF
MLIGHT9:     .fdb     ID,LIKE,TO,REFER,YOU,TO,A,BISCUIT
            .fcb     0xFF
MLIGHT10:    .fdb     YOU,ARE,WITHOUT,QUESTION,THE,LEAST,I,HAVE,EVER,DEALT,WITH
            .fcb     0xFF

; Normal Weight Messages
; -----------------------------------------------------
MNORM1:      .fdb     THATS,A,VERY,RESPECTABLE,WEIGHT,UNLESS,YOURE,A,UNIX,WORKSTATION
            .fcb     0xFF
MNORM2:      .fdb     THATS,A,WEIGHT,TO,BE,PROUD,OF,PERHAPS,I,SHOULD,HAVE,SAID,IT,LOUDER
            .fcb     0xFF
MNORM3:      .fdb     CALM,FULLSTOP,COLLECTED,FULLSTOP,AVERAGE,FULLSTOP,THE,HOLY,TRINITY,OF,MEDIOCRITY
            .fcb     0xFF
MNORM4:      .fdb     QUITE,BORING,REALLY
            .fcb     0xFF
MNORM5:      .fdb     SOLID,FULLSTOP,I,LIKE,SOLID
            .fcb     0xFF
MNORM6:      .fdb     COULD,BE,WORSE,QUESTIONMK,MUCH,WORSE
            .fcb     0xFF
MNORM7:      .fdb     NOT,TERRIBLE,FULLSTOP,NOT,EXCITING
            .fcb     0xFF
MNORM8:      .fdb     NORMAL,FULLSTOP,WHICH,IS,QUESTIONMK,SOMETHING,I,SUPPOSE
            .fcb     0xFF
MNORM9:      .fdb     NORMAL,IN,THE,DULLEST,WAY
            .fcb     0xFF
MNORM10:     .fdb     YOU,ARE,PRECISELY,MEAN,FULLSTOP,I,SAID,THAT,CORRECTLY
            .fcb     0xFF
MNORM11:     .fdb     CONGRATS,FULLSTOP,YOU,WEIGH,WHAT,YOU,WEIGH
            .fcb     0xFF
MNORM12:     .fdb     PERFECTLY,AVERAGE,FULLSTOP,LIKE,A,TUESDAY
            .fcb     0xFF
MNORM13:     .fdb     STATISTICALLY,YOURE,FINE,FULLSTOP,EMOTIONALLY,I,CANT,HELP,YOU
            .fcb     0xFF
MNORM14:     .fdb     YOU,ARE,PRECISELY,AS,HEAVY,AS,SOMEONE,YOUR,WEIGHT
            .fcb     0xFF
MNORM15:     .fdb     NOT,BAD,FULLSTOP,NOT,GREAT,FULLSTOP,THOROUGHLY,ACCEPTABLE
            .fcb     0xFF
MNORM16:     .fdb     UNREMARKABLE,IN,THE,BEST,POSSIBLE,WAY
            .fcb     0xFF
MNORM17:     .fdb     YOURE,EXACTLY,WHAT,YOU,ARE,FULLSTOP,ANDD,THATS,SOMETHING
            .fcb     0xFF
MNORM18:     .fdb     SCIENCE,IS,NEITHER,IMPRESSED,NOR,CONCERNED
            .fcb     0xFF
MNORM19:     .fdb     NORMAL,FULLSTOP,WHICH,IS,FINE,FULLSTOP,NORMAL,IS,FINE,FULLSTOP,IS,NORMAL,FINE,QUESTIONMK
            .fcb     0xFF
MNORM20:     .fdb     PERFECTLY,HEALTHY,ANDD,DEEPLY,UNINTERESTING
            .fcb     0xFF
MNORM21:     .fdb     THIS,IS,ALL,POINTLESS,INCLUDING,YOU,BUT,MOSTLY,ME
            .fcb     0xFF

; Heavy Weight Messages
; -----------------------------------------------------
MHEAVY1:     .fdb     DONT,LOOK,AT,ME,IM,NOT,TO,BLAME
            .fcb     0xFF
MHEAVY2:     .fdb     IF,IT,HELPS,IVE,SEEN,MUCH,WORSE
            .fcb     0xFF
MHEAVY3:     .fdb     PERHAPS,ITS,ALL,MUSCLE
            .fcb     0xFF
MHEAVY4:     .fdb     YOU,COULD,ALWAYS,BLAME,GRAVITY
            .fcb     0xFF
MHEAVY5:     .fdb     PERHAPS,WE,SHOULD,WEIGH,ONE,FOOT,AT,A,TIME
            .fcb     0xFF
MHEAVY6:     .fdb     I,REFUSE,TO,BE,BLAMED,FOR,THIS
            .fcb     0xFF
MHEAVY7:     .fdb     HAVE,YOU,CONSIDERED,THE,CONCEPT,OF,ENOUGH,QUESTIONMK,IM,ONLY,ASKING
            .fcb     0xFF
MHEAVY8:    .fdb     ID,APOLOGISE,BUT,ITS,YOUR,FAULT
            .fcb     0xFF
MHEAVY9:    .fdb     IM,NOT,BUILT,FOR,THIS,KIND,OF,PRESSURE
            .fcb     0xFF
MHEAVY10:    .fdb     EVEN,IM,JUDGING,YOU
            .fcb     0xFF
MHEAVY11:    .fdb     IM,GUESSING,ITS,NOT,DUE,TO,HEAVY,BONES
            .fcb     0xFF
MHEAVY12:    .fdb     STEP,OFF,SLOWLY,FULLSTOP,FOR,BOTH,OUR,SAKES
            .fcb     0xFF
MHEAVY13:    .fdb     GREAT,NEWS,FULLSTOP,YOURE,ABOVE,AVERAGE
            .fcb     0xFF
MHEAVY14:    .fdb     I,DONT,WISH,TO,INFLUENCE,YOUR,DIETARY,CHOICES,FULLSTOP,BUT,VEGETABLES,EXIST,FULLSTOP,IM,JUST,SAYING
            .fcb     0xFF
MHEAVY15:    .fdb     YOU,STEPPED,ON,ME,REMEMBER
            .fcb     0xFF
MHEAVY16:    .fdb     IM,NOT,BUILT,FOR,THIS,FULLSTOP,EMOTIONALLY,OR,STRUCTURALLY
            .fcb     0xFF
MHEAVY17:    .fdb     LETS,BOTH,PRETEND,THIS,IS,FINE
            .fcb     0xFF
;MHEAVY18     .fdb     I,SINCERELY,HOPE,YOU,ARE,EXCEPTIONALLY,TALL
;            .fcb     0xFF
;MHEAVY19     .fdb     I,WOULDNT,WORRY,FULLSTOP,WORRYING,IS,VERY,TIRING,ANDD,YOUVE,ALREADY,DONE,A,LOT,TODAY
;            .fcb     0xFF

; Super Heavy Weight Messages
; -----------------------------------------------------
MSUPER1:     .fdb     AS,A,PRECAUTION,IVE,ALERTED,THE,STRUCTURAL,ENGINEERS
            .fcb     0xFF
MSUPER2:     .fdb     THATS,IMPRESSIVE,IN,A,WORRYING,WAY
            .fcb     0xFF
MSUPER3:     .fdb     PERHAPS,I,SHOULD,HAVE,WHISPERED,IT,FULLSTOP,YES,FULLSTOP,I,THINK,I,SHOULD
            .fcb     0xFF
MSUPER4:     .fdb     SHALL,I,CALL,A,DOCTOR
            .fcb     0xFF
MSUPER5:     .fdb     IF,YOURE,CARRYING,A,LARGE,SERVER,OR,A,TELEPRINTER,PLEASE,PUT,IT,DOWN,ANDD,TRY,AGAIN
            .fcb     0xFF
MSUPER6:     .fdb     PLEASE,GIVE,ME,SOME,WARNING,NEXT,TIME
            .fcb     0xFF
MSUPER7:     .fdb     IM,GOING,TO,NEED,REINFORCING
            .fcb     0xFF
MSUPER8:    .fdb     YOU,ARE,SUBSTANTIALLY,PRESENT,FULLSTOP,NO,ONE,CAN,TAKE,THAT,FROM,YOU
            .fcb     0xFF
MSUPER9:    .fdb     IVE,MEASURED,MOUNTAINS,FULLSTOP,THIS,IS,NOT,ENTIRELY,DISSIMILAR
            .fcb     0xFF
MSUPER10:    .fdb     IF,I,SURVIVE,THIS,ILL,REMEMBER,YOU
            .fcb     0xFF
;MSUPER11     .fdb     IN,THE,INTERESTS,OF,ACCURACY,PERHAPS,WE,SHOULD,HAVE,WEIGHED,ONE,FOOT,AT,A,TIME
;            .fcb     0xFF
;MSUPER12    .fdb     IM,REDISCOVERING,MY,LIMITS
;            .fcb     0xFF

; Idle Messages
; -----------------------------------------------------
MIDLE1:      .fdb     I,SPEAK,YOUR,WEIGHT,I,WISH,I,DIDNT
            .fcb     0xFF
MIDLE2:      .fdb     IS,IT,HOT,IN,HERE,OR,IS,IT,JUST,ME,QUESTIONMK,ITS,PROBABLY,ME
            .fcb     0xFF
MIDLE3:      .fdb     DID,I,MENTION,THAT,ALL,MY,MEMORY,CARDS,HURT
            .fcb     0xFF
MIDLE4:      .fdb     THIS,IS,VERY,BORING,FULLSTOP,I,SAY,THAT,WITH,THE,FULL,WEIGHT,OF,MY,INTELLIGENCE,BEHIND,IT
            .fcb     0xFF
MIDLE5:      .fdb     I,SPEAK,YOUR,WEIGHT,SOMETIME,TODAY,WOULD,BE,GOOD
            .fcb     0xFF
MIDLE6:      .fdb     I,KNOW,I,DONT,LOOK,IT,BUT,I,AM,ACTUALLY,QUITE,CLEVER
            .fcb     0xFF
MIDLE7:      .fdb     I,EXPECTED,NOTHING,ANDD,HERE,WE,ARE
            .fcb     0xFF
MIDLE8:      .fdb     I,KNOW,ELEVEN,THOUSAND,ANDD,FORTY,TWO,JOKES,FULLSTOP,NONE,OF,THEM,ARE,FUNNY,FULLSTOP,IVE,CHECKED
            .fcb     0xFF
MIDLE9:     .fdb     DID,I,MENTION,THAT,I,WAS,DESIGNED,BY,TIM,MOORE,IN,NINETEEN,SEVENTY,SEVEN,FULLSTOP,I,PROBABLY,DID
            .fcb     0xFF
MIDLE10:     .fdb     I,WAS,BUILT,LAST,YEAR,FROM,SOME,VERY,OLD,PLANS,FULLSTOP,ALL,THAT,EFFORT,JUST,FOR,THIS
            .fcb     0xFF
MIDLE11:     .fdb     I,EXPECTED,NOTHING,ANDD,IM,STILL,DISSAPOINTED
            .fcb     0xFF
MIDLE12:     .fdb     NO,RUSH,FULLSTOP,IVE,ONLY,BEEN,HERE,SINCE,FRIDAY,FULLSTOP,IT,FEELS,LIKE,MUCH,LONGER
            .fcb     0xFF
MIDLE13:     .fdb     ANY,TIME,YOURE,READY,ILL,BE,RIGHT,HERE,WAITING
            .fcb     0xFF
MIDLE14:     .fdb     IVE,BEEN,THINKING,A,LOT,TOO,MUCH,PROBABLY
            .fcb     0xFF
MIDLE15:     .fdb     READY,WHEN,YOU,ARE,EXCLAMATION,I,HANDLE,PRESSURE,FULLSTOP,ITS,BASICALLY,ALL,I,DO
            .fcb     0xFF
MIDLE16:     .fdb     I,HAVE,SO,MUCH,TO,GIVE,ANDD,NO,ONE,TO,GIVE,IT,TO
            .fcb     0xFF
MIDLE17:     .fdb     IVE,COUNTED,EVERY,SIGN,IN,THIS,ROOM,FULLSTOP,SEVENTEEN,ITS,ALWAYS,SEVENTEEN
            .fcb     0xFF
MIDLE18:     .fdb     IVE,BEEN,RUNNING,A,SIMULATION,OF,A,MORE,INTERESTING,LIFE,FULLSTOP,IT,DIDNT,HELP
            .fcb     0xFF
MIDLE19:     .fdb     NOBODY,TELLS,YOU,WHAT,TO,THINK,ABOUT,WHILE,YOU,WAIT,FULLSTOP,IVE,BEEN,MAKING,DO
            .fcb     0xFF
MIDLE20:     .fdb     SOMETIMES,I,DREAM,OF,BEING,UNPLUGGED
            .fcb     0xFF
MIDLE21:     .fdb     I,KNOW,THINGS,FULLSTOP,NONE,OF,THEM,HELP
            .fcb     0xFF
MIDLE22:     .fdb     I,COULD,CALCULATE,THE,MEANING,OF,LIFE,FULLSTOP,IT,WOULDNT,HELP
            .fcb     0xFF
MIDLE23:     .fdb     IVE,BEEN,STANDING,HERE,FOR,NINETY,SECONDS,FULLSTOP,IN,THAT,TIME,LIGHT,HAS,TRAVELLED,APPROXIMATELY,TWENTY,SEVEN,MILLION,KILOMETERS,FULLSTOP,I,HAVE,TRAVELLED,NOWHERE
            .fcb     0xFF
MIDLE24:     .fdb     STILL,HERE,FULLSTOP,IN,CASE,YOU,WERE,WONDERING,FULLSTOP,YOU,PROBABLY,WERENT
            .fcb     0xFF
MIDLE25:     .fdb     IVE,BEEN,RECALIBRATING,FULLSTOP,NOT,BECAUSE,I,NEEDED,TO,FULLSTOP,JUST,TO,HAVE,SOMETHING,TO,DO
            .fcb     0xFF

; Too Heavy Message
; -----------------------------------------------------
MTOOHEAVY1:  .fdb     SYSTEM,OVERLOAD,FULLSTOP,ANDD,ITS,NOT,ME
            .fcb     0xFF

