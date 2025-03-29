module apb_master (
    input wire presetn,                // Active-low reset
    input wire pclk,                   // Clock signal
    input wire transfer,               // Transfer signal to initiate a transaction
    input wire read,                   // Read enable signal
    input wire write,                  // Write enable signal
    input wire [8:0] apb_write_paddr,  // Write address
    input wire [7:0] apb_write_data,   // Write data
    input wire [8:0] apb_read_paddr,   // Read address
    input wire pready,                  // Slave ready signal
    input wire pslverr,                 // Slave error signal
    input wire [7:0] prdata,            // Data from slave during read

    output reg psel1,                   // Select signal for slave 1
    output reg psel2,                   // Select signal for slave 2
    output reg penable,                 // Enable signal for the current transfer
    output reg pwrite,                  // Write signal (1 = write, 0 = read)
    output reg [8:0] paddr,             // Address signal for slave
    output reg [7:0] pwdata,            // Data to slave during write
    output reg [7:0] apb_read_data_out  // Data output during read
);

    // Internal state encoding
    parameter IDLE = 2'b00;
    parameter SETUP = 2'b01;
    parameter ENABLE = 2'b10;

    reg [1:0] state;          // Current state
    reg [1:0] next_state;     // Next state

    // Sequential state transition logic
    always @(posedge pclk or negedge presetn) begin
        if (!presetn)
            state <= IDLE;    // Reset to IDLE state
        else
            state <= next_state;
    end

    // Combinational next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (transfer)
                    next_state = SETUP;
                else
                    next_state = IDLE;
            end
            SETUP: begin
                next_state = ENABLE;  // Always move to ENABLE from SETUP
            end
            ENABLE: begin
                if (pready)
                    next_state = (transfer) ? SETUP : IDLE;
                else
                    next_state = ENABLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Output and state-dependent control logic
    always @(*) begin
        // Default assignments to prevent latches
        psel1 = 0;
        psel2 = 0;
        penable = 0;
        pwrite = 0;
        paddr = 9'b0;
        pwdata = 8'b0;

        case (state)
            IDLE: begin
                // No activity in IDLE
            end
            SETUP: begin
                penable = 0;
                if (read && !write) begin
                    paddr = apb_read_paddr;             // Load read address
                    psel1 = (apb_read_paddr[8] == 0);   // Select slave 1 for lower addresses
                    psel2 = (apb_read_paddr[8] == 1);   // Select slave 2 for higher addresses
                    pwrite = 0;                         // Set for read operation
                end
                else if (write && !read) begin
                    paddr = apb_write_paddr;                // Load write address
                    psel1 = (apb_write_paddr[8] == 0);
                    psel2 = (apb_write_paddr[8] == 1);
                    pwrite = 1;                            // Set for write operation
                    pwdata = apb_write_data;               // Load write data
                end
            end
            ENABLE: begin
                penable = 1;  // Enable the transfer
                if (pready) begin
                    if (read && !write) begin
                        apb_read_data_out = prdata; // Capture data from slave during read
                    end
                end
            end
        endcase
    end

endmodule

