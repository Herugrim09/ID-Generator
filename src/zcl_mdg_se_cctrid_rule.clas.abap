"! <p class="shorttext synchronized">MDG ID Generator - SE Cost Center Naming UIBB</p>
"! Ported from /S4E/CL_P40_MDG_0G_SE_CCTRID_R.
"! Siemens Energy cost center naming-convention feeder: profit center
"! and CTS sub-function value helps (OVS + BRF+), profit center text
"! resolution and project assignment (SE).
CLASS zcl_mdg_se_cctrid_rule DEFINITION
  PUBLIC
  INHERITING FROM zcl_mdg_cctrid_rule
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS if_fpm_guibb_form~get_data REDEFINITION .
    METHODS if_fpm_guibb_form~get_definition REDEFINITION .
    METHODS ovs_handle_phase_2 REDEFINITION .
    METHODS if_fpm_guibb~initialize REDEFINITION .

  PROTECTED SECTION.
    DATA it_profit_centers TYPE usmdz10_ts_ovs_output .
    METHODS on_zattr_selected REDEFINITION .

  PRIVATE SECTION.

    METHODS ovs_output_profit_center
      IMPORTING
        !pfd_i_field_name      TYPE name_komp
        !prd_i_query_parameter TYPE REF TO data
      EXPORTING
        !prd_e_output          TYPE REF TO data .
    METHODS ovs_output_cts_sub_func
      IMPORTING
        !pfd_i_field_name      TYPE name_komp
        !prd_i_query_parameter TYPE REF TO data
      EXPORTING
        !prd_e_output          TYPE REF TO data .
    METHODS get_cts_sub_functions
      IMPORTING
        !pfd_i_cts_main TYPE ze_mdg_cost_center_cts_func
      EXPORTING
        !pit_e_cts_sub  TYPE zcl_mdg_cctr_rules=>tt_func .
    METHODS read_profit_centers .

ENDCLASS.



CLASS zcl_mdg_se_cctrid_rule IMPLEMENTATION.


  METHOD get_cts_sub_functions.
    " TODO: environment-specific BRF+ function id - move to customizing.
    CONSTANTS:
      lc_function_id TYPE if_fdt_types=>id VALUE '55228BB355D61EEF92D2CBE998E98805',
      lc_cts_func    TYPE string VALUE 'CTS_FUNC',
      lc_data_object TYPE string VALUE '_V_RESULT'.

    DATA:
      lfd_timestamp  TYPE timestamp,
      lit_name_value TYPE abap_parmbind_tab,
      lwa_name_value TYPE abap_parmbind,
      lrd_data       TYPE REF TO data,
      lrcx_fdt       TYPE REF TO cx_fdt ##NEEDED,
      lfd_cts_func   TYPE if_fdt_types=>element_number.

    FIELD-SYMBOLS <lit_any> TYPE any.

    GET TIME STAMP FIELD lfd_timestamp.

    lwa_name_value-name = lc_cts_func.
    lfd_cts_func = pfd_i_cts_main.
    GET REFERENCE OF lfd_cts_func INTO lrd_data.
    lwa_name_value-value = lrd_data.
    INSERT lwa_name_value INTO TABLE lit_name_value.
    CLEAR lwa_name_value.

    cl_fdt_function_process=>get_data_object_reference(
      EXPORTING
        iv_function_id      = lc_function_id
        iv_data_object      = lc_data_object
        iv_timestamp        = lfd_timestamp
        iv_trace_generation = abap_false
      IMPORTING
        er_data             = lrd_data ).
    ASSIGN lrd_data->* TO <lit_any>.
    TRY.
        cl_fdt_function_process=>process(
          EXPORTING
            iv_function_id = lc_function_id
            iv_timestamp   = lfd_timestamp
          IMPORTING
            ea_result      = <lit_any>
          CHANGING
            ct_name_value  = lit_name_value ).
      CATCH cx_fdt INTO lrcx_fdt ##NO_HANDLER.
        " TODO: log the BRF+ error instead of swallowing it.
    ENDTRY.

    MOVE-CORRESPONDING <lit_any> TO pit_e_cts_sub.
  ENDMETHOD.


  METHOD if_fpm_guibb_form~get_data.
    DATA:
      lfd_prctr     TYPE prctr,
      lfd_text_comp TYPE name_komp.

    FIELD-SYMBOLS:
      <lfd_target> TYPE any,
      <lfd_any>    TYPE any.

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

    UNASSIGN <lfd_any>.
    ASSIGN COMPONENT zif_mdg_id_constants=>c_attributes-profit_center OF STRUCTURE cs_data TO <lfd_any>.
    IF <lfd_any> IS ASSIGNED.
      lfd_prctr = <lfd_any>.
    ENDIF.

    IF lfd_prctr IS NOT INITIAL.
      CASE io_event->mv_event_id.
        WHEN c_action_id.
          IF iv_raised_by_own_ui EQ abap_true.
            lfd_text_comp = |{ zif_mdg_id_constants=>c_attributes-profit_center }{ cl_usmd_generic_genil_text=>gv_text_suffix }|.
            UNASSIGN <lfd_any>.
            ASSIGN COMPONENT lfd_text_comp OF STRUCTURE cs_data TO <lfd_target>.
            IF <lfd_target> IS ASSIGNED.
              IF me->it_profit_centers IS INITIAL.
                me->read_profit_centers( ).
              ENDIF.
              ASSIGN me->it_profit_centers[ key = lfd_prctr ] TO FIELD-SYMBOL(<lwa_profit_centers>).
              IF <lwa_profit_centers> IS ASSIGNED.
                <lfd_target>    = <lwa_profit_centers>-text.
                ev_data_changed = abap_true.
              ENDIF.
            ENDIF.
          ENDIF.
      ENDCASE.
    ENDIF.
  ENDMETHOD.


  METHOD if_fpm_guibb_form~get_definition.
    DATA lit_field_description TYPE fpmgb_t_formfield_descr.

    CALL METHOD super->if_fpm_guibb_form~get_definition
      IMPORTING
        eo_field_catalog         = eo_field_catalog
        et_field_description      = et_field_description
        et_action_definition      = et_action_definition
        et_special_groups         = et_special_groups
        et_dnd_definition         = et_dnd_definition
        es_options                = es_options
        es_message                = es_message
        ev_additional_error_info  = ev_additional_error_info.

    DATA(lfd_class_name) = cl_abap_classdescr=>get_class_name( me ).
    DATA(lit_components) = rc_structure->get_components( ).
    LOOP AT lit_components ASSIGNING FIELD-SYMBOL(<lwa_field>).
      READ TABLE et_field_description ASSIGNING FIELD-SYMBOL(<lwa_field_descr>) WITH TABLE KEY name = CONV #( <lwa_field>-name ).
      IF <lwa_field_descr> IS ASSIGNED.
        IF NOT <lwa_field_descr>-read_only = abap_true.
          <lwa_field_descr>-ovs_name = lfd_class_name+7(40).
        ENDIF.
      ENDIF.
    ENDLOOP.
    INSERT LINES OF lit_field_description INTO TABLE et_field_description. "#EC CI_CONV_OK
  ENDMETHOD.


  METHOD ovs_handle_phase_2.
    " Field OVS logic. The generic wrapper in ZCL_MDG_ID_UIBB_FEEDER
    " falls back to an empty table and calls SET_OUTPUT_TABLE.
    CASE pfd_i_field_name.
      WHEN zif_mdg_id_constants=>c_attributes-profit_center.
        me->ovs_output_profit_center(
          EXPORTING
            pfd_i_field_name      = pfd_i_field_name
            prd_i_query_parameter = pri_i_ovs_callback->query_parameters
          IMPORTING
            prd_e_output          = prd_r_output ).

      WHEN zif_mdg_id_constants=>c_attributes-func_cts.
        me->ovs_output_cts_sub_func(
          EXPORTING
            pfd_i_field_name      = pfd_i_field_name
            prd_i_query_parameter = pri_i_ovs_callback->query_parameters
          IMPORTING
            prd_e_output          = prd_r_output ).
    ENDCASE.
  ENDMETHOD.


  METHOD if_fpm_guibb~initialize.
    CONSTANTS lc_proj_se TYPE ze_mdg_project_code VALUE 'SE'.

    CALL METHOD super->if_fpm_guibb~initialize
      EXPORTING
        it_parameter      = it_parameter
        io_app_parameter  = io_app_parameter
        iv_component_name = iv_component_name
        is_config_key     = is_config_key
        iv_instance_id    = iv_instance_id.

    me->fd_project_name = lc_proj_se.
  ENDMETHOD.


  METHOD on_zattr_selected.
    CONSTANTS lc_profit_center TYPE string VALUE 'PROFIT_CENTER'.
    DATA:
      lwa_profit_center TYPE zmdg_s_se_cctrid_rule,
      lfd_pctr          TYPE usmdz1_pctr ##NEEDED.

    ASSIGN me->wa_my_data->* TO FIELD-SYMBOL(<lwa_my_data>).
    IF <lwa_my_data> IS ASSIGNED.
      lwa_profit_center = CORRESPONDING #( <lwa_my_data> ).
    ENDIF.
    IF lwa_profit_center-profit_center IS NOT INITIAL.
      prc_i_event->mo_event_data->set_value(
        iv_key   = lc_profit_center
        iv_value = lwa_profit_center-profit_center ).
    ENDIF.

    CALL METHOD super->on_zattr_selected
      EXPORTING
        prc_i_event            = prc_i_event
        pfd_i_raised_by_own_ui = pfd_i_raised_by_own_ui
      IMPORTING
        pfd_e_result           = pfd_e_result
        pit_e_messages         = pit_e_messages
        prd_e_id               = prd_e_id.
  ENDMETHOD.


  METHOD ovs_output_cts_sub_func.
    TYPES:
      BEGIN OF lt_func,
        text     TYPE ze_mdg_func_text,
        func_cts TYPE ze_mdg_cost_func,
      END OF lt_func,
      ltt_func TYPE STANDARD TABLE OF lt_func.

    DATA:
      lfd_func         TYPE c LENGTH 1,
      lfd_func_int     TYPE ze_mdg_cost_center_cts_func,
      lit_cts_func_new TYPE ltt_func.

    CLEAR prd_e_output.

    ASSIGN me->wa_my_data_wo_txt->* TO FIELD-SYMBOL(<lwa_data_wo_text>).
    IF <lwa_data_wo_text> IS ASSIGNED.
      ASSIGN COMPONENT zif_mdg_id_constants=>c_attributes-profit_center OF STRUCTURE <lwa_data_wo_text> TO FIELD-SYMBOL(<lfd_profit_center>).
    ENDIF.
    IF <lfd_profit_center> IS NOT ASSIGNED OR <lfd_profit_center> IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lfd_length)   = strlen( <lfd_profit_center> ).
    DATA(lfd_position) = lfd_length - 3.
    IF lfd_length EQ 8.
      IF lfd_position GE 0.
        lfd_func = <lfd_profit_center>+lfd_position(1).
        IF NOT lfd_func CA sy-abcde.
          lfd_func_int = lfd_func.
        ENDIF.
      ENDIF.
    ENDIF.

    IF lfd_func_int IS INITIAL.
      RETURN.
    ENDIF.

    me->get_cts_sub_functions(
      EXPORTING
        pfd_i_cts_main = lfd_func_int
      IMPORTING
        pit_e_cts_sub  = DATA(lit_cts_func) ).
    IF lit_cts_func IS INITIAL.
      RETURN.
    ENDIF.

    lit_cts_func_new = VALUE #( FOR lwa_line IN lit_cts_func
                                 ( func_cts = lwa_line-func
                                   text     = lwa_line-text ) ).

    CREATE DATA prd_e_output LIKE lit_cts_func_new.
    ASSIGN prd_e_output->* TO FIELD-SYMBOL(<lit_cts_func>).
    IF <lit_cts_func> IS ASSIGNED.
      <lit_cts_func> = CORRESPONDING #( lit_cts_func_new ).
      me->ovs_output_filter(
        EXPORTING
          pfd_i_field_name      = pfd_i_field_name
          prd_i_query_parameter = prd_i_query_parameter
        CHANGING
          prd_c_output          = prd_e_output ).
    ENDIF.
  ENDMETHOD.


  METHOD ovs_output_profit_center.
    me->read_profit_centers( ).

    CREATE DATA prd_e_output TYPE usmdz10_ts_ovs_output.
    ASSIGN prd_e_output->* TO FIELD-SYMBOL(<lit_profit_center>).
    IF <lit_profit_center> IS ASSIGNED.
      <lit_profit_center> = CORRESPONDING #( me->it_profit_centers ).
      me->ovs_output_filter(
        EXPORTING
          pfd_i_field_name      = pfd_i_field_name
          prd_i_query_parameter = prd_i_query_parameter
        CHANGING
          prd_c_output          = prd_e_output ).
    ENDIF.
  ENDMETHOD.


  METHOD read_profit_centers.
    CONSTANTS lc_logical_name TYPE fieldname VALUE 'TXT_0G_PCTR'.

    DATA:
      lfd_field_temp     TYPE string,
      lit_allowtab       TYPE string_hashed_table,
      lit_profit_centers TYPE tt_profit_centers.

    IF me->it_profit_centers IS NOT INITIAL.
      RETURN.
    ENDIF.

    CALL METHOD cl_usmd_adapter_provider=>get_model_generation_adapter
      EXPORTING
        i_usmd_model         = if_usmdz_cons_general=>gc_model_default
      IMPORTING
        eo_model_gen_adapter = DATA(lri_model_gen_adapter).

    IF lri_model_gen_adapter IS NOT INITIAL.
      CALL METHOD lri_model_gen_adapter->get_generated_objects
        IMPORTING
          et_log_phys_name = DATA(lit_log_phys_name).
    ENDIF.

    IF lit_log_phys_name IS NOT INITIAL.
      READ TABLE lit_log_phys_name ASSIGNING FIELD-SYMBOL(<lit_log_phys_name_coa>) WITH KEY log_name = lc_logical_name.
      IF sy-subrc = 0.
        DATA(lfd_table_name) = <lit_log_phys_name_coa>-phys_name.
      ENDIF.
    ENDIF.

    IF lfd_table_name IS INITIAL.
      RETURN.
    ENDIF.

    lfd_field_temp = lfd_table_name.
    INSERT lfd_field_temp INTO TABLE lit_allowtab.

    TRY.
        lfd_table_name = cl_abap_dyn_prg=>check_whitelist_tab(
                           val       = lfd_table_name
                           whitelist = lit_allowtab ).
      CATCH cx_abap_not_in_whitelist.
        RAISE EXCEPTION TYPE cx_drf_filter_object.
    ENDTRY.

    SELECT DISTINCT                                     "#EC CI_SEL_DEL
        /1md/0gpctr AS key,
        txtsh       AS text
      FROM (lfd_table_name)
      INTO TABLE @lit_profit_centers
      WHERE /1md/0gcoarea = @zif_mdg_id_constants=>c_attr_values-coarea-co_sg01. "#EC CI_DYNTAB

    IF sy-subrc NE 0.
      " No profit center found for the coarea - write an application log
      " entry here (project-specific).
    ELSE.
      SORT lit_profit_centers ASCENDING BY key.
      DELETE ADJACENT DUPLICATES FROM lit_profit_centers COMPARING key.
      me->it_profit_centers = lit_profit_centers.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
