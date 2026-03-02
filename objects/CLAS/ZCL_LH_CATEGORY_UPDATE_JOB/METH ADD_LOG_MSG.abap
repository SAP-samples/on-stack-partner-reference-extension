  METHOD add_log_msg.
    TRY.
        DATA(lo_free_text) = cl_bali_free_text_setter=>create(
                               severity = iv_ty
                               text     = |{ iv_text }| ).
        IF mo_log IS BOUND.
          mo_log->add_item( item = lo_free_text ).
          cl_bali_log_db=>get_instance( )->save_log(
            log                       = mo_log
            assign_to_current_appl_job = abap_true ).
        ENDIF.
      CATCH cx_bali_runtime.
        CLEAR lo_free_text.
        " ##NO_HANDLER
        " Handle logging exceptions if necessary
    ENDTRY.
  ENDMETHOD.