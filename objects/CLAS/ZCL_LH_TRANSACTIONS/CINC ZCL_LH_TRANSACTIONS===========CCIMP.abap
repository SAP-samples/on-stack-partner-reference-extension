CLASS ltcl_transaction_handler DEFINITION DEFERRED FOR TESTING.

CLASS lhc_zlh_r_transactions DEFINITION
  INHERITING FROM cl_abap_behavior_handler
  FRIENDS ltcl_transaction_handler .

  PRIVATE SECTION.

    METHODS precheck_update
      FOR PRECHECK
      IMPORTING keys FOR UPDATE zlh_r_transactions.

    METHODS LoyaltyPointCalculations
      FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zlh_r_transactions~LoyaltyPointCalculations.

    METHODS validate_transaction_data
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR zlh_r_transactions~validate_transaction_data.

    METHODS get_instance_features
      FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features
      FOR zlh_r_transactions RESULT result.

    METHODS fillDefaultValues
      FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zlh_r_transactions~fillDefaultValues.

ENDCLASS.


CLASS lhc_zlh_r_transactions IMPLEMENTATION.

  METHOD LoyaltyPointCalculations.
    DATA(todaysdate) = cl_abap_context_info=>get_system_date( ).
    DATA: update_transactions TYPE TABLE FOR UPDATE zlh_r_transactions,
          loyalty_points TYPE zlh_loyaltypoint,
          defaultaccuconval TYPE p LENGTH 6 DECIMALS 2 VALUE '00.10'.
    SELECT businesspartner, categoryid, membershipid
      FROM zlh_r_category
      WHERE status = @zif_lh_constants=>category_status-active AND EndDate >= @todaysdate
      INTO TABLE @DATA(categories).
      IF categories IS NOT INITIAL.
          SELECT DISTINCT hdr~categoryid,
                 hdr~accuconval
            FROM zlh_category_hdr AS hdr
            INNER JOIN @categories AS cat
              ON hdr~categoryid = cat~categoryid
            INTO TABLE @DATA(categories_hdr).
      ENDIF.

    SELECT membershipid
      FROM zlh_membership
      WHERE membership_enddate = @zif_lh_constants=>membership_enddate
      INTO TABLE @DATA(MembershipStatus).

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY zlh_r_transactions
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(transactions).

    LOOP AT transactions ASSIGNING FIELD-SYMBOL(<transaction>).

      CLEAR loyalty_points.

      CHECK <transaction>-ActivityType = zif_lh_constants=>activity-purchase.
      CHECK <transaction>-TransactionAmount > 0.

      READ TABLE categories ASSIGNING FIELD-SYMBOL(<cat>)
        WITH KEY businesspartner = <transaction>-BusinessPartner.
      CHECK sy-subrc = 0.

      READ TABLE MembershipStatus WITH KEY membershipid = <cat>-MembershipID
        TRANSPORTING NO FIELDS.
      CHECK sy-subrc = 0.

      READ TABLE categories_hdr ASSIGNING FIELD-SYMBOL(<hdr>)
        WITH KEY categoryid = <cat>-CategoryID.
      CHECK sy-subrc = 0.
      IF <hdr>-accuconval > 0.
        loyalty_points = <transaction>-TransactionAmount * <hdr>-accuconval.
      ELSE.
        loyalty_points = <transaction>-TransactionAmount * defaultaccuconval.
      ENDIF.

      APPEND VALUE #(
        %tky          = <transaction>-%tky
        LoyaltyPoints = loyalty_points
      ) TO update_transactions.

    ENDLOOP.

    IF update_transactions IS NOT INITIAL .
      MODIFY ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
        ENTITY zlh_r_transactions
        UPDATE FIELDS ( LoyaltyPoints )
        WITH update_transactions.
    ENDIF.
  ENDMETHOD.

  METHOD validate_transaction_data.
    CHECK keys IS NOT INITIAL.
    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY zlh_r_transactions
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(transactions).
    LOOP AT transactions ASSIGNING FIELD-SYMBOL(<transaction>).
      IF <transaction>-LoyaltyPoints = 0.
        APPEND VALUE #(
          %tky = <transaction>-%tky
        ) TO failed-ZLH_R_Transactions.
        APPEND VALUE #(
          %tky = <transaction>-%tky

          %msg = new_message(
            id       = 'ZPRA_LOYALTYHUB'
            number   = '003'
            severity = if_abap_behv_message=>severity-error
          )
          %path         = VALUE #(
                  zlh_r_businesspartner-%is_draft = <transaction>-%is_draft
                  zlh_r_businesspartner-soldtoparty = <transaction>-BusinessPartner
                )
          %element-LoyaltyPoints = if_abap_behv=>mk-on
        ) TO reported-zlh_r_transactions.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_features.
    DATA active_keys TYPE TABLE FOR READ IMPORT zlh_r_transactions.
    active_keys = VALUE #( FOR key IN keys (
       TransactionId = key-TransactionId   " Assign the full transactional key group here
       %is_draft = if_abap_behv=>mk-off
   ) ).
    " read transactions which are created earlier(not in draft)
    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY zlh_r_transactions
      ALL FIELDS WITH CORRESPONDING #( active_keys )
      RESULT DATA(transactions).

    result = VALUE #( FOR key IN keys (
    %tky = key-%tky
  %features-%field-ActivityType = COND #(
      WHEN line_exists( transactions[ KEY id TransactionId = key-TransactionId
      %is_draft      = if_abap_behv=>mk-off  ] )
      THEN if_abap_behv=>fc-f-read_only
      ELSE if_abap_behv=>fc-f-mandatory )

  %features-%field-LoyaltyPoints = COND #(
      WHEN line_exists( transactions[ KEY id TransactionId = key-TransactionId
      %is_draft      = if_abap_behv=>mk-off  ] )
      THEN if_abap_behv=>fc-f-read_only
      ELSE if_abap_behv=>fc-f-mandatory )

  %features-%field-TransactionDate = COND #(
      WHEN line_exists( transactions[ KEY id TransactionId = key-TransactionId
      %is_draft      = if_abap_behv=>mk-off ] )
      THEN if_abap_behv=>fc-f-read_only
      ELSE if_abap_behv=>fc-f-mandatory )
 ) ).

  ENDMETHOD.

  METHOD filldefaultvalues.

    DATA update_transactions TYPE TABLE FOR UPDATE zlh_r_transactions.
    DATA(today) = cl_abap_context_info=>get_system_date( ).

    READ ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
      ENTITY zlh_r_transactions
      FIELDS ( BusinessPartner TransactionDate ActivityType
               TransactionAmount TransactionCurrency
               PointExpiryDate Membershipid )
      WITH CORRESPONDING #( keys )
      RESULT DATA(transactions).

    CHECK transactions IS NOT INITIAL.
*    IF transactions IS NOT INITIAL.
*        SELECT DISTINCT businesspartner, membershipid
*          FROM zlh_r_membership
*          FOR ALL ENTRIES IN @transactions
*          WHERE BusinessPartner = @transactions-BusinessPartner
*          INTO TABLE @DATA(memberships).
*
*    ENDIF.
    READ ENTITIES OF ZLH_R_BusinessPartner
         IN LOCAL MODE
         ENTITY ZLH_R_BusinessPartner
         BY \_MemberShip
         FIELDS ( BusinessPartner MembershipID )
         WITH VALUE #(
           ( SoldToParty = transactions[ 1 ]-BusinessPartner
             %is_draft   = if_abap_behv=>mk-on )   " draft
           ( SoldToParty = transactions[ 1 ]-BusinessPartner
             %is_draft   = if_abap_behv=>mk-off )  " active
         )
         RESULT DATA(memberships).
    LOOP AT transactions ASSIGNING FIELD-SYMBOL(<transaction>).

      DATA(transaction_date) =
        COND d( WHEN <transaction>-TransactionDate IS INITIAL
                THEN today
                ELSE <transaction>-TransactionDate ).

      DATA(activity_type) =
        COND zlh_activity_type(
          WHEN <transaction>-ActivityType IS INITIAL
          THEN zif_lh_constants=>activity-accrual
          ELSE <transaction>-ActivityType ).

      DATA(expiry_date) =
        COND d(
          WHEN <transaction>-PointExpiryDate IS INITIAL
               AND activity_type <> zif_lh_constants=>activity-redemption
               AND activity_type <> zif_lh_constants=>activity-deactivation
          THEN today + 365
          ELSE <transaction>-PointExpiryDate ).

      DATA(amount)   = COND #( WHEN activity_type = zif_lh_constants=>activity-purchase
                               THEN <transaction>-TransactionAmount ).
      DATA(currency) = COND #( WHEN activity_type = zif_lh_constants=>activity-purchase
                               THEN <transaction>-TransactionCurrency ).

      DATA(memberid) = <transaction>-Membershipid.
      IF memberid IS INITIAL.
        READ TABLE memberships ASSIGNING FIELD-SYMBOL(<membership>)
          WITH KEY businesspartner = <transaction>-BusinessPartner.
        IF sy-subrc = 0.
          memberid = <membership>-Membershipid.
        ENDIF.
      ENDIF.

      APPEND VALUE #(
        %tky                = <transaction>-%tky
        TransactionDate     = transaction_date
        ActivityType        = activity_type
        PointExpiryDate     = expiry_date
        TransactionAmount   = amount
        TransactionCurrency = currency
        Membershipid        = memberid
      ) TO update_transactions.

    ENDLOOP.

    MODIFY ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
      ENTITY zlh_r_transactions
      UPDATE FIELDS (
        TransactionDate ActivityType PointExpiryDate
        TransactionAmount TransactionCurrency Membershipid )
      WITH update_transactions.

  ENDMETHOD.

  METHOD precheck_update.
    CHECK keys IS NOT INITIAL.
    DATA(todaysdate) = cl_abap_context_info=>get_system_date( ).
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

      READ ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
      ENTITY zlh_r_transactions
        FIELDS ( BusinessPartner )
        WITH CORRESPONDING #( keys )
      RESULT DATA(transactions).
      IF transactions IS NOT INITIAL.
        IF <key>-LoyaltyPoints <= 0 AND <key>-%control-LoyaltyPoints = if_abap_behv=>mk-on.
          APPEND VALUE #(
            %tky = <key>-%tky
          ) TO failed-ZLH_R_Transactions.
          APPEND VALUE #(
            %tky = <key>-%tky

            %msg = new_message(
              id       = 'ZPRA_LOYALTYHUB'
              number   = '003'
              severity = if_abap_behv_message=>severity-error
            )
            %element-LoyaltyPoints = if_abap_behv=>mk-on
          ) TO reported-zlh_r_transactions.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations