`include "APB_top.v"
`timescale 1ns / 1ps

module apb_testbench;

    // Clock and reset signals
    reg pclk;
    reg presetn;

    // Master control signals
    reg transfer, read, write;
    reg [8:0] apb_write_paddr;
    reg [7:0] apb_write_data;
    reg [8:0] apb_read_paddr;

    // Outputs from the top module
    wire pslverr;
    wire [7:0] apb_read_data_out;

    // Clock generation
    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk;  // 100 MHz clock (10 ns period)
    end

    // Instantiate the top module
    apb_top dut (
        .pclk(pclk),
        .presetn(presetn),
        .transfer(transfer),
        .read(read),
        .write(write),
        .apb_write_paddr(apb_write_paddr),
        .apb_write_data(apb_write_data),
        .apb_read_paddr(apb_read_paddr),
        .pslverr(pslverr),
        .apb_read_data_out(apb_read_data_out)
    );

    // Reset and Initialization
    task reset_and_init;
        begin
            presetn = 0;
            transfer = 0;
            read = 0;
            write = 0;
            apb_write_paddr = 9'b0;
            apb_write_data = 8'b0;
            apb_read_paddr = 9'b0;
            #20;  // Hold reset for 20 ns
            presetn = 1;
            #10;
        end
    endtask

    // Test Case 1: Basic Write Operation
    task test_write;
        input [8:0] address;
        input [7:0] data;
        begin
            $display("Starting Basic Write Operation Test");
            transfer = 1;
            write = 1;
            read = 0;
            apb_write_paddr = address;
            apb_write_data = data;
            #10;  // Setup phase
            #10;  // Access phase
            transfer = 0; // Deassert transfer signal
            write = 0;
            $display("Write Operation Completed: Address = %h, Data = %h", address, data);
            #10;
        end
    endtask

    // Test Case 2: Basic Read Operation
    task test_read;
        input [8:0] address;
        begin
            $display("Starting Basic Read Operation Test");
            transfer = 1;
            write = 0;
            read = 1;
            apb_read_paddr = address;
            #10;  // Setup phase
            #10;  // Access phase
            transfer = 0; // Deassert transfer signal
            read = 0;
            $display("Read Operation Completed: Address = %h, Data Read = %h", address, apb_read_data_out);
            #10;
        end
    endtask

    // Test Case 3: Address Decoding (Slave Selection)
    task test_address_decoding;
        begin
            $display("Starting Address Decoding Test");
            test_write(9'h005, 8'hA5); // Target Slave 1
            test_write(9'h085, 8'h5A); // Target Slave 2
        end
    endtask

    // Test Case 4: Write with Wait States
    task test_write_with_wait_states;
        input [8:0] address;
        input [7:0] data;
        begin
            $display("Starting Write Operation with Wait States Test");
            transfer = 1;
            write = 1;
            read = 0;
            apb_write_paddr = address;
            apb_write_data = data;
            #10; // Setup phase
            // Simulate a wait state by delaying slave response
            @(posedge pclk);
            $display("Slave ready signal delayed");
            #20; // Access phase
            transfer = 0;
            write = 0;
            $display("Write Completed with Wait States: Address = %h, Data = %h", address, data);
            #10;
        end
    endtask

    // Test Case 5: Read with Wait States
    task test_read_with_wait_states;
        input [8:0] address;
        begin
            $display("Starting Read Operation with Wait States Test");
            transfer = 1;
            write = 0;
            read = 1;
            apb_read_paddr = address;
            #10; // Setup phase
            // Simulate a wait state by delaying slave response
            @(posedge pclk);
            $display("Slave ready signal delayed");
            #20; // Access phase
            transfer = 0;
            read = 0;
            $display("Read Completed with Wait States: Address = %h, Data Read = %h", address, apb_read_data_out);
            #10;
        end
    endtask

    // Test Case 6: Error Handling (PSLVERR)
    task test_error_handling;
        input [8:0] invalid_address;
        begin
            $display("Starting Error Handling Test");
            transfer = 1;
            write = 1;
            read = 0;
            apb_write_paddr = invalid_address;
            apb_write_data = 8'hFF;
            #10; // Setup phase
            #10; // Access phase
            transfer = 0;
            write = 0;
            $display("Error Condition PSLVERR = %b for Invalid Address = %h", pslverr, invalid_address);
            #10;
        end
    endtask

    // Test Case 7: Burst Transfers
    task test_burst_transfers;
        begin
            $display("Starting Burst Transfers Test");
            test_write(9'h001, 8'h11);
            test_read(9'h001);
            test_write(9'h002, 8'h22);
            test_read(9'h002);
            test_write(9'h003, 8'h33);
            test_read(9'h003);
            $display("Burst Transfers Completed");
        end
    endtask

    // Case 8: Test Out-of-Range Address Handling
    task test_out_of_range_address;
        input [8:0] invalid_address;
        begin
            $display("\n[Case 8] Testing Out-of-Range Address Handling...");
            transfer = 1;
            write = 1;
            read = 0;
            apb_write_paddr = invalid_address; // Use an invalid address
            apb_write_data = 8'hFF;           // Some test data
            #10; // Setup phase
            #10; // Access phase
            transfer = 0;
            write = 0;
            if (pslverr)
                $display("Error detected for invalid address %h, PSLVERR = %b", invalid_address, pslverr);
            else
                $display("No error detected for invalid address %h, PSLVERR = %b", invalid_address, pslverr);
            #10;
        end
    endtask

    // Case 9: Test Reset Behavior
    task test_reset_behavior;
        begin
            $display("\n[Case 9] Testing Reset Behavior...");
            presetn = 0; // Apply reset
            #20;
            if (!presetn)
                $display("System Reset Asserted.");
            presetn = 1; // Release reset
            #10;
            if (presetn)
                $display("System Reset Released. Registers and signals should return to default states.");
            #10;
        end
    endtask

    // Case 10: Test Randomized Transactions
    task test_randomized_transactions;
        integer i;
        begin
            $display("\n[Case 10] Stress Testing with Randomized Transactions...");
            for (i = 0; i < 20; i = i + 1) begin
                transfer = 1;
                // Randomly pick between read and write
                if ($random % 2) begin
                    write = 1;
                    read = 0;
                    apb_write_paddr = $random % 9'h100; // Random 9-bit address
                    apb_write_data = $random % 8'hFF;  // Random 8-bit data
                    $display("Write Transaction: Address = %h, Data = %h", apb_write_paddr, apb_write_data);
                end else begin
                    write = 0;
                    read = 1;
                    apb_read_paddr = $random % 9'h100; // Random 9-bit address
                    $display("Read Transaction: Address = %h", apb_read_paddr);
                end
                #10; // Setup phase
                #10; // Access phase
                transfer = 0;
                write = 0;
                read = 0;
                #10;
            end
            $display("Randomized Transactions Completed.");
        end
    endtask




    // Main Testbench Execution
    initial begin
        $display("APB System Testbench Start");
        reset_and_init;
        
        test_write(9'h005, 8'hAA);                  // Test Case 1
        test_read(9'h005);                          // Test Case 2
        test_address_decoding;                      // Test Case 3
        test_write_with_wait_states(9'h010, 8'hBB); // Test Case 4
        test_read_with_wait_states(9'h010);         // Test Case 5
        test_error_handling(9'h1FF);                // Test Case 6
        test_burst_transfers;                       // Test Case 7
        test_out_of_range_address(9'h1FF);          // Test Case 8
        test_reset_behavior;                        // Test Case 9
        test_randomized_transactions;               // Test Case 10
        $display("APB System Testbench Complete");
        $finish;
    end

endmodule



/*============================= TC:1  =================================

==> Basic Write Operation: write transaction with no wait states.
==> Input:  transfer = 1, write = 1, read = 0
            Valid address in apb_write_paddr
            Valid data in apb_write_data

==> Output: Slave receives correct address and data.
            pready is asserted after one clock cycle.
            Data is written to the correct location in the slave

============================= TC:2  =================================

==> Basic Read Operation: read transaction with no wait states.
==> Input:  transfer = 1, write = 0, read = 1
            Valid address in apb_read_paddr.

==> Output: Slave returns correct data for the requested address via prdata.
            apb_read_data_out in the master contains the expected data.
            pready is asserted after one clock cycle.

============================= TC:3  =================================

==> Address Decoding (Slave Selection): Validate the master correctly selects the slave based on the address range.
==> Input:  Test address ranges that map to:
            Slave 1 (psel1 = 1, psel2 = 0).
            Slave 2 (psel1 = 0, psel2 = 1).

==> Output: Only the correct slave (psel1 or psel2) is selected.
            Other slave remains idle.

============================= TC:4  =================================

==> Write with Wait States: write transaction where the slave introduces wait states.
==> Input:  Slave delays asserting pready.

==> Output: Master remains in the ENABLE state until pready is asserted.
            Data is written only when the transfer completes.

============================= TC:5  =================================

==> Read with Wait States: read transaction where the slave introduces wait states.

==> Input:  Slave delays asserting pready.

==> Output: Master remains in the ENABLE state until pready is asserted.
            Correct data is captured by the master when the transfer completes.

============================= TC:6  =================================

==> Error Handling (PSLVERR): Test error conditions during both read and write operations.

==> Input:  Simulate invalid address or other errors in the slave.
            Slave asserts pslverr HIGH.

==> Output: Master captures the error condition.
            apb_read_data_out may contain invalid data for a read transfer.
            Write operation may still modify slave memory depending on the slave's behavior.

============================= TC:7  =================================

==> Burst of Transfers: Execute multiple back-to-back read and write transfers.

==> Input:  Alternate between read and write transfers without returning to IDLE.

==> Output: Master and slaves handle consecutive transfers without issues.
            PSEL and PENABLE transition correctly between transfers.

============================= TC:8  =================================

==> Out-of-Range Address: Test with an address that is outside the valid range of the slaves.

==> Input:  Provide an invalid address in apb_write_paddr or apb_read_paddr.

==> Output: Slave asserts pslverr.
            Master detects the error and responds appropriately.


============================= TC:9  =================================

==> Reset: reset functionality for the system.

==> Input:  Assert presetn (active-low reset).

==> Output: All signals return to their default states.
            No transfers occur during reset.

============================= TC:10  =================================

==> Randomized Transactions: randomized read and write operations.

==> Input:  Randomly generate read, write, apb_write_paddr, apb_read_paddr, and apb_write_data.

==> Output: System remains stable

*/