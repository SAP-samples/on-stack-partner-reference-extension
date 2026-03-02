  METHOD init_log.
    TRY.
        " Initialize log with Object and Subobject
        mo_log = cl_bali_log=>create_with_header(
                   header = cl_bali_header_setter=>create( object = 'ZLH_APPLICATION_LOG'
                                                          subobject = 'ZLH_CATEGORY_UPDATE' ) ).
      CATCH cx_bali_runtime.
        CLEAR mo_log.
    ENDTRY.
  ENDMETHOD.