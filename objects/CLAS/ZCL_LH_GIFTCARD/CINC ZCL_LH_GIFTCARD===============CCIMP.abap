CLASS lhc_zlh_r_giftcard DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setGiftcardBalanceOnCreate FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zlh_r_giftcard~setGiftcardBalanceOnCreate.
    METHODS precheck_update FOR PRECHECK
      IMPORTING keys FOR UPDATE zlh_r_giftcard.
    METHODS addtransactiononcreate FOR DETERMINE ON SAVE
      IMPORTING keys FOR zlh_r_giftcard~addtransactiononcreate.
    METHODS validategiftcardfields FOR VALIDATE ON SAVE
      IMPORTING keys FOR zlh_r_giftcard~validategiftcardfields.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zlh_r_giftcard RESULT result.
    METHODS validategiftcardbalance FOR VALIDATE ON SAVE
      IMPORTING keys FOR zlh_r_giftcard~validategiftcardbalance.
    METHODS setgiftcardfieldsoncreate FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zlh_r_giftcard~setgiftcardfieldsoncreate.

ENDCLASS.

CLASS lhc_zlh_r_giftcard IMPLEMENTATION.

  METHOD setGiftcardBalanceOnCreate.
    DATA: update_giftcards TYPE TABLE FOR UPDATE zlh_r_giftcard.
    READ ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
       ENTITY zlh_r_giftcard
         ALL FIELDS
         WITH CORRESPONDING #( keys )
      RESULT DATA(giftcards).

    LOOP AT giftcards ASSIGNING FIELD-SYMBOL(<giftcard>).
      IF <giftcard>-GiftCardValue IS NOT INITIAL.
        APPEND VALUE #(
          %tky              = <giftcard>-%tky
          GiftCardBalance   = <giftcard>-GiftCardValue
        ) TO update_giftcards.
      ENDIF.
    ENDLOOP.

    IF update_giftcards IS NOT INITIAL.
      MODIFY ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
        ENTITY zlh_r_giftcard
        UPDATE FIELDS ( giftcardbalance )
        WITH update_giftcards.
    ENDIF.

  ENDMETHOD.

  METHOD precheck_update.

    READ ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
    ENTITY zlh_r_giftcard
      FIELDS ( BusinessPartner )
      WITH CORRESPONDING #( keys )
    RESULT DATA(giftcards_data).

" used group to remove duplicates when called from Gift card API for multiple gift cards redemption of same BP
    DATA(bp_keys) = VALUE zcl_lh_loyalty_points=>business_partner_keys(
      FOR GROUPS OF <group> IN giftcards_data
      WHERE ( BusinessPartner IS NOT INITIAL )
      GROUP BY ( bp = <group>-BusinessPartner )
      ( sold_to_party = <group>-BusinessPartner )
      ).
    DATA(loyalty_results) = COND #( WHEN bp_keys IS NOT INITIAL
                                    THEN zcl_lh_loyalty_points=>get_points( bp_keys )
                                    ELSE VALUE zcl_lh_loyalty_points=>loyalty_points( ) ).
    LOOP AT keys REFERENCE INTO DATA(key).

      IF key->%control-GiftcardValue = if_abap_behv=>mk-on.
        " Validation Logic
        IF key->GiftcardValue LE 0.
          " Block the update for this specific entry
          APPEND VALUE #( %tky = key->%tky ) TO failed-zlh_r_giftcard.
          APPEND VALUE #( %tky = key->%tky
                          %msg = new_message(
                                   id       = 'ZPRA_LOYALTYHUB'
                                   number   = '013'
                                   severity = if_abap_behv_message=>severity-error
                     )
                          %element-GiftcardValue = if_abap_behv=>mk-on ) TO reported-zlh_r_giftcard.
        ENDIF.

        IF key->GiftcardValue > zif_lh_constants=>max_giftcard_value.
          APPEND VALUE #( %tky = key->%tky ) TO failed-zlh_r_giftcard.
          APPEND VALUE #(
            %tky = key->%tky
            %msg = new_message(
                     id       = 'ZPRA_LOYALTYHUB'
                     number   = '015'
                     severity = if_abap_behv_message=>severity-error
                     v1       = |{ key->GiftcardValue DECIMALS = 2 }|
                     v2       = |{ zif_lh_constants=>max_giftcard_value DECIMALS = 2 }|
                   )
            %element-GiftcardValue = if_abap_behv=>mk-on
          ) TO reported-zlh_r_giftcard.
          CONTINUE.
        ENDIF.

        DATA(giftcard_data) = VALUE #( giftcards_data[ KEY id %tky = key->%tky ] OPTIONAL ).
        IF giftcard_data-BusinessPartner IS INITIAL.
          CONTINUE.
        ENDIF.
        DATA(available_points) = COND zlh_loyaltypoint(
       LET loyalty = VALUE zcl_lh_loyalty_points=>loyalty_point(
                       loyalty_results[ business_partner = giftcard_data-BusinessPartner ] OPTIONAL )
       IN WHEN loyalty-business_partner IS NOT INITIAL
          THEN loyalty-available
          ELSE 0
     ).
        IF key->GiftcardValue > available_points.
          " Block the update for this specific entry
          APPEND VALUE #( %tky = key->%tky ) TO failed-zlh_r_giftcard.
          APPEND VALUE #(
            %tky = key->%tky
            %msg = new_message(
                     id       = 'ZPRA_LOYALTYHUB'
                     number   = '002'
                     severity = if_abap_behv_message=>severity-error
                     v1       = |{ key->GiftcardValue }|
                     v2       = |{ available_points }|
                   )
            %element-giftcardvalue = if_abap_behv=>mk-on
          ) TO reported-zlh_r_giftcard.

        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD addTransactionOnCreate.

    DATA: transaction TYPE TABLE FOR CREATE ZLH_R_BusinessPartner\_Transactions.
    READ ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
        ENTITY zlh_r_giftcard
          FIELDS ( BusinessPartner )
          WITH CORRESPONDING #( keys )
        RESULT DATA(giftcards).

    LOOP AT giftcards ASSIGNING FIELD-SYMBOL(<giftcard>).
      APPEND INITIAL LINE TO transaction ASSIGNING FIELD-SYMBOL(<new_transaction>).
      <new_transaction>-%tky-SoldToParty = <giftcard>-BusinessPartner.
      <new_transaction>-%target = VALUE #( ( %cid = 'CID' && sy-tabix
                                                    ActivityType = zif_lh_constants=>activity-redemption
                                                    LoyaltyPoints = <giftcard>-GiftcardValue
                                                    %control-ActivityType = if_abap_behv=>mk-on
                                                    %control-LoyaltyPoints = if_abap_behv=>mk-on  ) ).
    ENDLOOP.
    CHECK transaction IS NOT INITIAL.

    MODIFY ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
    ENTITY ZLH_R_BusinessPartner
    CREATE BY \_Transactions
    FROM transaction
    FAILED DATA(failed_transaction)
    REPORTED DATA(reported_transaction).

  ENDMETHOD.


  METHOD validateGiftCardFields.

    " Read the data for the instances being validated
    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY zlh_r_giftcard
      FIELDS ( GiftcardValue SapDescription GiftcardCurrency )
      WITH CORRESPONDING #( keys )
      RESULT DATA(giftcards).

    LOOP AT giftcards REFERENCE INTO DATA(giftcard).

      IF giftcard->GiftcardValue IS INITIAL OR giftcard->GiftcardValue LE 0 OR giftcard->SapDescription IS INITIAL.
        " Block the Save/Create action
        APPEND VALUE #( %tky = giftcard->%tky ) TO failed-zlh_r_giftcard.
        IF giftcard->GiftcardValue IS INITIAL.
          APPEND VALUE #( %tky = giftcard->%tky
                          %msg = new_message(
                                   id       = 'ZPRA_LOYALTYHUB'
                                   number   = '006'
                                   severity = if_abap_behv_message=>severity-error
                     )
                          %element-GiftcardValue = if_abap_behv=>mk-on ) TO reported-zlh_r_giftcard.
        ENDIF.

        IF giftcard->GiftcardValue LE 0.
          APPEND VALUE #( %tky = giftcard->%tky
                          %msg = new_message(
                                   id       = 'ZPRA_LOYALTYHUB'
                                   number   = '013'
                                   severity = if_abap_behv_message=>severity-error
                     )
                          %element-GiftcardValue = if_abap_behv=>mk-on
                           ) TO reported-zlh_r_giftcard.
        ENDIF.

        " Error for SapDescription
        IF giftcard->SapDescription IS INITIAL.
          APPEND VALUE #( %tky = giftcard->%tky
                          %msg = new_message(
                                    id       = 'ZPRA_LOYALTYHUB'
                                    number   = '007'
                                    severity = if_abap_behv_message=>severity-error
                     )
                          %element-SapDescription = if_abap_behv=>mk-on
                          ) TO reported-zlh_r_giftcard.
        ENDIF.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_features.

    DATA active_keys TYPE TABLE FOR READ IMPORT zlh_r_giftcard.
    active_keys = VALUE #( FOR key IN keys (
       Giftcardnumber = key-Giftcardnumber   " Assign the full transactional key group here
       %is_draft = if_abap_behv=>mk-off
   ) ).
    " read giftcards which are created earlier(not in draft)
    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
       ENTITY zlh_r_giftcard
       FIELDS ( GiftcardValue SapDescription GiftcardCurrency )
       WITH CORRESPONDING #( active_keys )
       RESULT DATA(giftcards).
    result = VALUE #( FOR key IN keys (
 %tky = key-%tky

 %features-%field-GiftCardCurrency = if_abap_behv=>fc-f-read_only

 %features-%field-GiftcardValue = COND #(
     WHEN line_exists( giftcards[ KEY id Giftcardnumber = key-Giftcardnumber
     %is_draft      = if_abap_behv=>mk-off  ] )
     THEN if_abap_behv=>fc-f-read_only
     ELSE if_abap_behv=>fc-f-mandatory )

 %features-%field-SapDescription = COND #(
     WHEN line_exists( giftcards[ KEY id Giftcardnumber = key-Giftcardnumber
     %is_draft      = if_abap_behv=>mk-off ] )
     THEN if_abap_behv=>fc-f-read_only
     ELSE if_abap_behv=>fc-f-mandatory )
) ).

  ENDMETHOD.

  METHOD validateGiftcardBalance.

    READ ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
        ENTITY zlh_r_giftcard
          FIELDS ( BusinessPartner GiftcardValue )
          WITH CORRESPONDING #( keys )
        RESULT DATA(giftcards).

* Group by BusinessPartner to find the total requested amount per partner
    TYPES: BEGIN OF ty_bp_total,
             business_partner TYPE zlh_businesspartner,
             total_requested  TYPE zlh_giftcardamt,
           END OF ty_bp_total.
    DATA bp_totals TYPE HASHED TABLE OF ty_bp_total WITH UNIQUE KEY business_partner.

    LOOP AT giftcards REFERENCE INTO DATA(giftcard)
         GROUP BY ( partner_id = giftcard->BusinessPartner )
         REFERENCE INTO DATA(bp_group).

      DATA(accumulated_sum) = VALUE zlh_giftcardamt( ).

      " Sum up all gift cards for this specific partner in the current session
      LOOP AT GROUP bp_group REFERENCE INTO DATA(group_member).
        accumulated_sum += group_member->GiftcardValue.
      ENDLOOP.

      INSERT VALUE #( business_partner = bp_group->partner_id
                      total_requested  = accumulated_sum )
             INTO TABLE bp_totals.
    ENDLOOP.

    DATA(bp_keys) = VALUE zcl_lh_loyalty_points=>business_partner_keys(
    FOR bp_total IN bp_totals
    ( sold_to_party = bp_total-business_partner )
  ).

    " Step 4: Batch retrieve loyalty points for all business partners
    DATA(loyalty_results) = COND zcl_lh_loyalty_points=>loyalty_points(
      WHEN bp_keys IS NOT INITIAL
      THEN zcl_lh_loyalty_points=>get_points( bp_keys )
    ).


    DATA reported_bp TYPE HASHED TABLE OF zlh_businesspartner WITH UNIQUE KEY table_line.
    " Final Validation Loop: Compare session total vs actual database balance
    LOOP AT giftcards REFERENCE INTO giftcard.

      " Retrieve the pre-calculated session sum from our hashed table
      DATA(total_requested) = bp_totals[ business_partner = giftcard->BusinessPartner ]-total_requested.
      DATA(available_points) = COND zlh_loyaltypoint(
      LET loyalty = VALUE zcl_lh_loyalty_points=>loyalty_point(
                      loyalty_results[ business_partner = giftcard->BusinessPartner ] OPTIONAL )
      IN WHEN loyalty-business_partner IS NOT INITIAL
         THEN loyalty-available
         ELSE 0
    ).

      IF total_requested > available_points.

        APPEND VALUE #( %tky = giftcard->%tky ) TO failed-zlh_r_giftcard.
        " UI Reporting: Only report the error message ONCE per Business Partner
        IF NOT line_exists( reported_bp[ table_line = giftcard->BusinessPartner ] ).
          INSERT giftcard->BusinessPartner INTO TABLE reported_bp.
          APPEND VALUE #(
            %tky        = giftcard->%tky
            %msg        = new_message(
                            id       = 'ZPRA_LOYALTYHUB'
                            number   = '002'
                            severity = if_abap_behv_message=>severity-error
                            v1       = |{ total_requested }|
                            v2       = |{ available_points }| )
            %element-giftcardvalue = if_abap_behv=>mk-on
          ) TO reported-zlh_r_giftcard.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD setGiftcardFieldsOnCreate.

   DATA update_giftcard TYPE TABLE FOR UPDATE zlh_r_giftcard.

    LOOP AT keys REFERENCE INTO DATA(key).

      APPEND VALUE #(
        %tky = key->%tky
        GiftcardStatus   = zif_lh_constants=>giftcard_status-active
        GiftcardCurrency = zif_lh_constants=>default_currency
        CreatedOn        = cl_abap_context_info=>get_system_date( )
        %control-GiftcardStatus   = if_abap_behv=>mk-on
        %control-GiftcardCurrency = if_abap_behv=>mk-on
        %control-CreatedOn        = if_abap_behv=>mk-on
      ) TO update_giftcard.

    ENDLOOP.

    IF update_giftcard IS NOT INITIAL.
      MODIFY ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
        ENTITY zlh_r_giftcard
        UPDATE FIELDS ( GiftcardStatus GiftcardCurrency CreatedOn )
        WITH update_giftcard.
    ENDIF.

  ENDMETHOD.

ENDCLASS.