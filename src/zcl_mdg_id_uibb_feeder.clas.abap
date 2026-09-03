"! <p class="shorttext synchronized">MDG ID Generator - Generic UIBB Feeder Class</p>
"! Ported from /S4E/CL_P40_MDG_0G_UIBB_ID_GEN.
"! Generic FPM GUIBB form feeder for the ID generator naming-convention
"! UIBB. Builds its field catalog dynamically from the STRUCTURE_TYPE
"! parameter, drives the OVS value helps and, on the ZATTR_SELECTED
"! event, delegates ID creation to the number generator factory.
CLASS zcl_mdg_id_uibb_feeder DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_fpm_guibb .
    INTERFACES if_fpm_guibb_form .
    INTERFACES if_fpm_guibb_ovs .

    CONSTANTS c_action_id TYPE fpm_event_id VALUE 'ZATTR_SELECTED' ##NO_TEXT.

  PROTECTED SECTION.

    TYPES:
      BEGIN OF t_field_value,
        name  TYPE name_komp,
        value TYPE REF TO data,
      END OF t_field_value .
    TYPES:
      tt_field_value TYPE STANDARD TABLE OF t_field_value WITH DEFAULT KEY .

    DATA fd_entity         TYPE usmd_entity .
    DATA fd_kokrs          TYPE kokrs .
    CONSTANTS c_structure_name TYPE string VALUE 'STRUCTURE_TYPE' ##NO_TEXT.
    DATA rc_structure      TYPE REF TO cl_abap_structdescr .
    DATA fd_company_code   TYPE bukrs .
    CLASS-DATA fd_coarea   TYPE kokrs .
    DATA wa_my_data        TYPE REF TO data .
    DATA it_my_metadata    TYPE cl_abap_structdescr=>component_table .
    DATA wa_my_data_wo_txt TYPE REF TO data .
    DATA fd_project_name   TYPE ze_mdg_project_code .
    DATA fd_edition_number TYPE usmd_edition_number .

    METHODS ovs_output_filter
      IMPORTING
        !pfd_i_field_name      TYPE name_komp
        !prd_i_query_parameter TYPE REF TO data
        !pri_i_access          TYPE REF TO if_bol_bo_property_access OPTIONAL
        !pfd_i_field_name_key  TYPE name_komp DEFAULT space
      CHANGING
        !prd_c_output          TYPE REF TO data .
    METHODS ovs_output_filter_alpha
      IMPORTING
        !pfd_i_field_name      TYPE name_komp
        !pfd_i_query_component TYPE name_komp
      RETURNING
        VALUE(pfd_r_alpha)     TYPE i .
    METHODS ovs_handle_phase_3
      IMPORTING
        !pfd_i_field_name  TYPE name_komp
        !prd_i_selection   TYPE REF TO data
      EXPORTING
        !prc_e_fpm_event   TYPE REF TO cl_fpm_event
        !pit_e_field_value TYPE tt_field_value .
    METHODS on_zattr_selected
      IMPORTING
        !prc_i_event            TYPE REF TO cl_fpm_event
        !pfd_i_raised_by_own_ui TYPE boole_d
      EXPORTING
        !pfd_e_result           TYPE fpm_event_result
        !pit_e_messages         TYPE fpmgb_t_messages
        !prd_e_id               TYPE REF TO data .
    METHODS get_cr_edition
      RETURNING
        VALUE(pfd_r_edition_number) TYPE usmd_edition_number .

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_mdg_id_uibb_feeder IMPLEMENTATION.


  METHOD if_fpm_guibb_form~check_config ##NEEDED.
  ENDMETHOD.


  METHOD if_fpm_guibb_form~flush.
    wa_my_data = is_data.
    ASSIGN is_data->* TO FIELD-SYMBOL(<lwa_data>).
    IF <lwa_data> IS ASSIGNED.
      ASSIGN wa_my_data_wo_txt->* TO FIELD-SYMBOL(<lwa_data_wo_text>).
      IF <lwa_data_wo_text> IS ASSIGNED.
        <lwa_data_wo_text> = CORRESPONDING #( <lwa_data> ).
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD if_fpm_guibb_form~get_data ##NEEDED.
  ENDMETHOD.


  METHOD if_fpm_guibb_form~get_default_config ##NEEDED.
  ENDMETHOD.


  METHOD if_fpm_guibb_form~get_definition.
    DATA lrc_structure TYPE REF TO cl_abap_structdescr.

    CLEAR: eo_field_catalog, et_field_description, et_action_definition,
           et_special_groups, et_dnd_definition, es_options,
           es_message, ev_additional_error_info.

    eo_field_catalog = rc_structure.
    lrc_structure    = rc_structure.

    IF et_field_description IS INITIAL.
      LOOP AT lrc_structure->get_components( ) ASSIGNING FIELD-SYMBOL(<lwa_field>).
        IF <lwa_field> IS ASSIGNED.
          IF NOT <lwa_field>-name CS cl_usmd_generic_genil_text=>gv_text_suffix.
            INSERT VALUE fpmgb_s_formfield_descr( name = <lwa_field>-name ) INTO TABLE et_field_description.
          ELSE.
            INSERT VALUE fpmgb_s_formfield_descr( name      = <lwa_field>-name
                                                  read_only = abap_true ) INTO TABLE et_field_description.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
    et_action_definition = VALUE fpmgb_t_actiondef( ( id = c_action_id ) ).
  ENDMETHOD.


  METHOD if_fpm_guibb_form~process_event.
    CLEAR: ev_result, et_messages.
    CASE io_event->mv_event_id.
      WHEN c_action_id.
        me->on_zattr_selected(
          EXPORTING
            prc_i_event            = io_event
            pfd_i_raised_by_own_ui = iv_raised_by_own_ui
          IMPORTING
            pfd_e_result           = ev_result
            pit_e_messages         = et_messages ).
    ENDCASE.
  ENDMETHOD.


  METHOD if_fpm_guibb_ovs~handle_phase_0 ##NEEDED.
  ENDMETHOD.


  METHOD if_fpm_guibb_ovs~handle_phase_1.
    DATA: lrd_data         TYPE REF TO data,
          lit_label_texts  TYPE wdr_name_value_list,
          lfd_group_header TYPE string,
          lfd_window_title TYPE string,
          lfd_name         TYPE string.

    FIELD-SYMBOLS:
      <lwa_data>  TYPE usmdz10_s_ovs_output,
      <lwa_input> TYPE data.

    CREATE DATA lrd_data TYPE usmdz10_s_ovs_output.
    IF lrd_data IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN lrd_data->* TO <lwa_data>.
    IF <lwa_data> IS NOT ASSIGNED.
      RETURN.
    ENDIF.
    lfd_name = iv_field_name.
    io_ovs_callback->context_element->get_attribute(
      EXPORTING
        name  = lfd_name
      IMPORTING
        value = <lwa_data>-key ).
    ASSIGN lrd_data->* TO <lwa_input>.
    IF <lwa_input> IS ASSIGNED.
      io_ovs_callback->set_input_structure(
        input                      = <lwa_input>
        window_title               = lfd_window_title
        group_header               = lfd_group_header
        label_texts                = lit_label_texts
        display_values_immediately = abap_true ).
    ENDIF.
  ENDMETHOD.


  METHOD if_fpm_guibb_ovs~handle_phase_2 ##NEEDED.
  ENDMETHOD.


  METHOD if_fpm_guibb_ovs~handle_phase_3.
    CONSTANTS lc_text TYPE string VALUE 'TEXT'.
    DATA:
      lit_field_value TYPE tt_field_value,
      lfd_attr        TYPE string.
    FIELD-SYMBOLS <lfd_actual_value> TYPE any.

    CLEAR eo_fpm_event.

    me->ovs_handle_phase_3(
      EXPORTING
        pfd_i_field_name = iv_field_name
        prd_i_selection  = io_ovs_callback->selection
      IMPORTING
        prc_e_fpm_event  = eo_fpm_event
        pit_e_field_value = lit_field_value ).

    LOOP AT lit_field_value ASSIGNING FIELD-SYMBOL(<lwa_field_value>).
      IF <lwa_field_value> IS ASSIGNED.
        lfd_attr = iv_field_name.
        ASSIGN <lwa_field_value>-value->* TO <lfd_actual_value>.
        IF <lfd_actual_value> IS ASSIGNED.
          io_ovs_callback->context_element->set_attribute(
            name  = lfd_attr
            value = <lfd_actual_value> ).
          io_ovs_callback->context_element->set_changed_by_client( ).
        ENDIF.

        ASSIGN io_ovs_callback->selection->* TO FIELD-SYMBOL(<lwa_selection>).
        IF <lwa_selection> IS ASSIGNED.
          ASSIGN COMPONENT lc_text OF STRUCTURE <lwa_selection> TO FIELD-SYMBOL(<lfd_text>).
          IF <lfd_text> IS ASSIGNED.
            io_ovs_callback->context_element->set_attribute(
              name  = lfd_attr && cl_usmd_generic_genil_text=>gv_text_suffix
              value = <lfd_text> ).
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD if_fpm_guibb_ovs~handle_phase_value_suggest ##NEEDED.
  ENDMETHOD.


  METHOD if_fpm_guibb~get_parameter_list.
    CLEAR rt_parameter_descr.
    rt_parameter_descr = VALUE fpmgb_t_param_descr( ( name = 'STRUCTURE_TYPE' type = 'ZE_MDG_STRUCT_NAME' ) ).
  ENDMETHOD.


  METHOD if_fpm_guibb~initialize.
    DATA: lit_my_metadata      TYPE cl_abap_structdescr=>component_table,
          lit_my_metadata_text TYPE cl_abap_structdescr=>component_table,
          lrc_structure        TYPE REF TO cl_abap_structdescr.

    READ TABLE it_parameter INTO DATA(lwa_param_name) WITH KEY name = c_structure_name.
    IF sy-subrc = 0.
      ASSIGN lwa_param_name-value->* TO FIELD-SYMBOL(<lfd_any_name>).
      IF <lfd_any_name> IS ASSIGNED.
        lrc_structure ?= cl_abap_structdescr=>describe_by_name( p_name = <lfd_any_name> ).
        CREATE DATA wa_my_data_wo_txt TYPE HANDLE lrc_structure.
        lit_my_metadata = lrc_structure->get_components( ).
        LOOP AT lit_my_metadata INTO DATA(lwa_my_metadata) ##INTO_OK.
          APPEND INITIAL LINE TO lit_my_metadata_text ASSIGNING FIELD-SYMBOL(<lwa_texts>).
          IF <lwa_texts> IS ASSIGNED.
            <lwa_texts>-name = lwa_my_metadata-name && cl_usmd_generic_genil_text=>gv_text_suffix.
            <lwa_texts>-type = cl_abap_elemdescr=>get_string( ).
          ENDIF.
        ENDLOOP.

        IF lit_my_metadata_text IS NOT INITIAL.
          APPEND LINES OF lit_my_metadata_text TO lit_my_metadata.
        ENDIF.
        rc_structure = cl_abap_structdescr=>create( p_components = lit_my_metadata ).
        it_my_metadata = rc_structure->get_components( ).
        CREATE DATA wa_my_data TYPE HANDLE rc_structure.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD on_zattr_selected.
    DATA: lri_generator TYPE REF TO zif_mdg_id_number_gen,
          lrd_my_data   TYPE REF TO data,
          lri_fpm       TYPE REF TO if_fpm.

    CONSTANTS lc_generated_id TYPE string VALUE 'GENERATED_ID'.

    CLEAR: prd_e_id, pfd_e_result, pit_e_messages.
    lri_fpm = cl_fpm_factory=>get_instance( ).

    IF pfd_i_raised_by_own_ui = abap_false.
      RETURN.
    ENDIF.

    lrd_my_data = me->wa_my_data_wo_txt.

    IF me->fd_project_name IS INITIAL.
      lri_generator = zcl_mdg_id_numgen_factory=>get_number_generator(
                        pfd_i_entity    = fd_entity
                        pwa_i_structure = lrd_my_data ).
    ELSE.
      lri_generator = zcl_mdg_id_numgen_factory=>get_number_generator(
                        pfd_i_entity    = fd_entity
                        pwa_i_structure = lrd_my_data
                        pfd_i_project   = me->fd_project_name ).
    ENDIF.

    IF lri_generator IS BOUND.
      DATA(lrd_number) = lri_generator->generate_number( pwa_i_structure = lrd_my_data ).
      IF lrd_number IS NOT INITIAL.
        prd_e_id = lrd_number.
        prc_i_event->mo_event_data->set_value(
          iv_key   = lc_generated_id
          ir_value = lrd_number ).
        lri_fpm->raise_event_by_id( iv_event_id = if_fpm_constants=>gc_event-refresh ).
      ENDIF.
    ELSE.
      prc_i_event->mo_event_data->delete_value( iv_key = lc_generated_id ).
    ENDIF.
  ENDMETHOD.


  METHOD ovs_handle_phase_3.
    CONSTANTS lc_key TYPE string VALUE 'KEY'.
    FIELD-SYMBOLS:
      <lwa_selection>    TYPE data,
      <lfd_sel_value>    TYPE data,
      <lwa_field_value>  LIKE LINE OF pit_e_field_value,
      <lfd_result_value> TYPE data.

    CLEAR: pit_e_field_value, prc_e_fpm_event.

    prc_e_fpm_event = cl_fpm_event=>create_by_id( iv_event_id = c_action_id ).

    ASSIGN prd_i_selection->* TO <lwa_selection>.
    IF <lwa_selection> IS ASSIGNED.
      ASSIGN COMPONENT pfd_i_field_name OF STRUCTURE <lwa_selection> TO <lfd_sel_value>.
      IF <lfd_sel_value> IS NOT ASSIGNED.
        ASSIGN COMPONENT lc_key OF STRUCTURE <lwa_selection> TO <lfd_sel_value>.
      ENDIF.
      IF <lfd_sel_value> IS ASSIGNED.
        APPEND INITIAL LINE TO pit_e_field_value ASSIGNING <lwa_field_value>.
        IF <lwa_field_value> IS ASSIGNED.
          <lwa_field_value>-name = pfd_i_field_name.
          READ TABLE me->it_my_metadata ASSIGNING FIELD-SYMBOL(<lwa_metadata>) WITH TABLE KEY name = <lwa_field_value>-name.
          IF <lwa_metadata> IS ASSIGNED.
            CREATE DATA <lwa_field_value>-value TYPE HANDLE <lwa_metadata>-type.
          ELSE.
            CREATE DATA <lwa_field_value>-value LIKE <lfd_sel_value>.
          ENDIF.
          ASSIGN <lwa_field_value>-value->* TO <lfd_result_value>.
          IF <lfd_result_value> IS ASSIGNED.
            <lfd_result_value> = <lfd_sel_value>.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD ovs_output_filter.
    DATA:
      lit_filters TYPE STANDARD TABLE OF string,
      lit_query   TYPE crmt_attr_name_tab,
      lfd_alpha   TYPE i,
      lfd_delete  TYPE abap_bool,
      lfd_filter  TYPE string.

    FIELD-SYMBOLS:
      <lwa_query>     TYPE any,
      <lwa_output>    TYPE any,
      <lit_output>    TYPE ANY TABLE,
      <lfd_component> TYPE any,
      <lfd_value>     TYPE any.

    ASSIGN prd_i_query_parameter->* TO <lwa_query>.
    IF sy-subrc NE 0 OR <lwa_query> IS INITIAL.
      RETURN.
    ENDIF.

    ASSIGN prd_c_output->* TO <lit_output>.
    IF <lit_output> IS NOT ASSIGNED OR <lit_output> IS INITIAL.
      RETURN.
    ENDIF.

    lit_query = cl_usmd_generic_bolui_assist=>get_structure_components( is_data = <lwa_query> ).
    LOOP AT lit_query ASSIGNING <lfd_component>.
      ASSIGN COMPONENT <lfd_component> OF STRUCTURE <lwa_query> TO <lfd_value>.
      IF sy-subrc NE 0 OR <lfd_value> IS INITIAL.
        DELETE TABLE lit_query FROM <lfd_component>.
        CONTINUE.
      ENDIF.
      IF NOT <lfd_value> IS INITIAL AND
         find( val = <lfd_value> pcre = '[\*|\+]' occ = 1 ) <> -1.
        " Wildcard search - convert '*' and '+' into a PCRE expression.
        <lfd_value> = replace( val  = <lfd_value>
                               pcre = '[\\|\.|\[|\]|\{|\}|\?|\||\(|\)|\^|\$]'
                               with = '\\$0'
                               occ  = 0 ).
        IF find( val = <lfd_value> pcre = '[\*|\+]' occ = 1 ) <> 0.
          <lfd_value> = '^' && <lfd_value>.
        ENDIF.
        IF find( val = <lfd_value> pcre = '[\*|\+]' occ = -1 ) <> strlen( <lfd_value> ) - 1.
          <lfd_value> = <lfd_value> && '$'.
        ENDIF.
        <lfd_value> = replace( val  = <lfd_value>
                               pcre = '[\*|\+]'
                               with = '\.$0'
                               occ  = 0 ).
        CONTINUE.
      ELSEIF pfd_i_field_name IS NOT INITIAL
        AND pri_i_access IS BOUND
        AND ( <lfd_component> EQ 'KEY' OR <lfd_component> EQ pfd_i_field_name ).
        TRY.
            IF pri_i_access->get_property_as_string( iv_attr_name = pfd_i_field_name ) NE <lfd_value>.
              <lfd_value> = replace( val  = <lfd_value>
                                     pcre = '[\\|\.|\[|\]|\{|\}|\?|\||\(|\)|\^|\$]'
                                     with = '\\$0'
                                     occ  = 0 ).
              CONTINUE.
            ENDIF.
          CATCH cx_crm_cic_parameter_error.
            DELETE TABLE lit_query FROM <lfd_component>.
        ENDTRY.
      ELSE.
        <lfd_value> = replace( val  = <lfd_value>
                               pcre = '[\\|\.|\[|\]|\{|\}|\?|\||\(|\)|\^|\$]'
                               with = '\\$0'
                               occ  = 0 ).
      ENDIF.
    ENDLOOP.

    LOOP AT lit_query ASSIGNING <lfd_component>.
      UNASSIGN <lfd_value>.
      CLEAR: lit_filters, lfd_alpha, lfd_filter.

      ASSIGN COMPONENT <lfd_component> OF STRUCTURE <lwa_query> TO <lfd_value>.
      CHECK sy-subrc EQ 0.
      lfd_filter = <lfd_value>.
      APPEND lfd_filter TO lit_filters.

      IF lfd_filter CO '1234567890'.
        lfd_alpha = me->ovs_output_filter_alpha(
                      pfd_i_field_name      = pfd_i_field_name
                      pfd_i_query_component = <lfd_component> ).
        IF lfd_alpha IS NOT INITIAL.
          lfd_alpha = lfd_alpha - strlen( lfd_filter ).
          DO lfd_alpha TIMES.                            "#EC CI_NESTED
            lfd_filter = |0{ lfd_filter }|.
            APPEND lfd_filter TO lit_filters.
          ENDDO.
        ENDIF.
      ENDIF.

      LOOP AT <lit_output> ASSIGNING <lwa_output>.       "#EC CI_NESTED
        IF <lwa_output> IS ASSIGNED.
          ASSIGN COMPONENT <lfd_component> OF STRUCTURE <lwa_output> TO <lfd_value>.
          IF sy-subrc NE 0 AND pfd_i_field_name_key IS SUPPLIED AND pfd_i_field_name_key IS NOT INITIAL.
            ASSIGN COMPONENT pfd_i_field_name_key OF STRUCTURE <lwa_output> TO <lfd_value>.
            CHECK sy-subrc EQ 0.
          ENDIF.
          lfd_delete = abap_true.
          LOOP AT lit_filters INTO lfd_filter ##INTO_OK. "#EC CI_NESTED
            IF find( val = <lfd_value> pcre = lfd_filter case = abap_false ) <> -1.
              lfd_delete = abap_false.
              EXIT.
            ENDIF.
          ENDLOOP.
          CHECK lfd_delete = abap_true.
          DELETE TABLE <lit_output> FROM <lwa_output>.   "#EC CI_ANYSEQ
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD ovs_output_filter_alpha.
    " Defines whether ALPHA conversion (leading zeros) applies to the
    " given field / query component. Returns the field length when it
    " does, otherwise stays empty.
    CLEAR pfd_r_alpha.

    IF pfd_i_query_component NE 'KEY'.
      RETURN.
    ENDIF.
    CASE pfd_i_field_name.
      WHEN if_usmdz_cons_entitytypes=>gc_entity_account
        OR if_usmdz_cons_entitytypes=>gc_entity_cctr
        OR if_usmdz_cons_entitytypes=>gc_entity_consunit
        OR if_usmdz_cons_entitytypes=>gc_entity_fsi
        OR if_usmdz_cons_entitytypes=>gc_entity_frsi
        OR if_usmdz_cons_entitytypes=>gc_entity_pctr.
        pfd_r_alpha = 10.
      WHEN if_usmdz_cons_entitytypes=>gc_entity_company.
        pfd_r_alpha = 6.
      WHEN if_usmdz_cons_entitytypes=>gc_entity_bdc
        OR if_usmdz_cons_entitytypes=>gc_entity_submpack.
        pfd_r_alpha = 4.
      WHEN if_usmdz_cons_entitytypes=>gc_entity_transtype.
        pfd_r_alpha = 3.
      WHEN OTHERS.
    ENDCASE.
  ENDMETHOD.


  METHOD get_cr_edition.
    DATA lfd_edition TYPE usmd_edition.

    CLEAR pfd_r_edition_number.
    IF me->fd_edition_number IS INITIAL.
      DATA(lri_context) = cl_usmd_app_context=>get_context( ).
      lfd_edition = lri_context->mv_edition.
      DATA(lri_edition_api) = cl_usmd_edition_api=>get_instance( ).
      TRY.
          DATA(lwa_edition) = lri_edition_api->get_edition( iv_edition = lfd_edition ).
        CATCH cx_usmd_edition INTO DATA(lrcx_edition).
          zcl_mdg_id_logging=>write_application_log_simple(
            pfd_i_crequest      = lri_context->mv_crequest_id
            pfd_i_object        = zcl_mdg_id_logging=>c_object_fi
            pfd_i_subobject     = zcl_mdg_id_logging=>c_sub_object_wf
            pit_i_messages      = lrcx_edition->mt_messages
            pfd_i_exception_obj = lrcx_edition ).
          RETURN.
      ENDTRY.
      me->fd_edition_number = lwa_edition-usmd_edtn_number.
    ENDIF.

    pfd_r_edition_number = me->fd_edition_number.
  ENDMETHOD.

ENDCLASS.
