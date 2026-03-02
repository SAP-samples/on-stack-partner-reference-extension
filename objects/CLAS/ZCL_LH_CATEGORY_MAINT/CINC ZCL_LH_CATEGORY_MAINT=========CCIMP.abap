CLASS LHC_ZLH_R_CATEGORY_MAINT DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PUBLIC SECTION.
    CONSTANTS:
      CO_ENTITY TYPE abp_entity_name VALUE `ZLH_R_CATEGORY_MAINT`,
      CO_TRANSPORT_OBJECT TYPE mbc_cp_api=>indiv_transaction_obj_name VALUE `ZLH_TO_CATEGORY`,
      CO_AUTHORIZATION_ENTITY TYPE abp_entity_name VALUE `ZLH_R_CATEGORY_HDR`.

  PRIVATE SECTION.
    METHODS:
      GET_INSTANCE_FEATURES FOR INSTANCE FEATURES
        IMPORTING
          KEYS REQUEST requested_features FOR MaintainCategory
        RESULT result,
      SELECTCUSTOMIZINGTRANSPTREQ FOR MODIFY
        IMPORTING
          KEYS FOR ACTION MaintainCategory~SelectCustomizingTransptReq
        RESULT result,
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR MaintainCategory
        RESULT result,
      EDIT FOR MODIFY
        IMPORTING
          KEYS FOR ACTION MaintainCategory~edit,
      EARLY_NUMBERING_CBA_CAT_HDR FOR NUMBERING
        IMPORTING entities FOR CREATE MaintainCategory\_CategoryHeader.
ENDCLASS.

CLASS LHC_ZLH_R_CATEGORY_MAINT IMPLEMENTATION.
  METHOD GET_INSTANCE_FEATURES.
  mbc_cp_api=>rap_bc_api( )->get_instance_features(
    transport_object   = co_transport_object
    entity             = co_entity
    keys               = REF #( keys )
    requested_features = REF #( requested_features )
    result             = REF #( result )
    failed             = REF #( failed )
    reported           = REF #( reported ) ).
  ENDMETHOD.
  METHOD SELECTCUSTOMIZINGTRANSPTREQ.
  mbc_cp_api=>rap_bc_api( )->select_transport_action(
    entity   = co_entity
    keys     = REF #( keys )
    result   = REF #( result )
    mapped   = REF #( mapped )
    failed   = REF #( failed )
    reported = REF #( reported ) ).
  ENDMETHOD.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
  mbc_cp_api=>rap_bc_api( )->get_global_authorizations(
    entity                   = co_authorization_entity
    requested_authorizations = REF #( requested_authorizations )
    result                   = REF #( result )
    reported                 = REF #( reported ) ).
  ENDMETHOD.
  METHOD EDIT.
  mbc_cp_api=>rap_bc_api( )->get_default_transport_request(
    transport_object = co_transport_object
    entity           = co_entity
    keys             = REF #( keys )
    mapped           = REF #( mapped )
    failed           = REF #( failed )
    reported         = REF #( reported ) ).
  ENDMETHOD.
  METHOD EARLY_NUMBERING_CBA_CAT_HDR.
    DATA:
      CurrentCategoryID   TYPE zlh_category_id,
      use_number_range    TYPE abap_bool VALUE abap_true.

      DATA(Categories) = entities[ 1 ]-%target.
      DELETE Categories WHERE Categoryid NE 0.

      IF lines( Categories ) GT 0.
        "Get numbers
        TRY.
          cl_numberrange_runtime=>number_get(
            EXPORTING
              nr_range_nr       = '01'
              object            = 'ZLH_CID'
              quantity          = CONV #( lines( Categories ) )
            IMPORTING
              number            = DATA(number_range_key)
              returncode        = DATA(number_range_return_code)
              returned_quantity = DATA(number_range_returned_quantity)
              ).
        CATCH cx_number_ranges INTO DATA(lx_number_ranges).
          LOOP AT Categories INTO DATA(Category).
            APPEND VALUE #(  %cid      = Category-%cid
                             %key      = Category-%key
                             %is_draft = Category-%is_draft
                             %msg      = lx_number_ranges
                          ) TO reported-categoryheader.
            APPEND VALUE #(  %cid      = Category-%cid
                             %key      = Category-%key
                             %is_draft = Category-%is_draft
                          ) TO failed-categoryheader.
          ENDLOOP.
          EXIT.
        ENDTRY.
" Calculate starting ID (inclusive)
        currentcategoryid = number_range_key - number_range_returned_quantity.
        LOOP AT Categories INTO Category.
          currentcategoryid += 1.
          Category-Categoryid = currentcategoryid.

          APPEND VALUE #( %cid      = Category-%cid
                          %key      = Category-%key
                          %is_draft = Category-%is_draft
                        ) TO mapped-categoryheader.
        ENDLOOP.
      ELSE.
      " No number range required – just map directly
        LOOP AT entities[ 1 ]-%target INTO DATA(entity).
          APPEND VALUE #( %cid = entity-%cid
                          %key = entity-%key ) TO mapped-categoryheader.
          mapped-categoryheader[ sy-tabix ]-%is_draft = entity-%is_draft.
        ENDLOOP.
      ENDIF.
  ENDMETHOD.
ENDCLASS.
CLASS LSC_ZLH_R_CATEGORY_MAINT DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_SAVER.
  PROTECTED SECTION.
    METHODS:
      SAVE_MODIFIED REDEFINITION.
ENDCLASS.

CLASS LSC_ZLH_R_CATEGORY_MAINT IMPLEMENTATION.
  METHOD SAVE_MODIFIED.
  mbc_cp_api=>rap_bc_api( )->record_changes(
    transport_object = lhc_ZLH_R_CATEGORY_MAINT=>co_transport_object
    entity           = lhc_ZLH_R_CATEGORY_MAINT=>co_entity
    create           = REF #( create )
    update           = REF #( update )
    delete           = REF #( delete )
    reported         = REF #( reported ) ).
  mbc_cp_api=>rap_bc_api( )->update_last_changed_date_time(
    maintenance_object = 'ZLH_BCMO_CATEGORY'
    entity             = lhc_ZLH_R_CATEGORY_MAINT=>co_authorization_entity
    create             = REF #( create )
    update             = REF #( update )
    delete             = REF #( delete )
    reported           = REF #( reported ) ).
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZLH_R_CATEGORY_TEXT DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PUBLIC SECTION.
    CONSTANTS:
      CO_ENTITY TYPE sxco_cds_object_name VALUE `ZLH_R_CATEGORY_TEXT`.

  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_FEATURES FOR GLOBAL FEATURES
        IMPORTING
          REQUEST REQUESTED_FEATURES FOR CategoryText
        RESULT result.
ENDCLASS.

CLASS LHC_ZLH_R_CATEGORY_TEXT IMPLEMENTATION.
  METHOD GET_GLOBAL_FEATURES.
  mbc_cp_api=>rap_bc_api( )->get_global_features(
    transport_object   = lhc_ZLH_R_CATEGORY_MAINT=>co_transport_object
    entity             = co_entity
    requested_features = REF #( requested_features )
    result             = REF #( result )
    reported           = REF #( reported ) ).
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZLH_R_CATEGORY_HDR DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PUBLIC SECTION.
    CONSTANTS:
      CO_ENTITY TYPE sxco_cds_object_name VALUE `ZLH_R_CATEGORY_HDR`.

  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_FEATURES FOR GLOBAL FEATURES
        IMPORTING
          REQUEST REQUESTED_FEATURES FOR CategoryHeader
        RESULT result,
      VALIDATETRANSPORTREQUEST FOR VALIDATE ON SAVE
        IMPORTING
          KEYS_MAINTAINCATEGORY FOR MaintainCategory~ValidateTransportRequest
          KEYS_CATEGORYHEADER FOR CategoryHeader~ValidateTransportRequest
          KEYS_CATEGORYTEXT FOR CategoryText~ValidateTransportRequest.
ENDCLASS.

CLASS LHC_ZLH_R_CATEGORY_HDR IMPLEMENTATION.
  METHOD GET_GLOBAL_FEATURES.
  mbc_cp_api=>rap_bc_api( )->get_global_features(
    transport_object   = lhc_ZLH_R_CATEGORY_MAINT=>co_transport_object
    entity             = co_entity
    requested_features = REF #( requested_features )
    result             = REF #( result )
    reported           = REF #( reported ) ).
  ENDMETHOD.
  METHOD VALIDATETRANSPORTREQUEST.
  mbc_cp_api=>rap_bc_api( )->validate_transport_request(
    transport_object = lhc_ZLH_R_CATEGORY_MAINT=>co_transport_object
    entity           = lhc_ZLH_R_CATEGORY_MAINT=>co_entity
    validation_keys  = VALUE #( ( REF #( keys_MaintainCategory ) )
                                ( REF #( keys_CategoryHeader ) )
                                ( REF #( keys_CategoryText ) ) )
    failed           = REF #( failed )
    reported         = REF #( reported ) ).
  ENDMETHOD.
ENDCLASS.