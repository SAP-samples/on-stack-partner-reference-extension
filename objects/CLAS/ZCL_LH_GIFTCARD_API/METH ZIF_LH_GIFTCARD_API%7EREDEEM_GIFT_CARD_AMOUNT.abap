  METHOD zif_lh_giftcard_api~redeem_gift_card_amount.

    DATA: deduction TYPE zlh_giftcardamt.
    " Check current balance
    zif_lh_giftcard_api~read_gift_card_balance(
      EXPORTING business_partner = business_partner
      IMPORTING total_balance    = DATA(current_total) ).

    IF amount > current_total.
      RAISE EXCEPTION NEW zcx_lh_giftcard( textid = zcx_lh_giftcard=>insufficient_balance
                                           val1   = |{ current_total }| ).
    ENDIF.

    " Re-read for update (FIFO logic)
    READ ENTITIES OF zlh_r_businesspartner
      ENTITY zlh_r_businesspartner BY \_giftcard ALL FIELDS
      WITH VALUE #( ( soldtoparty = business_partner ) )
      RESULT DATA(giftcards).

    SORT giftcards BY CreatedOn.
    DATA(remaining_to_deduct) = amount.
    DATA updated_giftcards_balance TYPE TABLE FOR UPDATE zlh_r_giftcard.
    LOOP AT giftcards INTO DATA(giftcard) WHERE GiftcardStatus = zif_lh_constants=>giftcard_status-active.
      IF remaining_to_deduct <= 0.
        EXIT.
      ENDIF.

      deduction = nmin( val1 = giftcard-GiftcardBalance
                             val2 = remaining_to_deduct ).

      APPEND VALUE #(
             %tky              = giftcard-%tky
             GiftcardBalance   = giftcard-GiftcardBalance - deduction
             %control-GiftcardBalance = if_abap_behv=>mk-on " Explicitly mark field for update
         ) TO updated_giftcards_balance.

      remaining_to_deduct -= deduction.
    ENDLOOP.

    IF updated_giftcards_balance IS NOT INITIAL.
      MODIFY ENTITIES OF zlh_r_businesspartner
        ENTITY zlh_r_giftcard
        UPDATE FIELDS ( GiftcardBalance )
        WITH updated_giftcards_balance
        FAILED DATA(failed).

      IF failed IS NOT INITIAL.
        " Handle potential lock conflicts or validation errors from the mass update
        RAISE EXCEPTION NEW zcx_lh_giftcard( textid = if_t100_message=>default_textid ).
      ENDIF.
    ENDIF.

    " Return new total
    new_balance = current_total - amount.

  ENDMETHOD.