"! <p class="shorttext synchronized">MDG ID Generator - SGRE Bank GL Account ID</p>
"! Concrete number generator for entity ACCOUNT, project SGRE.
"! Resolved by ZCL_MDG_ID_NUMGEN_FACTORY for (ACCOUNT / SGRE).
"!
"! GL account (10 char, SAKNR) is fully deterministic:
"!   '00' + group(1-3) + bank code(4-5) + currency code(6-7) + planning digit(8)
"! e.g. 28805980 = 288 (Main) + 05 (BNP Paribas) + 98 (EUR) + 0
"!      48899063 = 488 (Interim IHB) + 99 (IHB) + 06 (DKK) + 3
"! Uniqueness of the result is enforced by MDG itself - this class does
"! not re-check the generated ID. The only DB read is the bank-code
"! sequence rule (see DETERMINE_BANK_CODE).
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

    CONSTANTS:
      lc_are           TYPE name_komp VALUE 'ARE',
      lc_bank_code     TYPE name_komp VALUE 'BANK_CODE',
      lc_currency      TYPE name_komp VALUE 'CURRENCY',
      lc_account_group TYPE name_komp VALUE 'ACCOUNT_GROUP',
      lc_payment_meth  TYPE name_komp VALUE 'PAYMENT_METHOD'.

    METHODS read_char
      IMPORTING !iv_component  TYPE name_komp
      RETURNING VALUE(rv_value) TYPE string .

    "! Bank-code sequence rule (concept slide 6: "same bank code and same
    "! currency" -> next code). Walks the selected bank's ordered code
    "! list and returns the first code whose (group + code + currency)
    "! slot is still free in the ACCOUNT staging area, checked via the
    "! inherited QUERYING_DB.
    METHODS determine_bank_code
      IMPORTING !iv_selected_code TYPE ze_mdg_bank_code
                !iv_group         TYPE ze_mdg_acct_group
                !iv_ccy_code      TYPE ze_mdg_currency_code
      RETURNING VALUE(rv_code)    TYPE ze_mdg_bank_code .

    METHODS parse_id_into_components
      IMPORTING !iv_number       TYPE any
      RETURNING VALUE(rr_return)  TYPE REF TO data .

ENDCLASS.



CLASS zcl_mdg_sg_acct_id_gen IMPLEMENTATION.


  METHOD zif_mdg_id_number_gen~generate_number.
    DATA(lv_kind)  = CONV ze_mdg_acct_group_kind( to_upper( read_char( lc_account_group ) ) ).
    DATA(lv_iso)   = CONV waers( to_upper( read_char( lc_currency ) ) ).
    DATA(lv_bank0) = CONV ze_mdg_bank_code( to_upper( read_char( lc_bank_code ) ) ).
    DATA(lv_pm)    = CONV ze_mdg_payment_method( to_upper( read_char( lc_payment_meth ) ) ).

    IF lv_kind IS INITIAL OR lv_iso IS INITIAL OR lv_bank0 IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_group) = zcl_mdg_sg_acct_rules=>group_of_kind( lv_kind ).
    DATA(lv_ccy)   = zcl_mdg_sg_acct_rules=>currency_code( lv_iso ).
    DATA(lv_digit) = zcl_mdg_sg_acct_rules=>planning_digit(
                       iv_kind           = lv_kind
                       iv_payment_method = lv_pm ).

    IF lv_group IS INITIAL OR lv_ccy IS INITIAL OR lv_digit IS INITIAL.
      " unknown group kind / currency, or Interim Out without a (mapped)
      " payment method -> cannot build a deterministic ID
      RETURN.
    ENDIF.

    DATA(lv_bank) = determine_bank_code( iv_selected_code = lv_bank0
                                         iv_group         = lv_group
                                         iv_ccy_code      = lv_ccy ).
    IF lv_bank IS INITIAL.
      " every code of this bank is already taken for this currency
      RETURN.
    ENDIF.

    DATA(lv_gl) = |00{ lv_group }{ lv_bank }{ lv_ccy }{ lv_digit }|.   " 10 characters

    CREATE DATA prd_r_number TYPE saknr.
    ASSIGN prd_r_number->* TO FIELD-SYMBOL(<lfd_gl>).
    IF <lfd_gl> IS ASSIGNED.
      <lfd_gl> = lv_gl.
    ENDIF.
  ENDMETHOD.


  METHOD determine_bank_code.
    CLEAR rv_code.

    DATA(lit_seq) = zcl_mdg_sg_acct_rules=>get_bank_code_sequence( iv_selected_code ).

    LOOP AT lit_seq INTO DATA(lv_cand).
      " reference = 00 + group(3) + candidate code(2) + currency(2) = 9 chars;
      " + 1 running digit (position 8) = full 10-char GL account key.
      DATA(lv_ref) = |00{ iv_group }{ lv_cand }{ iv_ccy_code }|.

      me->querying_db( pfd_i_reference          = lv_ref
                       pfd_i_running_num_length = 1 ).

      IF it_my_data IS INITIAL.
        rv_code = lv_cand.          " free slot -> use this code
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_mdg_id_number_gen~split_number.
    CLEAR pfd_r_return.
    IF pfd_i_number IS INITIAL.
      RETURN.
    ENDIF.
    pfd_r_return = parse_id_into_components( iv_number = pfd_i_number ).
  ENDMETHOD.


  METHOD parse_id_into_components.
    DATA: lv_gl   TYPE saknr,
          lv_body TYPE string,
          lv_iso  TYPE waers,
          lv_kind TYPE ze_mdg_acct_group_kind.

    CLEAR rr_return.
    lv_gl   = iv_number.
    lv_body = lv_gl.
    IF strlen( lv_gl ) = 10 AND lv_gl(2) = '00'.
      lv_body = lv_gl+2.
    ENDIF.
    IF strlen( lv_body ) < 8.
      RETURN.
    ENDIF.

    DATA(lv_group) = CONV ze_mdg_acct_group( lv_body(3) ).
    DATA(lv_bank)  = CONV ze_mdg_bank_code( lv_body+3(2) ).
    DATA(lv_ccy)   = CONV ze_mdg_currency_code( lv_body+5(2) ).

    LOOP AT zcl_mdg_sg_acct_rules=>get_currency_codes( ) INTO DATA(ls_ccy) WHERE code = lv_ccy.
      lv_iso = ls_ccy-iso.
      EXIT.
    ENDLOOP.
    LOOP AT zcl_mdg_sg_acct_rules=>get_account_groups( ) INTO DATA(ls_grp) WHERE grp = lv_group.
      lv_kind = ls_grp-kind.
      EXIT.
    ENDLOOP.

    ASSIGN me->rd_my_data->* TO FIELD-SYMBOL(<lwa_template>).
    IF <lwa_template> IS NOT ASSIGNED.
      RETURN.
    ENDIF.
    CREATE DATA rr_return LIKE <lwa_template>.
    ASSIGN rr_return->* TO FIELD-SYMBOL(<lwa_out>).
    IF <lwa_out> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    ASSIGN COMPONENT lc_bank_code OF STRUCTURE <lwa_out> TO FIELD-SYMBOL(<lfd_f>).
    IF <lfd_f> IS ASSIGNED.
      <lfd_f> = lv_bank.
    ENDIF.
    ASSIGN COMPONENT lc_currency OF STRUCTURE <lwa_out> TO <lfd_f>.
    IF <lfd_f> IS ASSIGNED.
      <lfd_f> = lv_iso.
    ENDIF.
    ASSIGN COMPONENT lc_account_group OF STRUCTURE <lwa_out> TO <lfd_f>.
    IF <lfd_f> IS ASSIGNED.
      <lfd_f> = lv_kind.
    ENDIF.
  ENDMETHOD.


  METHOD read_char.
    CLEAR rv_value.
    DATA(lrd_val) = me->get_field_value( pfd_i_component_name = iv_component ).
    IF lrd_val IS BOUND.
      ASSIGN lrd_val->* TO FIELD-SYMBOL(<lfd_any>).
      IF <lfd_any> IS ASSIGNED.
        rv_value = <lfd_any>.
        CONDENSE rv_value.
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
