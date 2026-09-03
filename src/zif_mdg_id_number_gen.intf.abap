"! <p class="shorttext synchronized">MDG ID Generator - Number Generator Interface</p>
"! Ported from /S4E/IF_P40_MDG_0G_NUMBER_GEN.
INTERFACE zif_mdg_id_number_gen
  PUBLIC.

  "! Generates the next ID for the entity, based on the values in the
  "! passed structure. Implemented by the concrete generator classes.
  METHODS generate_number
    IMPORTING
      !pwa_i_structure    TYPE REF TO data
    RETURNING
      VALUE(prd_r_number) TYPE REF TO data.

  "! Splits an existing ID back into its component attributes.
  METHODS split_number
    IMPORTING
      !pfd_i_number       TYPE any OPTIONAL
    RETURNING
      VALUE(pfd_r_return) TYPE REF TO data.

ENDINTERFACE.
