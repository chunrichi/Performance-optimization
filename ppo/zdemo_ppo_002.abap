*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_002
*&---------------------------------------------------------------------*
*& APPEND LINES OF vs Individual APPEND Performance Comparison
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_002.

CLASS lcl_append_comparison DEFINITION.
  PUBLIC SECTION.
    " Performance measurement data
    DATA: mv_time_individual_append TYPE i,
          mv_time_lines_of_append   TYPE i.

    " Data structure for testing
    TYPES: BEGIN OF ts_test_data,
             key_field  TYPE i,      " Key field
             data_field TYPE string, " Some data field
           END OF ts_test_data.

    DATA: mt_source_data        TYPE TABLE OF ts_test_data, " Source table
          mt_target_individual  TYPE TABLE OF ts_test_data, " Target for individual append
          mt_target_lines_of    TYPE TABLE OF ts_test_data. " Target for lines of append

    METHODS:
      init,
      individual_append,
      lines_of_append,
      measure_individual_append,
      measure_lines_of_append,
      display_results.
ENDCLASS.

CLASS lcl_append_comparison IMPLEMENTATION.

  METHOD init.
    " Generate source test data
    DATA: lv_counter TYPE i VALUE 1.

    CLEAR: mt_source_data.

    DO 1000 TIMES.  " Create 1000 test records in source table
      APPEND VALUE #( key_field = lv_counter
                      data_field = |Data for key { lv_counter }| ) TO mt_source_data.
      lv_counter = lv_counter + 1.
    ENDDO.

    cl_demo_output=>write( |Generated { lines( mt_source_data ) } source records| ).
    cl_demo_output=>write( 'Ready to compare APPEND methods from source to target tables' ).
  ENDMETHOD.

  METHOD individual_append.
    " Copy from source table to target using individual APPEND statements
    DATA: ls_line TYPE ts_test_data.

    CLEAR: mt_target_individual.

    " Copy each line individually from source to target
    LOOP AT mt_source_data INTO ls_line.
      APPEND ls_line TO mt_target_individual.
    ENDLOOP.

    " Just to ensure the method does something meaningful
    IF lines( mt_target_individual ) > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD lines_of_append.
    " Copy from source table to target using APPEND LINES OF
    CLEAR: mt_target_lines_of.

    " Copy all lines at once from source to target
    APPEND LINES OF mt_source_data TO mt_target_lines_of.

    " Just to ensure the method does something meaningful
    IF lines( mt_target_lines_of ) > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD measure_individual_append.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    individual_append( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_individual_append = mv_time_individual_append + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD measure_lines_of_append.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    lines_of_append( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_lines_of_append = mv_time_lines_of_append + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD display_results.
    DATA: lv_improvement    TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_factor TYPE p LENGTH 5 DECIMALS 2.

    cl_demo_output=>write( '=== APPEND METHODS PERFORMANCE COMPARISON ===' ).
    cl_demo_output=>write( 'Comparison: APPEND LINES OF vs Individual APPEND statements' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).

    " Calculate improvement percentage
    IF mv_time_individual_append > 0.
      lv_improvement = ( 1 - ( mv_time_lines_of_append / mv_time_individual_append ) ) * 100.
      lv_speedup_factor = mv_time_individual_append / mv_time_lines_of_append.
    ELSE.
      lv_improvement = 0.
      lv_speedup_factor = 1.
    ENDIF.

    cl_demo_output=>write( |Total time with INDIVIDUAL APPEND (LOOP AT...APPEND): { mv_time_individual_append } microseconds| ).
    cl_demo_output=>write( |Total time with APPEND LINES OF:                      { mv_time_lines_of_append } microseconds| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( |Performance improvement: { lv_improvement }%| ).
    cl_demo_output=>write( |Speedup factor: { lv_speedup_factor }x| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'Note: APPEND LINES OF is generally faster as it performs' ).
    cl_demo_output=>write( 'a single bulk operation instead of multiple individual appends.' ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  CONSTANTS: lc_num_of_iterations TYPE i VALUE 50. " More iterations for stable measurement

  DATA(object) = NEW lcl_append_comparison( ).
  object->init( ).

  " Warm-up run to avoid JIT compilation effects
  object->individual_append( ).
  object->lines_of_append( ).

  " Actual measurement runs
  DO lc_num_of_iterations TIMES.
    object->measure_individual_append( ).
    object->measure_lines_of_append( ).
  ENDDO.

  object->display_results( ).
  cl_demo_output=>display( ).
ENDFORM.
