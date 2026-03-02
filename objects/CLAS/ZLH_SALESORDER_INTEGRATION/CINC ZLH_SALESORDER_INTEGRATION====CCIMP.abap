
CLASS lhe_event DEFINITION INHERITING FROM cl_abap_behavior_event_handler.
   PRIVATE SECTION.
    METHODS on_created FOR ENTITY EVENT
       created FOR SalesOrder~created. " invoked after SO create is committed

    METHODS on_updated FOR ENTITY EVENT
       updated FOR SalesOrder~Changed. " invoked after SO change is committed
ENDCLASS.


CLASS lhe_event IMPLEMENTATION.

  METHOD on_created.



    " Read Sales Order payload for the event instances received in 'created[]'
    " RAP provides 'created' table with keys of affected instances
    SELECT SoldToParty,
           SalesOrder,
           TotalNetAmount,
           TransactionCurrency,
           HdrGeneralIncompletionStatus FROM I_SalesOrderTP
           FOR ALL ENTRIES IN @created  " table from RAP runtime
           WHERE SalesOrder = @created-SalesOrder INTO TABLE @DATA(sales_orders).

    " Stage Loyalty transactions to be created via composition _Transactions
    DATA: loyalty_transactions TYPE TABLE FOR CREATE ZLH_R_BusinessPartner\_Transactions.

    LOOP AT sales_orders ASSIGNING FIELD-SYMBOL(<sales_order>).

      " Only process orders that are complete (avoid premature transactions)
      CHECK <sales_order>-HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status.

      " Only process customers with an active membership
      SELECT SINGLE * FROM ZLH_R_Membership WHERE BusinessPartner  = @<sales_order>-SoldToParty
      INTO @DATA(membership_details).
      CHECK membership_details IS NOT INITIAL AND membership_details-MembershipEndDate = zif_lh_constants=>membership_enddate.

      " Idempotency: skip if we already created a loyalty transaction for this SalesOrder
      SELECT SINGLE @abap_true FROM zlh_r_transactions WHERE RefSalesorderId = @<sales_order>-SalesOrder
      INTO @DATA(existing_transaction).
      IF sy-subrc NE 0.

      " Prepare child creation under the parent business partner
        APPEND INITIAL LINE TO loyalty_transactions ASSIGNING FIELD-SYMBOL(<loyalty_transaction>).

      " %tky specifies the key of the parent entity for composition create
        <loyalty_transaction>-%tky-SoldToParty = <sales_order>-SoldToParty.


      " %target contains the fields for the child entity we want to create
      " %control-* marks the fields that we explicitly provide
        <loyalty_transaction>-%target = VALUE #( ( %cid = 'CID' && sy-tabix
                                                      ActivityType = zif_lh_constants=>activity-purchase
                                                      RefSalesorderId = <sales_order>-SalesOrder
                                                      TransactionAmount = <sales_order>-TotalNetAmount
                                                      TransactionCurrency = <sales_order>-TransactionCurrency
                                                      %control-RefSalesorderId = if_abap_behv=>mk-on
                                                      %control-ActivityType = if_abap_behv=>mk-on
                                                      %control-TransactionAmount = if_abap_behv=>mk-on
                                                      %control-TransactionCurrency = if_abap_behv=>mk-on  ) ).
      ENDIF.
    ENDLOOP.

    CHECK loyalty_transactions IS NOT INITIAL.

    MODIFY ENTITIES OF ZLH_R_BusinessPartner
    ENTITY ZLH_R_BusinessPartner
    CREATE BY \_Transactions
    FROM loyalty_transactions
    FAILED DATA(failed_items)
    REPORTED DATA(reported_items).

  ENDMETHOD.

  METHOD on_updated.

    " Read Sales Order payload for the event instances received in 'updated[]'
    " RAP provides 'updated' table with keys of affected instances
    SELECT SoldToParty,
    SalesOrder,
    TotalNetAmount,
    TransactionCurrency,
     HdrGeneralIncompletionStatus
      FROM I_SalesOrderTP FOR ALL ENTRIES IN @updated
      WHERE SalesOrder = @updated-SalesOrder
     INTO TABLE @DATA(sales_orders).

    " Stage Loyalty transactions to be created via composition _Transactions
    DATA: loyalty_transactions TYPE TABLE FOR CREATE ZLH_R_BusinessPartner\_Transactions.

    LOOP AT sales_orders ASSIGNING FIELD-SYMBOL(<sales_order>).

      " Only process orders that are complete (avoid premature transactions)
      CHECK <sales_order>-HdrGeneralIncompletionStatus = zif_lh_constants=>sales_order_completion_status.

      " Only process customers with an active membership
      SELECT SINGLE * FROM ZLH_R_Membership WHERE BusinessPartner  = @<sales_order>-SoldToParty INTO @DATA(membership_details).
      CHECK membership_details IS NOT INITIAL AND membership_details-MembershipEndDate = zif_lh_constants=>membership_enddate.

      " Idempotency: skip if we already created a loyalty transaction for this SalesOrder
      SELECT SINGLE @abap_true FROM zlh_r_transactions WHERE RefSalesorderId = @<sales_order>-SalesOrder INTO @DATA(existing_transaction).

      IF sy-subrc NE 0.


        APPEND INITIAL LINE TO loyalty_transactions ASSIGNING FIELD-SYMBOL(<loyalty_transaction>).

       " %tky specifies the key of the parent entity for composition create
        <loyalty_transaction>-%tky-SoldToParty = <sales_order>-SoldToParty.
        <loyalty_transaction>-%is_draft = if_abap_behv=>mk-off.

      " %target contains the fields for the child entity we want to create
      " %control-* marks the fields that we explicitly provide
        <loyalty_transaction>-%target = VALUE #( ( %cid = 'CID' && sy-tabix
                                                      ActivityType = zif_lh_constants=>activity-purchase
                                                      RefSalesorderId = <sales_order>-SalesOrder
                                                      TransactionAmount = <sales_order>-TotalNetAmount
                                                      TransactionCurrency = <sales_order>-TransactionCurrency
                                                      %control-RefSalesorderId = if_abap_behv=>mk-on
                                                      %control-ActivityType = if_abap_behv=>mk-on
                                                      %control-TransactionAmount = if_abap_behv=>mk-on
                                                      %control-TransactionCurrency = if_abap_behv=>mk-on  ) ).
      ENDIF.
    ENDLOOP.
    CHECK loyalty_transactions IS NOT INITIAL.
    MODIFY ENTITIES OF ZLH_R_BusinessPartner
    ENTITY ZLH_R_BusinessPartner
    CREATE BY \_Transactions
    FROM loyalty_transactions
    FAILED DATA(failed_items)
    REPORTED DATA(reported_items).

*    LOOP AT updated ASSIGNING FIELD-SYMBOL(<updated>).
**
*    ENDLOOP.
  ENDMETHOD.


ENDCLASS.