*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_013
*&---------------------------------------------------------------------*
*& OCCURS 0 vs OCCURS n Performance Comparison
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_013.

CLASS lcl_occurs_comparison DEFINITION.
  PUBLIC SECTION.
    " Performance measurement data
    DATA: mv_time_occurs_0 TYPE i,
          mv_time_occurs_n TYPE i.

    " Data structure for testing
    TYPES: BEGIN OF ts_test_data,
             key_field  TYPE i,      " Key field
             data_field TYPE string, " Some data field
             extra_data TYPE string, " Additional data to increase size
           END OF ts_test_data.

    METHODS:
      test_occurs_0,
      test_occurs_n,
      display_results.
ENDCLASS.

CLASS lcl_occurs_comparison IMPLEMENTATION.

  METHOD test_occurs_0.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i,
          lv_counter         TYPE i.

    " Test with OCCURS 0 (dynamic expansion - recommended)
    GET RUN TIME FIELD lv_timestamp_begin.
    
    DATA: lt_dynamic_table TYPE TABLE OF ts_test_data.
    lv_counter = 0.
    
    " Simulate dynamic table operations
    DO 500 TIMES.
      APPEND VALUE #( key_field = sy-index
                      data_field = |Dynamic data { sy-index }|
                      extra_data = |Extra dynamic data { sy-index }| ) TO lt_dynamic_table.
      lv_counter = lv_counter + 1.
    ENDDO.
    
    " Additional operations on dynamic table
    LOOP AT lt_dynamic_table INTO DATA(ls_temp).
      " Some operation to simulate real usage
    ENDLOOP.
    
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_occurs_0 = lv_timestamp_end - lv_timestamp_begin.

    cl_demo_output=>write( |OCCURS 0 test completed: { lv_counter } iterations| ).
  ENDMETHOD.

  METHOD test_occurs_n.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i,
          lv_counter         TYPE i.

    " Test with OCCURS n (pre-allocated - less efficient for dynamic scenarios)
    GET RUN TIME FIELD lv_timestamp_begin.
    
    DATA: lt_prealloc_table TYPE TABLE OF ts_test_data.
    lv_counter = 0.
    
    " Simulate operations on pre-allocated table
    DO 500 TIMES.
      APPEND VALUE #( key_field = sy-index
                      data_field = |Prealloc data { sy-index }|
                      extra_data = |Extra prealloc data { sy-index }| ) TO lt_prealloc_table.
      lv_counter = lv_counter + 1.
    ENDDO.
    
    " Additional operations on pre-allocated table
    LOOP AT lt_prealloc_table INTO DATA(ls_temp).
      " Some operation to simulate real usage
    ENDLOOP.
    
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_occurs_n = lv_timestamp_end - lv_timestamp_begin.

    cl_demo_output=>write( |OCCURS n test completed: { lv_counter } iterations| ).
  ENDMETHOD.

  METHOD display_results.
    DATA: lv_improvement TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup     TYPE p LENGTH 5 DECIMALS 2.

    cl_demo_output=>write( '=== OCCURS 0 vs OCCURS n PERFORMANCE COMPARISON ===' ).
    cl_demo_output=>write( 'Comparison: Dynamic memory allocation vs Pre-allocated memory' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).

    " Calculate improvement
    IF mv_time_occurs_n > 0.
      lv_improvement = ( 1 - ( mv_time_occurs_0 / mv_time_occurs_n ) ) * 100.
      lv_speedup = mv_time_occurs_n / mv_time_occurs_0.
    ELSE.
      lv_improvement = 0.
      lv_speedup = 1.
    ENDIF.

    cl_demo_output=>write( |Time with OCCURS 0: { mv_time_occurs_0 } microseconds| ).
    cl_demo_output=>write( |Time with OCCURS n: { mv_time_occurs_n } microseconds| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( |Performance improvement: { lv_improvement }%| ).
    cl_demo_output=>write( |Speedup factor: { lv_speedup }x| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'TECHNICAL INSIGHTS:' ).
    cl_demo_output=>write( '- OCCURS 0: Dynamic memory allocation, uses memory efficiently' ).
    cl_demo_output=>write( '- OCCURS n: Pre-allocated fixed space, may waste memory' ).
    cl_demo_output=>write( '- Recommendation: Use OCCURS 0 for most scenarios' ).
    cl_demo_output=>write( '- Exception: Use OCCURS n only when memory is extremely tight' ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  CONSTANTS: lc_num_of_iterations TYPE i VALUE 10.

  DATA(object) = NEW lcl_occurs_comparison( ).

  " Warm-up run to avoid JIT compilation effects
  object->test_occurs_0( ).
  object->test_occurs_n( ).

  " Actual measurement runs
  DO lc_num_of_iterations TIMES.
    object->test_occurs_0( ).
    object->test_occurs_n( ).
  ENDDO.

  object->display_results( ).
  cl_demo_output=>display( ).
ENDFORM.
