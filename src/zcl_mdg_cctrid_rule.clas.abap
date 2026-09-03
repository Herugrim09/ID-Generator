"! <p class="shorttext synchronized">MDG ID Generator - Cost Center Rule (Entity Base)</p>
"! Ported from /S4E/CL_P40_MDG_0G_CCTRID_RULE.
"! Thin entity layer on top of the generic feeder: fixes the entity to
"! CCTR. Project-specific feeders inherit from this class.
CLASS zcl_mdg_cctrid_rule DEFINITION
  PUBLIC
  INHERITING FROM zcl_mdg_id_uibb_feeder
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS if_fpm_guibb~initialize REDEFINITION .

  PROTECTED SECTION.
    TYPES tt_profit_centers TYPE STANDARD TABLE OF usmdz10_s_ovs_output .

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_mdg_cctrid_rule IMPLEMENTATION.


  METHOD if_fpm_guibb~initialize.
    CALL METHOD super->if_fpm_guibb~initialize
      EXPORTING
        it_parameter      = it_parameter
        io_app_parameter  = io_app_parameter
        iv_component_name = iv_component_name
        is_config_key     = is_config_key
        iv_instance_id    = iv_instance_id.

    me->fd_entity = if_usmdz_cons_entitytypes=>gc_entity_cctr.
  ENDMETHOD.

ENDCLASS.
