*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_006
*&---------------------------------------------------------------------*
*& Secondary Keys Performance Comparison
*&---------------------------------------------------------------------*
*& 二级索引：为内表定义额外的索引键，类似数据库索引
*& 可加速非主键字段的查询操作
*& 特别适用于哈希表和排序表，支持对二级键进行二分查找
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_006.

CLASS lcl_secondary_keys_comparison DEFINITION.
  PUBLIC SECTION.
    " Performance measurement data
    DATA: mv_time_without_secondary TYPE i,
          mv_time_with_secondary    TYPE i.

    " Data structure for testing
    TYPES: BEGIN OF ts_test_data,
             primary_key TYPE i,      " 主键字段
             data_field1 TYPE string, " 数据字段1
             data_field2 TYPE string, " 数据字段2
             secondary_key TYPE i,    " 二级键字段
           END OF ts_test_data.

    " Table with secondary key
    DATA: mt_table_with_secondary TYPE SORTED TABLE OF ts_test_data
          WITH UNIQUE KEY primary_key
          WITH NON-UNIQUE SORTED KEY secondary_key COMPONENTS secondary_key.

    " Table without secondary key (for comparison)
    DATA: mt_table_without_secondary TYPE SORTED TABLE OF ts_test_data
          WITH UNIQUE KEY primary_key.

    " Keys to search for performance testing
    DATA: mt_primary_search_keys TYPE TABLE OF i,
          mt_secondary_search_keys TYPE TABLE OF i.

    METHODS:
      init,
      test_without_secondary_key,
      test_with_secondary_key,
      measure_without_secondary_key,
      measure_with_secondary_key,
      display_results.
ENDCLASS.

CLASS lcl_secondary_keys_comparison IMPLEMENTATION.

  METHOD init.
    " Generate test data with primary and secondary keys
    DATA: lv_counter TYPE i VALUE 1.

    CLEAR: mt_table_with_secondary, mt_table_without_secondary,
           mt_primary_search_keys, mt_secondary_search_keys.

    " Generate 10000 test records
    DO 10000 TIMES.
      " Create data with primary key and secondary key
      " Secondary key is calculated as primary key modulo 100 to create duplicates
      DATA(ls_data) = VALUE ts_test_data(
        primary_key = lv_counter
        data_field1 = |Data1 for key { lv_counter }|
        data_field2 = |Data2 for key { lv_counter }|
        secondary_key = ( lv_counter MOD 100 ) + 1  " Secondary key values from 1 to 100
      ).

      " Add to both tables
      INSERT ls_data INTO TABLE mt_table_with_secondary.
      INSERT ls_data INTO TABLE mt_table_without_secondary.

      lv_counter = lv_counter + 1.
    ENDDO.

    " Generate search keys for performance testing
    " Primary keys: random selection
    DO 500 TIMES.
      DATA(lv_primary_key) = ( sy-index * 20 ) MOD 10000 + 1.
      APPEND lv_primary_key TO mt_primary_search_keys.
    ENDDO.

    " Secondary keys: test all possible secondary key values
    DO 100 TIMES.
      DATA(lv_secondary_key) = sy-index.
      APPEND lv_secondary_key TO mt_secondary_search_keys.
    ENDDO.

    cl_demo_output=>write( |Generated { lines( mt_table_with_secondary ) } test records| ).
    cl_demo_output=>write( |Created { lines( mt_primary_search_keys ) } primary search keys| ).
    cl_demo_output=>write( |Created { lines( mt_secondary_search_keys ) } secondary search keys| ).
    cl_demo_output=>write( 'Secondary key values range from 1 to 100 (with duplicates)' ).
    cl_demo_output=>write( 'Ready to compare secondary keys performance' ).
  ENDMETHOD.

  METHOD test_without_secondary_key.
    " Test performance without secondary key (using linear search for secondary key queries)
    DATA: ls_found_data TYPE ts_test_data,
          lv_found_count TYPE i VALUE 0.

    " Test 1: Primary key access (should be fast for both tables)
    LOOP AT mt_primary_search_keys INTO DATA(lv_primary_key).
      READ TABLE mt_table_without_secondary INTO ls_found_data
        WITH TABLE KEY primary_key = lv_primary_key.

      IF sy-subrc = 0.
        lv_found_count = lv_found_count + 1.
      ENDIF.
    ENDLOOP.

    " Test 2: Secondary key access (linear search - slow)
    LOOP AT mt_secondary_search_keys INTO DATA(lv_secondary_key).
      " Without secondary key, we need to use linear search
      LOOP AT mt_table_without_secondary INTO ls_found_data
        WHERE secondary_key = lv_secondary_key.
        lv_found_count = lv_found_count + 1.
      ENDLOOP.
    ENDLOOP.

    " Just to ensure the method does something meaningful
    IF lv_found_count > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD test_with_secondary_key.
    " Test performance with secondary key (using binary search for secondary key queries)
    DATA: ls_found_data TYPE ts_test_data,
          lv_found_count TYPE i VALUE 0.

    " Test 1: Primary key access (should be fast for both tables)
    LOOP AT mt_primary_search_keys INTO DATA(lv_primary_key).
      READ TABLE mt_table_with_secondary INTO ls_found_data
        WITH TABLE KEY primary_key = lv_primary_key.

      IF sy-subrc = 0.
        lv_found_count = lv_found_count + 1.
      ENDIF.
    ENDLOOP.

    " Test 2: Secondary key access (using secondary key - fast)
    LOOP AT mt_secondary_search_keys INTO DATA(lv_secondary_key).
      " With secondary key, we can use the secondary index directly with TABLE KEY syntax
      READ TABLE mt_table_with_secondary INTO ls_found_data
        WITH TABLE KEY secondary_key
        COMPONENTS secondary_key = lv_secondary_key.

      IF sy-subrc = 0.
        lv_found_count = lv_found_count + 1.
      ENDIF.
    ENDLOOP.

    " Just to ensure the method does something meaningful
    IF lv_found_count > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD measure_without_secondary_key.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    test_without_secondary_key( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_without_secondary = mv_time_without_secondary + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD measure_with_secondary_key.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    test_with_secondary_key( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_with_secondary = mv_time_with_secondary + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD display_results.
    DATA: lv_improvement    TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_factor TYPE p LENGTH 5 DECIMALS 2.

    cl_demo_output=>write( '=== SECONDARY KEYS PERFORMANCE COMPARISON ===' ).
    cl_demo_output=>write( 'Comparison: With Secondary Key vs Without Secondary Key' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'Test includes:' ).
    cl_demo_output=>write( '• 500 primary key lookups (binary search for both)' ).
    cl_demo_output=>write( '• 100 secondary key lookups (secondary index vs linear search)' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).

    " Calculate improvement percentage
    IF mv_time_without_secondary > 0.
      lv_improvement = ( 1 - ( mv_time_with_secondary / mv_time_without_secondary ) ) * 100.
      lv_speedup_factor = mv_time_without_secondary / mv_time_with_secondary.
    ELSE.
      lv_improvement = 0.
      lv_speedup_factor = 1.
    ENDIF.

    cl_demo_output=>write( |Total time WITHOUT SECONDARY KEY: { mv_time_without_secondary } microseconds| ).
    cl_demo_output=>write( |Total time WITH SECONDARY KEY:    { mv_time_with_secondary } microseconds| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( |Performance improvement: { lv_improvement }%| ).
    cl_demo_output=>write( |Speedup factor: { lv_speedup_factor }x| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'SECONDARY KEYS BENEFITS:' ).
    cl_demo_output=>write( '• Accelerates non-primary key field queries' ).
    cl_demo_output=>write( '• Supports binary search on secondary keys' ).
    cl_demo_output=>write( '• Reduces linear search overhead' ).
    cl_demo_output=>write( '• Particularly useful for large datasets' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'USAGE SYNTAX:' ).
    cl_demo_output=>write( '• Define: WITH NON-UNIQUE SORTED KEY key_name COMPONENTS field1, field2' ).
    cl_demo_output=>write( '• Use: READ TABLE itab WITH TABLE KEY key_name COMPONENTS field1 = value' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'RECOMMENDATIONS:' ).
    cl_demo_output=>write( '• Use secondary keys when frequently querying non-primary key fields' ).
    cl_demo_output=>write( '• Consider memory overhead of maintaining additional indexes' ).
    cl_demo_output=>write( '• Balance between query performance and insert/update performance' ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  CONSTANTS: lc_num_of_iterations TYPE i VALUE 25. " Multiple iterations for stable measurement

  DATA(object) = NEW lcl_secondary_keys_comparison( ).
  object->init( ).

  " Warm-up run to avoid JIT compilation effects
  object->test_without_secondary_key( ).
  object->test_with_secondary_key( ).

  " Actual measurement runs
  DO lc_num_of_iterations TIMES.
    object->measure_without_secondary_key( ).
    object->measure_with_secondary_key( ).
  ENDDO.

  object->display_results( ).
  cl_demo_output=>display( ).
ENDFORM.
