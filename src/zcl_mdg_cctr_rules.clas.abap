"! <p class="shorttext synchronized">MDG ID Generator - Cost Center Rule Types</p>
"! Ported type container from /S4E/CL_P40_MDG_0G_CCTR_RULES. Only the
"! types consumed by the cost center naming convention feeder are kept.
CLASS zcl_mdg_cctr_rules DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_func,
        func TYPE ze_mdg_cost_func,
        text TYPE ze_mdg_func_text,
      END OF ty_func.
    TYPES tt_func TYPE STANDARD TABLE OF ty_func WITH DEFAULT KEY.

ENDCLASS.


CLASS zcl_mdg_cctr_rules IMPLEMENTATION.
ENDCLASS.
