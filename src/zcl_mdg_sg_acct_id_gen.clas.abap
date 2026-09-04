"! <p class="shorttext synchronized">MDG ID Generator - SGRE Bank GL Account ID</p>
"! Concrete number generator for entity ACCOUNT, project SGRE.
"! Resolved by ZCL_MDG_ID_NUMGEN_FACTORY for (ACCOUNT / SGRE).
"!
"! GL account (10 char, SAKNR) is fully deterministic and needs no DB read
"! (MDG itself enforces uniqueness of the result):
"!   '00' + group(1-3) + bank code(4-5) + currency code(6-7) + planning digit(8)
"! e.g. 28805980 = 288 (Main) + 05 (BNP Paribas) + 98 (EUR) + 0
"!      48899063 = 488 (Interim IHB) + 99 (IHB) + 06 (DKK) + 3
"!
"! Positions 4-5: the user picks a BANK NAME in the OVS (field BANK); the
"! stored value is that bank's 2-char "Code for Bank". Every
"! "(Bank account# N)" entry is its own row with its own code, so the
"! "use the next code when bank + currency clash" rule from concept
"! slide 6 is a manual choice by the user, not derived here.
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
      lc_bank_code     TYPE name_komp VALUE 'BANK_CODE',
      lc_currency      TYPE name_komp VALUE 'CURRENCY',
      lc_account_group TYPE name_komp VALUE 'ACCOUNT_GROUP',
      lc_payment_meth  TYPE name_komp VALUE 'PAYMENT_METHOD'.

    METHODS read_char
      IMPORTING !iv_component  TYPE name_komp
      RETURNING VALUE(rv_value) TYPE string .

    METHODS parse_id_into_components
      IMPORTING !iv_number      TYPE any
      RETURNING VALUE(rr_return) TYPE REF TO data .

    "! Position 6-7: 2-char currency code for an ISO currency; INITIAL if
    "! unknown. Derived from ZCL_MDG_SG_BRF_DT=>GET_CURRENCY_CODES.
    METHODS currency_code
      IMPORTING !iv_iso        TYPE waers
      RETURNING VALUE(rv_code) TYPE ze_mdg_currency_code .

    "! Position 1-3: group for an account group kind; INITIAL if unknown.
    "! Derived from ZCL_MDG_SG_BRF_DT=>GET_ACCOUNT_GROUPS.
    METHODS group_of_kind
      IMPORTING !iv_kind        TYPE ze_mdg_acct_group_kind
      RETURNING VALUE(rv_group) TYPE ze_mdg_acct_group .

    "! Position 8 digit. MAIN / IHB -> 0, INT_IN -> 1, INT_OUT / IHB_INT
    "! -> per payment method (concept slide 8, ZCL_MDG_SG_BRF_DT=>
    "! GET_PLANNING_LEVELS).
    METHODS planning_digit
      IMPORTING !iv_kind           TYPE ze_mdg_acct_group_kind
                !iv_payment_method TYPE ze_mdg_payment_method OPTIONAL
      RETURNING VALUE(rv_digit)    TYPE ze_mdg_planning_digit .

ENDCLASS.



CLASS zcl_mdg_sg_acct_id_gen IMPLEMENTATION.


  METHOD zif_mdg_id_number_gen~generate_number.
    " Sync the internal buffer (RD_MY_DATA) with the data currently on the
    " screen. The factory caches the generator instance, so without this
    " the fields below are read from whatever RD_MY_DATA held at
    " CREATE OBJECT time - stale or empty on any call after the first.
    " Same first step as CL_P40_MDG_SE_PCTR_ID_GEN=>GENERATE_NUMBER.
    me->was_field_changed( pwa_i_structure ).

    DATA(lv_kind) = CONV ze_mdg_acct_group_kind( to_upper( read_char( lc_account_group ) ) ).
    DATA(lv_iso)  = CONV waers( to_upper( read_char( lc_currency ) ) ).
    DATA(lv_bank) = CONV ze_mdg_bank_code( to_upper( read_char( lc_bank_code ) ) ).
    DATA(lv_pm)   = CONV ze_mdg_payment_method( to_upper( read_char( lc_payment_meth ) ) ).

    " Every field of the structure must be filled before an ID is built.
    IF lv_kind IS INITIAL OR lv_iso IS INITIAL OR lv_bank IS INITIAL OR lv_pm IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_group) = group_of_kind( lv_kind ).
    DATA(lv_ccy)   = currency_code( lv_iso ).
    DATA(lv_digit) = planning_digit(
                       iv_kind           = lv_kind
                       iv_payment_method = lv_pm ).

    IF lv_group IS INITIAL OR lv_ccy IS INITIAL OR lv_digit IS INITIAL.
      " unknown group kind / currency, or Interim Out without a (mapped)
      " payment method -> cannot build a deterministic ID
      RETURN.
    ENDIF.

    DATA(lv_gl) = |00{ lv_group }{ lv_bank }{ lv_ccy }{ lv_digit }|.   " 10 characters

    CREATE DATA prd_r_number TYPE saknr.
    ASSIGN prd_r_number->* TO FIELD-SYMBOL(<lfd_gl>).
    IF <lfd_gl> IS ASSIGNED.
      <lfd_gl> = lv_gl.
    ENDIF.
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

    LOOP AT zcl_mdg_sg_brf_dt=>get_instance( )->get_currency_codes( ) INTO DATA(ls_ccy) WHERE code = lv_ccy.
      lv_iso = ls_ccy-iso.
      EXIT.
    ENDLOOP.
    LOOP AT zcl_mdg_sg_brf_dt=>get_instance( )->get_account_groups( ) INTO DATA(ls_grp) WHERE grp = lv_group.
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


  METHOD currency_code.
    DATA(lt) = zcl_mdg_sg_brf_dt=>get_instance( )->get_currency_codes( ).
    READ TABLE lt INTO DATA(ls) WITH KEY iso = iv_iso.
    IF sy-subrc = 0.
      rv_code = ls-code.
    ENDIF.
  ENDMETHOD.


  METHOD group_of_kind.
    DATA(lt) = zcl_mdg_sg_brf_dt=>get_instance( )->get_account_groups( ).
    READ TABLE lt INTO DATA(ls) WITH KEY kind = iv_kind.
    IF sy-subrc = 0.
      rv_group = ls-grp.
    ENDIF.
  ENDMETHOD.


  METHOD planning_digit.
    CASE iv_kind.
      WHEN zcl_mdg_sg_brf_dt=>c_kind-main.
        rv_digit = '0'.
      WHEN zcl_mdg_sg_brf_dt=>c_kind-int_in.
        rv_digit = '1'.
      WHEN zcl_mdg_sg_brf_dt=>c_kind-ihb.
        " Confirmed by concept slide 5 example 25399060
        " (253 + 99 + 06 + 0): IHB main behaves like the external main bank.
        rv_digit = '0'.
      WHEN zcl_mdg_sg_brf_dt=>c_kind-int_out OR zcl_mdg_sg_brf_dt=>c_kind-ihb_int.
        " Confirmed by concept slide 5 example 48899063
        " (488 + 99 + 06 + 3): IHB interim uses the same position-8
        " payment-method table as the external Interim Out (485).
        LOOP AT zcl_mdg_sg_brf_dt=>get_instance( )->get_planning_levels( ) INTO DATA(ls) WHERE pmethod = iv_payment_method.
          rv_digit = ls-digit.
          EXIT.
        ENDLOOP.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
