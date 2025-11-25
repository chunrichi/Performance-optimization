*&---------------------------------------------------------------------*
*& Report ZDEMO_PPO_007
*&---------------------------------------------------------------------*
*& Reduce Nested Loops - Hash Table vs Nested Loops Performance Comparison
*&---------------------------------------------------------------------*
REPORT zdemo_ppo_007.

CLASS lcl_nested_loops_comparison DEFINITION.
  PUBLIC SECTION.
    " Performance measurement data
    DATA: mv_time_nested_loops TYPE i,
          mv_time_hash_table   TYPE i.

    " Data structures for testing
    TYPES: BEGIN OF ts_customer,
             customer_id   TYPE i,      " Customer ID
             customer_name TYPE string, " Customer name
           END OF ts_customer.

    TYPES: BEGIN OF ts_order,
             order_id    TYPE i,      " Order ID
             customer_id TYPE i,      " Customer ID (foreign key)
             order_date  TYPE d,      " Order date
             amount      TYPE p LENGTH 8 DECIMALS 2, " Order amount
           END OF ts_order.

    TYPES: BEGIN OF ts_customer_order,
             customer_id   TYPE i,
             customer_name TYPE string,
             order_id      TYPE i,
             order_date    TYPE d,
             amount        TYPE p LENGTH 8 DECIMALS 2,
           END OF ts_customer_order.

    DATA: mt_customers TYPE TABLE OF ts_customer,
          mt_orders    TYPE TABLE OF ts_order,
          mt_result    TYPE TABLE OF ts_customer_order.

    METHODS:
      init,
      nested_loops_approach,
      hash_table_approach,
      measure_nested_loops,
      measure_hash_table,
      display_results.
ENDCLASS.

CLASS lcl_nested_loops_comparison IMPLEMENTATION.

  METHOD init.
    " Generate test data: customers and orders
    DATA: lv_counter TYPE i VALUE 1.

    CLEAR: mt_customers, mt_orders, mt_result.

    " Generate 1000 customers
    DO 1000 TIMES.
      APPEND VALUE #( customer_id = lv_counter
                      customer_name = |Customer { lv_counter }| ) TO mt_customers.
      lv_counter = lv_counter + 1.
    ENDDO.

    " Generate 10000 orders (10 orders per customer on average)
    lv_counter = 1.
    DO 10000 TIMES.
      DATA(lv_customer_id) = ( sy-index MOD 1000 ) + 1. " Distribute orders among customers
      APPEND VALUE #( order_id = lv_counter
                      customer_id = lv_customer_id
                      order_date = sy-datum - ( sy-index MOD 365 )
                      amount = ( sy-index MOD 1000 ) + 1 ) TO mt_orders.
      lv_counter = lv_counter + 1.
    ENDDO.

    cl_demo_output=>write( |Generated { lines( mt_customers ) } customers and { lines( mt_orders ) } orders| ).
    cl_demo_output=>write( 'Ready to compare nested loops vs hash table approach' ).
  ENDMETHOD.

  METHOD nested_loops_approach.
    " Traditional nested loops approach - O(n*m) complexity
    DATA: ls_customer TYPE ts_customer,
          ls_order    TYPE ts_order,
          ls_result   TYPE ts_customer_order.

    CLEAR: mt_result.

    " Outer loop: customers
    LOOP AT mt_customers INTO ls_customer.
      " Inner loop: orders
      LOOP AT mt_orders INTO ls_order WHERE customer_id = ls_customer-customer_id.
        " Create combined result record
        ls_result-customer_id   = ls_customer-customer_id.
        ls_result-customer_name = ls_customer-customer_name.
        ls_result-order_id      = ls_order-order_id.
        ls_result-order_date    = ls_order-order_date.
        ls_result-amount        = ls_order-amount.
        APPEND ls_result TO mt_result.
      ENDLOOP.
    ENDLOOP.

    " Just to ensure the method does something meaningful
    IF lines( mt_result ) > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD hash_table_approach.
    " Hash table approach - O(n+m) complexity
    DATA: lt_customer_hash TYPE HASHED TABLE OF ts_customer WITH UNIQUE KEY customer_id,
          ls_order         TYPE ts_order,
          ls_result        TYPE ts_customer_order,
          ls_customer      TYPE ts_customer.

    CLEAR: mt_result.

    " Build hash table from customers
    lt_customer_hash = mt_customers.

    " Single loop through orders with hash table lookup
    LOOP AT mt_orders INTO ls_order.
      " Lookup customer in hash table - O(1) complexity
      READ TABLE lt_customer_hash INTO ls_customer
        WITH TABLE KEY customer_id = ls_order-customer_id.

      IF sy-subrc = 0.
        " Create combined result record
        ls_result-customer_id   = ls_customer-customer_id.
        ls_result-customer_name = ls_customer-customer_name.
        ls_result-order_id      = ls_order-order_id.
        ls_result-order_date    = ls_order-order_date.
        ls_result-amount        = ls_order-amount.
        APPEND ls_result TO mt_result.
      ENDIF.
    ENDLOOP.

    " Just to ensure the method does something meaningful
    IF lines( mt_result ) > 0.
      " Do nothing - just to avoid optimization
    ENDIF.
  ENDMETHOD.

  METHOD measure_nested_loops.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    nested_loops_approach( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_nested_loops = mv_time_nested_loops + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD measure_hash_table.
    DATA: lv_timestamp_begin TYPE i,
          lv_timestamp_end   TYPE i.

    GET RUN TIME FIELD lv_timestamp_begin.
    hash_table_approach( ).
    GET RUN TIME FIELD lv_timestamp_end.
    mv_time_hash_table = mv_time_hash_table + ( lv_timestamp_end - lv_timestamp_begin ).
  ENDMETHOD.

  METHOD display_results.
    DATA: lv_improvement    TYPE p LENGTH 5 DECIMALS 2,
          lv_speedup_factor TYPE p LENGTH 5 DECIMALS 2.

    cl_demo_output=>write( '=== NESTED LOOPS REDUCTION PERFORMANCE COMPARISON ===' ).
    cl_demo_output=>write( 'Comparison: Hash Table Approach vs Traditional Nested Loops' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).

    " Calculate improvement percentage
    IF mv_time_nested_loops > 0.
      lv_improvement = ( 1 - ( mv_time_hash_table / mv_time_nested_loops ) ) * 100.
      lv_speedup_factor = mv_time_nested_loops / mv_time_hash_table.
    ELSE.
      lv_improvement = 0.
      lv_speedup_factor = 1.
    ENDIF.

    cl_demo_output=>write( |Total time with NESTED LOOPS: { mv_time_nested_loops } microseconds| ).
    cl_demo_output=>write( |Total time with HASH TABLE:   { mv_time_hash_table } microseconds| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( |Performance improvement: { lv_improvement }%| ).
    cl_demo_output=>write( |Speedup factor: { lv_speedup_factor }x| ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'Algorithm Complexity Analysis:' ).
    cl_demo_output=>write( '- Nested Loops: O(n*m) = 1000 customers * 10000 orders = 10,000,000 operations' ).
    cl_demo_output=>write( '- Hash Table: O(n+m) = 1000 customers + 10000 orders = 11,000 operations' ).
    cl_demo_output=>write( '------------------------------------------------------------------' ).
    cl_demo_output=>write( 'Key Optimization Techniques:' ).
    cl_demo_output=>write( '1. Use hash tables for O(1) lookups instead of O(n) linear searches' ).
    cl_demo_output=>write( '2. Pre-sort data when possible to enable binary search' ).
    cl_demo_output=>write( '3. Avoid nested loops in favor of single loops with efficient lookups' ).
    cl_demo_output=>write( '4. Consider data structure transformations to reduce complexity' ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  PERFORM main.

FORM main.
  CONSTANTS: lc_num_of_iterations TYPE i VALUE 10. " Fewer iterations due to larger data volume

  DATA(object) = NEW lcl_nested_loops_comparison( ).
  object->init( ).

  " Warm-up run to avoid JIT compilation effects
  object->nested_loops_approach( ).
  object->hash_table_approach( ).

  " Actual measurement runs
  DO lc_num_of_iterations TIMES.
    object->measure_nested_loops( ).
    object->measure_hash_table( ).
  ENDDO.

  object->display_results( ).
  cl_demo_output=>display( ).
ENDFORM.
