**"* use this source file for your ABAP unit test classes
*CLASS ltc_giftcard_api DEFINITION FINAL FOR TESTING
*  DURATION LONG
*  RISK LEVEL HARMLESS.
*
*  PRIVATE SECTION.
*    METHODS:
*      setup,
*      test_get_balance FOR TESTING,
*      test_redeem      FOR TESTING.
*
*    DATA:
*      gv_soldto   TYPE zlh_businesspartner,
*      gv_currency TYPE zlh_currency.
*
*ENDCLASS.
*
*
*
*CLASS ltc_giftcard_api IMPLEMENTATION.
*
*  METHOD setup.
*    "Set a test Sold-To Party known to have Gift Cards
*    gv_soldto = '9980000003'.
*    gv_currency = 'EUR'.
*  ENDMETHOD.
*
*
*  METHOD test_get_balance.
*    DATA: lv_balance TYPE zlh_giftcardamt,
*          lv_curr    TYPE zlh_currency.
*
*    zcl_lh_giftcard_api=>read_gift_card_balance(
*      EXPORTING business_partner = gv_soldto
*      IMPORTING total_balance = lv_balance
*                currency      = lv_curr ).
*
*    cl_abap_unit_assert=>assert_not_initial(
*      act = lv_balance
*      msg = |Gift card balance should not be initial for { gv_soldto }| ).
*
*    cl_abap_unit_assert=>assert_equals(
*      act = lv_curr
*      exp = gv_currency
*      msg = |Currency mismatch for Gift Card balance| ).
*  ENDMETHOD.
*
*
*  METHOD test_redeem.
*    DATA: lv_message      TYPE string,
*          lv_new_balance  TYPE zlh_giftcardamt,
*          lv_redeem_value TYPE zlh_giftcardamt VALUE '100'.
*
**    zcl_lh_giftcard_api=>redeem_gift_card_amount(
**      EXPORTING iv_business_partner   = gv_soldto
**                iv_amount   = lv_redeem_value
**                iv_currency = gv_currency
**      IMPORTING ev_message      = lv_message
**                ev_new_balance = lv_new_balance
**                ev_status = DATA(lv_status) ).
*
*    cl_abap_unit_assert=>assert_not_initial(
*      act = lv_message
*      msg = |Redemption did not return a status| ).
*
*    cl_abap_unit_assert=>assert_true(
*      act = xsdbool( lv_new_balance >= 0 )
*      msg = |New balance cannot be negative| ).
*
**    cl_abap_unit_assert=>assert_contains(
**      act = lv_status
**      sub = 'successful'
**      msg = |Expected redemption success message, got: { lv_status }| ).
*  ENDMETHOD.
*
*ENDCLASS.