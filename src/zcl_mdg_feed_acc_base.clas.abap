"! <p class="shorttext synchronized">MDG-F Account Detail UIBB - Base Feeder</p>
"! Base feeder for the ACCOUNT detail form UIBB in the MDG change
"! request. Mirrors /S4E/CL_P40_MDG_FEED_CCTR_BASE for the cost centre.
"!
"! Sole job: on the custom FPM event ZATTR_SELECTED (raised by the ID
"! generator UIBB, ZCL_MDG_SG_ACC_ID_A_GEN), take GENERATED_ID from the
"! event payload and write it into the ACCOUNT entity key attribute via
"! MO_ENTITY->SET_PROPERTY.
"!
"! Wiring: in the ACCOUNT detail UIBB configuration, replace the feeder
"! class with this one (or a project subclass of it).
"!
"! NOTE: INHERITING FROM must be the standard MDG-F feeder that the
"! ACCOUNT detail UIBB currently uses. CL_MDGF_GUIBB_ACCOUNT is the
"! usual one; check SE80 -> the entity form config -> Feeder Class and
"! adjust if your system differs.
CLASS zcl_mdg_feed_acc_base DEFINITION
  PUBLIC
  INHERITING FROM cl_mdgf_guibb_account
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS if_fpm_guibb_form~process_event REDEFINITION .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_mdg_feed_acc_base IMPLEMENTATION.


  METHOD if_fpm_guibb_form~process_event.
    DATA lrd_event_data TYPE REF TO data.
    CONSTANTS:
      lc_generated_id TYPE string       VALUE 'GENERATED_ID',
      lc_event_id     TYPE fpm_event_id VALUE 'ZATTR_SELECTED'.

    CALL METHOD super->if_fpm_guibb_form~process_event
      EXPORTING
        io_event            = io_event
        iv_raised_by_own_ui = iv_raised_by_own_ui
      IMPORTING
        ev_result           = ev_result
        et_messages         = et_messages.

    CASE io_event->mv_event_id.
      "  Take the generated account ID into the ACCOUNT entity key.
      WHEN lc_event_id.
        io_event->mo_event_data->get_value(
          EXPORTING
            iv_key   = lc_generated_id
          IMPORTING
            er_value = lrd_event_data ).
        IF lrd_event_data IS BOUND.
          ASSIGN lrd_event_data->* TO FIELD-SYMBOL(<lfd_generated_id>).
          IF <lfd_generated_id> IS ASSIGNED.
            me->mo_entity->set_property(
              iv_attr_name = CONV name_komp( if_usmdz_cons_entitytypes=>gc_entity_account )
              iv_value     = <lfd_generated_id> ).
          ENDIF.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
