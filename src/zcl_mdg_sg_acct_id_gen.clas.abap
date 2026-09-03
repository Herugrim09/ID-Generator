"! <p class="shorttext synchronized">MDG ID Generator - SGRE Account ID</p>
"! Concrete number generator for entity ACCOUNT, project SGRE.
"! Resolved by ZCL_MDG_ID_NUMGEN_FACTORY for (ACCOUNT / SGRE).
"!
"! STATUS: scaffold. GENERATE_NUMBER / SPLIT_NUMBER are stubs pending
"! the functional spec for the SGRE account ID composition rule
"! (prefix, driver attributes, segment lengths, running number length,
"! split logic). See ZCL_MDG_SE_PCTR_ID_GEN for a complete example.
CLASS zcl_mdg_sg_acct_id_gen DEFINITION
  PUBLIC
  INHERITING FROM zcl_mdg_id_numgen_base
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS zif_mdg_id_number_gen~generate_number REDEFINITION .
    METHODS zif_mdg_id_number_gen~split_number REDEFINITION .

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS parse_id_into_components
      IMPORTING
        !pfd_i_number       TYPE any
      RETURNING
        VALUE(pfd_r_return) TYPE REF TO data .

ENDCLASS.



CLASS zcl_mdg_sg_acct_id_gen IMPLEMENTATION.


  METHOD zif_mdg_id_number_gen~generate_number.
*   TODO(spec): implement the SGRE ACCOUNT ID rule. Expected shape,
*   following the profit center generator:
*     1. Read the driver attributes from the buffered structure via
*        me->get_field_value( pfd_i_component_name = '<COMPONENT>' ).
*     2. Detect whether the input changed:
*        DATA(lfd_changed) = me->was_field_changed( pwa_i_structure ).
*     3. Build the reference prefix, e.g.
*        DATA(lfd_ref) = |<PREFIX><segment1><segment2>|.
*     4. Load the existing IDs in that range:
*        IF it_my_data IS INITIAL OR lfd_changed = abap_true.
*          me->querying_db( pfd_i_reference          = lfd_ref
*                           pfd_i_running_num_length = <n> ).
*        ENDIF.
*     5. Gap-scan me->it_my_data (sorted) for the first free running
*        number, respect the ceiling ( 10 ** <n> ) - 1.
*     6. CREATE DATA prd_r_number TYPE usmd_value (or the model's
*        ACCOUNT key data element) and hand back the assembled ID.
    RETURN.
  ENDMETHOD.


  METHOD zif_mdg_id_number_gen~split_number.
    CLEAR pfd_r_return.
    IF pfd_i_number IS INITIAL.
      RETURN.
    ENDIF.
    pfd_r_return = parse_id_into_components( pfd_i_number = pfd_i_number ).
  ENDMETHOD.


  METHOD parse_id_into_components.
*   TODO(spec): reverse of GENERATE_NUMBER - split an existing ACCOUNT
*   ID back into its component attributes and return them in a copy of
*   the buffered structure. See ZCL_MDG_SE_PCTR_ID_GEN=>PARSE_ID_INTO_COMPONENTS.
    CLEAR pfd_r_return.
    ASSIGN me->rd_my_data->* TO FIELD-SYMBOL(<lwa_template>).
    IF <lwa_template> IS ASSIGNED.
      CREATE DATA pfd_r_return LIKE <lwa_template>.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
