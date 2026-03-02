  METHOD if_sadl_exit_calc_element_read~get_calculation_info.

    CASE iv_entity.
      WHEN 'ZLH_C_BUSINESSPARTNER'.
        INSERT |MEMBERSHIPID| INTO TABLE et_requested_orig_elements.
        INSERT |SOLDTOPARTY| INTO TABLE et_requested_orig_elements.
    ENDCASE.

  ENDMETHOD.