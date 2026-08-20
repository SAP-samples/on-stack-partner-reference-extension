  METHOD zif_lh_giftcard_api~read_gift_card_balance.
    CLEAR: total_balance, currency.

    READ ENTITIES OF zlh_r_businesspartner
      ENTITY zlh_r_businesspartner
        BY \_giftcard
        ALL FIELDS
        WITH VALUE #( ( soldtoparty = business_partner ) )
      RESULT DATA(giftcards)
      FAILED DATA(failed).
    IF failed IS NOT INITIAL OR giftcards IS INITIAL.
      RAISE EXCEPTION NEW zcx_lh_giftcard( textid = zcx_lh_giftcard=>no_gift_cards ).
    ENDIF.

    DATA(lv_running_total) = CONV decfloat34( 0 ).

    LOOP AT giftcards INTO DATA(giftcard) WHERE giftcardstatus = zif_lh_constants=>giftcard_status-active.

      lv_running_total += giftcard-giftcardbalance.

      " Check for overflow after each addition
      IF lv_running_total > zif_lh_constants=>max_giftcard_value.
        " Cap at maximum value
        total_balance = zif_lh_constants=>max_giftcard_value.
        currency = giftcard-giftcardcurrency.
        RETURN. " Exit early - already at maximum
      ENDIF.
      currency = giftcard-giftcardcurrency.

    ENDLOOP.
    total_balance = lv_running_total.

  ENDMETHOD.