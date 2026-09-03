"! <p class="shorttext synchronized">MDG ID Generator - SGRE Account Naming UIBB</p>
"! Siemens Gamesa (SGRE) account naming-convention feeder. Sets the
"! project code so the number generator factory resolves
"! ZCL_MDG_SG_ACCT_ID_GEN. Add ACCOUNT-specific OVS value helps here
"! (redefine IF_FPM_GUIBB_OVS~HANDLE_PHASE_2 etc.) once the functional
"! spec is available - see ZCL_MDG_SE_CCTRID_RULE for the pattern.
CLASS zcl_mdg_sg_acctid_rule DEFINITION
  PUBLIC
  INHERITING FROM zcl_mdg_acctid_rule
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS if_fpm_guibb~initialize REDEFINITION .

  PROTECTED SECTION.
  PRIVATE SECTION.
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

ENDCLASS.
