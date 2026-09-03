"! <p class="shorttext synchronized">MDG ID Generator - SGRE Bank GL Account Naming UIBB</p>
"! Siemens Gamesa (SGRE) bank GL account naming-convention feeder.
"! Sets the project code so the number generator factory resolves
"! ZCL_MDG_SG_ACCT_ID_GEN, and provides the OVS value helps for the
"! account group, bank, currency and payment method fields from the
"! hard-coded rule tables (ZCL_MDG_SG_ACCT_RULES).
CLASS zcl_mdg_sg_acc_id_a_gen DEFINITION
  PUBLIC
  INHERITING FROM zcl_mdg_0g_acc_id_a_gen
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS if_fpm_guibb~initialize REDEFINITION .
    METHODS if_fpm_guibb_form~get_definition REDEFINITION .
    METHODS if_fpm_guibb_form~get_data REDEFINITION .

  PROTECTED SECTION.
    METHODS ovs_handle_phase_2 REDEFINITION .

  PRIVATE SECTION.

    CONSTANTS:
      lc_bank_code     TYPE name_komp VALUE 'BANK_CODE',
      lc_currency      TYPE name_komp VALUE 'CURRENCY',
      lc_account_group TYPE name_komp VALUE 'ACCOUNT_GROUP',
      lc_payment_meth  TYPE name_komp VALUE 'PAYMENT_METHOD'.

    METHODS build_ovs_table
      IMPORTING !iv_field_name TYPE name_komp
      RETURNING VALUE(rr_output) TYPE REF TO data .

ENDCLASS.



CLASS zcl_mdg_sg_acc_id_a_gen IMPLEMENTATION.


  METHOD if_fpm_guibb~initialize.
    CONSTANTS lc_proj_sgre TYPE ze_mdg_project_code VALUE 'SGRE'.

    CALL METHOD super->if_fpm_guibb~initialize
      EXPORTING
        it_parameter      = it_parameter
        io_app_parameter  = io_app_parameter
        iv_component_name = iv_component_name
        is_config_key     = is_config_key
        iv_instance_id    = iv_instance_id.

    me->fd_project_name = lc_proj_sgre.
  ENDMETHOD.


  METHOD if_fpm_guibb_form~get_data.
    " PAYMENT_METHOD only feeds position 8 for Interim Out (485) and
    " Interim IHB (488); for Main / IHB / Interim In it is fixed
    " (0 / 0 / 1). Hide the field unless the chosen group needs it.
    CALL METHOD super->if_fpm_guibb_form~get_data
      EXPORTING
        io_event                = io_event
        iv_raised_by_own_ui     = iv_raised_by_own_ui
        it_selected_fields      = it_selected_fields
        iv_edit_mode            = iv_edit_mode
        io_extended_ctrl        = io_extended_ctrl
      IMPORTING
        et_messages             = et_messages
        ev_data_changed         = ev_data_changed
        ev_field_usage_changed  = ev_field_usage_changed
        ev_action_usage_changed = ev_action_usage_changed
      CHANGING
        cs_data                 = cs_data
        ct_field_usage          = ct_field_usage
        ct_action_usage         = ct_action_usage.

    DATA lv_kind TYPE ze_mdg_acct_group_kind.
    ASSIGN COMPONENT lc_account_group OF STRUCTURE cs_data TO FIELD-SYMBOL(<lv_kind>).
    IF <lv_kind> IS ASSIGNED.
      lv_kind = <lv_kind>.
    ENDIF.

    DATA(lv_visibility) = COND #(
      WHEN lv_kind = zcl_mdg_sg_acct_rules=>c_kind-int_out
        OR lv_kind = zcl_mdg_sg_acct_rules=>c_kind-ihb_int
      THEN if_fpm_constants=>gc_visibility-visible
      ELSE if_fpm_constants=>gc_visibility-not_visible ).

    LOOP AT ct_field_usage ASSIGNING FIELD-SYMBOL(<lwa_fu>)
         WHERE name = lc_payment_meth
            OR name = lc_payment_meth && cl_usmd_generic_genil_text=>gv_text_suffix.
      <lwa_fu>-visibility = lv_visibility.
    ENDLOOP.
    ev_field_usage_changed = abap_true.
  ENDMETHOD.


  METHOD if_fpm_guibb_form~get_definition.
    " Same ovs_name (this feeder's class name) for every value-help field
    " so FPM uses one OVS usage for the feeder and OVS_HANDLE_PHASE_2
    " branches on the field name. Unique across the floorplan, unlike the
    " bare field name.
    DATA(lfd_ovs_name) = CONV name_komp(
      replace( val  = cl_abap_classdescr=>get_class_name( me )
               sub  = '\CLASS='
               with = '' ) ).

    CALL METHOD super->if_fpm_guibb_form~get_definition
      IMPORTING
        eo_field_catalog         = eo_field_catalog
        et_field_description      = et_field_description
        et_action_definition     = et_action_definition
        et_special_groups        = et_special_groups
        et_dnd_definition        = et_dnd_definition
        es_options               = es_options
        es_message               = es_message
        ev_additional_error_info = ev_additional_error_info.

    LOOP AT et_field_description ASSIGNING FIELD-SYMBOL(<lwa_fd>)
         WHERE name = lc_account_group
            OR name = lc_bank_code
            OR name = lc_currency
            OR name = lc_payment_meth.
      <lwa_fd>-ovs_name = lfd_ovs_name.
    ENDLOOP.
  ENDMETHOD.


  METHOD ovs_handle_phase_2.
    " Build the value help for the field, then filter it by the user's
    " query. The generic wrapper in ZCL_MDG_ID_UIBB_FEEDER hands the
    " result to the OVS.
    prd_r_output = build_ovs_table( pfd_i_field_name ).

    IF prd_r_output IS BOUND.
      me->ovs_output_filter(
        EXPORTING
          pfd_i_field_name      = pfd_i_field_name
          prd_i_query_parameter = pri_i_ovs_callback->query_parameters
        CHANGING
          prd_c_output          = prd_r_output ).
    ENDIF.
  ENDMETHOD.


  METHOD build_ovs_table.
    DATA lit_out TYPE usmdz10_ts_ovs_output.

    CASE iv_field_name.
      WHEN lc_bank_code.
        " every bank row - incl. the "(Bank account# N)" variants - so the
        " user picks the exact code they want (03 / 33 / 3A / 3B ...).
        LOOP AT zcl_mdg_sg_acct_rules=>get_bank_codes( ) INTO DATA(ls_bank).
          INSERT VALUE usmdz10_s_ovs_output(
                   key  = ls_bank-code
                   text = |{ ls_bank-name } ({ ls_bank-code })| ) INTO TABLE lit_out.
        ENDLOOP.

      WHEN lc_currency.
        LOOP AT zcl_mdg_sg_acct_rules=>get_currency_codes( ) INTO DATA(ls_ccy).
          INSERT VALUE usmdz10_s_ovs_output(
                   key  = ls_ccy-iso
                   text = |{ ls_ccy-iso } - { ls_ccy-country }| ) INTO TABLE lit_out.
        ENDLOOP.

      WHEN lc_account_group.
        LOOP AT zcl_mdg_sg_acct_rules=>get_account_groups( ) INTO DATA(ls_grp).
          INSERT VALUE usmdz10_s_ovs_output(
                   key  = ls_grp-kind
                   text = |{ ls_grp-grp } - { ls_grp-descr }| ) INTO TABLE lit_out.
        ENDLOOP.

      WHEN lc_payment_meth.
        LOOP AT zcl_mdg_sg_acct_rules=>get_planning_levels( ) INTO DATA(ls_pl).
          INSERT VALUE usmdz10_s_ovs_output(
                   key  = ls_pl-pmethod
                   text = |{ ls_pl-pmethod } - { ls_pl-descr } ({ ls_pl-level })| ) INTO TABLE lit_out.
        ENDLOOP.

      WHEN OTHERS.
        RETURN.
    ENDCASE.

    CREATE DATA rr_output TYPE usmdz10_ts_ovs_output.
    ASSIGN rr_output->* TO FIELD-SYMBOL(<lit>).
    IF <lit> IS ASSIGNED.
      <lit> = lit_out.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
