  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor(
    previous = previous
    ).
    me->attribute1 = val1.
    CLEAR me->textid.
    if_t100_message~t100key = COND #( WHEN textid IS INITIAL
                                      THEN if_t100_message=>default_textid
                                      ELSE textid ).
  ENDMETHOD.