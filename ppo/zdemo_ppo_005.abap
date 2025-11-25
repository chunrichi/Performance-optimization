*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_005
*&---------------------------------------------------------------------*
*& Internal Table Types Performance Comparison
*&---------------------------------------------------------------------*
*& 哈希表：数据量巨大且无重复行，仅需关键字访问时性能最优（查找复杂度O(1)）
*& 排序表：需要数据始终保持排序状态时使用
*& 标准表：数据量小且需要多种访问方式时适用
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_005.

CLASS lcl_table_type_comparison DEFINITION.
  PUBLIC SECTION.
    " Performance measurement data
    DATA: mv_time_standard_table TYPE i,
          mv_time_sorted_table   TYPE i,
          mv_time_hashed_table   TYPE i.

    " Data structure for testing
    TYPES: BEGIN OF ts_test_data,
             key_field  TYPE i,      " Key field for searching
             data_field TYPE string, " Some data field
           END OF ts_test_data.

    " Different table types for comparison
    DATA: mt_standard_table TYPE STANDARD TABLE OF ts_test_data,
          mt_sorted_table   TYPE SORTED TABLE OF ts_test_data WITH UNIQUE KEY key_field,
          mt_hashed_table   TYPE HASHED TABLE OF ts_test_data WITH UNIQUE KEY key_field.

    " Keys to search for performance testing
    DATA: mt_search_keys TYPE TABLE OF i.

    METHODS:
      init,
      test_standard_table,
      test_sorted_table,
      test_hashed_table,
      measure_standard_table,
      measure_sorted_table,
      measure_hashed_table,
      display_results.
ENDCLASS.

CLASS lcl_table_type_comparison IMPLEMENTATION.

  METHOD init.
    " Generate test data with unique keys
    DATA: lv_counter TYPE i VALUE 1.

    CLEAR: mt_standard_table, mt_sorted_table, mt_hashed_table, mt_search_keys.

    " Generate 10000 test records to make performance differences more noticeable
    DO 10000 TIMES.
      DATA(ls_data) = VALUE ts_test_data(
        key_field = lv_counter
        data_field = |Data for key { lv_counter }|
      ).

      " Add to all three table types
      APPEND ls_data TO mt_standard_table.
      INSERT ls_data INTO TABLE mt_sorted_table.
      INSERT ls_data INTO TABLE mt_hashed_table.

      lv_counter = lv_counter + 1.
    ENDDO.

    " Generate search keys for performance testing
    " Use systematic keys to ensure predictable performance
    DO 1000 TIMES.
      DATA(lv_search_key) = ( sy-index * 10 ) MOD 10000 + 1. " Generate keys 10, 20, 30, ..., 9990, 1, 11, etc.
      APPEND lv_search_key TO mt_search_keys.
    ENDDO.

    cl_demo_output=>write( |Generated { lines( mt_standard_table ) } test records| ).
    cl_demo_output=>write( |Created { lines( mt_search_keys ) } random search keys| ).
    cl_demo_output=>write( 'Ready to compare internal table types performance' ).
  ENDMETHOD.

  METHOD test_standard_table.
    " Test standard table performance with READ TABLE
    DATA: ls_found_data TYPE ts_test_data,
          lv_found_count TYPE i VALUE 0.

    " Search for keys in standard table (linear search)
    LOOP AT mt_search_keys INTO DATA(lv_search_key).
      READ TABLE mt_standard_table INTO ls_found_data
        WITH KEY key_field = lv_search_key.

      IF sy-subrc = 0.
        lv_found_count = lv_found_count + 1.
      ENDIF.
    ENDLOOP.

    " Just to ensure the method does something meaningful
    IF lv_found_count > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD test_sorted_table.
    " Test sorted table performance with READ TABLE (binary search)
    DATA: ls_found_data TYPE ts_test_data,
          lv_found_count TYPE i VALUE 0.

    " Search for keys in sorted table (binary search)
    LOOP AT mt_search_keys INTO DATA(lv_search_key).
      READ TABLE mt_sorted_table INTO ls_found_data
        WITH TABLE KEY key_field = lv_search_key.

      IF sy-subrc = 0.
        lv_found_count = lv_found_count + 1.
      ENDIF.
    ENDLOOP.

    " Just to ensure the method does something meaningful
    IF lv_found_count > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD test_hashed_table.
    " Test hashed table performance with READ TABLE (hash access)
    DATA: ls_found_data TYPE ts_test_data,
          lv_found_count TYPE i VALUE 0.

    " Search for keys in hashed table (hash access - O(1) complexity)
    LOOP AT mt_search_keys INTO DATA(lv_search_key).
      READ TABLE mt_hashed_table INTO ls_found_data
        WITH TABLE KEY key_field = lv_search_key.

      IF sy-subrc = 0.
        lv_found_count = lv_found_count + 1.
      ENDIF.
    ENDLOOP.

    " Just to ensure the method does something meaningful
    IF lv_found_count > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD measure_standard_table.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    test_standard_table( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_standard_table = mv_time_standard_table + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD measure_sorted_table.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    test_sorted_table( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_sorted_table = mv_time_sorted_table + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD measure_hashed_table.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    test_hashed_table( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_hashed_table = mv_time_hashed_table + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD display_results.
    DATA: lv_improvement_sorted TYPE p LENGTH 5 DECIMALS 2,
          lv_improvement_hashed TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_sorted     TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_hashed     TYPE p LENGTH 5 DECIMALS 2.

    cl_demo_output=>write( '=== INTERNAL TABLE TYPES PERFORMANCE COMPARISON ===' ).
    cl_demo_output=>write( 'Comparison: STANDARD TABLE vs SORTED TABLE vs HASHED TABLE' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).

    " Calculate improvements compared to standard table
    IF mv_time_standard_table > 0.
      lv_improvement_sorted = ( 1 - ( mv_time_sorted_table / mv_time_standard_table ) ) * 100.
      lv_improvement_hashed = ( 1 - ( mv_time_hashed_table / mv_time_standard_table ) ) * 100.
      lv_speedup_sorted = mv_time_standard_table / mv_time_sorted_table.
      lv_speedup_hashed = mv_time_standard_table / mv_time_hashed_table.
    ELSE.
      lv_improvement_sorted = 0.
      lv_improvement_hashed = 0.
      lv_speedup_sorted = 1.
      lv_speedup_hashed = 1.
    ENDIF.

    cl_demo_output=>write( |Total time with STANDARD TABLE (linear search): { mv_time_standard_table } microseconds| ).
    cl_demo_output=>write( |Total time with SORTED TABLE (binary search):   { mv_time_sorted_table } microseconds| ).
    cl_demo_output=>write( |Total time with HASHED TABLE (hash access):     { mv_time_hashed_table } microseconds| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( |Performance improvement SORTED vs STANDARD: { lv_improvement_sorted }%| ).
    cl_demo_output=>write( |Performance improvement HASHED vs STANDARD: { lv_improvement_hashed }%| ).
    cl_demo_output=>write( |Speedup factor SORTED vs STANDARD: { lv_speedup_sorted }x| ).
    cl_demo_output=>write( |Speedup factor HASHED vs STANDARD: { lv_speedup_hashed }x| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'RECOMMENDATIONS:' ).
    cl_demo_output=>write( '• HASHED TABLE: Use when data volume is large, no duplicate keys,' ).
    cl_demo_output=>write( '  and only key-based access is needed (O(1) lookup complexity)' ).
    cl_demo_output=>write( '• SORTED TABLE: Use when data needs to remain sorted and' ).
    cl_demo_output=>write( '  frequent key-based access is required (O(log n) complexity)' ).
    cl_demo_output=>write( '• STANDARD TABLE: Use for small datasets or when multiple' ).
    cl_demo_output=>write( '  access patterns are needed (index, key, etc.)' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'NOTE: This test focuses on READ TABLE performance.' ).
    cl_demo_output=>write( 'Consider INSERT/DELETE/MODIFY performance for complete evaluation.' ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  CONSTANTS: lc_num_of_iterations TYPE i VALUE 30. " Multiple iterations for stable measurement

  DATA(object) = NEW lcl_table_type_comparison( ).
  object->init( ).

  " Warm-up run to avoid JIT compilation effects
  object->test_standard_table( ).
  object->test_sorted_table( ).
  object->test_hashed_table( ).

  " Actual measurement runs
  DO lc_num_of_iterations TIMES.
    object->measure_standard_table( ).
    object->measure_sorted_table( ).
    object->measure_hashed_table( ).
  ENDDO.

  object->display_results( ).
  cl_demo_output=>display( ).
ENDFORM.
