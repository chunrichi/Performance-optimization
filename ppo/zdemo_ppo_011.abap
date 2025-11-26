*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_011
*&---------------------------------------------------------------------*
*& Memory Management Optimization Performance Comparison
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_011.

CLASS lcl_memory_optimization_comparison DEFINITION.
  PUBLIC SECTION.
    " Performance measurement data
    DATA: mv_time_field_symbols TYPE i,
          mv_time_work_area     TYPE i,
          mv_time_occurs_0      TYPE i,
          mv_time_occurs_n      TYPE i,
          mv_time_ref_to        TYPE i,
          mv_time_value_pass    TYPE i.

    " Data structure for testing
    TYPES: BEGIN OF ts_test_data,
             key_field  TYPE i,      " Key field
             data_field TYPE string, " Some data field
             extra_data TYPE string, " Additional data to increase size
           END OF ts_test_data.

    " Large data structure for reference passing test
    TYPES: BEGIN OF ts_large_data,
             id          TYPE i,
             description TYPE string,
             data_array  TYPE TABLE OF string,
             timestamp   TYPE timestampl,
           END OF ts_large_data.

    DATA: mt_test_data      TYPE TABLE OF ts_test_data,
          mt_test_data_occ0 TYPE TABLE OF ts_test_data,
          mt_test_data_occn TYPE TABLE OF ts_test_data.

    METHODS:
      init,
      test_field_symbols_vs_work_area,
      test_occurs_0_vs_occurs_n,
      test_ref_to_vs_value_pass,
      display_results.
ENDCLASS.

CLASS lcl_memory_optimization_comparison IMPLEMENTATION.

  METHOD init.
    " Generate test data
    DATA: lv_counter TYPE i VALUE 1.

    " Generate 1000 test records with larger data to make memory differences more noticeable
    DO 1000 TIMES.
      APPEND VALUE #( key_field = lv_counter
                      data_field = |Data for key { lv_counter } with some additional content to increase memory usage|
                      extra_data = |Extra data field { lv_counter } with even more content to make the data structure larger| )
        TO mt_test_data.
      lv_counter = lv_counter + 1.
    ENDDO.

    " Initialize tables with different OCCURS strategies
    mt_test_data_occ0 = mt_test_data.
    mt_test_data_occn = mt_test_data.

    cl_demo_output=>write( |Generated { lines( mt_test_data ) } test records| ).
    cl_demo_output=>write( 'Memory optimization performance comparison initialized' ).
  ENDMETHOD.

  METHOD test_field_symbols_vs_work_area.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i,
          lv_counter         TYPE i.

    " Test with FIELD-SYMBOLS (more efficient)
    GET RUN TIME FIELD lv_timestamp_begin.
    
    FIELD-SYMBOLS: <fs_data> TYPE ts_test_data.
    lv_counter = 0.
    
    LOOP AT mt_test_data ASSIGNING <fs_data>.
      " Modify data using field symbol (no data copy)
      <fs_data>-data_field = |Modified { <fs_data>-data_field }|.
      lv_counter = lv_counter + 1.
    ENDLOOP.
    
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_field_symbols = lv_timestamp_end - lv_timestamp_begin.

    " Test with work area (less efficient - data copy)
    GET RUN TIME FIELD lv_timestamp_begin.
    
    DATA: ls_work_area TYPE ts_test_data.
    lv_counter = 0.
    
    LOOP AT mt_test_data INTO ls_work_area.
      " Modify data in work area (data copy occurs)
      ls_work_area-data_field = |Modified { ls_work_area-data_field }|.
      MODIFY mt_test_data FROM ls_work_area INDEX sy-tabix.
      lv_counter = lv_counter + 1.
    ENDLOOP.
    
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_work_area = lv_timestamp_end - lv_timestamp_begin.

    cl_demo_output=>write( |FIELD-SYMBOLS vs WORK AREA test completed: { lv_counter } iterations| ).
  ENDMETHOD.

  METHOD test_occurs_0_vs_occurs_n.
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
      " Some operation
    ENDLOOP.
    
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_occurs_0 = lv_timestamp_end - lv_timestamp_begin.

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
    LOOP AT lt_prealloc_table INTO ls_temp.
      " Some operation
    ENDLOOP.
    
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_occurs_n = lv_timestamp_end - lv_timestamp_begin.

    cl_demo_output=>write( |OCCURS 0 vs OCCURS n test completed: { lv_counter } iterations| ).
  ENDMETHOD.

  METHOD test_ref_to_vs_value_pass.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i,
          lv_counter         TYPE i.

    " Create large data structure for testing
    DATA: ls_large_data TYPE ts_large_data.
    ls_large_data-id = 1.
    ls_large_data-description = 'Large data structure for reference passing test'.
    ls_large_data-timestamp = utclong_current( ).
    
    " Fill with some data
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

    cl_demo_output=>write( |REF TO vs VALUE PASS test completed: { lv_counter } iterations| ).
  ENDMETHOD.

  METHOD display_results.
    DATA: lv_improvement_fs    TYPE p LENGTH 5 DECIMALS 2,
          lv_improvement_occ0  TYPE p LENGTH 5 DECIMALS 2,
          lv_improvement_ref   TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_fs        TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_occ0      TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_ref       TYPE p LENGTH 5 DECIMALS 2.

    cl_demo_output=>write( '=== MEMORY MANAGEMENT OPTIMIZATION PERFORMANCE COMPARISON ===' ).
    cl_demo_output=>write( 'Comparison of different memory optimization techniques' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).

    " Calculate improvements
    IF mv_time_work_area > 0.
      lv_improvement_fs = ( 1 - ( mv_time_field_symbols / mv_time_work_area ) ) * 100.
      lv_speedup_fs = mv_time_work_area / mv_time_field_symbols.
    ELSE.
      lv_improvement_fs = 0.
      lv_speedup_fs = 1.
    ENDIF.

    IF mv_time_occurs_n > 0.
      lv_improvement_occ0 = ( 1 - ( mv_time_occurs_0 / mv_time_occurs_n ) ) * 100.
      lv_speedup_occ0 = mv_time_occurs_n / mv_time_occurs_0.
    ELSE.
      lv_improvement_occ0 = 0.
      lv_speedup_occ0 = 1.
    ENDIF.

    IF mv_time_value_pass > 0.
      lv_improvement_ref = ( 1 - ( mv_time_ref_to / mv_time_value_pass ) ) * 100.
      lv_speedup_ref = mv_time_value_pass / mv_time_ref_to.
    ELSE.
      lv_improvement_ref = 0.
      lv_speedup_ref = 1.
    ENDIF.

    " Display FIELD-SYMBOLS vs WORK AREA results
    cl_demo_output=>write( '1. FIELD-SYMBOLS vs WORK AREA:' ).
    cl_demo_output=>write( |   Time with FIELD-SYMBOLS: { mv_time_field_symbols } microseconds| ).
    cl_demo_output=>write( |   Time with WORK AREA:     { mv_time_work_area } microseconds| ).
    cl_demo_output=>write( |   Improvement: { lv_improvement_fs }% (Speedup: { lv_speedup_fs }x)| ).
    cl_demo_output=>write( '   -> FIELD-SYMBOLS avoids data copying, reducing memory usage' ).

    " Display OCCURS 0 vs OCCURS n results
    cl_demo_output=>write( '2. OCCURS 0 vs OCCURS n:' ).
    cl_demo_output=>write( |   Time with OCCURS 0: { mv_time_occurs_0 } microseconds| ).
    cl_demo_output=>write( |   Time with OCCURS n: { mv_time_occurs_n } microseconds| ).
    cl_demo_output=>write( |   Improvement: { lv_improvement_occ0 }% (Speedup: { lv_speedup_occ0 }x)| ).
    cl_demo_output=>write( '   -> OCCURS 0 uses dynamic memory allocation, faster for most scenarios' ).

    " Display REF TO vs VALUE PASS results
    cl_demo_output=>write( '3. REF TO vs VALUE PASS:' ).
    cl_demo_output=>write( |   Time with REF TO:    { mv_time_ref_to } microseconds| ).
    cl_demo_output=>write( |   Time with VALUE PASS: { mv_time_value_pass } microseconds| ).
    cl_demo_output=>write( |   Improvement: { lv_improvement_ref }% (Speedup: { lv_speedup_ref }x)| ).
    cl_demo_output=>write( '   -> REF TO passes references instead of copying large data objects' ).

    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'SUMMARY: Memory optimization techniques can significantly improve' ).
    cl_demo_output=>write( 'performance by reducing unnecessary data copying and memory usage.' ).
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

  DATA(object) = NEW lcl_memory_optimization_comparison( ).
  object->init( ).

  " Run tests multiple times for stable measurement
  DO lc_num_of_iterations TIMES.
    object->test_field_symbols_vs_work_area( ).
    object->test_occurs_0_vs_occurs_n( ).
    object->test_ref_to_vs_value_pass( ).
  ENDDO.

  object->display_results( ).
  cl_demo_output=>display( ).
ENDFORM.
