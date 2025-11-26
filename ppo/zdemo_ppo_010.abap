*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_010
*&---------------------------------------------------------------------*
*& Real-World Table Expression Applications
*& 实际业务场景中的表表达式应用
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_010.

CLASS lcl_real_world_applications DEFINITION.
  PUBLIC SECTION.
    " 业务数据结构
    TYPES: BEGIN OF ts_customer,
             customer_id TYPE string,    " 客户ID
             name        TYPE string,    " 客户名称
             city        TYPE string,    " 城市
             country     TYPE string,    " 国家
             credit_limit TYPE p DECIMALS 2, " 信用额度
           END OF ts_customer.

    TYPES: BEGIN OF ts_order,
             order_id    TYPE string,    " 订单ID
             customer_id TYPE string,    " 客户ID
             order_date  TYPE d,         " 订单日期
             amount      TYPE p DECIMALS 2, " 订单金额
             status      TYPE string,    " 订单状态
           END OF ts_order.

    TYPES: BEGIN OF ts_product,
             product_id  TYPE string,    " 产品ID
             name        TYPE string,    " 产品名称
             category    TYPE string,    " 产品类别
             price       TYPE p DECIMALS 2, " 产品价格
             stock       TYPE i,         " 库存数量
           END OF ts_product.

    DATA: mt_customers TYPE SORTED TABLE OF ts_customer
                       WITH UNIQUE KEY customer_id,
          mt_orders    TYPE SORTED TABLE OF ts_order
                       WITH UNIQUE KEY order_id,
          mt_products  TYPE SORTED TABLE OF ts_product
                       WITH UNIQUE KEY product_id.

    METHODS:
      init_business_data,
      demonstrate_customer_operations,
      demonstrate_order_processing,
      demonstrate_product_management,
      run_performance_comparison,
      display_business_insights.
ENDCLASS.

CLASS lcl_real_world_applications IMPLEMENTATION.

  METHOD init_business_data.
    " 初始化业务测试数据

    " 客户数据
    APPEND VALUE #( customer_id = 'CUST001' name = '张三' city = '北京' country = '中国' credit_limit = 100000.00 ) TO mt_customers.
    APPEND VALUE #( customer_id = 'CUST002' name = '李四' city = '上海' country = '中国' credit_limit = 150000.00 ) TO mt_customers.
    APPEND VALUE #( customer_id = 'CUST003' name = '王五' city = '广州' country = '中国' credit_limit = 80000.00 ) TO mt_customers.
    APPEND VALUE #( customer_id = 'CUST004' name = 'John Smith' city = 'New York' country = 'USA' credit_limit = 200000.00 ) TO mt_customers.
    APPEND VALUE #( customer_id = 'CUST005' name = 'Maria Garcia' city = 'Madrid' country = 'Spain' credit_limit = 120000.00 ) TO mt_customers.

    " 订单数据
    APPEND VALUE #( order_id = 'ORD001' customer_id = 'CUST001' order_date = '20240115' amount = 5000.00 status = 'COMPLETED' ) TO mt_orders.
    APPEND VALUE #( order_id = 'ORD002' customer_id = 'CUST002' order_date = '20240116' amount = 7500.00 status = 'PENDING' ) TO mt_orders.
    APPEND VALUE #( order_id = 'ORD003' customer_id = 'CUST001' order_date = '20240117' amount = 3000.00 status = 'COMPLETED' ) TO mt_orders.
    APPEND VALUE #( order_id = 'ORD004' customer_id = 'CUST003' order_date = '20240118' amount = 12000.00 status = 'CANCELLED' ) TO mt_orders.
    APPEND VALUE #( order_id = 'ORD005' customer_id = 'CUST004' order_date = '20240119' amount = 25000.00 status = 'COMPLETED' ) TO mt_orders.

    " 产品数据
    APPEND VALUE #( product_id = 'PROD001' name = '笔记本电脑' category = 'ELECTRONICS' price = 8999.00 stock = 50 ) TO mt_products.
    APPEND VALUE #( product_id = 'PROD002' name = '智能手机' category = 'ELECTRONICS' price = 3999.00 stock = 100 ) TO mt_products.
    APPEND VALUE #( product_id = 'PROD003' name = '办公椅' category = 'FURNITURE' price = 599.00 stock = 30 ) TO mt_products.
    APPEND VALUE #( product_id = 'PROD004' name = '咖啡机' category = 'APPLIANCES' price = 1299.00 stock = 20 ) TO mt_products.
    APPEND VALUE #( product_id = 'PROD005' name = '书籍' category = 'STATIONERY' price = 49.00 stock = 200 ) TO mt_products.

    cl_demo_output=>write( '=== 业务数据初始化完成 ===' ).
    cl_demo_output=>write( |客户数量: { lines( mt_customers ) }| ).
    cl_demo_output=>write( |订单数量: { lines( mt_orders ) }| ).
    cl_demo_output=>write( |产品数量: { lines( mt_products ) }| ).
  ENDMETHOD.

  METHOD demonstrate_customer_operations.
    " 客户管理操作演示
    cl_demo_output=>write( '=== 客户管理操作演示 ===' ).

    " 1. 客户信息查询
    DATA(lv_customer_name) = VALUE #( mt_customers[ customer_id = 'CUST001' ]-name OPTIONAL ).
    cl_demo_output=>write( |客户查询: CUST001 = { lv_customer_name }| ).

    " 2. 客户信用检查
    DATA(lv_credit_limit) = VALUE #( mt_customers[ customer_id = 'CUST002' ]-credit_limit DEFAULT 0 ).
    IF lv_credit_limit > 100000.
      cl_demo_output=>write( |信用检查: CUST002 信用额度较高 ({ lv_credit_limit })| ).
    ENDIF.

    " 3. 客户存在性验证
    IF line_exists( mt_customers[ customer_id = 'CUST999' ] ).
      cl_demo_output=>write( '客户验证: CUST999 存在' ).
    ELSE.
      cl_demo_output=>write( '客户验证: CUST999 不存在' ).
    ENDIF.

    " 4. 多条件客户查询
    DATA(ls_customer_city) = VALUE #( mt_customers[ name = 'John Smith' country = 'USA' ] OPTIONAL ).
    IF ls_customer_city IS NOT INITIAL.
      cl_demo_output=>write( |多条件查询: John Smith 在 { ls_customer_city-city }| ).
    ENDIF.

    " 5. 客户数据安全访问
    DATA(ls_safe_customer) = VALUE #( mt_customers[ customer_id = 'UNKNOWN' ] 
                                     DEFAULT VALUE #( customer_id = 'DEFAULT' name = '未知客户' ) ).
    cl_demo_output=>write( |安全访问: { ls_safe_customer-name }| ).
  ENDMETHOD.

  METHOD demonstrate_order_processing.
    " 订单处理操作演示
    cl_demo_output=>write( '=== 订单处理操作演示 ===' ).

    " 1. 订单状态查询
    DATA(lv_order_status) = VALUE #( mt_orders[ order_id = 'ORD001' ]-status OPTIONAL ).
    cl_demo_output=>write( |订单状态: ORD001 = { lv_order_status }| ).

    " 2. 客户订单关联查询
    DATA(ls_customer_order) = VALUE #( mt_orders[ customer_id = 'CUST001' order_id = 'ORD003' ] OPTIONAL ).
    IF ls_customer_order IS NOT INITIAL.
      cl_demo_output=>write( |关联查询: CUST001 的订单 ORD003 金额为 { ls_customer_order-amount }| ).
    ENDIF.

    " 3. 订单金额统计
    DATA(lv_total_amount) = REDUCE p DECIMALS 2(
      INIT total = 0
      FOR order IN mt_orders WHERE ( customer_id = 'CUST001' AND status = 'COMPLETED' )
      NEXT total = total + order-amount ).
    cl_demo_output=>write( |金额统计: CUST001 已完成订单总额 = { lv_total_amount }| ).

    " 4. 订单日期验证
    DATA(ls_recent_order) = VALUE #( mt_orders[ order_date = '20240119' ] OPTIONAL ).
    IF ls_recent_order IS NOT INITIAL.
      cl_demo_output=>write( |日期查询: 2024-01-19 有订单 { ls_recent_order-order_id }| ).
    ENDIF.

    " 5. 订单状态批量检查
    DATA: lv_completed_count TYPE i.
    LOOP AT mt_orders ASSIGNING FIELD-SYMBOL(<fs_order>).
      IF line_exists( mt_orders[ order_id = <fs_order>-order_id status = 'COMPLETED' ] ).
        lv_completed_count = lv_completed_count + 1.
      ENDIF.
    ENDLOOP.
    cl_demo_output=>write( |状态统计: 已完成订单数量 = { lv_completed_count }| ).
  ENDMETHOD.

  METHOD demonstrate_product_management.
    " 产品管理操作演示
    cl_demo_output=>write( '=== 产品管理操作演示 ===' ).

    " 1. 产品价格查询
    DATA(lv_product_price) = VALUE #( mt_products[ product_id = 'PROD001' ]-price OPTIONAL ).
    cl_demo_output=>write( |价格查询: PROD001 价格 = { lv_product_price }| ).

    " 2. 库存检查
    DATA(lv_product_stock) = VALUE #( mt_products[ product_id = 'PROD002' ]-stock OPTIONAL ).
    IF lv_product_stock < 50.
      cl_demo_output=>write( |库存预警: PROD002 库存不足 ({ lv_product_stock })| ).
    ELSE.
      cl_demo_output=>write( |库存正常: PROD002 库存充足 ({ lv_product_stock })| ).
    ENDIF.

    " 3. 产品分类查询
    DATA(lt_electronics) = VALUE ts_product_tab(
      FOR product IN mt_products WHERE ( category = 'ELECTRONICS' )
      ( product ) ).
    cl_demo_output=>write( |分类查询: 电子产品数量 = { lines( lt_electronics ) }| ).

    " 4. 产品价格范围查询
    DATA(lt_expensive_products) = VALUE ts_product_tab(
      FOR product IN mt_products WHERE ( price > 1000 )
      ( product ) ).
    cl_demo_output=>write( |价格筛选: 高价产品数量 = { lines( lt_expensive_products ) }| ).

    " 5. 产品信息组合查询
    DATA(ls_product_info) = VALUE #( mt_products[ 
      product_id = 'PROD003' 
      category = 'FURNITURE' 
    ] OPTIONAL ).
    IF ls_product_info IS NOT INITIAL.
      cl_demo_output=>write( |组合查询: { ls_product_info-name } - { ls_product_info-price }| ).
    ENDIF.
  ENDMETHOD.

  METHOD run_performance_comparison.
    " 性能对比测试
    cl_demo_output=>write( '=== 性能对比测试 ===' ).

    DATA: lv_time_traditional TYPE i,
          lv_time_expression  TYPE i.

    " 传统语法性能测试
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i,
          ls_temp_customer   TYPE ts_customer,
          ls_temp_order      TYPE ts_order.

    GET RUN TIME FIELD lv_timestamp_begin.

    " 传统方式：客户查询 + 订单查询
    READ TABLE mt_customers INTO ls_temp_customer
      WITH TABLE KEY customer_id = 'CUST001'.
    IF sy-subrc = 0.
      READ TABLE mt_orders INTO ls_temp_order
        WITH TABLE KEY customer_id = ls_temp_customer-customer_id.
    ENDIF.

    GET RUN TIME FIELD lv_timestamp_end.
    lv_time_traditional = lv_timestamp_end - lv_timestamp_begin.

    " 表表达式性能测试
    GET RUN TIME FIELD lv_timestamp_begin.

    " 表表达式方式：链式查询
    DATA(ls_customer_data) = VALUE #( mt_customers[ customer_id = 'CUST001' ] OPTIONAL ).
    IF ls_customer_data IS NOT INITIAL.
      DATA(ls_order_data) = VALUE #( mt_orders[ customer_id = ls_customer_data-customer_id ] OPTIONAL ).
    ENDIF.

    GET RUN TIME FIELD lv_timestamp_end.
    lv_time_expression = lv_timestamp_end - lv_timestamp_begin.

    " 显示性能结果
    cl_demo_output=>write( |传统语法耗时: { lv_time_traditional } 微秒| ).
    cl_demo_output=>write( |表表达式耗时: { lv_time_expression } 微秒| ).

    IF lv_time_traditional > 0.
      DATA(lv_improvement) = ( 1 - ( lv_time_expression / lv_time_traditional ) ) * 100.
      cl_demo_output=>write( |性能提升: { lv_improvement }%| ).
    ENDIF.
  ENDMETHOD.

  METHOD display_business_insights.
    " 业务洞察分析
    cl_demo_output=>write( '=== 业务洞察分析 ===' ).

    " 1. 客户订单分析
    DATA(lt_customer_orders) = VALUE ts_order_tab(
      FOR customer IN mt_customers
      LET customer_orders = VALUE ts_order_tab(
        FOR order IN mt_orders WHERE ( customer_id = customer-customer_id )
        ( order ) )
      IN ( LINES OF customer_orders ) ).

    cl_demo_output=>write( |客户订单关联: 总关联记录数 = { lines( lt_customer_orders ) }| ).

    " 2. 高价值客户识别
    DATA(lt_high_value_customers) = VALUE ts_customer_tab(
      FOR customer IN mt_customers WHERE ( credit_limit > 100000 )
      ( customer ) ).
    cl_demo_output=>write( |高价值客户: 数量 = { lines( lt_high_value_customers ) }| ).

    " 3. 产品库存分析
    DATA(lv_low_stock_count) = REDUCE i(
      INIT count = 0
      FOR product IN mt_products
      NEXT count = count + COND #( WHEN product-stock < 30 THEN 1 ELSE 0 ) ).
    cl_demo_output=>write( |低库存产品: 数量 = { lv_low_stock_count }| ).

    " 4. 订单状态分布
    DATA(lv_completed_orders) = REDUCE i(
      INIT count = 0
      FOR order IN mt_orders
      NEXT count = count + COND #( WHEN order-status = 'COMPLETED' THEN 1 ELSE 0 ) ).
    cl_demo_output=>write( |订单完成率: { lv_completed_orders }/{ lines( mt_orders ) }| ).

    " 5. 业务总结
    cl_demo_output=>write( '=== 表表达式业务优势总结 ===' ).
    cl_demo_output=>write( '✓ 代码简洁：减少临时变量和重复代码' ).
    cl_demo_output=>write( '✓ 性能优化：内部优化比传统语法更高效' ).
    cl_demo_output=>write( '✓ 可读性强：业务逻辑表达更清晰' ).
    cl_demo_output=>write( '✓ 错误处理：强制处理未找到数据的情况' ).
    cl_demo_output=>write( '✓ 维护性好：代码结构统一，易于维护' ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  DATA(object) = NEW lcl_real_world_applications( ).
  object->init_business_data( ).

  " 演示各种业务操作
  object->demonstrate_customer_operations( ).
  object->demonstrate_order_processing( ).
  object->demonstrate_product_management( ).

  " 运行性能对比
  object->run_performance_comparison( ).

  " 显示业务洞察
  object->display_business_insights( ).

  cl_demo_output=>display( ).
ENDFORM.
