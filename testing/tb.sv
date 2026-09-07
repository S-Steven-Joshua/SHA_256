`timescale 1ns/1ps

module sha_256_tb;

    // =========================================================
    // DUT SIGNALS
    // =========================================================

    logic         clk;
    logic         rst;
    logic         start;

    logic [255:0] data_in;
    logic [5:0]   length;

    logic [255:0] hash;
    logic         ready;


    // =========================================================
    // DUT
    // =========================================================

    sha_256_top uut (
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .data_in (data_in),
        .length  (length),
        .hash    (hash),
        .ready    (ready)
    );


    // =========================================================
    // CLOCK
    // =========================================================

    always #5 clk = ~clk;


    // =========================================================
    // REGRESSION PARAMETERS
    // =========================================================

    // For initial testing you can change this to:
    //
    // 1000
    // 10000
    // 1000000
    //
    // Once verified, use:
    //
    // 150000000
    //
    localparam integer TOTAL_TESTS = 15_00_000;

    localparam integer MAX_LENGTH  = 31;


    // =========================================================
    // RESULT FILE
    // =========================================================

    integer result_file;


    // =========================================================
    // TEST VARIABLES
    // =========================================================

    integer test_id;
    integer msg_len;
    integer i;

    logic [255:0] captured_hash;


    // =========================================================
    // RANDOM ASCII CHARACTER
    //
    // Printable ASCII:
    //
    // 0x20 = SPACE
    // 0x21 = !
    // ...
    // 0x7E = ~
    //
    // Total = 95 characters
    // =========================================================

    function automatic byte random_ascii;

        begin

            random_ascii = $urandom_range(8'h20, 8'h7E);

        end

    endfunction


    // =========================================================
    // GENERATE RANDOM MESSAGE
    //
    // Length = 1 to 31
    // Characters = printable ASCII 0x20 to 0x7E
    // =========================================================

    task automatic generate_message;

        integer j;

        begin

            // -------------------------------------------------
            // Random length
            // -------------------------------------------------

            msg_len = $urandom_range(1, MAX_LENGTH);


            // -------------------------------------------------
            // Clear data
            // -------------------------------------------------

            data_in = '0;


            // -------------------------------------------------
            // Generate printable ASCII characters
            //
            // First character goes to MSB.
            // -------------------------------------------------

            for (j = 0; j < msg_len; j = j + 1) begin

                data_in[255 - (j * 8) -: 8] =
                    random_ascii();

            end


            // -------------------------------------------------
            // Length in bytes
            // -------------------------------------------------

            length = msg_len[5:0];

        end

    endtask


    // =========================================================
    // RESET DUT
    //
    // ACTIVE-LOW RESET
    //
    // rst = 0 -> RESET
    // rst = 1 -> NORMAL
    //
    // Only ONE clock cycle reset.
    // =========================================================

    task automatic reset_dut;

        begin

            start = 1'b0;

            // Assert reset
            rst = 1'b0;

            // One clock cycle
            @(posedge clk);

            #1;

            // Release reset
            rst = 1'b1;

            #1;

        end

    endtask


    // =========================================================
    // RUN ONE SHA-256 TRANSACTION
    //
    // Sequence:
    //
    // DATA + LENGTH
    //       |
    //       v
    // START = 1
    //       |
    //       v
    // START = 0
    //       |
    //       v
    // SHA-256 PROCESSING
    //       |
    //       v
    // READY = 1
    //       |
    //       v
    // CAPTURE HASH
    //       |
    //       v
    // WRITE FILE
    //       |
    //       v
    // WAIT CLOCK
    // =========================================================

    task automatic run_sha256;

        begin

            // -------------------------------------------------
            // DATA and LENGTH are already driven
            // -------------------------------------------------

            @(posedge clk);

            #1;


            // -------------------------------------------------
            // Assert START
            // -------------------------------------------------

            start = 1'b1;


            // -------------------------------------------------
            // Hold START for one clock
            // -------------------------------------------------

            @(posedge clk);

            #1;


            // -------------------------------------------------
            // Deassert START
            // -------------------------------------------------

            start = 1'b0;


            // -------------------------------------------------
            // Wait for READY
            // -------------------------------------------------

            @(posedge ready);

            #1;


            // -------------------------------------------------
            // Capture HASH
            // -------------------------------------------------

            captured_hash = hash;


            // -------------------------------------------------
            // Write result
            //
            // TEST_ID LENGTH DATA_IN RTL_HASH
            // -------------------------------------------------

            $fwrite(
                result_file,
                "%0d %0d %064h %064h\n",
                test_id,
                msg_len,
                data_in,
                captured_hash
            );


            // -------------------------------------------------
            // Wait one clock before next transaction
            // -------------------------------------------------

            @(posedge clk);

            #1;

        end

    endtask


    // =========================================================
    // MAIN REGRESSION
    // =========================================================

    initial begin

        // =====================================================
        // INITIAL VALUES
        // =====================================================

        clk     = 1'b0;

        // Active-low reset
        rst     = 1'b0;

        start   = 1'b0;

        data_in = '0;

        length  = 6'd0;

        test_id = 0;


        // =====================================================
        // OPEN RESULT FILE
        // =====================================================

        result_file = $fopen(
            "D:\\protocol\\sha_256\\sha256_results.txt",
            "w"
        );


        if (result_file == 0) begin

            $display("");
            $display("ERROR: Could not create result file");
            $display("");

            $finish;

        end


        // =====================================================
        // FILE HEADER
        // =====================================================

        $fwrite(
            result_file,
            "# TEST_ID LENGTH DATA_IN RTL_HASH\n"
        );


        // =====================================================
        // INITIAL RESET
        // =====================================================

        rst = 1'b0;

        repeat (2) @(posedge clk);

        #1;

        rst = 1'b1;

        #1;


        // =====================================================
        // REGRESSION HEADER
        // =====================================================

        $display("");
        $display("================================================");
        $display("             SHA-256 STRESS REGRESSION");
        $display("================================================");
        $display("");

        $display(
            "Character range : ASCII 0x20 - 0x7E"
        );

        $display(
            "Characters      : 95 printable ASCII characters"
        );

        $display(
            "Length range    : 1 - 31 bytes"
        );

        $display(
            "Total tests     : %0d",
            TOTAL_TESTS
        );

        $display(
            "Reset           : Active LOW, 1 clock"
        );

        $display("");

        $display("================================================");
        $display("");


        // =====================================================
        // RUN TESTS
        // =====================================================

        for (
            test_id = 0;
            test_id < TOTAL_TESTS;
            test_id = test_id + 1
        ) begin

            // -------------------------------------------------
            // Reset DUT before every test
            // -------------------------------------------------

            reset_dut;


            // -------------------------------------------------
            // Generate new random ASCII message
            // -------------------------------------------------

            generate_message;


            // -------------------------------------------------
            // Run SHA-256
            // -------------------------------------------------

            run_sha256;


            // -------------------------------------------------
            // Progress every 1 million tests
            // -------------------------------------------------

            if (((test_id + 1) % 1_000_000) == 0) begin

                $display(
                    "Progress : %0d / %0d",
                    test_id + 1,
                    TOTAL_TESTS
                );

            end

        end


        // =====================================================
        // CLOSE FILE
        // =====================================================

        $fclose(result_file);


        // =====================================================
        // FINAL MESSAGE
        // =====================================================

        $display("");
        $display("================================================");
        $display("       SHA-256 STRESS REGRESSION COMPLETE");
        $display("================================================");

        $display(
            "Total tests : %0d",
            TOTAL_TESTS
        );

        $display(
            "Result file : sha256_results.txt"
        );

        $display("================================================");
        $display("");


        #20;

        $finish;

    end

endmodule
