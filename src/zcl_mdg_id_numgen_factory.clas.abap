"! <p class="shorttext synchronized">MDG ID Generator - Number Generator Factory</p>
"! Ported from /S4E/CL_P40_MDG_NUMGEN_FACTORY.
"! Returns the concrete number generator for an entity / project code
"! combination and, when no structure is supplied, creates a default
"! one from the mapped structure name.
CLASS zcl_mdg_id_numgen_factory DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.

    "! Static factory method.
    CLASS-METHODS get_number_generator
      IMPORTING
        !pfd_i_entity        TYPE usmd_entity
        !pwa_i_structure     TYPE REF TO data OPTIONAL
        !pfd_i_project       TYPE ze_mdg_project_code OPTIONAL
      RETURNING
        VALUE(pri_r_generator) TYPE REF TO zif_mdg_id_number_gen .

  PROTECTED SECTION.

    CLASS-DATA ri_my_interface  TYPE REF TO zif_mdg_id_number_gen .
    CLASS-DATA fd_my_class_name TYPE string .

  PRIVATE SECTION.

    CLASS-METHODS get_generator_class_name
      IMPORTING
        !pfd_i_entity     TYPE usmd_entity
        !pfd_i_project    TYPE ze_mdg_project_code OPTIONAL
      EXPORTING
        !pfd_e_class_name TYPE string
        !pfd_e_structure  TYPE string .
    CLASS-METHODS create_generator_instance
      IMPORTING
        !pfd_i_class_name    TYPE string
        !pfd_i_entity        TYPE usmd_entity
        !pwa_i_structure     TYPE REF TO data
      RETURNING
        VALUE(pri_r_generator) TYPE REF TO zif_mdg_id_number_gen .

ENDCLASS.



CLASS zcl_mdg_id_numgen_factory IMPLEMENTATION.


  METHOD create_generator_instance.
    CLEAR pri_r_generator.
    " Create instance dynamically (cached per class name).
    IF ri_my_interface IS NOT BOUND OR fd_my_class_name <> pfd_i_class_name.
      CREATE OBJECT ri_my_interface TYPE (pfd_i_class_name)
        EXPORTING
          pfd_i_entity    = pfd_i_entity
          pwa_i_structure = pwa_i_structure.
    ENDIF.
    pri_r_generator ?= ri_my_interface.
    fd_my_class_name = pfd_i_class_name.
  ENDMETHOD.


  METHOD get_generator_class_name.
    CONSTANTS:
      lc_struct_se_cctr    TYPE string VALUE 'ZMDG_S_SE_CCTRID_RULE',
      lc_struct_sgre_cctr  TYPE string VALUE 'ZMDG_S_SG_CCTRID_RULE',
      lc_struct_se_pctr    TYPE string VALUE 'ZMDG_S_SE_PROFIT_NAMING',
      lc_struct_sgre_pctr  TYPE string VALUE 'ZMDG_S_SG_PCTRID_RULE',
      lc_struct_sg_acct    TYPE string VALUE 'ZMDG_S_SG_ACCT_NAMING',
      lc_classname_se_pctr TYPE string VALUE 'ZCL_MDG_SE_PCTR_ID_GEN',
      lc_classname_sg_pctr TYPE string VALUE 'ZCL_MDG_SG_PCTR_ID_GEN',
      lc_classname_se_cctr TYPE string VALUE 'ZCL_MDG_SE_CCTR_ID_GEN',
      lc_classname_sg_cctr TYPE string VALUE 'ZCL_MDG_SG_CCTR_ID_GEN',
      lc_classname_sg_acct TYPE string VALUE 'ZCL_MDG_SG_ACCT_ID_GEN'.

    CLEAR: pfd_e_class_name, pfd_e_structure.

    " Build class name based on entity and project code.
    IF pfd_i_project IS INITIAL.
      CASE pfd_i_entity.
        WHEN if_usmdz_cons_entitytypes=>gc_entity_cctr.
          pfd_e_class_name = lc_classname_sg_cctr.
      ENDCASE.
    ELSE.
      CASE pfd_i_entity.
        WHEN if_usmdz_cons_entitytypes=>gc_entity_pctr.
          CASE pfd_i_project.
            WHEN zif_mdg_id_constants=>c_project_codes-c_se.
              pfd_e_structure  = lc_struct_se_pctr.
              pfd_e_class_name = lc_classname_se_pctr.
            WHEN zif_mdg_id_constants=>c_project_codes-c_sgre.
              pfd_e_structure  = lc_struct_sgre_pctr.
              pfd_e_class_name = lc_classname_sg_pctr.
          ENDCASE.

        WHEN if_usmdz_cons_entitytypes=>gc_entity_cctr.
          CASE pfd_i_project.
            WHEN zif_mdg_id_constants=>c_project_codes-c_se.
              pfd_e_structure  = lc_struct_se_cctr.
              pfd_e_class_name = lc_classname_se_cctr.
            WHEN zif_mdg_id_constants=>c_project_codes-c_sgre.
              pfd_e_class_name = lc_classname_sg_cctr.
              pfd_e_structure  = lc_struct_sgre_cctr.
          ENDCASE.

        WHEN if_usmdz_cons_entitytypes=>gc_entity_account.
          CASE pfd_i_project.
            WHEN zif_mdg_id_constants=>c_project_codes-c_sgre.
              pfd_e_structure  = lc_struct_sg_acct.
              pfd_e_class_name = lc_classname_sg_acct.
          ENDCASE.

      ENDCASE.
    ENDIF.
  ENDMETHOD.


  METHOD get_number_generator.
    DATA lrd_structure TYPE REF TO data.

    IF pfd_i_entity IS INITIAL.
      RETURN.
    ENDIF.

    get_generator_class_name(
      EXPORTING
        pfd_i_entity     = pfd_i_entity
        pfd_i_project    = pfd_i_project
      IMPORTING
        pfd_e_class_name = DATA(lfd_class_name)
        pfd_e_structure  = DATA(lfd_structure_name) ).

    " Guard vs. original: no mapping -> no generator (avoids a dump on
    " CREATE OBJECT / CREATE DATA with an empty name).
    IF lfd_class_name IS INITIAL.
      RETURN.
    ENDIF.

    IF pwa_i_structure IS SUPPLIED.
      pri_r_generator = create_generator_instance(
                          pfd_i_class_name = lfd_class_name
                          pfd_i_entity     = pfd_i_entity
                          pwa_i_structure  = pwa_i_structure ).
    ELSE.
      IF lfd_structure_name IS INITIAL.
        RETURN.
      ENDIF.
      CREATE DATA lrd_structure TYPE (lfd_structure_name).
      pri_r_generator = create_generator_instance(
                          pfd_i_class_name = lfd_class_name
                          pfd_i_entity     = pfd_i_entity
                          pwa_i_structure  = lrd_structure ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
