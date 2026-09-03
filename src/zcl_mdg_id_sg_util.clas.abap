"! <p class="shorttext synchronized">MDG ID Generator - Plant / Company Code Utility</p>
"! Ported from /S4E/CL_P40_MDG_0G_SG_UTIL. Provides the company code
"! vs. plant assignment used by the profit center ID generator.
"! GET_PLANTS is a buffered stub - fill it with the real selection.
CLASS zcl_mdg_id_sg_util DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_plant,
        bukrs        TYPE bukrs,
        plant_number TYPE werks_d,
      END OF ty_plant.
    TYPES tt_plants TYPE STANDARD TABLE OF ty_plant WITH DEFAULT KEY.

    CLASS-METHODS get_instance
      RETURNING VALUE(pri_r_instance) TYPE REF TO zcl_mdg_id_sg_util.

    METHODS get_plants
      RETURNING VALUE(pit_r_plants) TYPE tt_plants.

  PRIVATE SECTION.
    CLASS-DATA go_instance TYPE REF TO zcl_mdg_id_sg_util.
    DATA it_plants_buffer TYPE tt_plants.

ENDCLASS.


CLASS zcl_mdg_id_sg_util IMPLEMENTATION.

  METHOD get_instance.
    IF go_instance IS NOT BOUND.
      go_instance = NEW #( ).
    ENDIF.
    pri_r_instance = go_instance.
  ENDMETHOD.

  METHOD get_plants.
    IF it_plants_buffer IS INITIAL.
      " TODO: select the company code <-> plant assignment (e.g. T001W / T001K)
      "       into it_plants_buffer.
    ENDIF.
    pit_r_plants = it_plants_buffer.
  ENDMETHOD.

ENDCLASS.
