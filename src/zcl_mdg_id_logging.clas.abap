"! <p class="shorttext synchronized">MDG ID Generator - Application Logging</p>
"! Thin wrapper around the BAL application log used by the ID generator
"! framework. Ported from /S4E/CL_P40_MDG_0G_LOGGING - replace the body of
"! WRITE_APPLICATION_LOG_SIMPLE with the project's own logging call.
CLASS zcl_mdg_id_logging DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CONSTANTS c_object_mdg     TYPE balobj_d   VALUE 'USMD' ##NO_TEXT.
    CONSTANTS c_object_fi      TYPE balobj_d   VALUE 'FI'   ##NO_TEXT.
    CONSTANTS c_sub_object_wf  TYPE balsubobj  VALUE 'WF'   ##NO_TEXT.

    "! Writes a simple message (text or exception based) to SLG1.
    CLASS-METHODS write_application_log_simple
      IMPORTING
        !pfd_i_crequest      TYPE usmd_crequest_id OPTIONAL
        !pfd_i_object        TYPE balobj_d
        !pfd_i_subobject     TYPE balsubobj
        !pfd_i_message_text  TYPE string OPTIONAL
        !pit_i_messages      TYPE ANY TABLE OPTIONAL
        !pfd_i_exception_obj TYPE REF TO cx_root OPTIONAL.

ENDCLASS.


CLASS zcl_mdg_id_logging IMPLEMENTATION.

  METHOD write_application_log_simple.
    " TODO: connect to the project application log (BAL / cl_bal_log ...).
    " Kept as a no-op stub so the framework activates stand-alone.
    RETURN.
  ENDMETHOD.

ENDCLASS.
