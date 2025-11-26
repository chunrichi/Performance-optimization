*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_008
*&---------------------------------------------------------------------*
*& Table Expression Performance Comparison
*& ABAP 7.4+ 表表达式性能对比
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_008.

CLASS lcl_table_expression_comparison DEFINITION.
  PUBLIC SECTION.
    " Performance measurement data
    DATA: mv_time_traditional TYPE i,
          mv_time_expression  TYPE i.

    " Data structure for testing
    TYPES: BEGIN OF ts_test_data,
             carrid    TYPE s_carr_id,   " 航空公司代码
             connid    TYPE s_conn_id,   " 航班连接号
             countryfr TYPE s_countrfr,  " 出发国家
             cityfrom  TYPE s_from_cit,  " 出发城市
           END OF ts_test_data.

    DATA: mt_test_data TYPE SORTED TABLE OF ts_test_data
          WITH UNIQUE KEY carrid connid.

    METHODS:
      init,
      measure_traditional_read,
      measure_table_expression,
      display_results,
      run_comprehensive_tests.
ENDCLASS.

CLASS lcl_table_expression_comparison IMPLEMENTATION.

  METHOD init.
    " 生成测试数据 - 模拟航班数据
    APPEND VALUE #( carrid = 'AA' connid = '0017' countryfr = 'US' cityfrom = 'NEW YORK' ) TO mt_test_data.
    APPEND VALUE #( carrid = 'LH' connid = '0400' countryfr = 'DE' cityfrom = 'FRANKFURT' ) TO mt_test_data.
    APPEND VALUE #( carrid = 'UA' connid = '0351' countryfr = 'US' cityfrom = 'CHICAGO' ) TO mt_test_data.
    APPEND VALUE #( carrid = 'BA' connid = '0174' countryfr = 'GB' cityfrom = 'LONDON' ) TO mt_test_data.
    APPEND VALUE #( carrid = 'AF' connid = '0064' countryfr = 'FR' cityfrom = 'PARIS' ) TO mt_test_data.
    APPEND VALUE #( carrid = 'JL' connid = '0412' countryfr = 'JP' cityfrom = 'TOKYO' ) TO mt_test_data.
    APPEND VALUE #( carrid = 'SQ' connid = '0256' countryfr = 'SG' cityfrom = 'SINGAPORE' ) TO mt_test_data.
    APPEND VALUE #( carrid = 'QF' connid = '0632' countryfr = 'AU' cityfrom = 'SYDNEY' ) TO mt_test_data.

    cl_demo_output=>write( |Generated { lines( mt_test_data ) } test flight records| ).
    cl_demo_output=>write( 'Test data is sorted by carrid and connid' ).
  ENDMETHOD.

  METHOD measure_traditional_read.
    " 传统 READ TABLE 语法性能测试
    DATA: ls_found_data TYPE ts_test_data,
          lv_city       TYPE s_from_cit,
          lv_country    TYPE s_countrfr,
          lv_found      TYPE abap_bool.

    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.

    " 场景1: 读取整行数据
    READ TABLE mt_test_data INTO ls_found_data
      WITH TABLE KEY carrid = 'LH' connid = '0400'.
    IF sy-subrc = 0.
      " 成功读取
    ENDIF.

    " 场景2: 读取特定字段
    READ TABLE mt_test_data INTO ls_found_data
      WITH TABLE KEY carrid = 'AA' connid = '0017'.
    IF sy-subrc = 0.
      lv_city = ls_found_data-cityfrom.
    ENDIF.

    " 场景3: 检查记录是否存在
    READ TABLE mt_test_data TRANSPORTING NO FIELDS
      WITH TABLE KEY carrid = 'UA' connid = '0351'.
    IF sy-subrc = 0.
      lv_found = abap_true.
    ENDIF.

    " 场景4: 处理未找到的情况
    READ TABLE mt_test_data INTO ls_found_data
      WITH TABLE KEY carrid = 'XX' connid = '9999'.
    IF sy-subrc <> 0.
      " 处理未找到的情况
      lv_country = 'NOT_FOUND'.
    ENDIF.

    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_traditional = lv_timestamp_end - lv_timestamp_begin.
  ENDMETHOD.

  METHOD measure_table_expression.
    " 表表达式语法性能测试
    DATA: lv_city    TYPE s_from_cit,
          lv_country TYPE s_countrfr,
          lv_found   TYPE abap_bool.

    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.

    " 场景1: 读取整行数据 (使用 OPTIONAL 避免异常)
    DATA(ls_found_data) = VALUE #( mt_test_data[ carrid = 'LH' connid = '0400' ] OPTIONAL ).

    " 场景2: 直接读取特定字段
    lv_city = VALUE #( mt_test_data[ carrid = 'AA' connid = '0017' ]-cityfrom OPTIONAL ).

    " 场景3: 检查记录是否存在
    lv_found = xsdbool( line_exists( mt_test_data[ carrid = 'UA' connid = '0351' ] ) ).

    " 场景4: 处理未找到的情况 (使用 DEFAULT 提供默认值)
    lv_country = VALUE #( mt_test_data[ carrid = 'XX' connid = '9999' ]-countryfr 
                          DEFAULT 'NOT_FOUND' ).

    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_expression = lv_timestamp_end - lv_timestamp_begin.
  ENDMETHOD.

  METHOD run_comprehensive_tests.
    " 综合测试各种表表达式用法
    cl_demo_output=>write( '=== 表表达式综合用法演示 ===' ).

    " 1. 通过索引读取
    DATA(ls_by_index) = VALUE #( mt_test_data[ 2 ] OPTIONAL ).
    IF ls_by_index IS NOT INITIAL.
      cl_demo_output=>write( |索引读取: { ls_by_index-carrid } { ls_by_index-connid } { ls_by_index-cityfrom }| ).
    ENDIF.

    " 2. 通过关键字段读取整行
    DATA(ls_by_key) = VALUE #( mt_test_data[ carrid = 'SQ' connid = '0256' ] OPTIONAL ).
    IF ls_by_key IS NOT INITIAL.
      cl_demo_output=>write( |关键字段读取: { ls_by_key-carrid } { ls_by_key-connid } { ls_by_key-countryfr }| ).
    ENDIF.

    " 3. 直接读取字段值
    DATA(lv_direct_city) = VALUE #( mt_test_data[ carrid = 'BA' connid = '0174' ]-cityfrom OPTIONAL ).
    cl_demo_output=>write( |直接读取字段: { lv_direct_city }| ).

    " 4. 行存在性检查
    DATA(lv_exists) = xsdbool( line_exists( mt_test_data[ carrid = 'AF' connid = '0064' ] ) ).
    cl_demo_output=>write( |行存在检查: { lv_exists }| ).

    " 5. 获取行索引
    DATA(lv_index) = line_index( mt_test_data[ carrid = 'JL' connid = '0412' ] ).
    cl_demo_output=>write( |行索引: { lv_index }| ).

    " 6. 安全处理 - 使用 DEFAULT
    DATA(ls_default) = VALUE #( mt_test_data[ carrid = 'NOT' connid = 'EXIST' ] 
                                DEFAULT VALUE #( carrid = 'DEFAULT' connid = '0000' 
                                                countryfr = 'DEFAULT' cityfrom = 'DEFAULT_CITY' ) ).
    cl_demo_output=>write( |默认值处理: { ls_default-carrid } { ls_default-connid } { ls_default-cityfrom }| ).

    " 7. 链式表表达式
    DATA(lv_chain_result) = VALUE #( mt_test_data[ 3 ]-countryfr OPTIONAL ).
    cl_demo_output=>write( |链式表达式: { lv_chain_result }| ).
  ENDMETHOD.

  METHOD display_results.
    DATA: lv_improvement    TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_factor TYPE p LENGTH 5 DECIMALS 2.

    cl_demo_output=>write( '=== 表表达式性能对比 ===' ).
    cl_demo_output=>write( '对比: ABAP 7.4+ 表表达式 vs 传统 READ TABLE 语法' ).
    cl_demo_output=>write( '------------------------------------------------' ).

    " 计算性能提升百分比
    IF mv_time_traditional > 0.
      lv_improvement = ( 1 - ( mv_time_expression / mv_time_traditional ) ) * 100.
      lv_speedup_factor = mv_time_traditional / mv_time_expression.
    ELSE.
      lv_improvement = 0.
      lv_speedup_factor = 1.
    ENDIF.

    cl_demo_output=>write( |传统 READ TABLE 语法耗时: { mv_time_traditional } 微秒| ).
    cl_demo_output=>write( |表表达式语法耗时:        { mv_time_expression } 微秒| ).
    cl_demo_output=>write( '------------------------------------------------' ).
    cl_demo_output=>write( |性能提升: { lv_improvement }%| ).
    cl_demo_output=>write( |加速倍数: { lv_speedup_factor }x| ).
    cl_demo_output=>write( '------------------------------------------------' ).

    " 显示性能分析
    IF lv_improvement > 0.
      cl_demo_output=>write( '✓ 表表达式语法性能更优' ).
      cl_demo_output=>write( '✓ 代码更简洁，可读性更好' ).
      cl_demo_output=>write( '✓ 强制错误处理，避免遗漏' ).
    ELSE.
      cl_demo_output=>write( '⚠ 性能差异不明显，但表表达式语法更现代化' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  CONSTANTS: lc_num_of_iterations TYPE i VALUE 50. " 多次迭代以获得稳定测量

  DATA(object) = NEW lcl_table_expression_comparison( ).
  object->init( ).

  " 预热运行以避免JIT编译影响
  object->measure_traditional_read( ).
  object->measure_table_expression( ).

  " 实际测量运行
  DO lc_num_of_iterations TIMES.
    object->measure_traditional_read( ).
    object->measure_table_expression( ).
  ENDDO.

  " 显示综合用法演示
  object->run_comprehensive_tests( ).

  " 显示性能结果
  object->display_results( ).
  cl_demo_output=>display( ).
ENDFORM.
