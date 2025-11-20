*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_004
*&---------------------------------------------------------------------*
*& DELETE itab WHERE condition vs Individual DELETE Performance Comparison
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_004.

CLASS lcl_delete_comparison DEFINITION.
  PUBLIC SECTION.
    " Performance measurement data
    DATA: mv_time_individual_delete TYPE i,
          mv_time_bulk_delete       TYPE i.

    " Data structure for testing
    TYPES: BEGIN OF ts_test_data,
             key_field  TYPE i,      " Key field
             data_field TYPE string, " Some data field
           END OF ts_test_data.

    DATA: mt_source_data        TYPE TABLE OF ts_test_data, " Source data for copying
          mt_test_individual    TYPE TABLE OF ts_test_data, " For individual DELETE
          mt_test_bulk          TYPE TABLE OF ts_test_data, " For bulk DELETE
          mt_keys_to_delete     TYPE TABLE OF ts_test_data. " Keys to delete

    METHODS:
      init,
      individual_delete,
      bulk_delete,
      measure_individual_delete,
      measure_bulk_delete,
      display_results.
ENDCLASS.

CLASS lcl_delete_comparison IMPLEMENTATION.

  METHOD init.
    " Generate source test data and keys to delete
    DATA: lv_counter TYPE i VALUE 1.

    CLEAR: mt_source_data, mt_keys_to_delete.

    " Generate 1000 test records
    DO 1000 TIMES.
      APPEND VALUE #( key_field = lv_counter
                      data_field = |Data for key { lv_counter }| ) TO mt_source_data.
      lv_counter = lv_counter + 1.
    ENDDO.

    " Generate keys to delete (every 2nd record from 500 to 900)
    lv_counter = 500.
    WHILE lv_counter <= 900.
      APPEND VALUE #( key_field = lv_counter ) TO mt_keys_to_delete.
      lv_counter = lv_counter + 2.
    ENDWHILE.

    cl_demo_output=>write( |Generated { lines( mt_source_data ) } source records| ).
    cl_demo_output=>write( |Will delete { lines( mt_keys_to_delete ) } records for comparison| ).
    cl_demo_output=>write( 'Ready to compare DELETE methods: bulk vs individual' ).
  ENDMETHOD.

  METHOD individual_delete.
    " Delete records using individual DELETE statements in loop
    DATA: ls_key TYPE ts_test_data.

    " Copy source data to working table
    mt_test_individual = mt_source_data.

    " Delete records one by one using LOOP AT...DELETE
    LOOP AT mt_keys_to_delete INTO ls_key.
      DELETE mt_test_individual WHERE key_field = ls_key-key_field.
    ENDLOOP.

    " Just to ensure the method does something meaningful
    IF lines( mt_test_individual ) > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD bulk_delete.
    " Delete records using DELETE itab WHERE condition (bulk operation)
    DATA: lt_keys_to_delete TYPE TABLE OF ts_test_data.

    " Copy source data to working table
    mt_test_bulk = mt_source_data.

    " Delete records using bulk DELETE WHERE condition
    " Create a range table for the keys to delete
    DATA: lt_key_range TYPE RANGE OF i.
    
    LOOP AT mt_keys_to_delete INTO DATA(ls_key).
      APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_key-key_field ) TO lt_key_range.
    ENDLOOP.
    
    " Perform bulk delete using WHERE condition with range
    DELETE mt_test_bulk WHERE key_field IN lt_key_range.

    " Just to ensure the method does something meaningful
    IF lines( mt_test_bulk ) > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD measure_individual_delete.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    individual_delete( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_individual_delete = mv_time_individual_delete + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD measure_bulk_delete.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    bulk_delete( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_bulk_delete = mv_time_bulk_delete + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD display_results.
    DATA: lv_improvement    TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_factor TYPE p LENGTH 5 DECIMALS 2.

    cl_demo_output=>write( '=== DELETE METHODS PERFORMANCE COMPARISON ===' ).
    cl_demo_output=>write( 'Comparison: DELETE itab WHERE condition vs Individual DELETE statements' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).

    " Calculate improvement percentage
    IF mv_time_individual_delete > 0.
      lv_improvement = ( 1 - ( mv_time_bulk_delete / mv_time_individual_delete ) ) * 100.
      lv_speedup_factor = mv_time_individual_delete / mv_time_bulk_delete.
    ELSE.
      lv_improvement = 0.
      lv_speedup_factor = 1.
    ENDIF.

    cl_demo_output=>write( |Total time with INDIVIDUAL DELETE (LOOP AT...DELETE): { mv_time_individual_delete } microseconds| ).
    cl_demo_output=>write( |Total time with BULK DELETE (DELETE WHERE condition): { mv_time_bulk_delete } microseconds| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( |Performance improvement: { lv_improvement }%| ).
    cl_demo_output=>write( |Speedup factor: { lv_speedup_factor }x| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'Note: DELETE itab WHERE condition is generally faster as it performs' ).
    cl_demo_output=>write( 'a single bulk operation instead of multiple individual deletes.' ).
    cl_demo_output=>write( 'This is especially beneficial when deleting many records from a large table.' ).
    cl_demo_output=>write( 'The performance gain increases with the number of records to delete.' ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  CONSTANTS: lc_num_of_iterations TYPE i VALUE 50. " More iterations for stable measurement

  DATA(object) = NEW lcl_delete_comparison( ).
  object->init( ).

  " Warm-up run to avoid JIT compilation effects
  object->individual_delete( ).
  object->bulk_delete( ).

  " Actual measurement runs
  DO lc_num_of_iterations TIMES.
    object->measure_individual_delete( ).
    object->measure_bulk_delete( ).
  ENDDO.

  object->display_results( ).
  cl_demo_output=>display( ).
ENDFORM.
