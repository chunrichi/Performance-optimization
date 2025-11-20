*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_001
*&---------------------------------------------------------------------*
*& Binary Search vs Linear Search Performance Comparison
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_001.

CLASS lcl_binary_search_comparison DEFINITION.
  PUBLIC SECTION.
    " Performance measurement data
    DATA: mv_time_without_binary TYPE i,
          mv_time_with_binary    TYPE i.

    " Data structure for testing
    TYPES: BEGIN OF ts_test_data,
             key_field  TYPE i,      " Key field for searching
             data_field TYPE string, " Some data field
           END OF ts_test_data.

    DATA: mt_test_data TYPE TABLE OF ts_test_data.

    METHODS:
      init,
      before,
      after,
      measure_before,
      measure_after,
      display_results.
ENDCLASS.

CLASS lcl_binary_search_comparison IMPLEMENTATION.

  METHOD init.
    " Generate test data with sorted keys for binary search
    DATA: lv_counter TYPE i VALUE 1.

    DO 1000 TIMES.  " Create 1000 test records
      APPEND VALUE #( key_field = lv_counter
                      data_field = |Data for key { lv_counter }| ) TO mt_test_data.
      lv_counter = lv_counter + 1.
    ENDDO.

    cl_demo_output=>write( |Generated { lines( mt_test_data ) } test records| ).
    cl_demo_output=>write( 'Test data is sorted by key_field for binary search' ).
  ENDMETHOD.

  METHOD before.
    " Read table without binary search (linear search)
    DATA: ls_found_data  TYPE ts_test_data,
          lv_found_count TYPE i VALUE 0.

    " Search for 100 random keys using linear search
    DO 100 TIMES.
      DATA(lv_search_key) = sy-index * 10.  " Search for keys 10, 20, 30, ..., 1000

      READ TABLE mt_test_data INTO ls_found_data
        WITH KEY key_field = lv_search_key.

      IF sy-subrc = 0.
        lv_found_count = lv_found_count + 1.
      ENDIF.
    ENDDO.

    " Just to ensure the method does something meaningful
    IF lv_found_count > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD after.
    " Read table with binary search
    DATA: ls_found_data  TYPE ts_test_data,
          lv_found_count TYPE i VALUE 0.

    " Search for 100 random keys using binary search
    DO 100 TIMES.
      DATA(lv_search_key) = sy-index * 10.  " Search for keys 10, 20, 30, ..., 1000

      READ TABLE mt_test_data INTO ls_found_data
        WITH KEY key_field = lv_search_key
        BINARY SEARCH.

      IF sy-subrc = 0.
        lv_found_count = lv_found_count + 1.
      ENDIF.
    ENDDO.

    " Just to ensure the method does something meaningful
    IF lv_found_count > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD measure_before.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    before( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_without_binary = mv_time_without_binary + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD measure_after.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    after( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_with_binary = mv_time_with_binary + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD display_results.
    DATA: lv_improvement    TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_factor TYPE p LENGTH 5 DECIMALS 2.

    cl_demo_output=>write( '=== BINARY SEARCH PERFORMANCE COMPARISON ===' ).
    cl_demo_output=>write( 'Comparison: READ TABLE with BINARY SEARCH vs without BINARY SEARCH' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).

    " Calculate improvement percentage
    IF mv_time_without_binary > 0.
      lv_improvement = ( 1 - ( mv_time_with_binary / mv_time_without_binary ) ) * 100.
      lv_speedup_factor = mv_time_without_binary / mv_time_with_binary.
    ELSE.
      lv_improvement = 0.
      lv_speedup_factor = 1.
    ENDIF.

    cl_demo_output=>write( |Total time WITHOUT BINARY SEARCH: { mv_time_without_binary } microseconds| ).
    cl_demo_output=>write( |Total time WITH BINARY SEARCH:    { mv_time_with_binary } microseconds| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( |Performance improvement: { lv_improvement }%| ).
    cl_demo_output=>write( |Speedup factor: { lv_speedup_factor }x| ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  CONSTANTS: lc_num_of_iterations TYPE i VALUE 20. " More iterations for stable measurement

  DATA(object) = NEW lcl_binary_search_comparison( ).
  object->init( ).

  " Warm-up run to avoid JIT compilation effects
  object->before( ).
  object->after( ).

  " Actual measurement runs
  DO lc_num_of_iterations TIMES.
    object->measure_before( ).
    object->measure_after( ).
  ENDDO.

  object->display_results( ).
  cl_demo_output=>display( ).
ENDFORM.
