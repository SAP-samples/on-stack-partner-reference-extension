CLASS lhc_salesorder DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR SalesOrder RESULT result.
    METHODS zz_use_gift_card FOR MODIFY
      IMPORTING it_keys FOR ACTION SalesOrder~zz_use_gift_card RESULT result.


ENDCLASS.

CLASS lhc_salesorder IMPLEMENTATION.

  METHOD get_instance_features.

    READ ENTITIES OF I_SalesOrderTP IN LOCAL MODE
      ENTITY SalesOrder
      FIELDS ( TotalNetAmount )
        WITH CORRESPONDING #( keys )
          RESULT DATA(lt_result_salesorder).

    result = VALUE #( FOR ls_salesorder IN lt_result_salesorder ( %tky = ls_salesorder-%tky
                                                                  %features-%action-zz_use_gift_card = if_abap_behv=>fc-o-enabled ) ).

*    result = VALUE #( FOR ls_salesorder IN lt_result_salesorder ( %tky = ls_salesorder-%tky
*                                                                  %features-%action-zz_use_gift_card = COND #( WHEN ls_salesorder-TotalNetAmount < '50'
*                                                                                                               THEN if_abap_behv=>fc-o-disabled
*                                                                                                               ELSE if_abap_behv=>fc-o-enabled ) ) ).
*
  ENDMETHOD.

  METHOD zz_use_gift_card.

    LOOP AT it_keys ASSIGNING FIELD-SYMBOL(<lfs_key>).

      DATA(salesorder_id) = <lfs_key>-SalesOrder.
      DATA(giftcard_amount) = <lfs_key>-%param-giftcardamount.

      SELECT SINGLE SalesOrder, SoldToParty,TransactionCurrency, TotalNetAmount, HdrGeneralIncompletionStatus FROM I_SalesOrderTP WHERE SalesOrder = @salesorder_id INTO  @DATA(salesorder_detail).

      " Only proceed for orders in the intended completion status.
      CHECK salesorder_detail-HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status.


      " Read available gift card balance for the Sold-to Party.
      TRY.
          zcl_lh_giftcard_api=>read_gift_card_balance( EXPORTING business_partner = salesorder_detail-SoldToParty
                                                        IMPORTING currency = DATA(available_gc_currency)
                                                                  total_balance = DATA(available_gc_balance) ).
        CATCH zcx_lh_giftcard into dATA(exp).
         data(msg) = exp->get_text( ).
      ENDTRY.

      " Validation 1: Requested amount must not exceed available balance.
      IF giftcard_amount > available_gc_balance.
        APPEND VALUE #( %tky  = <lfs_key>-%tky ) TO failed-salesorder.
        APPEND VALUE #(
          %tky                        = <lfs_key>-%tky
          %msg = new_message(
                   id = 'ZPRA_LOYALTYHUB'
                   number = '001'
                   severity = if_abap_behv_message=>severity-error )
           ) TO reported-salesorder.

      " Validation 2: Requested amount must not exceed SO net amount.
      elseif giftcard_amount > salesorder_detail-TotalNetAmount.
        APPEND VALUE #( %tky  = <lfs_key>-%tky ) TO failed-salesorder.
        APPEND VALUE #(
          %tky                        = <lfs_key>-%tky
          %msg = new_message(
                   id = 'ZPRA_LOYALTYHUB'
                   number = '018'
                   severity = if_abap_behv_message=>severity-error )
           ) TO reported-salesorder.

      " Validation 3: Business rule — SO net amount must be >= 50.
      elseif salesorder_detail-TotalNetAmount < 50.
        APPEND VALUE #( %tky  = <lfs_key>-%tky ) TO failed-salesorder.
        APPEND VALUE #(
          %tky                        = <lfs_key>-%tky
          %msg = new_message(
                   id = 'ZPRA_LOYALTYHUB'
                   number = '019'
                   severity = if_abap_behv_message=>severity-error )
           ) TO reported-salesorder.

      " Validation 4: Amount must be > 0.
      ELSEIF giftcard_amount EQ 0.
        APPEND VALUE #( %tky  = <lfs_key>-%tky ) TO failed-salesorder.
        APPEND VALUE #(
          %tky                        = <lfs_key>-%tky
          %msg = new_message(
                   id = 'ZPRA_LOYALTYHUB'
                   number = '000'
                   severity = if_abap_behv_message=>severity-error )
           ) TO reported-salesorder.
      ELSE.
        TRY.
            zcl_lh_giftcard_api=>redeem_gift_card_amount( EXPORTING business_partner = salesorder_detail-SoldToParty
                                                                   amount = giftcard_amount
                                                                   currency = salesorder_detail-TransactionCurrency ).
*                                                          IMPORTING ev_status = DATA(redeem_status) ).
          CATCH zcx_lh_giftcard iNTO exp.
            msg = exp->get_text( ).
            data(redeem_status) = 'F'.
        ENDTRY.

        " On successful redemption, update persistent fields and create pricing element
        IF redeem_status NE 'F'.
          MODIFY ENTITIES OF i_salesordertp IN LOCAL MODE
            ENTITY salesorder
            UPDATE SET FIELDS WITH VALUE #(
            ( %tky                    = <lfs_key>-%tky
              %data-zz_giftcardamount_sdh  = giftcard_amount
              %data-zz_giftcardcurrency_sdh = salesorder_detail-TransactionCurrency )
             )
           CREATE BY \_pricingelement SET FIELDS WITH VALUE #(
            ( %tky    = <lfs_key>-%tky
              %target =   VALUE #( (
                %cid                = 'CIDGIFTCARD'
                conditiontype       = 'DRV1'
                "conditiontype       = 'XXXX'
                conditionrateamount = giftcard_amount * ( -1 )
                conditioncurrency   = salesorder_detail-TransactionCurrency ) ) ) )
            FAILED   DATA(modify_failed)
            REPORTED DATA(modify_reported).

          failed   = CORRESPONDING #( APPENDING BASE ( failed   ) modify_failed   ).
          reported = CORRESPONDING #( APPENDING BASE ( reported ) modify_reported ).
        ELSE. "error in redeeming gift card
          APPEND VALUE #( %tky  = <lfs_key>-%tky ) TO failed-salesorder.
          APPEND VALUE #(
            %tky                        = <lfs_key>-%tky
            %msg = new_message(
                     id = 'ZPRA_LOYALTYHUB'
                     number = '003'
                     severity = if_abap_behv_message=>severity-error )
             ) TO reported-salesorder.
        ENDIF.
      ENDIF.
    ENDLOOP.

    " Return the (possibly updated) SalesOrder state as action result for the given keys.
    READ ENTITIES OF i_salesordertp IN LOCAL MODE
    ENTITY salesorder
    ALL FIELDS WITH
    CORRESPONDING #( it_keys )
    RESULT DATA(lt_salesorder).

    result = VALUE #( FOR salesorder IN lt_salesorder ( %tky   = salesorder-%tky
                                                        %param = CORRESPONDING #( salesorder ) ) ).


  ENDMETHOD.


ENDCLASS.

CLASS lsc_R_SALESORDERTP DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS cleanup_finalize REDEFINITION.


ENDCLASS.

CLASS lsc_R_SALESORDERTP IMPLEMENTATION.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.