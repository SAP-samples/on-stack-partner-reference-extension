CLASS zcl_lh_giftcard_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .
  PUBLIC SECTION.
    CLASS-METHODS:
      read_gift_card_balance
        IMPORTING
          business_partner TYPE zlh_businesspartner
        EXPORTING
          total_balance    TYPE zlh_giftcardamt
          currency         TYPE zlh_currency
        RAISING
          zcx_lh_giftcard,

      redeem_gift_card_amount
        IMPORTING
          business_partner TYPE zlh_businesspartner
          amount           TYPE zlh_giftcardamt
          currency         TYPE zlh_currency
        EXPORTING
          new_balance      TYPE zlh_giftcardamt
        RAISING
          zcx_lh_giftcard.