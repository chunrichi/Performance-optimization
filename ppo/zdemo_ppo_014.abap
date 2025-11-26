*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_014
*&---------------------------------------------------------------------*
*& REF TO vs VALUE PASS Performance Comparison
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_014.

CLASS lcl_ref_to_comparison DEFINITION.
  PUBLIC SECTION.
    " Performance measurement data
    DATA: mv_time_ref_to     TYPE i,
          mv_time_value_pass TYPE i.

    " Large data structure for reference passing test
    TYPES: BEGIN OF ts_large_data,
             id          TYPE i,
             description TYPE string,
             data_array  TYPE TABLE OF string,
             timestamp   TYPE timestampl,
           END OF ts_large_data.

    METHODS:
      test_ref_to,
      test_value_pass,
      display_results.
ENDCLASS.

CLASS lcl_ref_to_comparison IMPLEMENTATION.

  METHOD test_ref_to.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i,
          lv_counter         TYPE i.

    " Create large data structure for testing
    DATA: ls_large_data TYPE ts_large_data.
    ls_large_data-id = 1.
    ls_large_data-description = 'Large data structure for reference passing test'.
    ls_large_data-timestamp = utclong_current( ).
    
    " Fill with some data to make it large
    DO 100 TIMES.
      APPEND |Data element { sy-index } with substantial content to increase memory footprint| TO ls_large_data-data_array.
    ENDDO.

    " Test with REF TO (reference passing - efficient)
    GET RUN TIME FIELD lv_timestamp_begin.
    
    DATA: lr_data_ref TYPE REF TO ts_large_data.
    lv_counter = 0.
    
    " Pass by reference multiple times
    DO 100 TIMES.
      GET REFERENCE OF ls_large_data INTO lr_data_ref.
      PERFORM process_data_by_reference USING lr_data_ref.
      lv_counter = lv_counter + 1.
    ENDDO.
    
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_ref_to = lv_timestamp_end - lv_timestamp_begin.

    cl_demo_output=>write( |REF TO test completed: { lv_counter } iterations| ).
  ENDMETHOD.

  METHOD test_value_pass.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i,
          lv_counter         TYPE i.

    " Create large data structure for testing
    DATA: ls_large_data TYPE ts_large_data.
    ls_large_data-id = 1.
    ls_large_data-description = 'Large data structure for value passing test'.
    ls_large_data-timestamp = utclong_current( ).
    
    " Fill with some data to make it large
    DO 100 TIMES.
      APPEND |Data element { sy-index } with substantial content to increase memory footprint| TO ls_large_data-data_array.
    ENDDO.

    " Test with value passing (inefficient - data copy)
    GET RUN TIME FIELD lv_timestamp_begin.
    
    lv_counter = 0.
    
    " Pass by value multiple times
    DO 100 TIMES.
      PERFORM process_data_by_value USING ls_large_data.
      lv_counter = lv_counter + 1.
    ENDDO.
    
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_value_pass = lv_timestamp_end - lv_timestamp_begin.

    cl_demo_output=>write( |VALUE PASS test completed: { lv_counter } iterations| ).
  ENDMETHOD.

  METHOD display_results.
    DATA: lv_improvement TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup     TYPE p LENGTH 5 DECIMALS 2.

    cl_demo_output=>write( '=== REF TO vs VALUE PASS PERFORMANCE COMPARISON ===' ).
    cl_demo_output=>write( 'Comparison: Reference passing vs Value passing for large data objects' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).

    " Calculate improvement
    IF mv_time_value_pass > 0.
      lv_improvement = ( 1 - ( mv_time_ref_to / mv_time_value_pass ) ) * 100.
      lv_speedup = mv_time_value_pass / mv_time_ref_to.
    ELSE.
      lv_improvement = 0.
      lv_speedup = 1.
    ENDIF.

    cl_demo_output=>write( |Time with REF TO:    { mv_time_ref_to } microseconds| ).
    cl_demo_output=>write( |Time with VALUE PASS: { mv_time_value_pass } microseconds| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( |Performance improvement: { lv_improvement }%| ).
    cl_demo_output=>write( |Speedup factor: { lv_speedup }x| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'TECHNICAL INSIGHTS:' ).
    cl_demo_output=>write( '- REF TO: Passes reference to data, no data copying' ).
    cl_demo_output=>write( '- VALUE PASS: Copies entire data structure for each call' ).
    cl_demo_output=>write( '- Recommendation: Use REF TO for large data objects' ).
    cl_demo_output=>write( '- Memory impact: VALUE PASS can significantly increase memory usage' ).
  ENDMETHOD.

ENDCLASS.

" Helper methods for reference vs value passing test
FORM process_data_by_reference USING pr_data TYPE REF TO ts_large_data.
  " Simulate processing with reference (no data copy)
  IF pr_data IS BOUND.
    pr_data->description = |Processed: { pr_data->description }|.
  ENDIF.
ENDFORM.

FORM process_data_by_value USING ps_data TYPE ts_large_data.
  " Simulate processing with value (data copy occurs)
  DATA(ls_temp) = ps_data.
  ls_temp-description = |Processed: { ls_temp-description }|.
ENDFORM.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  CONSTANTS: lc_num_of_iterations TYPE i VALUE 10.

  DATA(object) = NEW lcl_ref_to_comparison( ).

  " Warm-up run to avoid JIT compilation effects
  object->test_ref_to( ).
  object->test_value_pass( ).

  " Actual measurement runs
  DO lc_num_of_iterations TIMES.
    object->test_ref_to( ).
    object->test_value_pass( ).
  ENDDO.

  object->display_results( ).
  cl_demo_output=>display( ).
ENDFORM.
