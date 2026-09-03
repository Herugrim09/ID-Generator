"! <p class="shorttext synchronized">MDG-F ID Number Generator - Base Class</p>
"! Ported from /S4E/CL_P40_MDG_NUMGEN_BASE.
"! Common functionality for all number generators: buffering the input
"! structure, reading field values, querying the MDG staging area for
"! existing IDs and validating structures. Concrete generators inherit
"! from this class and implement GENERATE_NUMBER / SPLIT_NUMBER.
"!
"! Works out of the box for Flex data models. Redefine QUERYING_DB (and
"! the helpers it calls) to read database tables other than the MDG
"! staging tables.
CLASS zcl_mdg_id_numgen_base DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_mdg_id_number_gen.

    TYPES:
      BEGIN OF t_cctr,
        /1md/0gcctr TYPE usmdz1_cctr,
      END OF t_cctr .
    TYPES:
      BEGIN OF t_pctr,
        /1md/0gpctr TYPE usmdz1_pctr,
      END OF t_pctr .
    TYPES tt_cctr TYPE SORTED TABLE OF t_cctr WITH UNIQUE KEY /1md/0gcctr .
    TYPES tt_pctr TYPE SORTED TABLE OF t_pctr WITH UNIQUE KEY /1md/0gpctr .
    TYPES:
      BEGIN OF t_id_table,
        id_number TYPE usmd_value,
      END OF t_id_table .
    TYPES tt_id_table TYPE SORTED TABLE OF t_id_table WITH UNIQUE KEY id_number .

    METHODS constructor
      IMPORTING
        !pfd_i_entity    TYPE usmd_entity
        !pwa_i_structure TYPE REF TO data OPTIONAL .

  PROTECTED SECTION.

    DATA fd_cr_type        TYPE usmd_crequest_type .
    DATA rd_my_data        TYPE REF TO data .
    DATA fd_entity         TYPE usmd_entity .
    DATA ri_model          TYPE REF TO if_usmd_model_ext .
    DATA fd_model          TYPE usmd_model .
    DATA it_my_data        TYPE tt_id_table .
    DATA fd_edition_number TYPE usmd_edition_number .

    METHODS get_field_value
      IMPORTING
        !pfd_i_component_name TYPE name_komp
      RETURNING
        VALUE(prd_r_value)    TYPE REF TO data .
    METHODS querying_db
      IMPORTING
        !pfd_i_reference          TYPE any
        !pfd_i_running_num_length TYPE i .
    METHODS get_logical_name
      RETURNING
        VALUE(pfd_r_logical_name) TYPE fieldname .
    METHODS get_sta_component_name
      RETURNING
        VALUE(pfd_r_comp_name) TYPE string .
    METHODS was_field_changed
      IMPORTING
        !pwa_i_structure     TYPE REF TO data
      RETURNING
        VALUE(pfd_r_changed) TYPE abap_boolean .
    METHODS validate_structure
      RETURNING
        VALUE(pfd_r_continue) TYPE abap_boolean .
    METHODS get_data_element
      RETURNING
        VALUE(pfd_r_data_element) TYPE string .
    METHODS get_table_reference
      RETURNING
        VALUE(prd_r_tab) TYPE REF TO data .
    METHODS get_cr_edition_number
      RETURNING
        VALUE(pfd_r_edition_number) TYPE usmd_edition_number .

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_mdg_id_numgen_base IMPLEMENTATION.


  METHOD zif_mdg_id_number_gen~generate_number.
    " Number generation takes place in the child classes.
    RETURN.
  ENDMETHOD.


  METHOD zif_mdg_id_number_gen~split_number.
    " Number splitting takes place in the child classes.
    RETURN.
  ENDMETHOD.


  METHOD constructor.
    DATA lri_context TYPE REF TO if_usmd_app_context.

    lri_context = cl_usmd_app_context=>get_context( ).
    fd_entity = pfd_i_entity.
    IF pwa_i_structure IS BOUND.
      ASSIGN pwa_i_structure->* TO FIELD-SYMBOL(<lwa_my_data>).
      IF <lwa_my_data> IS ASSIGNED.
        CREATE DATA rd_my_data LIKE <lwa_my_data>.
        ASSIGN rd_my_data->* TO FIELD-SYMBOL(<lwa_ref_struct>).
        IF <lwa_ref_struct> IS ASSIGNED.
          <lwa_ref_struct> = <lwa_my_data>.
        ENDIF.
      ENDIF.
    ENDIF.
    IF lri_context IS BOUND.
      fd_cr_type = lri_context->mv_crequest_type.
      fd_model   = lri_context->mv_usmd_model.
      ri_model  ?= lri_context->mo_model.
    ENDIF.
  ENDMETHOD.


  METHOD get_field_value.
    DATA lfd_fieldname TYPE name_komp.

    CLEAR prd_r_value.
    IF pfd_i_component_name IS NOT INITIAL.
      lfd_fieldname = pfd_i_component_name.
      ASSIGN rd_my_data->* TO FIELD-SYMBOL(<lwa_data>).
      IF <lwa_data> IS ASSIGNED.
        ASSIGN COMPONENT lfd_fieldname OF STRUCTURE <lwa_data> TO FIELD-SYMBOL(<lfd_any>).
        IF <lfd_any> IS ASSIGNED.
          CREATE DATA prd_r_value LIKE <lfd_any>.
          ASSIGN prd_r_value->* TO FIELD-SYMBOL(<lfd_return>).
          IF <lfd_return> IS ASSIGNED.
            <lfd_return> = <lfd_any>.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD get_logical_name.
    DATA lfd_fieldname TYPE fieldname.
    CONSTANTS lc_tck TYPE fieldname VALUE 'TCK_'.

    CLEAR pfd_r_logical_name.
    CONCATENATE lc_tck fd_model '_' fd_entity INTO lfd_fieldname.
    pfd_r_logical_name = lfd_fieldname.
  ENDMETHOD.


  METHOD get_sta_component_name.
    DATA lfd_component_name TYPE string.
    CONSTANTS lc_prefix TYPE string VALUE '/1MD/'.

    CLEAR pfd_r_comp_name.
    CONCATENATE lc_prefix fd_model fd_entity INTO lfd_component_name.
    pfd_r_comp_name = lfd_component_name.
  ENDMETHOD.


  METHOD get_data_element.
    DATA lfd_data_element TYPE string.
    CONSTANTS lc_usmdz1 TYPE string VALUE 'USMDZ1_'.

    CLEAR pfd_r_data_element.
    CONCATENATE lc_usmdz1 fd_entity INTO lfd_data_element.
    pfd_r_data_element = lfd_data_element.
  ENDMETHOD.


  METHOD querying_db.
    DATA:
      lfd_comp_name     TYPE string,
      lit_allowtab      TYPE string_hashed_table,
      lrd_return_tab    TYPE REF TO data,
      lfd_reference_str TYPE string,
      lfd_base_ref      TYPE string,
      lfd_first         TYPE string,
      lfd_last          TYPE string,
      lfd_zeros         TYPE string,
      lfd_nines         TYPE string.

    " Fix vs. original: start each run from a clean buffer, otherwise a
    " re-query (changed driver fields) appends rows for a different
    " reference prefix and the gap detection parses garbage.
    CLEAR it_my_data.

    CALL METHOD cl_usmd_adapter_provider=>get_model_generation_adapter
      EXPORTING
        i_usmd_model         = fd_model
      IMPORTING
        eo_model_gen_adapter = DATA(lri_model_gen_adapter).

    IF lri_model_gen_adapter IS NOT INITIAL.
      " Retrieve the generated table names from the 0G USMD_DATA_MODEL
      CALL METHOD lri_model_gen_adapter->get_generated_objects
        IMPORTING
          et_log_phys_name = DATA(lit_log_phys_name).
    ENDIF.

    DATA(lfd_logical_name) = me->get_logical_name( ).
    IF lit_log_phys_name IS NOT INITIAL.
      READ TABLE lit_log_phys_name ASSIGNING FIELD-SYMBOL(<lit_log_phys_name_coa>) WITH KEY log_name = lfd_logical_name.
      IF sy-subrc = 0.
        DATA(lfd_table_name) = <lit_log_phys_name_coa>-phys_name.
      ENDIF.
    ENDIF.

    IF lfd_table_name IS INITIAL.
      " No physical staging table resolved - nothing to read.
      RETURN.
    ENDIF.

    lfd_comp_name = lfd_table_name.
    INSERT lfd_comp_name INTO TABLE lit_allowtab.
    CLEAR lfd_comp_name.

    " Verify the table name against the whitelist before the dynamic SELECT.
    TRY.
        lfd_table_name = cl_abap_dyn_prg=>check_whitelist_tab(
                           val       = lfd_table_name
                           whitelist = lit_allowtab ).
      CATCH cx_abap_not_in_whitelist.
        RAISE EXCEPTION TYPE cx_drf_filter_object.
    ENDTRY.

    " Construct the range boundaries.
    lfd_reference_str = |{ pfd_i_reference }|.
    lfd_base_ref      = lfd_reference_str.

    DO pfd_i_running_num_length TIMES.
      lfd_zeros = |{ lfd_zeros }0|.
      lfd_nines = |{ lfd_nines }9|.
    ENDDO.

    lfd_first = |{ lfd_base_ref }{ lfd_zeros }|.
    lfd_last  = |{ lfd_base_ref }{ lfd_nines }|.

    lfd_comp_name = me->get_sta_component_name( ).

    " Fix vs. original: use QUOTE (adds the enclosing quotes) instead of
    " QUOTE_STR for a character literal in the dynamic WHERE clause.
    lfd_first = cl_abap_dyn_prg=>quote( lfd_first ).
    lfd_last  = cl_abap_dyn_prg=>quote( lfd_last ).

    DATA(lfd_where_clause) = |{ lfd_comp_name } BETWEEN { lfd_first } AND { lfd_last }|.

    lrd_return_tab = me->get_table_reference( ).
    ASSIGN lrd_return_tab->* TO FIELD-SYMBOL(<lit_return>).

    " Select all columns to avoid an SQL injection via the field list.
    SELECT DISTINCT *
      FROM (lfd_table_name)
      WHERE (lfd_where_clause)
      INTO CORRESPONDING FIELDS OF TABLE @<lit_return>. "#EC CI_DYNTAB "#EC CI_DYNWHERE

    IF sy-subrc = 0.
      LOOP AT <lit_return> ASSIGNING FIELD-SYMBOL(<lwa_data>).
        IF <lwa_data> IS ASSIGNED.
          ASSIGN COMPONENT lfd_comp_name OF STRUCTURE <lwa_data> TO FIELD-SYMBOL(<lfd_any_key>).
          IF <lfd_any_key> IS ASSIGNED.
            INSERT VALUE t_id_table( id_number = <lfd_any_key> ) INTO TABLE it_my_data.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD get_table_reference.
    DATA:
      lit_components   TYPE cl_abap_structdescr=>component_table,
      lwa_component    TYPE cl_abap_structdescr=>component,
      lrd_return_str   TYPE REF TO data,
      lrc_struct_descr TYPE REF TO cl_abap_structdescr.

    CLEAR prd_r_tab.
    " Staging area DB table component name, e.g. /1MD/0GCCTR.
    lwa_component-name  = me->get_sta_component_name( ).
    lwa_component-type ?= cl_mdg_mdf_ddic=>get_typedescr_by_name( iv_name = me->get_data_element( ) ).
    APPEND lwa_component TO lit_components.
    lrc_struct_descr = cl_abap_structdescr=>get( p_components = lit_components ).
    CREATE DATA lrd_return_str TYPE HANDLE lrc_struct_descr.
    ASSIGN lrd_return_str->* TO FIELD-SYMBOL(<lwa_return>).
    CREATE DATA prd_r_tab LIKE STANDARD TABLE OF <lwa_return>.
  ENDMETHOD.


  METHOD validate_structure.
    DATA:
      lrc_structure  TYPE REF TO cl_abap_structdescr,
      lit_components TYPE cl_abap_structdescr=>component_table.

    ASSIGN me->rd_my_data->* TO FIELD-SYMBOL(<lwa_my_data>).
    IF <lwa_my_data> IS ASSIGNED.
      lrc_structure ?= cl_abap_structdescr=>describe_by_data( p_data = <lwa_my_data> ).
      lit_components = lrc_structure->get_components( ).
      LOOP AT lit_components ASSIGNING FIELD-SYMBOL(<lwa_components>).
        IF <lwa_components> IS ASSIGNED.
          ASSIGN COMPONENT <lwa_components>-name OF STRUCTURE <lwa_my_data> TO FIELD-SYMBOL(<lfd_any>).
          IF <lfd_any> IS ASSIGNED AND <lfd_any> IS INITIAL.
            pfd_r_continue = abap_false.
            EXIT.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD was_field_changed.
    CLEAR pfd_r_changed.
    ASSIGN me->rd_my_data->* TO FIELD-SYMBOL(<lwa_buffer_data>).
    IF <lwa_buffer_data> IS NOT ASSIGNED.
      RETURN.
    ENDIF.
    ASSIGN pwa_i_structure->* TO FIELD-SYMBOL(<lwa_current_data>).
    IF <lwa_current_data> IS ASSIGNED AND <lwa_current_data> <> <lwa_buffer_data>.
      <lwa_buffer_data> = <lwa_current_data>.
      pfd_r_changed = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD get_cr_edition_number.
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
