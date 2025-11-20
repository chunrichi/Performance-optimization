*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_003
*&---------------------------------------------------------------------*
*& MODIFY itab TRANSPORTING field WHERE condition vs Individual MODIFY Performance Comparison
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_003.

CLASS lcl_modify_comparison DEFINITION.
  PUBLIC SECTION.
    " Performance measurement data
    DATA: mv_time_individual_modify TYPE i,
          mv_time_bulk_modify       TYPE i.

    " Data structure for testing
    TYPES: BEGIN OF ts_test_data,
             key_field  TYPE i,      " Key field
             data_field TYPE string, " Some data field
             status     TYPE c LENGTH 1, " Status field to be modified
           END OF ts_test_data.

    DATA: mt_test_data_individual TYPE TABLE OF ts_test_data, " For individual MODIFY
          mt_test_data_bulk       TYPE TABLE OF ts_test_data. " For bulk MODIFY

    METHODS:
      init,
      individual_modify,
      bulk_modify,
      measure_individual_modify,
      measure_bulk_modify,
      display_results.
ENDCLASS.

CLASS lcl_modify_comparison IMPLEMENTATION.

  METHOD init.
    " Generate test data with initial status 'A'
    DATA: lv_counter TYPE i VALUE 1.

    CLEAR: mt_test_data_individual, mt_test_data_bulk.

    DO 1000 TIMES.  " Create 1000 test records
      APPEND VALUE #( key_field = lv_counter
                      data_field = |Data for key { lv_counter }|
                      status = 'A' ) TO mt_test_data_individual.
      APPEND VALUE #( key_field = lv_counter
                      data_field = |Data for key { lv_counter }|
                      status = 'A' ) TO mt_test_data_bulk.
      lv_counter = lv_counter + 1.
    ENDDO.

    cl_demo_output=>write( |Generated { lines( mt_test_data_individual ) } test records| ).
    cl_demo_output=>write( 'Ready to compare MODIFY methods: bulk vs individual' ).
  ENDMETHOD.

  METHOD individual_modify.
    " Update status field using individual MODIFY statements in loop
    DATA: ls_line TYPE ts_test_data.

    " Update status from 'A' to 'B' for records with key_field >= 500
    LOOP AT mt_test_data_individual INTO ls_line WHERE key_field >= 500.
      ls_line-status = 'B'.
      MODIFY mt_test_data_individual FROM ls_line.
    ENDLOOP.

    " Just to ensure the method does something meaningful
    IF lines( mt_test_data_individual ) > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD bulk_modify.
    " Update status field using MODIFY itab TRANSPORTING field WHERE condition
    " Update status from 'A' to 'B' for records with key_field >= 500 using bulk MODIFY
    MODIFY mt_test_data_bulk FROM VALUE #( status = 'B' ) TRANSPORTING status WHERE key_field >= 500.

    " Just to ensure the method does something meaningful
    IF lines( mt_test_data_bulk ) > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD measure_individual_modify.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    individual_modify( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_individual_modify = mv_time_individual_modify + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD measure_bulk_modify.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    bulk_modify( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_bulk_modify = mv_time_bulk_modify + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD display_results.
    DATA: lv_improvement    TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_factor TYPE p LENGTH 5 DECIMALS 2.

    cl_demo_output=>write( '=== MODIFY METHODS PERFORMANCE COMPARISON ===' ).
    cl_demo_output=>write( 'Comparison: MODIFY itab TRANSPORTING field WHERE condition vs Individual MODIFY in loop' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).

    " Calculate improvement percentage
    IF mv_time_individual_modify > 0.
      lv_improvement = ( 1 - ( mv_time_bulk_modify / mv_time_individual_modify ) ) * 100.
      lv_speedup_factor = mv_time_individual_modify / mv_time_bulk_modify.
    ELSE.
      lv_improvement = 0.
      lv_speedup_factor = 1.
    ENDIF.

    cl_demo_output=>write( |Total time with INDIVIDUAL MODIFY (LOOP AT...MODIFY): { mv_time_individual_modify } microseconds| ).
    cl_demo_output=>write( |Total time with BULK MODIFY (TRANSPORTING WHERE):     { mv_time_bulk_modify } microseconds| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( |Performance improvement: { lv_improvement }%| ).
    cl_demo_output=>write( |Speedup factor: { lv_speedup_factor }x| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'Note: MODIFY itab TRANSPORTING field WHERE condition is generally faster as it' ).
    cl_demo_output=>write( 'performs a single bulk operation instead of multiple individual modifications.' ).
    cl_demo_output=>write( 'This is especially beneficial when updating many records that match the condition.' ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  CONSTANTS: lc_num_of_iterations TYPE i VALUE 50. " More iterations for stable measurement

  DATA(object) = NEW lcl_modify_comparison( ).
  object->init( ).

  " Warm-up run to avoid JIT compilation effects
  object->individual_modify( ).
  object->bulk_modify( ).

  " Actual measurement runs
  DO lc_num_of_iterations TIMES.
    object->measure_individual_modify( ).
    object->measure_bulk_modify( ).
  ENDDO.

  object->display_results( ).
  cl_demo_output=>display( ).
ENDFORM.
