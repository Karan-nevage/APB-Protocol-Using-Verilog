# APB Protocol Implementation and Testbench

## Overview
This project implements an **Advanced Peripheral Bus (APB)** protocol system, including an APB master, two APB slaves, and a top module integrating them. The system is designed according to the AMBA APB specification, supporting read and write operations with error handling and slave selection based on address decoding. A comprehensive testbench is provided to validate the system's functionality through various test cases.

The design is written in **Verilog** and includes a testbench to simulate and verify the APB protocol operations, such as basic read/write, address decoding, wait states, error handling, burst transfers, and randomized transactions.

## Files
- **APB_master.v**: Implements the APB master module, responsible for initiating read and write transactions, controlling the bus, and handling slave responses.
- **APB_slave.v**: Implements the APB slave module, which responds to read and write requests, manages a 256-byte memory, and generates error signals for invalid addresses.
- **APB_top.v**: Integrates the APB master with two APB slaves, connecting them via the necessary signals and handling slave selection.
- **APB_tb.v**: A testbench that verifies the functionality of the APB system through a series of test cases, including basic operations, error handling, and stress testing.

## Signal Descriptions

### APB Master Signals
| Signal Name         | Type   | Width | Description                                      |
|---------------------|--------|-------|--------------------------------------------------|
| `presetn`           | Input  | 1     | Active-low reset signal                          |
| `pclk`              | Input  | 1     | Clock signal (100 MHz in testbench)              |
| `transfer`          | Input  | 1     | Initiates a transaction                          |
| `read`              | Input  | 1     | Read enable signal (1 = read operation)          |
| `write`             | Input  | 1     | Write enable signal (1 = write operation)        |
| `apb_write_paddr`   | Input  | 9     | Write address for the slave                      |
| `apb_write_data`    | Input  | 8     | Data to be written to the slave                  |
| `apb_read_paddr`    | Input  | 9     | Read address for the slave                       |
| `pready`            | Input  | 1     | Slave ready signal (1 = slave ready)             |
| `pslverr`           | Input  | 1     | Slave error signal (1 = error occurred)          |
| `prdata`            | Input  | 8     | Data from slave during read                      |
| `psel1`             | Output | 1     | Select signal for slave 1                        |
| `psel2`             | Output | 1     | Select signal for slave 2                        |
| `penable`           | Output | 1     | Enable signal for the current transfer            |
| `pwrite`            | Output | 1     | Write signal (1 = write, 0 = read)               |
| `paddr`             | Output | 9     | Address signal for the slave                     |
| `pwdata`            | Output | 8     | Data to the slave during write                   |
| `apb_read_data_out` | Output | 8     | Data output from master during read              |

### APB Slave Signals
| Signal Name | Type   | Width | Description                                      |
|-------------|--------|-------|--------------------------------------------------|
| `pclk`      | Input  | 1     | Clock signal                                     |
| `presetn`   | Input  | 1     | Active-low reset signal                          |
| `psel`      | Input  | 1     | Slave select signal                              |
| `penable`   | Input  | 1     | Enable signal from master                        |
| `pwrite`    | Input  | 1     | Write signal (1 = write, 0 = read)               |
| `paddr`     | Input  | 8     | Address from master (lower 8 bits used)          |
| `pwdata`    | Input  | 8     | Write data from master                           |
| `prdata`    | Output | 8     | Read data to master                              |
| `pready`    | Output | 1     | Ready signal to master (1 = ready)               |
| `pslverr`   | Output | 1     | Error signal to master (1 = error)               |

### APB Top Module Signals
| Signal Name         | Type   | Width | Description                                      |
|---------------------|--------|-------|--------------------------------------------------|
| `pclk`              | Input  | 1     | Clock signal                                     |
| `presetn`           | Input  | 1     | Active-low reset signal                          |
| `transfer`          | Input  | 1     | Initiates a transaction                          |
| `read`              | Input  | 1     | Read enable signal                               |
| `write`             | Input  | 1     | Write enable signal                              |
| `apb_write_paddr`   | Input  | 9     | Write address for the slave                      |
| `apb_write_data`    | Input  | 8     | Data to be written to the slave                  |
| `apb_read_paddr`    | Input  | 9     | Read address for the slave                       |
| `pslverr`           | Output | 1     | Slave error signal                               |
| `apb_read_data_out` | Output | 8     | Data output during read                          |

## Test Cases
The testbench (`APB_tb.v`) includes the following test cases to verify the functionality of the APB system:

1. **Basic Write Operation (TC1)**  
   - **Description**: Tests a write transaction with no wait states.  
   - **Inputs**: `transfer = 1`, `write = 1`, `read = 0`, valid `apb_write_paddr`, valid `apb_write_data`.  
   - **Expected Output**: Slave receives correct address and data, `pready` is asserted after one clock cycle, and data is written to the correct memory location.  
   - **Test**: Writes data `8'hAA` to address `9'h005`.

2. **Basic Read Operation (TC2)**  
   - **Description**: Tests a read transaction with no wait states.  
   - **Inputs**: `transfer = 1`, `write = 0`, `read = 1`, valid `apb_read_paddr`.  
   - **Expected Output**: Slave returns correct data via `prdata`, `apb_read_data_out` contains expected data, `pready` is asserted after one clock cycle.  
   - **Test**: Reads data from address `9'h005`.

3. **Address Decoding (Slave Selection) (TC3)**  
   - **Description**: Validates that the master correctly selects the appropriate slave based on the address range.  
   - **Inputs**: Test addresses for Slave 1 (`9'h005`, `psel1 = 1`, `psel2 = 0`) and Slave 2 (`9'h085`, `psel1 = 0`, `psel2 = 1`).  
   - **Expected Output**: Only the correct slave is selected, and the other remains idle.  
   - **Test**: Writes `8'hA5` to `9'h005` (Slave 1) and `8'h5A` to `9'h085` (Slave 2).

4. **Write with Wait States (TC4)**  
   - **Description**: Tests a write transaction where the slave introduces wait states.  
   - **Inputs**: Slave delays asserting `pready`.  
   - **Expected Output**: Master remains in the ENABLE state until `pready` is asserted, and data is written only when the transfer completes.  
   - **Test**: Writes `8'hBB` to `9'h010` with a simulated wait state.

5. **Read with Wait States (TC5)**  
   - **Description**: Tests a read transaction where the slave introduces wait states.  
   - **Inputs**: Slave delays asserting `pready`.  
   - **Expected Output**: Master remains in the ENABLE state until `pready` is asserted, and correct data is captured when the transfer completes.  
   - **Test**: Reads from `9'h010` with a simulated wait state.

6. **Error Handling (PSLVERR) (TC6)**  
   - **Description**: Tests error conditions during a write operation with an invalid address.  
   - **Inputs**: Invalid address (`9'h1FF`), `write = 1`, `read = 0`.  
   - **Expected Output**: Slave asserts `pslverr`, and the master captures the error condition.  
   - **Test**: Attempts to write `8'hFF` to `9'h1FF`.

7. **Burst of Transfers (TC7)**  
   - **Description**: Tests multiple back-to-back read and write transfers.  
   - **Inputs**: Alternate read and write transactions without returning to IDLE.  
   - **Expected Output**: Master and slaves handle consecutive transfers correctly, with proper `psel` and `penable` transitions.  
   - **Test**: Performs write and read operations on addresses `9'h001`, `9'h002`, and `9'h003`.

8. **Out-of-Range Address (TC8)**  
   - **Description**: Tests system behavior with an address outside the valid range of the slaves.  
   - **Inputs**: Invalid address (`9'h1FF`).  
   - **Expected Output**: Slave asserts `pslverr`, and the master detects the error.  
   - **Test**: Attempts to write `8'hFF` to `9'h1FF`.

9. **Reset Behavior (TC9)**  
   - **Description**: Tests the reset functionality of the system.  
   - **Inputs**: Assert `presetn` (active-low reset).  
   - **Expected Output**: All signals return to their default states, and no transfers occur during reset.  
   - **Test**: Applies reset for 20 ns and verifies default states.

10. **Randomized Transactions (TC10)**  
    - **Description**: Stress-tests the system with randomized read and write operations.  
    - **Inputs**: Randomly generated `read`, `write`, `apb_write_paddr`, `apb_read_paddr`, and `apb_write_data`.  
    - **Expected Output**: System remains stable and handles transactions correctly.  
    - **Test**: Executes 20 randomized read and write transactions.

## Usage
1. **Simulation Environment**: Use a Verilog simulator (e.g., ModelSim, Vivado, or QuestaSim) to compile and simulate the design.
2. **Compilation**: Compile the Verilog files in the following order:
   - `APB_master.v`
   - `APB_slave.v`
   - `APB_top.v`
   - `APB_tb.v`
   - `run.do`
3. **Simulation**: Run the testbench (`APB_tb.v`) to execute all test cases. The testbench generates console output to display the progress and results of each test case.
4. **Verification**: Check the simulation logs and waveforms to verify that the system behaves as expected for each test case.

## Notes
- The APB master uses a finite state machine (FSM) with three states: IDLE, SETUP, and ENABLE.
- The slaves have a 256-byte memory and assert `pslverr` for addresses outside this range (`paddr >= 8'd256`).
- The testbench uses a 100 MHz clock (`pclk`) with a 10 ns period.
- Wait states in test cases 4 and 5 are simulated by delaying the slave response in the testbench, though the slave module itself does not explicitly model wait states.
- The system assumes that `read` and `write` signals are mutually exclusive to avoid undefined behavior.

## Author
**Karankumar Nevage**  
- **Email**: [karanpr9423@gmail.com](mailto:karanpr9423@gmail.com)  
- **LinkedIn**: [https://www.linkedin.com/in/karankumar-nevage/](https://www.linkedin.com/in/karankumar-nevage/)
