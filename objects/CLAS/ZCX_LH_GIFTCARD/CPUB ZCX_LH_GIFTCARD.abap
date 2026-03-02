CLASS zcx_lh_giftcard DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_t100_message .
    INTERFACES if_t100_dyn_msg .

    DATA attribute1 TYPE string.


    CONSTANTS:
      BEGIN OF insufficient_balance,
        msgid TYPE symsgid      VALUE 'ZPRA_LOYALTYHUB',
        msgno TYPE symsgno      VALUE '001',
        attr1 TYPE scx_attrname VALUE 'ATTRIBUTE1',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF insufficient_balance,

      BEGIN OF no_gift_cards,
        msgid TYPE symsgid      VALUE 'ZPRA_LOYALTYHUB',
        msgno TYPE symsgno      VALUE '011',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF no_gift_cards.

    METHODS constructor
      IMPORTING
        !textid   LIKE if_t100_message=>t100key OPTIONAL
        !previous LIKE previous OPTIONAL
        !val1     TYPE string OPTIONAL.