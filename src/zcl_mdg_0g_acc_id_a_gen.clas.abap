"! <p class="shorttext synchronized">MDG ID Generator - Account Rule (Entity Base)</p>
"! Entity layer on top of the generic feeder: fixes the entity to
"! ACCOUNT. Project-specific account feeders inherit from this class.
"! Mirrors ZCL_MDG_CCTRID_RULE for the cost center entity.
CLASS zcl_mdg_0g_acc_id_a_gen DEFINITION
  PUBLIC
  INHERITING FROM zcl_mdg_id_uibb_feeder
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS if_fpm_guibb~initialize REDEFINITION .

  PROTECTED SECTION.
    TYPES tt_accounts TYPE STANDARD TABLE OF usmdz10_s_ovs_output .

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_mdg_0g_acc_id_a_gen IMPLEMENTATION.


  METHOD if_fpm_guibb~initialize.
    CALL METHOD super->if_fpm_guibb~initialize
      EXPORTING
        it_parameter      = it_parameter
        io_app_parameter  = io_app_parameter
        iv_component_name = iv_component_name
        is_config_key     = is_config_key
        iv_instance_id    = iv_instance_id.

    me->fd_entity = if_usmdz_cons_entitytypes=>gc_entity_account.
  ENDMETHOD.

ENDCLASS.
