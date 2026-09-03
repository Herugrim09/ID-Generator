"! <p class="shorttext synchronized">MDG ID Generator - SE Profit Center ID</p>
"! Ported from /S4E/CL_P40_MDG_SE_PCTR_ID_GEN.
"! Generates / splits the Siemens Energy profit center ID:
"! P + company code(2) + plant(2) + CTS function(1) + running number(2).
CLASS zcl_mdg_se_pctr_id_gen DEFINITION
  PUBLIC
  INHERITING FROM zcl_mdg_id_numgen_base
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS zif_mdg_id_number_gen~generate_number REDEFINITION .
    METHODS zif_mdg_id_number_gen~split_number REDEFINITION .

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS get_ccode_vs_plants
      RETURNING VALUE(pit_r_plants) TYPE zcl_mdg_id_sg_util=>tt_plants .
    METHODS parse_id_into_components
      IMPORTING
        !pfd_i_number      TYPE any
      RETURNING
        VALUE(pfd_r_return) TYPE REF TO data .

ENDCLASS.



CLASS zcl_mdg_se_pctr_id_gen IMPLEMENTATION.


  METHOD zif_mdg_id_number_gen~generate_number.
    DATA:
      lfd_ref_value             TYPE usmdz1_pctr,
      lfd_bukrs                 TYPE ze_mdg_profit_company_code,
      lfd_plant                 TYPE ze_mdg_profit_plant,
      lfd_function              TYPE ze_mdg_profit_func_cts,
      lfd_was_changed           TYPE abap_boolean,
      lfd_running_number_length TYPE i,
      lfd_next_number           TYPE i VALUE 0,
      lfd_current_num           TYPE i,
      lfd_sequence_part         TYPE string,
      lfd_generated_id          TYPE usmdz1_pctr,
      lfd_ref_length            TYPE i,
      lrd_component             TYPE REF TO data.
    CONSTANTS:
      lc_company_code TYPE name_komp VALUE 'COMPANY_CODE',
      lc_func_cts     TYPE name_komp VALUE 'FUNC_CTS',
      lc_plant        TYPE name_komp VALUE 'PLANT'.

    lfd_was_changed = me->was_field_changed( pwa_i_structure = pwa_i_structure ).

    lrd_component = me->get_field_value( pfd_i_component_name = lc_company_code ).
    ASSIGN lrd_component->* TO FIELD-SYMBOL(<lfd_any>).
    IF <lfd_any> IS ASSIGNED.
      lfd_bukrs = <lfd_any>.
    ENDIF.
    UNASSIGN <lfd_any>.
    FREE lrd_component.

    lrd_component = me->get_field_value( pfd_i_component_name = lc_plant ).
    ASSIGN lrd_component->* TO <lfd_any>.
    IF <lfd_any> IS ASSIGNED.
      lfd_plant = <lfd_any>.
    ENDIF.
    FREE lrd_component.

    lrd_component = me->get_field_value( pfd_i_component_name = lc_func_cts ).
    ASSIGN lrd_component->* TO <lfd_any>.
    IF <lfd_any> IS ASSIGNED.
      lfd_function = <lfd_any>.
    ENDIF.

    IF lfd_bukrs IS INITIAL OR lfd_plant IS INITIAL OR lfd_function IS INITIAL.
      RETURN.
    ENDIF.

    " Reference value: P + company code(2) + plant chars 3-4 + CTS function.
    lfd_ref_value = |P{ lfd_bukrs+0(2) }{ lfd_plant+2(2) }{ lfd_function }|.
    lfd_running_number_length = 2.
    lfd_ref_length = strlen( lfd_ref_value ).

    IF it_my_data IS INITIAL OR lfd_was_changed = abap_true.
      me->querying_db(
        pfd_i_reference          = lfd_ref_value
        pfd_i_running_num_length = lfd_running_number_length ).
    ENDIF.

    " Find the next free running number by detecting the first gap.
    lfd_next_number = 0.
    LOOP AT it_my_data ASSIGNING FIELD-SYMBOL(<lwa_current_data>).
      lfd_sequence_part = <lwa_current_data>-id_number+lfd_ref_length(lfd_running_number_length).
      lfd_current_num = lfd_sequence_part.
      IF lfd_current_num - lfd_next_number > 0.
        EXIT.
      ELSE.
        lfd_next_number = lfd_current_num + 1.
      ENDIF.
    ENDLOOP.

    ##OPERATOR[**] DATA(lfd_max_possible) = ( 10 ** lfd_running_number_length ) - 1.
    IF lfd_next_number > lfd_max_possible.
      RETURN.
    ENDIF.

    lfd_generated_id = |{ lfd_ref_value }{ lfd_next_number WIDTH = ( lfd_running_number_length ) PAD = '0' ALIGN = RIGHT }|.

    CREATE DATA prd_r_number TYPE usmdz1_pctr.
    ASSIGN prd_r_number->* TO FIELD-SYMBOL(<lfd_result>).
    IF <lfd_result> IS ASSIGNED.
      <lfd_result> = lfd_generated_id.
    ENDIF.
  ENDMETHOD.


  METHOD zif_mdg_id_number_gen~split_number.
    DATA: lfd_input_number    TYPE string,
          lfd_number_length   TYPE i,
          lfd_expected_length TYPE i.

    CLEAR pfd_r_return.

    IF pfd_i_number IS INITIAL.
      RETURN.
    ENDIF.

    lfd_input_number  = |{ pfd_i_number }|.
    lfd_number_length = strlen( lfd_input_number ).

    IF lfd_input_number+0(1) <> 'P'.
      RETURN.
    ENDIF.

    " P(1) + company code(2) + plant(2) + CTS function(1) + running number(2) = 8
    lfd_expected_length = 8.
    IF lfd_number_length <> lfd_expected_length.
      RETURN.
    ENDIF.

    pfd_r_return = parse_id_into_components( pfd_i_number = pfd_i_number ).
  ENDMETHOD.


  METHOD get_ccode_vs_plants.
    CLEAR pit_r_plants.
    " The utility class buffers the plants itself.
    pit_r_plants = zcl_mdg_id_sg_util=>get_instance( )->get_plants( ).
  ENDMETHOD.


  METHOD parse_id_into_components.
    DATA: lfd_pctr            TYPE usmdz1_pctr,
          lfd_compcode_first2 TYPE char2,
          lfd_plant_last2     TYPE char2,
          lfd_cts_function    TYPE ze_mdg_profit_func_cts.

    CLEAR pfd_r_return.
    lfd_pctr = pfd_i_number.

    lfd_compcode_first2 = lfd_pctr+1(2).
    lfd_plant_last2     = lfd_pctr+3(2).
    lfd_cts_function    = lfd_pctr+5(1).

    ASSIGN me->rd_my_data->* TO FIELD-SYMBOL(<lwa_template>).
    IF <lwa_template> IS ASSIGNED.
      CREATE DATA pfd_r_return LIKE <lwa_template>.
      ASSIGN pfd_r_return->* TO FIELD-SYMBOL(<lwa_result>).
      IF <lwa_result> IS NOT ASSIGNED.
        RETURN.
      ENDIF.
    ELSE.
      RETURN.
    ENDIF.

    DATA(lit_plants) = get_ccode_vs_plants( ).

    " Fix vs. original: offset/length is not allowed in READ TABLE WITH KEY,
    " so match the 2-char company code / plant fragments explicitly.
    FIELD-SYMBOLS <lwa_plant> LIKE LINE OF lit_plants.
    LOOP AT lit_plants ASSIGNING <lwa_plant>.
      IF <lwa_plant>-bukrs+0(2)        = lfd_compcode_first2
     AND <lwa_plant>-plant_number+2(2) = lfd_plant_last2.
        EXIT.
      ENDIF.
      UNASSIGN <lwa_plant>.
    ENDLOOP.

    IF <lwa_plant> IS ASSIGNED.
      ASSIGN COMPONENT zif_mdg_id_constants=>c_attributes-company_code
             OF STRUCTURE <lwa_result> TO FIELD-SYMBOL(<lfd_cc_field>).
      IF <lfd_cc_field> IS ASSIGNED.
        <lfd_cc_field> = <lwa_plant>-bukrs.
      ENDIF.
      ASSIGN COMPONENT zif_mdg_id_constants=>c_attributes-plant
             OF STRUCTURE <lwa_result> TO FIELD-SYMBOL(<lfd_plant_field>).
      IF <lfd_plant_field> IS ASSIGNED.
        <lfd_plant_field> = <lwa_plant>-plant_number.
      ENDIF.
      ASSIGN COMPONENT zif_mdg_id_constants=>c_attributes-func_cts
             OF STRUCTURE <lwa_result> TO FIELD-SYMBOL(<lfd_cts_field>).
      IF <lfd_cts_field> IS ASSIGNED.
        <lfd_cts_field> = lfd_cts_function.
      ENDIF.
    ELSE.
      " Return the raw fragments so the caller never gets an empty result.
      ASSIGN COMPONENT zif_mdg_id_constants=>c_attributes-company_code
             OF STRUCTURE <lwa_result> TO <lfd_cc_field>.
      IF <lfd_cc_field> IS ASSIGNED.
        <lfd_cc_field> = lfd_compcode_first2.
      ENDIF.
      ASSIGN COMPONENT zif_mdg_id_constants=>c_attributes-plant
             OF STRUCTURE <lwa_result> TO <lfd_plant_field>.
      IF <lfd_plant_field> IS ASSIGNED.
        <lfd_plant_field> = lfd_plant_last2.
      ENDIF.
      ASSIGN COMPONENT zif_mdg_id_constants=>c_attributes-func_cts
             OF STRUCTURE <lwa_result> TO <lfd_cts_field>.
      IF <lfd_cts_field> IS ASSIGNED.
        <lfd_cts_field> = lfd_cts_function.
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
