"! <p class="shorttext synchronized">MDG ID Generator - SGRE Bank GL Account Naming UIBB</p>
"! Siemens Gamesa (SGRE) bank GL account naming-convention feeder.
"! Sets the project code so the number generator factory resolves
"! ZCL_MDG_SG_ACCT_ID_GEN, and provides the OVS value helps for the
"! account group, bank, currency and payment method fields from the
"! hard-coded rule tables (ZCL_MDG_SG_ACCT_RULES).
CLASS zcl_mdg_sg_acctid_rule DEFINITION
  PUBLIC
  INHERITING FROM zcl_mdg_sgre_acc_id_a_gen
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS if_fpm_guibb~initialize REDEFINITION .
    METHODS if_fpm_guibb_form~get_definition REDEFINITION .
    METHODS if_fpm_guibb_ovs~handle_phase_2 REDEFINITION .

  PROTECTED SECTION.
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



CLASS zcl_mdg_sg_acctid_rule IMPLEMENTATION.


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


  METHOD if_fpm_guibb_form~get_definition.
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

    " Enable the OVS on the fields that have a hard-coded value help.
    LOOP AT et_field_description ASSIGNING FIELD-SYMBOL(<lwa_fd>)
         WHERE name = lc_account_group
            OR name = lc_bank_code
            OR name = lc_currency
            OR name = lc_payment_meth.
      <lwa_fd>-ovs_name = <lwa_fd>-name.
    ENDLOOP.
  ENDMETHOD.


  METHOD if_fpm_guibb_ovs~handle_phase_2.
    FIELD-SYMBOLS <lit_output> TYPE ANY TABLE.

    DATA(lrd_output) = build_ovs_table( iv_field_name ).

    IF lrd_output IS NOT BOUND.
      CREATE DATA lrd_output TYPE crmt_text_value_pair_tab.
    ENDIF.

    ASSIGN lrd_output->* TO <lit_output>.
    IF <lit_output> IS ASSIGNED.
      me->ovs_output_filter(
        EXPORTING
          pfd_i_field_name      = iv_field_name
          prd_i_query_parameter = io_ovs_callback->query_parameters
        CHANGING
          prd_c_output          = lrd_output ).
      ASSIGN lrd_output->* TO <lit_output>.
      io_ovs_callback->set_output_table( output = <lit_output> ).
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
