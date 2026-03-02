CLASS lhc_BusinessPartner DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ZLH_R_BusinessPartner RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zlh_r_businesspartner RESULT result.

    METHODS get_global_features FOR GLOBAL FEATURES
      IMPORTING REQUEST requested_features FOR ZLH_R_BusinessPartner RESULT result.


    METHODS earlynumbering_cba_giftcard FOR NUMBERING
      IMPORTING entities FOR CREATE zlh_r_businesspartner\_giftcard.

    METHODS createmembership FOR MODIFY
      IMPORTING keys FOR ACTION zlh_r_businesspartner~createmembership RESULT result.

    METHODS createcategory FOR MODIFY
      IMPORTING keys FOR ACTION ZLH_R_BusinessPartner~createCategory.

    METHODS deleteMembership FOR MODIFY
      IMPORTING keys FOR ACTION ZLH_R_BusinessPartner~deleteMembership RESULT result.

    METHODS precheck_cba_Giftcard FOR PRECHECK
      IMPORTING keys FOR CREATE ZLH_R_BusinessPartner\_Giftcard.

    METHODS GetDefaultsForGiftCard FOR READ
      IMPORTING keys FOR FUNCTION ZLH_R_BusinessPartner~GetDefaultsForGiftCard RESULT result.

    METHODS precheck_cba_Transactions FOR PRECHECK
      IMPORTING keys FOR CREATE ZLH_R_BusinessPartner\_Transactions.

*    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
*          IMPORTING REQUEST requested_authorizations FOR ZLH_R_BusinessPartner RESULT result.

    METHODS earlynumbering_cba_Membership FOR NUMBERING
      IMPORTING entities FOR CREATE ZLH_R_BusinessPartner\_MemberShip.

    METHODS earlynumbering_cba_Transaction FOR NUMBERING
      IMPORTING entities FOR CREATE ZLH_R_BusinessPartner\_Transactions.

ENDCLASS.

CLASS lhc_BusinessPartner IMPLEMENTATION.

  METHOD get_instance_authorizations.

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
    ENTITY ZLH_R_BusinessPartner
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(BusinessPartners)
    BY \_MemberShip
    FIELDS ( MembershipID MembershipStatus BusinessPartner )
    WITH CORRESPONDING #( keys )
    RESULT DATA(Memberships).

    LOOP AT BusinessPartners ASSIGNING FIELD-SYMBOL(<businesspartner>).
      DATA(membership_of_bp) = value #( memberships[ BusinessPartner = <businesspartner>-SoldToParty ] optional ).
      IF membership_of_bp-BusinessPartner is not initial and requested_authorizations-%update = if_abap_behv=>mk-on. "only onboading team can change
        IF membership_of_bp-MembershipStatus = zif_lh_constants=>membership_status-active.
          APPEND VALUE #( %tky = <businesspartner>-%tky
                          %update = if_abap_behv=>auth-allowed ) TO result.
        ELSE.
          APPEND VALUE #( %tky = <businesspartner>-%tky
                          %update = if_abap_behv=>auth-unauthorized ) TO result.
          APPEND VALUE #( %msg        = new_message( id        = 'ZPRA_LOYALTYHUB'
                                                     number    = '014'
                                                     severity  = if_abap_behv_message=>severity-error
                        ) ) TO reported-zlh_r_businesspartner.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
    ENTITY ZLH_R_BusinessPartner
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(BusinessPartners)
    BY \_MemberShip
    FIELDS ( MembershipID MembershipStatus )
    WITH CORRESPONDING #( keys )
     RESULT DATA(memberships).

    IF lines( memberships ) > 0.
      DATA(membership_status) = memberships[ 1 ]-MembershipStatus.
    ELSE.
      membership_status = 'I'.
    ENDIF.

         AUTHORITY-CHECK OBJECT 'ZLOYLTYHUB'
    ID 'ZLH_USER' FIELD 'ADMIN'
    ID 'ACTVT' FIELD '01'.

    IF sy-subrc = 0.
      data(has_admin_auth) = abap_true.
    ELSE.
      has_admin_auth = abap_false.
    ENDIF.

    result = VALUE #( FOR ls_BP IN BusinessPartners
                         ( %tky = ls_bp-%tky

                           %action-createMembership          = COND #( WHEN  lines( memberships ) EQ 0 and BusinessPartners[ 1 ]-%is_draft = '01'
                                                                 THEN if_abap_behv=>fc-o-enabled
                                                                 ELSE if_abap_behv=>fc-o-disabled )
                           %action-deleteMembership          = COND #( WHEN membership_status EQ zif_lh_constants=>membership_status-active
                                                                        AND BusinessPartners[ 1 ]-%is_draft = '01'
                                                                 THEN if_abap_behv=>fc-o-enabled
                                                                 ELSE if_abap_behv=>fc-o-disabled )
                           %action-Edit =                       COND #( WHEN has_admin_auth EQ abap_true
                                                                 THEN if_abap_behv=>fc-o-enabled
                                                                 ELSE if_abap_behv=>fc-o-disabled )
                          ) ).
  ENDMETHOD.

  METHOD get_global_features.
*    requested_features-%update = if_abap_behv=>fc-o-disabled.
*    requ
  ENDMETHOD.

*  METHOD get_global_authorizations.
*    IF requested_authorizations-%create = if_abap_behv=>mk-on.
*
*      AUTHORITY-CHECK OBJECT 'ZLOYLTYHUB'
*        ID 'ZLH_USER' FIELD 'ADMIN'
*        ID 'ACTVT'    FIELD '01'.
*
*      IF sy-subrc = 0.
*        result-%create = if_abap_behv=>auth-allowed.
*      ELSE.
*        result-%create = if_abap_behv=>auth-unauthorized.
*        APPEND VALUE #(
*          %msg = new_message(
*                   id       = 'ZPRA_LOYALTYHUB'
*                   number   = '014'
*                   severity = if_abap_behv_message=>severity-error
*                 )
*        ) TO reported-zlh_r_businesspartner.
*      ENDIF.
*
*    ENDIF.
*  ENDMETHOD.

  METHOD earlynumbering_cba_Membership.
    DATA: CurrentMembershipID TYPE zlh_membership_id,
          use_number_range    TYPE abap_bool VALUE abap_true.


    DATA(without_membershipids) = entities[ 1 ]-%target.
    DELETE without_membershipids WHERE MembershipID NE 0.
*    DELETE lt_wo_membershipid WHERE %is_draft NE '01'.

    IF lines( without_membershipids ) GT 0.
      "Get numbers
      TRY.
          cl_numberrange_runtime=>number_get(
            EXPORTING
              nr_range_nr       = '01'
              object            = 'ZLH_MID'
              quantity          = CONV #( lines( without_membershipids ) )
            IMPORTING
              number            = DATA(number_range_key)
              returncode        = DATA(number_range_return_code)
              returned_quantity = DATA(number_range_returned_quantity)
          ).
        CATCH cx_number_ranges INTO DATA(lx_number_ranges).
          LOOP AT without_membershipids INTO DATA(without_membershipid).
            APPEND VALUE #(  %cid      = without_membershipid-%cid
                             %key      = without_membershipid-%key
                             %is_draft = without_membershipid-%is_draft
                             %msg      = lx_number_ranges
                          ) TO reported-zlh_r_membership.
            APPEND VALUE #(  %cid      = without_membershipid-%cid
                             %key      = without_membershipid-%key
                             %is_draft = without_membershipid-%is_draft
                          ) TO failed-zlh_r_membership.
          ENDLOOP.
          EXIT.
      ENDTRY.
      CurrentMembershipID = number_range_key - number_range_returned_quantity.
      LOOP AT without_membershipids INTO without_membershipid.
        CurrentMembershipID += 1.
        without_membershipid-MembershipID = CurrentMembershipID.

        APPEND VALUE #( %cid      = without_membershipid-%cid
                        %key      = without_membershipid-%key
                        %is_draft = without_membershipid-%is_draft
                      ) TO mapped-zlh_r_membership.
      ENDLOOP.
    ELSE.
      LOOP AT entities[ 1 ]-%target INTO DATA(lylpts_pgm_txn1).
        APPEND VALUE #( %cid  = lylpts_pgm_txn1-%cid
                        %key  = lylpts_pgm_txn1-%key ) TO mapped-zlh_r_membership.
        mapped-zlh_r_membership[ sy-tabix ]-%is_draft = lylpts_pgm_txn1-%is_draft.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD earlynumbering_cba_Transaction.
    DATA:
      CurrenttransactionID TYPE zlh_transaction_id,
      use_number_range     TYPE abap_bool VALUE abap_true.

    " Process each parent entity's target transactions
    LOOP AT entities INTO DATA(entity).
      DATA(lt_wo_transactionid) = entity-%target.
      DELETE lt_wo_transactionid WHERE TransactionId NE 0.

      IF lines( lt_wo_transactionid ) GT 0.
        "Get numbers
        TRY.
            cl_numberrange_runtime=>number_get(
              EXPORTING
                nr_range_nr       = '01'
                object            = 'ZLH_TID'
                quantity          = CONV #( lines( lt_wo_transactionid ) )
              IMPORTING
                number            = DATA(number_range_key)
                returncode        = DATA(number_range_return_code)
                returned_quantity = DATA(number_range_returned_quantity)
            ).
          CATCH cx_number_ranges INTO DATA(lx_number_ranges).
            LOOP AT lt_wo_transactionid INTO DATA(ls_wo_transactionid).
              APPEND VALUE #(  %cid      = ls_wo_transactionid-%cid
                               %key      = ls_wo_transactionid-%key
                               %is_draft = ls_wo_transactionid-%is_draft
                               %msg      = lx_number_ranges
                            ) TO reported-zlh_r_transactions.
              APPEND VALUE #(  %cid      = ls_wo_transactionid-%cid
                               %key      = ls_wo_transactionid-%key
                               %is_draft = ls_wo_transactionid-%is_draft
                            ) TO failed-zlh_r_transactions.
            ENDLOOP.
            CONTINUE.
        ENDTRY.
        " Calculate starting ID (inclusive)
        CurrentTransactionID = number_range_key - number_range_returned_quantity.
        LOOP AT lt_wo_transactionid INTO ls_wo_transactionid.
          CurrenttransactionID += 1.
          ls_wo_transactionid-TransactionId = CurrentTransactionID.

          APPEND VALUE #( %cid      = ls_wo_transactionid-%cid
                          %key      = ls_wo_transactionid-%key
                          %is_draft = ls_wo_transactionid-%is_draft
                        ) TO mapped-zlh_r_transactions.
        ENDLOOP.
      ELSE.
        " No number range required – just map directly
        LOOP AT entity-%target INTO DATA(lylpts_pgm_txn1).
          APPEND VALUE #( %cid  = lylpts_pgm_txn1-%cid
                          %key  = lylpts_pgm_txn1-%key
                          %is_draft = lylpts_pgm_txn1-%is_draft ) TO mapped-zlh_r_transactions.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.



  METHOD earlynumbering_cba_Giftcard.

    DATA current_giftcard_number TYPE zlh_giftcardnumber.

    LOOP AT entities INTO DATA(ls_entity).

      DATA(lt_giftcards) = ls_entity-%target.
      DELETE lt_giftcards WHERE giftcardnumber NE 0.

      IF lt_giftcards IS INITIAL.
        " Nothing to number – just map existing entries
        LOOP AT ls_entity-%target INTO DATA(ls_existing_gc).
          APPEND VALUE #(
            %cid      = ls_existing_gc-%cid
            %key      = ls_existing_gc-%key
            %is_draft = ls_existing_gc-%is_draft
          ) TO mapped-zlh_r_giftcard.
        ENDLOOP.
        CONTINUE.
      ENDIF.

      TRY.
          cl_numberrange_runtime=>number_get(
            EXPORTING
              nr_range_nr       = '01'
              object            = 'ZLH_GCID'
              quantity          = CONV #( lines( lt_giftcards ) )
            IMPORTING
              number            = DATA(lv_number_range_key)
              returncode        = DATA(lv_return_code)
              returned_quantity = DATA(lv_returned_quantity)
          ).
        CATCH cx_number_ranges INTO DATA(lx_number_ranges).

          LOOP AT lt_giftcards INTO DATA(ls_gc_error).
            APPEND VALUE #(
              %cid      = ls_gc_error-%cid
              %key      = ls_gc_error-%key
              %is_draft = ls_gc_error-%is_draft
              %msg      = lx_number_ranges
            ) TO reported-zlh_r_giftcard.

            APPEND VALUE #(
              %cid      = ls_gc_error-%cid
              %key      = ls_gc_error-%key
              %is_draft = ls_gc_error-%is_draft
            ) TO failed-zlh_r_giftcard.
          ENDLOOP.

          CONTINUE.
      ENDTRY.

      " Calculate starting number (inclusive)
      current_giftcard_number =
        lv_number_range_key - lv_returned_quantity.

      LOOP AT lt_giftcards INTO DATA(ls_giftcard).
        current_giftcard_number += 1.

        ls_giftcard-giftcardnumber = current_giftcard_number.

        APPEND VALUE #(
          %cid      = ls_giftcard-%cid
          %key      = ls_giftcard-%key
          %is_draft = ls_giftcard-%is_draft
        ) TO mapped-zlh_r_giftcard.
      ENDLOOP.

    ENDLOOP.
  ENDMETHOD.

  METHOD createMembership.


    DATA: memberships_create  TYPE TABLE FOR CREATE ZLH_R_BusinessPartner\_MemberShip.

    SELECT SINGLE threshold FROM zlh_r_category_hdr
      WHERE Isdefault EQ @abap_true
      INTO @DATA(default_category_threshold) PRIVILEGED ACCESS.
    IF sy-subrc IS NOT INITIAL.
      APPEND VALUE #( %tky = CORRESPONDING #( keys[ 1 ]-%tky ) ) TO failed-zlh_r_businesspartner.
      APPEND VALUE #(
        %tky = CORRESPONDING #( keys[ 1 ]-%tky )
        %msg = new_message(
                     id       = 'ZPRA_LOYALTYHUB'
                     number   = '020'
                     severity = if_abap_behv_message=>severity-error
                   ) ) TO reported-zlh_r_businesspartner.


      RETURN.
    ELSE.
      " Prepare business partner keys for loyalty points retrieval
      DATA(bp_keys) = VALUE zcl_lh_loyalty_points=>business_partner_keys(
        FOR key IN keys ( sold_to_party = key-SoldToParty ) ).

      " Get loyalty points for all business partners in one call
      DATA(loyalty_results) = zcl_lh_loyalty_points=>get_points( bp_keys ).

      " Calulate total loyalty points
      DATA(loyalty_result) = VALUE #( loyalty_results[ business_partner = keys[ 1 ]-SoldToParty ] OPTIONAL ).
      DATA(total_loyalty_points) = loyalty_result-available + loyalty_result-redeemed.

      " Display insufficient points if it is less than the threshold.
      IF total_loyalty_points < default_category_threshold.
        APPEND VALUE #( %tky = CORRESPONDING #( keys[ 1 ]-%tky ) ) TO failed-zlh_r_businesspartner.
        APPEND VALUE #(
          %tky = CORRESPONDING #( keys[ 1 ]-%tky )
          %msg = new_message(
                   id       = 'ZPRA_LOYALTYHUB'
                   number   = '021'
                   severity = if_abap_behv_message=>severity-error
                   v1       = |{ default_category_threshold }|
                 )
        ) TO reported-zlh_r_businesspartner.
        RETURN.
      ENDIF.
    ENDIF.

    memberships_create = VALUE #(
    (
     %tky-SoldToParty = keys[ 1 ]-SoldToParty
     %is_draft = keys[ 1 ]-%is_draft
     %target = VALUE #( (
                     %cid = 'cid'
                     %is_draft        = keys[ 1 ]-%is_draft
                     MemberSince = cl_abap_context_info=>get_system_date( )
                     MembershipEndDate = '99991231'
                     MembershipStatus = 'A'
                     %control-MemberSince = if_abap_behv=>mk-on
                     %control-MembershipStatus = if_abap_behv=>mk-on
                     %control-MembershipEndDate = if_abap_behv=>mk-on
                     ) ) ) ).

    MODIFY ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
    ENTITY ZLH_R_BusinessPartner
    CREATE BY \_MemberShip
    FROM memberships_create
     FAILED failed
    REPORTED reported.

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
    ENTITY ZLH_R_BusinessPartner
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(BusinessPartners).

    result = VALUE #( FOR BusinessPartner IN BusinessPartners
                    ( %tky   = BusinessPartner-%tky
                      %param = BusinessPartner ) ).

  ENDMETHOD.

  METHOD createcategory.

    DATA new_category TYPE TABLE FOR CREATE ZLH_R_Membership\_Category.

    DATA(new_categoryid) = keys[ 1 ]-%param-Categoryid.

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
     ENTITY ZLH_R_BusinessPartner
     BY \_MemberShip
     FIELDS ( MembershipID )
     WITH CORRESPONDING #( keys )
      RESULT DATA(membershipids).

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY ZLH_R_BusinessPartner
      BY \_Category
      FIELDS ( CategoryID )
      WITH VALUE #( ( SoldToParty = keys[ 1 ]-SoldToParty ) )
      RESULT DATA(categories).

    IF line_exists( categories[ Key entity COMPONENTS
                                BusinessPartner = keys[ 1 ]-SoldToParty
                                MembershipID = membershipids[ 1 ]-MembershipID
                                CategoryID = new_categoryid ] ).
      APPEND VALUE #( %tky = categories[ 1 ]-%tky ) TO failed-zlh_r_category.
      APPEND VALUE #(
        %tky = categories[ 1 ]-%tky
        %msg = new_message(
                 id       = 'ZPRA_LOYALTYHUB'
                 number   = '017'
                 severity = if_abap_behv_message=>severity-error
               )
      ) TO reported-zlh_r_category.
      RETURN.
    ENDIF.

    SELECT SINGLE FROM zlh_r_category_hdr
      FIELDS threshold
      WHERE Categoryid EQ @new_categoryid
      INTO @DATA(new_category_threshold).
    IF sy-subrc IS INITIAL.

      " Prepare business partner keys for loyalty points retrieval
      DATA(bp_keys) = VALUE zcl_lh_loyalty_points=>business_partner_keys(
        FOR key IN keys ( sold_to_party = key-SoldToParty ) ).

      " Get loyalty points for all business partners in one call
      DATA(loyalty_results) = zcl_lh_loyalty_points=>get_points( bp_keys ).

      " Calulate total loyalty points
      DATA(loyalty_result) = VALUE #( loyalty_results[ business_partner = keys[ 1 ]-SoldToParty ] OPTIONAL ).
      DATA(total_loyalty_points) = loyalty_result-available + loyalty_result-redeemed.

      " Display insufficient points if it is less than the threshold.
      IF total_loyalty_points < new_category_threshold.
        APPEND VALUE #( %tky = CORRESPONDING #( keys[ 1 ]-%tky ) ) TO failed-zlh_r_category.
        APPEND VALUE #(
          %tky = CORRESPONDING #( keys[ 1 ]-%tky )
          %msg = new_message(
                   id       = 'ZPRA_LOYALTYHUB'
                   number   = '012'
                   severity = if_abap_behv_message=>severity-error
                   v1       = |{ new_category_threshold }|
                 )
        ) TO reported-zlh_r_category.
        RETURN.
      ENDIF.
    ENDIF.

    IF membershipids[] IS NOT INITIAL.

      new_category = VALUE #( ( %tky-MembershipID = membershipids[ 1 ]-MembershipID
                                %tky-%is_draft = if_abap_behv=>mk-on
                                %target = VALUE #(  (
                                           %cid = 'CID'
                                           %is_draft = if_abap_behv=>mk-on
                                           CategoryID = keys[ 1 ]-%param-Categoryid
                                           BusinessPartner = keys[ 1 ]-SoldToParty
                                           MembershipID = membershipids[ 1 ]-MembershipID
                                           Status = keys[ 1 ]-%param-Status
                                           StartDate = keys[ 1 ]-%param-Startdate
                                           EndDate = keys[ 1 ]-%param-Enddate
                                           %control-BusinessPartner = if_abap_behv=>mk-on
                                           %control-CategoryID = if_abap_behv=>mk-on
                                           %control-status = if_abap_behv=>mk-on
                                           %control-StartDate = if_abap_behv=>mk-on
                                           %control-EndDate = if_abap_behv=>mk-on ) ) ) ).

      MODIFY ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY ZLH_R_Membership
      CREATE BY \_Category
      FROM new_category
      FAILED failed
      REPORTED reported
      MAPPED mapped.

    ENDIF.
  ENDMETHOD.

  METHOD deleteMembership.

*    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
*     ENTITY ZLH_R_Membership
*     ALL FIELDS WITH CORRESPONDING #( keys )
*     RESULT DATA(lt_Membership).
*

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
ENTITY ZLH_R_BusinessPartner
BY \_MemberShip
FIELDS ( MembershipID )
WITH CORRESPONDING #( keys )
 RESULT DATA(Memberships).


    MODIFY ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
    ENTITY ZLH_R_Membership
    UPDATE  FIELDS ( MembershipEndDate MembershipStatus )
    WITH VALUE #( FOR membership IN memberships ( %tky = membership-%tky
                                                       MembershipEndDate = cl_abap_context_info=>get_system_date( )
                                                       MembershipStatus = 'I'  ) )
     FAILED failed
    REPORTED reported.

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
    ENTITY ZLH_R_BusinessPartner
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_BP).

*****setting giftcard status to Inactive******************************
    READ ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
          ENTITY ZLH_R_BusinessPartner
          BY \_GiftCard
            FIELDS ( GiftcardStatus )
            WITH CORRESPONDING #( keys )
          RESULT DATA(giftcards).
    MODIFY ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
     ENTITY zlh_r_giftcard
      UPDATE FIELDS ( GiftcardStatus )
      WITH VALUE #(
        FOR gc IN giftcards
        WHERE ( GiftcardStatus <> zif_lh_constants=>giftcard_status-inactive )
        (
          %tky           = gc-%tky
          GiftcardStatus = zif_lh_constants=>giftcard_status-inactive
          %control-GiftcardStatus = if_abap_behv=>mk-on
        )
      )
      REPORTED DATA(reported_data)
      FAILED DATA(failed_data).
**********************************************************************

*****setting category status to Inactive******************************
    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY ZLH_R_BusinessPartner
      BY \_Category
      FIELDS ( StartDate EndDate Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(categories).

    MODIFY ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
      ENTITY zlh_r_category
      UPDATE FIELDS ( EndDate Status StatusCriticality )
      WITH VALUE #(
        FOR category IN categories
        WHERE ( EndDate EQ zif_lh_constants=>category_enddate )
        (
          %tky = category-%tky
          EndDate = cl_abap_context_info=>get_system_date( )
          Status = zif_lh_constants=>category_status-inactive
          StatusCriticality = 0
          %control-EndDate = if_abap_behv=>mk-on
          %control-Status = if_abap_behv=>mk-on
          %control-StatusCriticality = if_abap_behv=>mk-on
        )
      )
      REPORTED DATA(reported_category)
      FAILED DATA(failed_category).
**********************************************************************
*****setting transaction point valid untill todays date****************
    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
          ENTITY ZLH_R_BusinessPartner
          BY \_Transactions
            FIELDS ( PointExpiryDate )
            WITH CORRESPONDING #( keys )
          RESULT DATA(transactions).
    MODIFY ENTITIES OF zlh_r_businesspartner IN LOCAL MODE
     ENTITY zlh_r_transactions
      UPDATE FIELDS ( PointExpiryDate )
      WITH VALUE #(
        FOR tc IN transactions
        WHERE ( PointExpiryDate > cl_abap_context_info=>get_system_date( ) )
        (
          %tky           = tc-%tky
          PointExpiryDate = cl_abap_context_info=>get_system_date( )
          %control-PointExpiryDate = if_abap_behv=>mk-on
        )
      )
      REPORTED DATA(reportedtransactions)
      FAILED DATA(failedtransactions).
**********************************************************************
    result = VALUE #( FOR ls_bp IN lt_BP
                    ( %tky   = ls_bp-%tky
                      %param = ls_bp ) ).

  ENDMETHOD.

  METHOD precheck_cba_Giftcard.

    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY ZLH_R_BusinessPartner
      BY \_MemberShip
      FIELDS ( MembershipStatus MembershipEndDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(Memberships).
    LOOP AT keys REFERENCE INTO DATA(key).
      DATA(membership) = VALUE #( memberships[ BusinessPartner = key->SoldToParty ] OPTIONAL ).

      " Block creation if membership is not active
     IF membership-MembershipEndDate <> zif_lh_constants=>membership_enddate.
        APPEND VALUE #( %tky = key->%tky ) TO failed-zlh_r_businesspartner.
        APPEND VALUE #( %tky = key->%tky
                        %msg = new_message(
                                    id       = 'ZPRA_LOYALTYHUB'
                                    number   = '009'
                                    severity = if_abap_behv_message=>severity-error
                     )
                      ) TO reported-zlh_r_businesspartner.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD GetDefaultsForGiftCard.
   READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY ZLH_R_BusinessPartner
      BY \_GiftCard
      all FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(Memberships).
    DATA(loyalty_results) = zcl_lh_loyalty_points=>get_points(
    VALUE #( FOR key IN keys ( sold_to_party = key-SoldToParty ) )
  ).

    result = VALUE #(
    FOR key IN keys
    LET available_points =
      COND zlh_giftcardamt(
        WHEN line_exists( loyalty_results[ business_partner = key-SoldToParty ] )
        THEN
          COND zlh_giftcardamt(
            WHEN loyalty_results[ business_partner = key-SoldToParty ]-available
                 > zif_lh_constants=>max_giftcard_value
            THEN zif_lh_constants=>max_giftcard_value
            ELSE loyalty_results[ business_partner = key-SoldToParty ]-available
          )
        ELSE 0
      )
    IN
    (
      %tky   = key-%tky
      %param = VALUE #( GiftcardValue = available_points )
    )
  ).

  ENDMETHOD.

  METHOD precheck_cba_Transactions.
    READ ENTITIES OF ZLH_R_BusinessPartner IN LOCAL MODE
      ENTITY ZLH_R_BusinessPartner
      BY \_MemberShip
      FIELDS ( MembershipStatus MembershipEndDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(Memberships).
    LOOP AT keys REFERENCE INTO DATA(key).
      DATA(membership) = VALUE #( memberships[ BusinessPartner = key->SoldToParty ] OPTIONAL ).

      " Block creation if membership is Inactive ('I')
*      IF membership-MembershipStatus <> zif_lh_constants=>membership_status-active.
      IF membership-MembershipEndDate <> zif_lh_constants=>membership_enddate.

        APPEND VALUE #( %tky = key->%tky ) TO failed-zlh_r_businesspartner.
        APPEND VALUE #( %tky = key->%tky
                        %msg = new_message(
                                    id       = 'ZPRA_LOYALTYHUB'
                                    number   = '010'
                                    severity = if_abap_behv_message=>severity-error
                     )
                      ) TO reported-zlh_r_businesspartner.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.