*"* use this source file for your ABAP unit test classes
CLASS ltcl_giftcard_api DEFINITION FINAL
  FOR TESTING DURATION MEDIUM RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-DATA:
      mo_environment TYPE REF TO if_cds_test_environment.

    CLASS-METHODS:
      class_setup,
      class_teardown.

    METHODS:
      setup,
      teardown,

      "Test methods for read_gift_card_balance
      read_no_giftcards   FOR TESTING,
      read_failed_entity  FOR TESTING,
      read_single_active  FOR TESTING,
      read_multi_active   FOR TESTING,
      read_with_inactive  FOR TESTING,
      read_overflow_check FOR TESTING,
      read_at_max_value   FOR TESTING,

      "Test methods for redeem_gift_card_amount
      redeem_insufficient FOR TESTING,
      redeem_exact_amt    FOR TESTING,
      redeem_partial      FOR TESTING,
      redeem_multi_cards  FOR TESTING,
      redeem_fifo         FOR TESTING,
      redeem_upd_fail     FOR TESTING,
      redeem_zero_remain  FOR TESTING.

    DATA:
      mo_cut             TYPE REF TO zcl_lh_giftcard_api,
      mo_cut_i           TYPE REF TO zif_lh_giftcard_api,
      mt_businesspartner TYPE STANDARD TABLE OF I_BusinessPartner,
      mt_giftcard        TYPE STANDARD TABLE OF zlh_giftcard,
      mt_soldtoparty     TYPE STANDARD TABLE OF ZLH_I_SoldToParty.

ENDCLASS.

CLASS ltcl_giftcard_api IMPLEMENTATION.

  METHOD class_setup.
    mo_environment = cl_cds_test_environment=>create_for_multiple_cds(
      i_for_entities = VALUE #(
        ( i_for_entity = 'ZLH_R_BusinessPartner' i_select_base_dependencies = abap_false )
        ( i_for_entity = 'ZLH_R_GIFTCARD' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    mo_environment->destroy( ).
  ENDMETHOD.
  METHOD setup.
    mo_environment->clear_doubles( ).
    CLEAR: mt_businesspartner, mt_giftcard.
    CREATE OBJECT mo_cut.
    mo_cut_i = zcl_lh_giftcard_api=>get_instance(  ).
  ENDMETHOD.

  METHOD teardown.
    zcl_lh_giftcard_api=>set_instance( io_instance = mo_cut_i ).
    ROLLBACK WORK.
    FREE mo_cut.
  ENDMETHOD.

  METHOD read_no_giftcards.
    DATA: total_balance TYPE zlh_giftcardamt,
          currency      TYPE zlh_currency.

    mt_businesspartner = VALUE #( ( BusinessPartner = '1000000001' ) ).
    mo_environment->insert_test_data( mt_businesspartner ).

    CLEAR mt_businesspartner.

    TRY.
        mo_cut->zif_lh_giftcard_api~read_gift_card_balance(
          EXPORTING business_partner = '1000000001'
          IMPORTING total_balance = total_balance
                    currency = currency ).
        cl_abap_unit_assert=>fail( 'Expected exception not raised' ).
      CATCH zcx_lh_giftcard INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->if_t100_message~t100key-msgid
          exp = zcx_lh_giftcard=>no_gift_cards-msgid
          msg = 'Wrong exception raised' ).
    ENDTRY.
  ENDMETHOD.

  METHOD read_failed_entity.
    DATA: total_balance TYPE zlh_giftcardamt,
          currency      TYPE zlh_currency.

    TRY.
        mo_cut->zif_lh_giftcard_api~read_gift_card_balance(
          EXPORTING business_partner = ''
          IMPORTING total_balance = total_balance
                    currency = currency ).
        cl_abap_unit_assert=>fail( 'Expected exception not raised' ).
      CATCH zcx_lh_giftcard.
        cl_abap_unit_assert=>assert_true( abap_true ).
    ENDTRY.
  ENDMETHOD.

  METHOD read_single_active.
    DATA: total_balance TYPE zlh_giftcardamt,
          currency      TYPE zlh_currency.

    mt_businesspartner = VALUE #( ( BusinessPartner = '1000000002' ) ).
    mt_giftcard = VALUE #(
      ( business_partner = '1000000002' Giftcardnumber = '001'
        giftcard_balance = '100.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' ) ).

    mo_environment->insert_test_data( mt_businesspartner ).
    mo_environment->insert_test_data( mt_giftcard ).

    CLEAR: mt_businesspartner, mt_giftcard.

    TRY.
        mo_cut->zif_lh_giftcard_api~read_gift_card_balance(
          EXPORTING business_partner = '1000000002'
          IMPORTING total_balance = total_balance
                    currency = currency ).

      CATCH zcx_lh_giftcard.

    ENDTRY.

    cl_abap_unit_assert=>assert_equals(
      act = total_balance exp = '100.00' msg = 'Balance mismatch' ).
    cl_abap_unit_assert=>assert_equals(
      act = currency exp = 'EUR' msg = 'Currency mismatch' ).
  ENDMETHOD.

  METHOD read_multi_active.
    DATA: total_balance TYPE zlh_giftcardamt,
          currency      TYPE zlh_currency.

    mt_businesspartner = VALUE #( ( BusinessPartner = '1000000003' ) ).
    mt_giftcard = VALUE #(
      ( business_partner = '1000000003' Giftcardnumber = '001'
        giftcard_balance = '100.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' )
      ( business_partner = '1000000003' Giftcardnumber = '002'
        giftcard_balance = '250.50' giftcard_currency = 'EUR'
        giftcard_status = 'A' )
      ( business_partner = '1000000003' Giftcardnumber = '003'
        giftcard_balance = '75.25' giftcard_currency = 'EUR'
        giftcard_status = 'A' ) ).

    mo_environment->insert_test_data( mt_businesspartner ).
    mo_environment->insert_test_data( mt_giftcard ).

    TRY.
        mo_cut->zif_lh_giftcard_api~read_gift_card_balance(
          EXPORTING business_partner = '1000000003'
          IMPORTING total_balance = total_balance
                    currency = currency ).

      CATCH zcx_lh_giftcard.

    ENDTRY.

    cl_abap_unit_assert=>assert_equals(
      act = total_balance exp = '425.75' msg = 'Total incorrect' ).
  ENDMETHOD.

  METHOD read_with_inactive.
    DATA: total_balance TYPE zlh_giftcardamt,
          currency      TYPE zlh_currency.

    mt_businesspartner = VALUE #( ( BusinessPartner = '1000000004' ) ).
    mt_giftcard = VALUE #(
      ( business_partner = '1000000004' Giftcardnumber = '001'
        giftcard_balance = '100.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' )
      ( business_partner = '1000000004' Giftcardnumber = '002'
        giftcard_balance = '200.00' giftcard_currency = 'EUR'
        giftcard_status = 'I' )
      ( business_partner = '1000000004' Giftcardnumber = '003'
        giftcard_balance = '50.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' ) ).


    mt_soldtoparty = VALUE #( ( SoldToParty = '1000000004' ) ).

    mo_environment->insert_test_data( mt_soldtoparty ).

    mo_environment->insert_test_data( mt_businesspartner ).
    mo_environment->insert_test_data( mt_giftcard ).

    TRY.

        mo_cut->zif_lh_giftcard_api~read_gift_card_balance(
          EXPORTING business_partner = '1000000004'
          IMPORTING total_balance = total_balance
                    currency = currency ).

      CATCH zcx_lh_giftcard.

    ENDTRY.

    cl_abap_unit_assert=>assert_equals(
      act = total_balance exp = '150.00'
      msg = 'Should sum only active' ).
  ENDMETHOD.

  METHOD read_overflow_check.
    DATA: total_balance TYPE zlh_giftcardamt,
          currency      TYPE zlh_currency.

    mt_businesspartner = VALUE #( ( BusinessPartner = '1000000005' ) ).
    mt_giftcard = VALUE #(
      ( business_partner = '1000000005' Giftcardnumber = '001'
        giftcard_balance = '999999.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' )
      ( business_partner = '1000000005' Giftcardnumber = '002'
        giftcard_balance = '999999.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' ) ).

    mt_soldtoparty = VALUE #( ( SoldToParty = '1000000005' ) ).

    mo_environment->insert_test_data( mt_soldtoparty ).

    mo_environment->insert_test_data( mt_businesspartner ).
    mo_environment->insert_test_data( mt_giftcard ).

    TRY.
        mo_cut->zif_lh_giftcard_api~read_gift_card_balance(
          EXPORTING business_partner = '1000000005'
          IMPORTING total_balance = total_balance
                    currency = currency ).

      CATCH zcx_lh_giftcard.

    ENDTRY.

    cl_abap_unit_assert=>assert_equals(
      act = total_balance
      exp = zif_lh_constants=>max_giftcard_value
      msg = 'Should be capped at max' ).
  ENDMETHOD.

  METHOD read_at_max_value.
    DATA: total_balance TYPE zlh_giftcardamt,
          currency      TYPE zlh_currency.

    mt_businesspartner = VALUE #( ( BusinessPartner = '1000000006' ) ).
    mt_giftcard = VALUE #(
      ( business_partner = '1000000006' Giftcardnumber = '001'
        giftcard_balance = zif_lh_constants=>max_giftcard_value
        giftcard_currency = 'EUR' giftcard_status = 'A' ) ).
    mt_soldtoparty = VALUE #( ( SoldToParty = '1000000006' ) ).

    mo_environment->insert_test_data( mt_soldtoparty ).
    mo_environment->insert_test_data( mt_businesspartner ).
    mo_environment->insert_test_data( mt_giftcard ).

    TRY.

        mo_cut->zif_lh_giftcard_api~read_gift_card_balance(
          EXPORTING business_partner = '1000000006'
          IMPORTING total_balance = total_balance
                    currency = currency ).
      CATCH zcx_lh_giftcard.

    ENDTRY.

    cl_abap_unit_assert=>assert_equals(
      act = total_balance
      exp = zif_lh_constants=>max_giftcard_value
      msg = 'Should handle max value' ).
  ENDMETHOD.

  METHOD redeem_insufficient.
    DATA: new_balance TYPE zlh_giftcardamt.

    mt_businesspartner = VALUE #( ( BusinessPartner = '2000000001' ) ).
    mt_giftcard = VALUE #(
      ( business_partner = '2000000001' Giftcardnumber = '100'
        giftcard_balance = '50.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' ) ).

    mo_environment->insert_test_data( mt_businesspartner ).
    mo_environment->insert_test_data( mt_giftcard ).

    TRY.
        mo_cut->zif_lh_giftcard_api~redeem_gift_card_amount(
          EXPORTING business_partner = '2000000001'
                    amount = '100.00'
                    currency = 'EUR'
          IMPORTING new_balance = new_balance ).
        cl_abap_unit_assert=>fail( 'Expected exception' ).
      CATCH zcx_lh_giftcard INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_equals(
          act = lx_error->if_t100_message~t100key-msgid
          exp = zcx_lh_giftcard=>insufficient_balance-msgid
          msg = 'Wrong exception' ).
    ENDTRY.
  ENDMETHOD.

  METHOD redeem_exact_amt.
    DATA: new_balance TYPE zlh_giftcardamt.

    mt_businesspartner = VALUE #( ( BusinessPartner = '2000000002' ) ).
    mt_giftcard = VALUE #(
      ( business_partner = '2000000002' Giftcardnumber = '101'
        giftcard_balance = '100.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' created_on = '20240101' ) ).

    mt_soldtoparty = VALUE #( ( SoldToParty = '2000000002' ) ).

    mo_environment->insert_test_data( mt_soldtoparty ).

    mo_environment->insert_test_data( mt_businesspartner ).
    mo_environment->insert_test_data( mt_giftcard ).

    TRY.
        mo_cut->zif_lh_giftcard_api~redeem_gift_card_amount(
          EXPORTING business_partner = '2000000002'
                    amount = '100.00'
                    currency = 'EUR'
          IMPORTING new_balance = new_balance ).

      CATCH zcx_lh_giftcard.

    ENDTRY.

    cl_abap_unit_assert=>assert_equals(
      act = new_balance exp = '0.00' msg = 'Balance should be zero' ).
  ENDMETHOD.

  METHOD redeem_partial.
    DATA: new_balance TYPE zlh_giftcardamt.

    mt_businesspartner = VALUE #( ( BusinessPartner = '2000000003' ) ).
    mt_giftcard = VALUE #(
      ( business_partner = '2000000003' Giftcardnumber = '102'
        giftcard_balance = '200.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' created_on = '20240101' ) ).

    mt_soldtoparty = VALUE #( ( SoldToParty = '2000000003' ) ).

    mo_environment->insert_test_data( mt_soldtoparty ).

    mo_environment->insert_test_data( mt_businesspartner ).
    mo_environment->insert_test_data( mt_giftcard ).

    TRY.

        mo_cut->zif_lh_giftcard_api~redeem_gift_card_amount(
          EXPORTING business_partner = '2000000003'
                    amount = '75.00'
                    currency = 'EUR'
          IMPORTING new_balance = new_balance ).

      CATCH zcx_lh_giftcard.

    ENDTRY.

    cl_abap_unit_assert=>assert_equals(
      act = new_balance exp = '125.00' msg = 'Partial redeem failed' ).
  ENDMETHOD.

  METHOD redeem_multi_cards.
    DATA: new_balance TYPE zlh_giftcardamt.

    mt_businesspartner = VALUE #( ( BusinessPartner = '2000000004' ) ).
    mt_giftcard = VALUE #(
      ( business_partner = '2000000004' Giftcardnumber = '103'
        giftcard_balance = '50.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' created_on = '20240101' )
      ( business_partner = '2000000004' Giftcardnumber = '104'
        giftcard_balance = '100.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' created_on = '20240102' ) ).

    mt_soldtoparty = VALUE #( ( SoldToParty = '2000000004' ) ).

    mo_environment->insert_test_data( mt_soldtoparty ).

    mo_environment->insert_test_data( mt_businesspartner ).
    mo_environment->insert_test_data( mt_giftcard ).


    TRY.

        mo_cut->zif_lh_giftcard_api~redeem_gift_card_amount(
          EXPORTING business_partner = '2000000004'
                    amount = '120.00'
                    currency = 'EUR'
          IMPORTING new_balance = new_balance ).

      CATCH zcx_lh_giftcard.

    ENDTRY.

    cl_abap_unit_assert=>assert_equals(
      act = new_balance exp = '30.00' msg = 'Multi-card redeem failed' ).
  ENDMETHOD.

  METHOD redeem_fifo.
    DATA: new_balance TYPE zlh_giftcardamt.

    mt_businesspartner = VALUE #( ( BusinessPartner = '2000000005' ) ).
    mt_giftcard = VALUE #(
      ( business_partner = '2000000005' Giftcardnumber = '105'
        giftcard_balance = '40.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' created_on = '20240103' )
      ( business_partner = '2000000005' Giftcardnumber = '106'
        giftcard_balance = '60.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' created_on = '20240101' ) ).


    mt_soldtoparty = VALUE #( ( SoldToParty = '2000000005' ) ).

    mo_environment->insert_test_data( mt_soldtoparty ).

    mo_environment->insert_test_data( mt_businesspartner ).
    mo_environment->insert_test_data( mt_giftcard ).

    TRY.

        mo_cut->zif_lh_giftcard_api~redeem_gift_card_amount(
          EXPORTING business_partner = '2000000005'
                    amount = '70.00'
                    currency = 'EUR'
          IMPORTING new_balance = new_balance ).

      CATCH zcx_lh_giftcard.

    ENDTRY.

    cl_abap_unit_assert=>assert_equals(
      act = new_balance exp = '30.00' msg = 'FIFO order failed' ).
  ENDMETHOD.

  METHOD redeem_upd_fail.
    DATA: new_balance TYPE zlh_giftcardamt.

    mt_businesspartner = VALUE #( ( BusinessPartner = '2000000006' ) ).
    mt_giftcard = VALUE #(
      ( business_partner = '2000000006' Giftcardnumber = '107'
        giftcard_balance = '100.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' created_on = '20240101' ) ).

    mt_soldtoparty = VALUE #( ( SoldToParty = '2000000006' ) ).

    mo_environment->insert_test_data( mt_soldtoparty ).

    mo_environment->insert_test_data( mt_businesspartner ).
    mo_environment->insert_test_data( mt_giftcard ).

    TRY.
        mo_cut->zif_lh_giftcard_api~redeem_gift_card_amount(
          EXPORTING business_partner = '2000000006'
                    amount = '50.00'
                    currency = 'EUR'
          IMPORTING new_balance = new_balance ).

      CATCH zcx_lh_giftcard.

    ENDTRY.


    cl_abap_unit_assert=>assert_equals(
      act = new_balance exp = '50.00' msg = 'Update test failed' ).
  ENDMETHOD.

  METHOD redeem_zero_remain.
    DATA: new_balance TYPE zlh_giftcardamt.

    mt_businesspartner = VALUE #( ( BusinessPartner = '2000000007' ) ).
    mt_giftcard = VALUE #(
      ( business_partner = '2000000007' Giftcardnumber = '108'
        giftcard_balance = '25.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' created_on = '20240101' )
      ( business_partner = '2000000007' Giftcardnumber = '109'
        giftcard_balance = '75.00' giftcard_currency = 'EUR'
        giftcard_status = 'A' created_on = '20240102' ) ).

    mt_soldtoparty = VALUE #( ( SoldToParty = '2000000007' ) ).

    mo_environment->insert_test_data( mt_soldtoparty ).

    mo_environment->insert_test_data( mt_businesspartner ).
    mo_environment->insert_test_data( mt_giftcard ).

    TRY.
        mo_cut->zif_lh_giftcard_api~redeem_gift_card_amount(
          EXPORTING business_partner = '2000000007'
                    amount = '25.00'
                    currency = 'EUR'
          IMPORTING new_balance = new_balance ).

      CATCH zcx_lh_giftcard.

    ENDTRY.

    cl_abap_unit_assert=>assert_equals(
      act = new_balance exp = '75.00' msg = 'Zero remaining test failed' ).
  ENDMETHOD.

ENDCLASS.