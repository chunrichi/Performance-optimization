*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_009
*&---------------------------------------------------------------------*
*& Advanced Table Expression Performance
*& 高级表表达式性能优化示例
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_009.

CLASS lcl_advanced_expression_comparison DEFINITION.
  PUBLIC SECTION.
    " Performance measurement data
    DATA: mv_time_standard    TYPE i,
          mv_time_binary      TYPE i,
          mv_time_expression  TYPE i.

    " Data structure for large dataset testing
    TYPES: BEGIN OF ts_large_data,
             id        TYPE i,        " 唯一标识符
             category  TYPE string,   " 分类
             value     TYPE string,   " 数值
             timestamp TYPE timestampl, " 时间戳
           END OF ts_large_data.

    DATA: mt_large_data TYPE STANDARD TABLE OF ts_large_data,
          mt_sorted_data TYPE SORTED TABLE OF ts_large_data
                         WITH UNIQUE KEY id.

    METHODS:
      init_large_dataset,
      measure_standard_search,
      measure_binary_search,
      measure_expression_search,
      run_advanced_scenarios,
      display_comparison_results.
ENDCLASS.

CLASS lcl_advanced_expression_comparison IMPLEMENTATION.

  METHOD init_large_dataset.
    " 生成大型测试数据集 (10000条记录)
    DATA: lv_start_time TYPE timestampl.

    GET TIME STAMP FIELD lv_start_time.

    DO 10000 TIMES.
      DATA(lv_id) = sy-index.
      DATA(lv_category) = SWITCH string( lv_id MOD 10
        WHEN 0 THEN 'CATEGORY_A'
        WHEN 1 THEN 'CATEGORY_B'
        WHEN 2 THEN 'CATEGORY_C'
        WHEN 3 THEN 'CATEGORY_D'
        WHEN 4 THEN 'CATEGORY_E'
        WHEN 5 THEN 'CATEGORY_F'
        WHEN 6 THEN 'CATEGORY_G'
        WHEN 7 THEN 'CATEGORY_H'
        WHEN 8 THEN 'CATEGORY_I'
        ELSE 'CATEGORY_J' ).

      APPEND VALUE #(
        id        = lv_id
        category  = lv_category
        value     = |Value_{ lv_id }|
        timestamp = lv_start_time
      ) TO mt_large_data.
    ENDDO.

    " 创建排序版本用于二进制搜索
    mt_sorted_data = mt_large_data.
    SORT mt_sorted_data BY id.

    cl_demo_output=>write( |Generated { lines( mt_large_data ) } test records| ).
    cl_demo_output=>write( 'Dataset includes both standard and sorted tables' ).
  ENDMETHOD.

  METHOD measure_standard_search.
    " 标准线性搜索性能测试
    DATA: ls_found TYPE ts_large_data,
          lv_count TYPE i.

    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.

    " 搜索100个随机ID
    DO 100 TIMES.
      DATA(lv_search_id) = ( sy-index * 100 ) MOD 10000 + 1.

      " 传统 READ TABLE 线性搜索
      READ TABLE mt_large_data INTO ls_found
        WITH KEY id = lv_search_id.

      IF sy-subrc = 0.
        lv_count = lv_count + 1.
      ENDIF.
    ENDDO.

    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_standard = lv_timestamp_end - lv_timestamp_begin.
  ENDMETHOD.

  METHOD measure_binary_search.
    " 二进制搜索性能测试
    DATA: ls_found TYPE ts_large_data,
          lv_count TYPE i.

    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.

    " 搜索100个随机ID
    DO 100 TIMES.
      DATA(lv_search_id) = ( sy-index * 100 ) MOD 10000 + 1.

      " 传统 READ TABLE 二进制搜索
      READ TABLE mt_sorted_data INTO ls_found
        WITH KEY id = lv_search_id
        BINARY SEARCH.

      IF sy-subrc = 0.
        lv_count = lv_count + 1.
      ENDIF.
    ENDDO.

    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_binary = lv_timestamp_end - lv_timestamp_begin.
  ENDMETHOD.

  METHOD measure_expression_search.
    " 表表达式搜索性能测试
    DATA: lv_count TYPE i.

    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.

    " 搜索100个随机ID - 使用表表达式
    DO 100 TIMES.
      DATA(lv_search_id) = ( sy-index * 100 ) MOD 10000 + 1.

      " 表表达式搜索 (在排序表上)
      DATA(ls_found) = VALUE #( mt_sorted_data[ id = lv_search_id ] OPTIONAL ).

      IF ls_found IS NOT INITIAL.
        lv_count = lv_count + 1.
      ENDIF.
    ENDDO.

    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_expression = lv_timestamp_end - lv_timestamp_begin.
  ENDMETHOD.

  METHOD run_advanced_scenarios.
    " 高级表表达式场景演示
    cl_demo_output=>write( '=== 高级表表达式场景演示 ===' ).

    " 1. 多条件表表达式
    DATA(ls_multi_condition) = VALUE #( 
      mt_sorted_data[ id = 5000 category = 'CATEGORY_E' ] OPTIONAL ).
    IF ls_multi_condition IS NOT INITIAL.
      cl_demo_output=>write( |多条件查询: ID={ ls_multi_condition-id }, Category={ ls_multi_condition-category }| ).
    ENDIF.

    " 2. 表表达式在条件语句中的使用
    IF line_exists( mt_sorted_data[ id = 7500 ] ).
      cl_demo_output=>write( '条件检查: ID 7500 存在' ).
    ELSE.
      cl_demo_output=>write( '条件检查: ID 7500 不存在' ).
    ENDIF.

    " 3. 表表达式与 VALUE 构造器的结合
    DATA(lt_filtered) = VALUE ts_large_data_tab(
      FOR wa IN mt_sorted_data WHERE ( category = 'CATEGORY_A' )
      ( wa ) ).
    cl_demo_output=>write( |过滤结果: 找到 { lines( lt_filtered ) } 条 CATEGORY_A 记录| ).

    " 4. 表表达式在循环中的优化使用
    DATA: lv_total_value TYPE string.
    LOOP AT mt_sorted_data ASSIGNING FIELD-SYMBOL(<fs_data>)
                          FROM 1 TO 10.
      " 传统方式需要额外变量
      DATA(ls_current) = VALUE #( mt_sorted_data[ id = <fs_data>-id ] OPTIONAL ).
      IF ls_current IS NOT INITIAL.
        lv_total_value = |{ lv_total_value }{ ls_current-value }|.
      ENDIF.
    ENDLOOP.
    cl_demo_output=>write( |循环优化: 处理前10条记录| ).

    " 5. 表表达式与异常处理
    TRY.
        DATA(ls_risky) = mt_sorted_data[ id = 99999 ]. " 不存在的ID
        cl_demo_output=>write( '异常处理: 记录找到' ).
      CATCH cx_sy_itab_line_not_found.
        cl_demo_output=>write( '异常处理: 记录未找到，已捕获异常' ).
    ENDTRY.

    " 6. 表表达式性能优化技巧
    " 使用 OPTIONAL 避免异常处理开销
    DATA(ls_safe) = VALUE #( mt_sorted_data[ id = 88888 ] OPTIONAL ).
    IF ls_safe IS INITIAL.
      cl_demo_output=>write( '安全访问: 使用 OPTIONAL 避免异常' ).
    ENDIF.

    " 7. 表表达式与 REDUCE 的结合
    DATA(lv_max_id) = REDUCE i( 
      INIT max = 0
      FOR wa IN mt_sorted_data
      NEXT max = COND #( WHEN wa-id > max THEN wa-id ELSE max ) ).
    cl_demo_output=>write( |REDUCE 结合: 最大ID = { lv_max_id }| ).
  ENDMETHOD.

  METHOD display_comparison_results.
    DATA: lv_improvement_binary   TYPE p LENGTH 5 DECIMALS 2,
          lv_improvement_expr     TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_binary       TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_expr         TYPE p LENGTH 5 DECIMALS 2.

    cl_demo_output=>write( '=== 高级表表达式性能对比 ===' ).
    cl_demo_output=>write( '对比: 线性搜索 vs 二进制搜索 vs 表表达式' ).
    cl_demo_output=>write( '数据集: 10000条记录，搜索100次' ).
    cl_demo_output=>write( '------------------------------------------------' ).

    " 计算性能提升百分比
    IF mv_time_standard > 0.
      lv_improvement_binary = ( 1 - ( mv_time_binary / mv_time_standard ) ) * 100.
      lv_improvement_expr = ( 1 - ( mv_time_expression / mv_time_standard ) ) * 100.
      lv_speedup_binary = mv_time_standard / mv_time_binary.
      lv_speedup_expr = mv_time_standard / mv_time_expression.
    ELSE.
      lv_improvement_binary = 0.
      lv_improvement_expr = 0.
      lv_speedup_binary = 1.
      lv_speedup_expr = 1.
    ENDIF.

    cl_demo_output=>write( |线性搜索耗时:    { mv_time_standard } 微秒| ).
    cl_demo_output=>write( |二进制搜索耗时:  { mv_time_binary } 微秒| ).
    cl_demo_output=>write( |表表达式耗时:    { mv_time_expression } 微秒| ).
    cl_demo_output=>write( '------------------------------------------------' ).
    cl_demo_output=>write( |二进制搜索提升:  { lv_improvement_binary }% (加速 { lv_speedup_binary }x)| ).
    cl_demo_output=>write( |表表达式提升:    { lv_improvement_expr }% (加速 { lv_speedup_expr }x)| ).
    cl_demo_output=>write( '------------------------------------------------' ).

    " 性能分析总结
    cl_demo_output=>write( '性能分析总结:' ).
    cl_demo_output=>write( '✓ 二进制搜索在大数据集上性能最优' ).
    cl_demo_output=>write( '✓ 表表达式语法简洁，性能接近二进制搜索' ).
    cl_demo_output=>write( '✓ 表表达式代码可读性更好，维护成本低' ).
    cl_demo_output=>write( '✓ 推荐在排序表上使用表表达式获得最佳性能' ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  CONSTANTS: lc_num_of_iterations TYPE i VALUE 30.

  DATA(object) = NEW lcl_advanced_expression_comparison( ).
  object->init_large_dataset( ).

  " 预热运行
  object->measure_standard_search( ).
  object->measure_binary_search( ).
  object->measure_expression_search( ).

  " 实际测量运行
  DO lc_num_of_iterations TIMES.
    object->measure_standard_search( ).
    object->measure_binary_search( ).
    object->measure_expression_search( ).
  ENDDO.

  " 显示高级场景演示
  object->run_advanced_scenarios( ).

  " 显示性能对比结果
  object->display_comparison_results( ).
  cl_demo_output=>display( ).
ENDFORM.
