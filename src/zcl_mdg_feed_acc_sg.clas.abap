"! <p class="shorttext synchronized">MDG-F Account Detail UIBB - SGRE Feeder</p>
"! Project (SGRE) feeder for the ACCOUNT detail form UIBB. Mirrors
"! /S4E/CL_P40_MDG_FEED_CCTR_SG (which sits on _FEED_CCTR_BASE).
"!
"! This is the class the ACCOUNT detail UIBB configuration should point
"! at. It currently only inherits the GENERATED_ID write-back from
"! ZCL_MDG_FEED_ACC_BASE.
"!
"! Add project-specific behaviour here as needed, e.g.:
"!   - IF_FPM_GUIBB_FORM~GET_DATA  : default values, hide fields,
"!                                   read-only field properties
"!   - IF_FPM_GUIBB_FORM~GET_DEFINITION : extra actions
"!   - OVS_HANDLE_PHASE_2 (protected, from the standard MDG-F feeder)
"!                                   : custom value helps; CASE on the
"!                                   field and delegate WHEN OTHERS to
"!                                   super->ovs_handle_phase_2
CLASS zcl_mdg_feed_acc_sg DEFINITION
  PUBLIC
  INHERITING FROM zcl_mdg_feed_acc_base
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_mdg_feed_acc_sg IMPLEMENTATION.
ENDCLASS.
