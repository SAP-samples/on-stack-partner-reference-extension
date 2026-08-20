
CLASS lcl_test_probe DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-DATA created_count TYPE i.
    CLASS-DATA created_ref TYPE zlh_r_transactions-refsalesorderid.
    CLASS-DATA updated_count TYPE i.
    CLASS-DATA updated_ref TYPE zlh_r_transactions-refsalesorderid.
    CLASS-DATA updated_draft TYPE abp_behv_flag.
ENDCLASS.

CLASS lhe_event DEFINITION INHERITING FROM cl_abap_behavior_event_handler.
   PRIVATE SECTION.
    METHODS on_created FOR ENTITY EVENT
       created FOR SalesOrder~created. " invoked after SO create is committed

    METHODS on_updated FOR ENTITY EVENT
       updated FOR SalesOrder~Changed. " invoked after SO change is committed
ENDCLASS.


CLASS lcl_soi_executor DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES tt_salesorder_ids TYPE STANDARD TABLE OF zlh_r_transactions-refsalesorderid WITH EMPTY KEY.

    CLASS-METHODS execute_created
      IMPORTING
        it_salesorder_ids TYPE tt_salesorder_ids.

    CLASS-METHODS execute_updated
      IMPORTING
        it_salesorder_ids TYPE tt_salesorder_ids.
ENDCLASS.


CLASS lhe_event IMPLEMENTATION.

  METHOD on_created.

    lcl_soi_executor=>execute_created(
      it_salesorder_ids = VALUE #( FOR <created_row> IN created ( <created_row>-SalesOrder ) ) ).

  ENDMETHOD.

  METHOD on_updated.

    lcl_soi_executor=>execute_updated(
      it_salesorder_ids = VALUE #( FOR <updated_row> IN updated ( <updated_row>-SalesOrder ) ) ).

  ENDMETHOD.


ENDCLASS.


CLASS lcl_soi_executor IMPLEMENTATION.

  METHOD execute_created.

    SELECT SoldToParty,
           SalesOrder,
           TotalNetAmount,
           TransactionCurrency,
           HdrGeneralIncompletionStatus
      FROM I_SalesOrderTP
      FOR ALL ENTRIES IN @it_salesorder_ids
      WHERE SalesOrder = @it_salesorder_ids-table_line
      INTO TABLE @DATA(sales_orders).

    DATA loyalty_transactions TYPE TABLE FOR CREATE zlh_r_businesspartner\_transactions.

    LOOP AT sales_orders ASSIGNING FIELD-SYMBOL(<sales_order>).
      CHECK <sales_order>-HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status.

      SELECT SINGLE *
        FROM zlh_r_membership
        WHERE BusinessPartner = @<sales_order>-SoldToParty
        INTO @DATA(membership_details).
      CHECK membership_details IS NOT INITIAL
        AND membership_details-MembershipEndDate = zif_lh_constants=>membership_enddate.

      SELECT SINGLE @abap_true
        FROM zlh_r_transactions
        WHERE RefSalesorderId = @<sales_order>-SalesOrder
        INTO @DATA(existing_transaction).
      CHECK sy-subrc <> 0.

      APPEND INITIAL LINE TO loyalty_transactions ASSIGNING FIELD-SYMBOL(<loyalty_transaction>).
      <loyalty_transaction>-%tky-SoldToParty = <sales_order>-SoldToParty.
      <loyalty_transaction>-%target = VALUE #(
        ( %cid = 'CID' && sy-tabix
          ActivityType = zif_lh_constants=>activity-purchase
          RefSalesorderId = <sales_order>-SalesOrder
          TransactionAmount = <sales_order>-TotalNetAmount
          TransactionCurrency = <sales_order>-TransactionCurrency
          %control-RefSalesorderId = if_abap_behv=>mk-on
          %control-ActivityType = if_abap_behv=>mk-on
          %control-TransactionAmount = if_abap_behv=>mk-on
          %control-TransactionCurrency = if_abap_behv=>mk-on ) ).
    ENDLOOP.

    CHECK loyalty_transactions IS NOT INITIAL.

    TEST-SEAM created_modify_entities.
      MODIFY ENTITIES OF zlh_r_businesspartner
      ENTITY zlh_r_businesspartner
      CREATE BY \_Transactions
      FROM loyalty_transactions
      FAILED DATA(failed_items)
      REPORTED DATA(reported_items).
    END-TEST-SEAM.

  ENDMETHOD.


  METHOD execute_updated.

    SELECT SoldToParty,
           SalesOrder,
           TotalNetAmount,
           TransactionCurrency,
           HdrGeneralIncompletionStatus
      FROM I_SalesOrderTP
      FOR ALL ENTRIES IN @it_salesorder_ids
      WHERE SalesOrder = @it_salesorder_ids-table_line
      INTO TABLE @DATA(sales_orders).

    DATA loyalty_transactions TYPE TABLE FOR CREATE zlh_r_businesspartner\_transactions.

    LOOP AT sales_orders ASSIGNING FIELD-SYMBOL(<sales_order>).
      CHECK <sales_order>-HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status.

      SELECT SINGLE *
        FROM zlh_r_membership
        WHERE BusinessPartner = @<sales_order>-SoldToParty
        INTO @DATA(membership_details).
      CHECK membership_details IS NOT INITIAL
        AND membership_details-MembershipEndDate = zif_lh_constants=>membership_enddate.

      SELECT SINGLE @abap_true
        FROM zlh_r_transactions
        WHERE RefSalesorderId = @<sales_order>-SalesOrder
        INTO @DATA(existing_transaction).
      CHECK sy-subrc <> 0.

      APPEND INITIAL LINE TO loyalty_transactions ASSIGNING FIELD-SYMBOL(<loyalty_transaction>).
      <loyalty_transaction>-%tky-SoldToParty = <sales_order>-SoldToParty.
      <loyalty_transaction>-%is_draft = if_abap_behv=>mk-off.
      <loyalty_transaction>-%target = VALUE #(
        ( %cid = 'CID' && sy-tabix
          ActivityType = zif_lh_constants=>activity-purchase
          RefSalesorderId = <sales_order>-SalesOrder
          TransactionAmount = <sales_order>-TotalNetAmount
          TransactionCurrency = <sales_order>-TransactionCurrency
          %control-RefSalesorderId = if_abap_behv=>mk-on
          %control-ActivityType = if_abap_behv=>mk-on
          %control-TransactionAmount = if_abap_behv=>mk-on
          %control-TransactionCurrency = if_abap_behv=>mk-on ) ).
    ENDLOOP.

    CHECK loyalty_transactions IS NOT INITIAL.

    TEST-SEAM updated_modify_entities.
      MODIFY ENTITIES OF zlh_r_businesspartner
      ENTITY zlh_r_businesspartner
      CREATE BY \_Transactions
      FROM loyalty_transactions
      FAILED DATA(failed_items)
      REPORTED DATA(reported_items).
    END-TEST-SEAM.

  ENDMETHOD.

ENDCLASS.