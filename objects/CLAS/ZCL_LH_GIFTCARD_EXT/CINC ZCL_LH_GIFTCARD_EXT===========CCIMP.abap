CLASS lhc_salesorder DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR SalesOrder RESULT result.
    METHODS zz_use_gift_card FOR MODIFY
      IMPORTING it_keys FOR ACTION SalesOrder~zz_use_gift_card RESULT result.
ENDCLASS.

CLASS lcl_giftcard_logic DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_eval,
        soldtoparty     TYPE i_salesordertp-soldtoparty,
        currency        TYPE i_salesordertp-transactioncurrency,
        giftcard_amount TYPE i_salesordertp-totalnetamount,
        error_no        TYPE symsgno,
        should_modify   TYPE abap_bool,
      END OF ty_eval.
    CLASS-METHODS evaluate
      IMPORTING
        iv_salesorder_id   TYPE i_salesordertp-salesorder
        iv_giftcard_amount TYPE i_salesordertp-totalnetamount
      RETURNING
        VALUE(rs_eval) TYPE ty_eval.
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

      DATA(ls_eval) = lcl_giftcard_logic=>evaluate(
        iv_salesorder_id = salesorder_id
        iv_giftcard_amount = giftcard_amount ).

      IF ls_eval-error_no IS NOT INITIAL.
        APPEND VALUE #( %tky  = <lfs_key>-%tky ) TO failed-salesorder.
        APPEND VALUE #(
          %tky                        = <lfs_key>-%tky
          %msg = new_message(
                   id = 'ZPRA_LOYALTYHUB'
                   number = ls_eval-error_no
                   severity = if_abap_behv_message=>severity-error )
           ) TO reported-salesorder.

      ELSEIF ls_eval-should_modify = abap_true.
          MODIFY ENTITIES OF i_salesordertp IN LOCAL MODE
            ENTITY salesorder
            UPDATE SET FIELDS WITH VALUE #(
            ( %tky                    = <lfs_key>-%tky
              %data-zz_giftcardamount_sdh  = ls_eval-giftcard_amount
              %data-zz_giftcardcurrency_sdh = ls_eval-currency )
             )
           CREATE BY \_pricingelement SET FIELDS WITH VALUE #(
            ( %tky    = <lfs_key>-%tky
              %target =   VALUE #( (
                %cid                = 'CIDGIFTCARD'
                conditiontype       = 'DRV1'
                "conditiontype       = 'XXXX'
                conditionrateamount = ls_eval-giftcard_amount * ( -1 )
                conditioncurrency   = ls_eval-currency ) ) ) )
            FAILED   DATA(modify_failed)
            REPORTED DATA(modify_reported).

          failed   = CORRESPONDING #( APPENDING BASE ( failed   ) modify_failed   ).
          reported = CORRESPONDING #( APPENDING BASE ( reported ) modify_reported ).
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

CLASS lcl_giftcard_logic IMPLEMENTATION.

  METHOD evaluate.
    DATA available_gc_balance TYPE i_salesordertp-totalnetamount.
    DATA available_gc_currency TYPE i_salesordertp-transactioncurrency.
    DATA redeem_status TYPE c LENGTH 1.
    DATA(lo_giftcard_api) = zcl_lh_giftcard_api=>get_instance( ).

    SELECT SINGLE SalesOrder,
                  SoldToParty,
                  TransactionCurrency,
                  TotalNetAmount,
                  HdrGeneralIncompletionStatus
      FROM I_SalesOrderTP
      WHERE SalesOrder = @iv_salesorder_id
      INTO @DATA(salesorder_detail).

    CHECK salesorder_detail-HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status.

    rs_eval-soldtoparty = salesorder_detail-SoldToParty.
    rs_eval-currency = salesorder_detail-TransactionCurrency.
    rs_eval-giftcard_amount = iv_giftcard_amount.

    TRY.
        lo_giftcard_api->read_gift_card_balance(
          EXPORTING business_partner = salesorder_detail-SoldToParty
          IMPORTING currency = available_gc_currency
                    total_balance = available_gc_balance ).
      CATCH zcx_lh_giftcard INTO DATA(exp_balance).
        DATA(msg_balance) = exp_balance->get_text( ).
    ENDTRY.

    IF iv_giftcard_amount > available_gc_balance.
      rs_eval-error_no = '001'.
      RETURN.
    ELSEIF iv_giftcard_amount > salesorder_detail-TotalNetAmount.
      rs_eval-error_no = '018'.
      RETURN.
    ELSEIF salesorder_detail-TotalNetAmount < 50.
      rs_eval-error_no = '019'.
      RETURN.
    ELSEIF iv_giftcard_amount EQ 0.
      rs_eval-error_no = '000'.
      RETURN.
    ENDIF.

    TRY.
        lo_giftcard_api->redeem_gift_card_amount(
          EXPORTING business_partner = salesorder_detail-SoldToParty
                    amount = iv_giftcard_amount
                    currency = salesorder_detail-TransactionCurrency ).
      CATCH zcx_lh_giftcard INTO DATA(exp_redeem).
        DATA(msg_redeem) = exp_redeem->get_text( ).
        redeem_status = 'F'.
    ENDTRY.

    IF redeem_status = 'F'.
      rs_eval-error_no = '003'.
      RETURN.
    ENDIF.

    rs_eval-should_modify = abap_true.
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